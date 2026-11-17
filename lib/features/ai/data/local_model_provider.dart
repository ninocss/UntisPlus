import 'dart:async';
import 'dart:io';

import 'package:fllama/fllama.dart';
import 'package:flutter/foundation.dart';

import 'remote_ai_provider.dart';

typedef LocalModelValidator = Future<bool> Function(String path);

/// Number of parallel slots allocated by native fllama (`params.n_parallel = 4`).
/// In llama.cpp, when kv_unified is false, each slot receives
/// `context_size / kLocalModelParallelSlots` tokens.
const int kLocalModelParallelSlots = 4;

/// Target usable context window per conversation slot.
const int kLocalModelDefaultSlotContext = 4096;

/// Default context size constant for backward compatibility.
const int kLocalModelContextSize = kLocalModelDefaultSlotContext;

/// Default output token budget for on-device generation. Keeping this at 512
/// ensures fast, responsive replies on phone hardware while preserving 3584+
/// tokens for schedule, homework, and exam data.
const int kLocalModelDefaultMaxTokens = 512;

/// Calculates the native context size to pass to llama.cpp so that each slot
/// receives at least [slotContextSize] tokens.
int nativeContextSizeForSlot(int slotContextSize) =>
    slotContextSize * kLocalModelParallelSlots;

/// Conservative token estimate (about 2.5 characters per token plus safety
/// margin) so that German compound words, JSON keys, numbers, and timetable
/// formatting never overflow the context window.
int estimateLocalTokens(String text) => (text.length / 2.5).ceil() + 8;

/// Limits the answer length to avoid context starvation. Caps at 1024 tokens
/// or half the slot context, whichever is smaller.
int effectiveLocalMaxTokens(int requested, int contextSize) {
  final ceiling = (contextSize ~/ 2).clamp(128, 1024);
  return requested.clamp(64, ceiling).toInt();
}

String _truncateHead(String text, int maxTokens) {
  final maxChars = (maxTokens * 2.5).clamp(0, text.length).toInt();
  return text.length <= maxChars ? text : text.substring(0, maxChars);
}

String _truncateMiddle(String text, int maxTokens) {
  final maxChars = (maxTokens * 2.5).toInt();
  if (text.length <= maxChars) return text;
  if (maxChars < 32) return text.substring(0, maxChars.clamp(0, text.length));
  final head = (maxChars * 0.45).floor();
  final tail = maxChars - head - 5;
  return '${text.substring(0, head)}\n...\n${text.substring(text.length - tail)}';
}

/// Fits [messages] (system prompt first, newest message last) into [budget]
/// estimated tokens.
///
/// Priority:
/// 1. The newest user message (at the end) is preserved completely whenever possible.
/// 2. Older conversation history (oldest user/assistant turns) is pruned first.
/// 3. If still over budget, the system prompt is trimmed (preserving the rules at the end).
/// 4. As an extreme last resort, the user query is truncated only if it alone exceeds the budget.
@visibleForTesting
List<Message> fitMessagesToBudget(
  List<Message> messages, {
  required int budget,
}) {
  if (messages.isEmpty) return messages;
  if (messages.length == 1) {
    final m = messages.first;
    if (estimateLocalTokens(m.text) <= budget) return messages;
    return [Message(m.role, _truncateHead(m.text, budget))];
  }

  final system = messages.first;
  final rest = [...messages.skip(1)];
  int restTokens() =>
      rest.fold<int>(0, (sum, m) => sum + estimateLocalTokens(m.text));

  var systemText = system.text;

  // 1. Prune oldest conversation history first (in user + assistant pairs)
  while (estimateLocalTokens(systemText) + restTokens() > budget &&
      rest.length > 1) {
    rest.removeAt(0);
    while (rest.length > 1 && rest.first.role == Role.assistant) {
      rest.removeAt(0);
    }
  }

  // 2. If still over budget, shorten the system prompt before touching the user query
  if (estimateLocalTokens(systemText) + restTokens() > budget) {
    final queryTokens = rest.isEmpty ? 0 : estimateLocalTokens(rest.last.text);
    final remainingForSystem = (budget - queryTokens - 8).clamp(64, budget).toInt();
    systemText = _truncateMiddle(systemText, remainingForSystem);
  }

  // 3. As an extreme last resort (e.g. giant pasted user text/file), trim the user query
  if (estimateLocalTokens(systemText) + restTokens() > budget && rest.isNotEmpty) {
    final last = rest.last;
    final maxQueryTokens =
        (budget - estimateLocalTokens(systemText) - 4).clamp(32, budget).toInt();
    rest[rest.length - 1] = Message(
      last.role,
      _truncateHead(last.text, maxQueryTokens),
    );
  }

  return [Message(system.role, systemText), ...rest];
}

