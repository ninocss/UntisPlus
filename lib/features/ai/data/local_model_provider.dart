import 'dart:async';
import 'dart:io';

import 'package:fllama/fllama.dart';
import 'package:flutter/foundation.dart';

import 'remote_ai_provider.dart';

typedef LocalModelValidator = Future<bool> Function(String path);

/// Copy and dependencies needed by the on-device inference adapter.
class LocalModelRuntime {
  const LocalModelRuntime({
    required this.settings,
    required this.isValidModel,
    required this.loadErrorMessage,
    required this.noReplyMessage,
  });

  final AiGenerationSettings settings;
  final LocalModelValidator isValidModel;
  final String loadErrorMessage;
  final String noReplyMessage;
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
      String response,
      String openaiResponseJsonString,
      bool done,
    ) {
      if (controller.isClosed) return;
      final pending = response.startsWith(previousResponse)
          ? response.substring(previousResponse.length)
          : response;
      previousResponse = response;
      if (done) {
        if (isFllamaLoadError(response)) {
          _reportLoadError();
          controller.addError(Exception('AI: ${runtime.loadErrorMessage}'));
        } else if (pending.isNotEmpty) {
          controller.add(pending);
        }
        controller.close();
      } else if (pending.isNotEmpty && !isFllamaLoadError(response)) {
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
    return OpenAiRequest(
      messages: messages,
      modelPath: modelPath,
      contextSize: 1024,
      maxTokens: settings.maxTokens,
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
    if (pending.isNotEmpty) buffer.write(pending);
    if (done) completer.complete(buffer.toString().trim());
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
  if (result.isEmpty) throw Exception('API: ${runtime.noReplyMessage}');
  return result;
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
