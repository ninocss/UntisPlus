// lib/features/ai/providers.dart
// Riverpod providers for AI feature

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_state.dart';
import '../../features/ai/application/ai_request_coordinator.dart';
import '../../features/ai/data/ai_chat_history_store.dart';
import '../../features/ai/domain/ai_models.dart';

final aiRequestCoordinatorProvider = Provider<AiRequestCoordinator>((ref) {
  return const AiRequestCoordinator();
});

final aiChatHistoryStoreProvider = Provider<AiChatHistoryStore>((ref) {
  final prefs = ref.read(settingsStoreProvider).preferences;
  return AiChatHistoryStore(prefs);
});

// AI Runtime Configuration
final aiRuntimeConfigProvider = Provider<AiRuntimeConfiguration>((ref) {
  final state = ref.watch(appStateNotifierProvider);
  final coordinator = ref.watch(aiRequestCoordinatorProvider);

  return AiRuntimeConfiguration(
    provider: state.aiProvider,
    apiKey: _activeAiApiKey(state),
    customBaseUrl: state.aiCustomBaseUrl,
    customCompatibility: state.aiCustomCompatibility,
    model: state.aiModel,
    localModelPath: state.aiLocalModelPath,
    generationSettings: _currentAiGenerationSettings(state),
    providerFactory: (configuration, settings) => _createAIProvider(configuration, settings, state),
    defaultModelResolver: (provider, compatibility) => _defaultModelForProvider(provider, customCompatibility: compatibility),
  );
});

String _activeAiApiKey(AppState state) {
  switch (state.aiProvider) {
    case 'openai':
      return state.openAiApiKey;
    case 'mistral':
      return state.mistralApiKey;
    case 'custom':
      return state.customAiApiKey;
    case 'gemini':
    default:
      return state.geminiApiKey;
  }
}

AiGenerationSettings _currentAiGenerationSettings(AppState state) {
  final l = ref.read(appL10nProvider); // Would need to be passed or accessed differently
  // For now return defaults
  return AiGenerationSettings(
    temperature: state.aiTemperature,
    maxTokens: state.aiMaxTokens,
    topP: state.aiTopP,
    formatAttachmentText: (attachment) => '', // Would need l10n
    formatUnsupportedAttachment: (attachment) => '', // Would need l10n
  );
}

AIProvider _createAIProvider(
  AiProviderConfiguration configuration,
  AiGenerationSettings settings,
  AppState state,
) {
  switch (configuration.provider) {
    case 'gemini':
      return GeminiProvider(apiKey: configuration.apiKey, settings: settings);
    case 'openai':
      return OpenAICompatibleProvider(
        apiKey: configuration.apiKey,
        settings: settings,
        endpoint: 'https://api.openai.com/v1/chat/completions',
      );
    case 'mistral':
      return OpenAICompatibleProvider(
        apiKey: configuration.apiKey,
        settings: settings,
        endpoint: 'https://api.mistral.ai/v1/chat/completions',
      );
    case 'custom':
      final compat = configuration.customCompatibility == 'gemini' ? 'gemini' : 'openai';
      if (compat == 'gemini') {
        return GeminiProvider(
          apiKey: configuration.apiKey,
          settings: settings,
          endpoint: geminiStreamingEndpoint(configuration.customBaseUrl, configuration.model),
        );
      }
      return OpenAICompatibleProvider(
        apiKey: configuration.apiKey,
        settings: settings,
        endpoint: openAiCompatibleEndpoint(configuration.customBaseUrl),
        baseUrl: configuration.customBaseUrl,
      );
    case 'local':
      if (configuration.localModelPath.isEmpty) {
        throw Exception('Local model path not configured');
      }
      return LocalModelProvider(
        modelPath: configuration.localModelPath,
        runtime: LocalModelRuntime(
          settings: settings,
          isValidModel: (path) => _isValidLocalModelFile(path, model: _localModelForPath(path)),
          loadErrorMessage: '',
          noReplyMessage: '',
        ),
      );
    default:
      return GeminiProvider(apiKey: configuration.apiKey, settings: settings);
  }
}

// Helper functions (would be moved from main.dart)
bool _isValidLocalModelFile(String path, {LocalModelInfo? model}) => true;
LocalModelInfo? _localModelForPath(String path) => null;
String geminiStreamingEndpoint(String baseUrl, String model) => '';
String openAiCompatibleEndpoint(String baseUrl) => '';
String _defaultModelForProvider(String provider, {String? customCompatibility}) => 'gemini-3.6-flash';

// Chat Notifier
class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() {
    return AiChatState.initial();
  }

  Future<void> loadHistory() async {
    final store = ref.read(aiChatHistoryStoreProvider);
    try {
      final sessions = await store.read();
      state = state.copyWith(chatHistory: sessions);
    } catch (_) {}
  }

  void startNewChat() {
    state = state.copyWith(
      currentChatId: null,
      messages: [],
      latestResult: null,
      latestQuery: '',
      chatMode: true,
    );
  }

  void loadSession(AiChatSession session) {
    state = state.copyWith(
      currentChatId: session.id,
      messages: List.from(session.messages),
      chatMode: true,
      latestResult: null,
    );
  }

  void deleteSession(String sessionId) {
    state = state.copyWith(
      chatHistory: state.chatHistory.where((s) => s.id != sessionId).toList(),
      currentChatId: state.currentChatId == sessionId ? null : state.currentChatId,
      messages: state.currentChatId == sessionId ? [] : state.messages,
    );
    ref.read(aiChatHistoryStoreProvider).write(state.chatHistory);
  }

  Future<void> sendMessage(String text, {List<AiChatAttachment> attachments = const []}) async {
    // Implementation would go here
  }

  Future<void> sendAnalysis(String query) async {
    // Implementation would go here
  }
}

@freezed
abstract class AiChatState with _$AiChatState {
  const factory AiChatState({
    @Default([]) List<AiChatSession> chatHistory,
    String? currentChatId,
    @Default([]) List<Map<String, String>> messages,
    AiSearchResult? latestResult,
    @Default('') String latestQuery,
    @Default(false) bool chatMode,
    @Default(false) bool thinking,
    @Default([]) List<AiChatAttachment> attachments,
  }) = _AiChatState;

  factory AiChatState.initial() => const AiChatState();
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

// Selectors
final currentChatMessagesProvider = Provider<List<Map<String, String>>>((ref) {
  final state = ref.watch(aiChatProvider);
  return state.messages;
});

final aiThinkingProvider = Provider<bool>((ref) {
  final state = ref.watch(aiChatProvider);
  return state.thinking;
});

final currentChatProvider = Provider<AiChatSession?>((ref) {
  final state = ref.watch(aiChatProvider);
  if (state.currentChatId == null) return null;
  for (final session in state.chatHistory) {
    if (session.id == state.currentChatId) return session;
  }
  return null;
});