/// Copy and dependencies needed by the on-device inference adapter.
class LocalModelRuntime {
  const LocalModelRuntime({
    required this.settings,
    required this.isValidModel,
    required this.loadErrorMessage,
    required this.noReplyMessage,
    this.contextExceededMessage = 'Context window exceeded',
    int? contextSize,
  }) : slotContextSize = contextSize ?? kLocalModelDefaultSlotContext;

  final int slotContextSize;
  int get contextSize => slotContextSize;
  int get nativeContextSize => nativeContextSizeForSlot(slotContextSize);
  final AiGenerationSettings settings;
  final LocalModelValidator isValidModel;
  final String loadErrorMessage;
  final String noReplyMessage;
  final String contextExceededMessage;
}

/// On-device LLM provider backed by fllama (llama.cpp).
class LocalModelProvider implements AIProvider {
  LocalModelProvider({required this.modelPath, required this.runtime});

  final String modelPath;
  final LocalModelRuntime runtime;

  bool _isLoading = false;
  final StringBuffer _nativeLogs = StringBuffer();

  @override
  Stream<String> streamResponse({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String model,
    List<AiChatAttachment> attachments = const [],
  }) async* {
    if (_isLoading) return;
    if (!await _prepareModel()) {
      throw Exception('AI: ${runtime.loadErrorMessage}');
    }

    final attachmentContext = attachments
        .where((attachment) => attachment.isText)
        .map(runtime.settings.formatAttachmentText)
        .join();
    final messages = <Message>[
      Message(Role.system, systemPrompt),
      for (final entry in history.indexed)
        Message(
          entry.$2['role'] == 'user' ? Role.user : Role.assistant,
          '${entry.$2['content'] ?? ''}${entry.$1 == history.length - 1 ? attachmentContext : ''}',
        ),
    ];

    final request = _request(messages);
    _isLoading = true;
    final controller = StreamController<String>.broadcast();

    var previousResponse = '';
    fllamaChat(request, (
      String rawResponse,
      String openaiResponseJsonString,
      bool done,
    ) {
      if (controller.isClosed) return;
      final response = stripThinkingBlocks(rawResponse);
      final pending = response.startsWith(previousResponse)
          ? response.substring(previousResponse.length)
          : response;
      previousResponse = response;
      if (done) {
        if (isFllamaLoadError(response)) {
          _reportLoadError();
          controller.addError(Exception('AI: ${runtime.loadErrorMessage}'));
        } else if (isFllamaContextExceededError(response)) {
          _reportLoadError();
          controller.addError(Exception('AI: ${runtime.contextExceededMessage}'));
        } else if (pending.isNotEmpty) {
          controller.add(pending);
        }
        controller.close();
      } else if (pending.isNotEmpty &&
          !isFllamaLoadError(response) &&
          !isFllamaContextExceededError(response)) {
        controller.add(pending);
      }
    }).catchError((Object error) {
      if (!controller.isClosed) {
        controller.addError(error);
        controller.close();
      }
      return -1;
    });

    try {
      yield* controller.stream;
    } finally {
      _isLoading = false;
    }
  }

  OpenAiRequest _request(List<Message> messages) {
    final settings = runtime.settings;
    final slotContext = runtime.slotContextSize;
    final maxTokens = effectiveLocalMaxTokens(settings.maxTokens, slotContext);
    final budget = slotContext - maxTokens;
    return OpenAiRequest(
      messages: fitMessagesToBudget(messages, budget: budget),
      modelPath: modelPath,
      contextSize: runtime.nativeContextSize,
      maxTokens: maxTokens,
      numGpuLayers: 0,
      temperature: settings.temperature,
      topP: settings.topP,
      frequencyPenalty: 0.5,
      presencePenalty: 0.5,
      logger: (String line) {
        if (_nativeLogs.length < 16000) _nativeLogs.write('$line\n');
      },
    );
  }

  Future<bool> _prepareModel() async {
    if (await runtime.isValidModel(modelPath)) return true;

    // Tiny files are interrupted downloads, not usable GGUF models.
    final file = File(modelPath);
    if (await file.exists() && await file.length() < 1024 * 1024) {
      try {
        await file.delete();
      } catch (_) {
        // A later download can still replace the file.
      }
    }
    return false;
  }

  void _reportLoadError() {
    final logTail = _nativeLogs.toString().trim();
    debugPrint('[LocalModel] load failed. Native log tail:\n$logTail');
  }

  @override
  Future<void> dispose() async {
    _isLoading = false;
  }
}

/// Runs a one-shot inference for non-chat features such as exam import.
Future<String> requestLocalModelText({
  required String systemPrompt,
  required String userQuery,
  required String modelPath,
  required LocalModelRuntime runtime,
}) async {
  final provider = LocalModelProvider(modelPath: modelPath, runtime: runtime);
  if (!await provider._prepareModel()) {
    throw Exception('AI: ${runtime.loadErrorMessage}');
  }

  final request = provider._request([
    Message(Role.system, systemPrompt),
    Message(Role.user, userQuery),
  ]);
  final buffer = StringBuffer();
  final completer = Completer<String>();
  var previousResponse = '';

  fllamaChat(request, (
    String response,
    String openaiResponseJsonString,
    bool done,
  ) {
    if (completer.isCompleted) return;
    final pending = response.startsWith(previousResponse)
        ? response.substring(previousResponse.length)
        : response;
    previousResponse = response;
    if (pending.isNotEmpty &&
        !isFllamaLoadError(response) &&
        !isFllamaContextExceededError(response)) {
      buffer.write(pending);
    }
    if (done) {
      if (isFllamaContextExceededError(response)) {
        completer.completeError(Exception('AI: ${runtime.contextExceededMessage}'));
      } else {
        completer.complete(buffer.toString().trim());
      }
    }
  }).catchError((Object error) {
    if (!completer.isCompleted) completer.completeError(error);
    return -1;
  });

  final result = await completer.future;
  if (isFllamaLoadError(result)) {
    provider._reportLoadError();
    final detail = lastMeaningfulNativeLine(provider._nativeLogs.toString());
    throw Exception(
      detail == null
          ? 'AI: ${runtime.loadErrorMessage}'
          : 'AI: ${runtime.loadErrorMessage}\n($detail)',
    );
  }
  if (isFllamaContextExceededError(result)) {
    throw Exception('AI: ${runtime.contextExceededMessage}');
  }
  final cleanResult = stripThinkingBlocks(result).trim();
  if (cleanResult.isEmpty) throw Exception('API: ${runtime.noReplyMessage}');
  return cleanResult;
}

/// Checks whether an error message or native output indicates a context window
/// overflow in llama.cpp / fllama.
bool isFllamaContextExceededError(String text) {
  final lower = text.toLowerCase();
  return lower.contains('exceeds the available context size') ||
      lower.contains('exceed_context_size') ||
      lower.contains('running out of context capacity') ||
      lower.contains('failed to find a slot') ||
      lower.contains('context capacity exceeded');
}

/// fllama does not currently classify every llama.cpp load failure itself.
bool isFllamaLoadError(String text) {
  return fllamaOutputIndicatesLoadError(text) ||
      text.contains('Error: Failed to create inference context');
}

String? lastMeaningfulNativeLine(String log) {
  final lines = log
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;
  final last = lines.last.trim();
  return last.length > 200 ? last.substring(last.length - 200) : last;
}

/// Removes Qwen3-style `<think>` reasoning from [text]. An unclosed
/// block (still streaming) is hidden until its closing tag arrives, so the
/// user never sees the raw reasoning.
@visibleForTesting
String stripThinkingBlocks(String text) {
  final withoutClosed = text.replaceAll(
    RegExp(r'<think>[\s\S]*?</think>\s*'),
    '',
  );
  final open = withoutClosed.indexOf('<think>');
  return open == -1 ? withoutClosed : withoutClosed.substring(0, open);
}
