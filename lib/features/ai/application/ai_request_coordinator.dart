import '../data/remote_ai_provider.dart';

typedef AiProviderFactory =
    AIProvider Function(
      AiProviderConfiguration configuration,
      AiGenerationSettings generationSettings,
    );

typedef AiDefaultModelResolver =
    String Function(String provider, String customCompatibility);

class AiRuntimeConfiguration {
  const AiRuntimeConfiguration({
    required this.provider,
    required this.apiKey,
    required this.customBaseUrl,
    required this.customCompatibility,
    required this.model,
    required this.localModelPath,
    required this.generationSettings,
    required this.providerFactory,
    required this.defaultModelResolver,
  });

  final String provider;
  final String apiKey;
  final String customBaseUrl;
  final String customCompatibility;
  final String model;
  final String localModelPath;
  final AiGenerationSettings generationSettings;
  final AiProviderFactory providerFactory;
  final AiDefaultModelResolver defaultModelResolver;
}

class AiRequestSpec {
  const AiRequestSpec({
    required this.systemPrompt,
    required this.userPrompt,
    required this.noReplyMessage,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.requiresImages = false,
    this.requiresPdf = false,
    this.attachments = const <AiChatAttachment>[],
    this.modelOverride,
    this.missingApiKeyMessage = 'API key missing',
    this.customBaseUrlMissingMessage = 'Custom base URL missing',
    this.localModelMissingMessage = 'Local model is not configured',
    this.unsupportedAttachmentMessage,
  });

  final String systemPrompt;
  final String userPrompt;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final bool requiresImages;
  final bool requiresPdf;
  final List<AiChatAttachment> attachments;
  final String? modelOverride;
  final String noReplyMessage;
  final String missingApiKeyMessage;
  final String customBaseUrlMissingMessage;
  final String localModelMissingMessage;
  final String Function(String mimeType)? unsupportedAttachmentMessage;
}

class AiResolvedRequest {
  const AiResolvedRequest({
    required this.provider,
    required this.model,
    required this.capabilities,
    required this.configuration,
    required this.generationSettings,
  });

  final String provider;
  final String model;
  final AiProviderCapabilities capabilities;
  final AiProviderConfiguration configuration;
  final AiGenerationSettings generationSettings;
}

class AiRequestCoordinator {
  const AiRequestCoordinator();

  String normalizeProvider(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'gemini' || 'openai' || 'mistral' || 'custom' || 'local' => normalized,
      _ => 'gemini',
    };
  }

  String normalizeCustomCompatibility(String value) =>
      value.trim().toLowerCase() == 'gemini' ? 'gemini' : 'openai';

  AiProviderCapabilities capabilities(AiRuntimeConfiguration runtime) =>
      AiProviderCapabilities.resolve(
        provider: normalizeProvider(runtime.provider),
        customCompatibility: normalizeCustomCompatibility(
          runtime.customCompatibility,
        ),
      );

  AiResolvedRequest resolve(
    AiRuntimeConfiguration runtime,
    AiRequestSpec spec,
  ) {
    final provider = normalizeProvider(runtime.provider);
    final compatibility = normalizeCustomCompatibility(
      runtime.customCompatibility,
    );
    final isLocal = provider == 'local';
    final apiKey = runtime.apiKey.trim();

    if (!isLocal && apiKey.isEmpty) {
      throw Exception('CONFIG: ${spec.missingApiKeyMessage}');
    }
    if (provider == 'custom' && runtime.customBaseUrl.trim().isEmpty) {
      throw Exception('CONFIG: ${spec.customBaseUrlMissingMessage}');
    }
    if (isLocal && runtime.localModelPath.trim().isEmpty) {
      throw Exception('CONFIG: ${spec.localModelMissingMessage}');
    }

    final resolvedCapabilities = AiProviderCapabilities.resolve(
      provider: provider,
      customCompatibility: compatibility,
    );
    final needsImages =
        spec.requiresImages || spec.attachments.any((item) => item.isImage);
    final needsPdf =
        spec.requiresPdf || spec.attachments.any((item) => item.isPdf);
    if (needsImages && !resolvedCapabilities.images) {
      final mimeType = spec.attachments
          .where((item) => item.isImage)
          .map((item) => item.mimeType)
          .firstOrNull;
      throw Exception(
        'API: ${spec.unsupportedAttachmentMessage?.call(mimeType ?? 'image/*') ?? 'Unsupported image attachment'}',
      );
    }
    if (needsPdf && !resolvedCapabilities.pdf) {
      throw Exception(
        'API: ${spec.unsupportedAttachmentMessage?.call('application/pdf') ?? 'Unsupported PDF attachment'}',
      );
    }

    final configuredModel = spec.modelOverride?.trim();
    final runtimeModel = runtime.model.trim();
    final model = configuredModel != null && configuredModel.isNotEmpty
        ? configuredModel
        : runtimeModel.isNotEmpty
        ? runtimeModel
        : runtime.defaultModelResolver(provider, compatibility);

    final baseSettings = runtime.generationSettings;
    final settings = AiGenerationSettings(
      temperature: spec.temperature ?? baseSettings.temperature,
      maxTokens: spec.maxTokens ?? baseSettings.maxTokens,
      topP: spec.topP ?? baseSettings.topP,
      formatAttachmentText: baseSettings.formatAttachmentText,
      formatUnsupportedAttachment: baseSettings.formatUnsupportedAttachment,
    );
    final configuration = AiProviderConfiguration(
      provider: provider,
      model: model,
      apiKey: apiKey,
      customBaseUrl: runtime.customBaseUrl,
      customCompatibility: compatibility,
      localModelPath: isLocal ? runtime.localModelPath : '',
    );
    return AiResolvedRequest(
      provider: provider,
      model: model,
      capabilities: resolvedCapabilities,
      configuration: configuration,
      generationSettings: settings,
    );
  }

  void validate(
    AiRuntimeConfiguration runtime,
    AiRequestSpec spec,
  ) {
    resolve(runtime, spec);
  }

  Future<String> generate({
    required AiRuntimeConfiguration runtime,
    required AiRequestSpec spec,
  }) {
    final resolved = resolve(runtime, spec);
    final provider = runtime.providerFactory(
      resolved.configuration,
      resolved.generationSettings,
    );
    return const AiTextGenerationService().generate(
      provider: provider,
      systemPrompt: spec.systemPrompt,
      userPrompt: spec.userPrompt,
      model: resolved.model,
      noReplyMessage: spec.noReplyMessage,
      attachments: spec.attachments,
    );
  }

  Stream<String> stream({
    required AiRuntimeConfiguration runtime,
    required AiRequestSpec spec,
    required List<Map<String, String>> history,
  }) async* {
    final resolved = resolve(runtime, spec);
    final provider = runtime.providerFactory(
      resolved.configuration,
      resolved.generationSettings,
    );
    try {
      yield* provider.streamResponse(
        systemPrompt: spec.systemPrompt,
        history: history,
        model: resolved.model,
        attachments: spec.attachments,
      );
    } finally {
      await provider.dispose();
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
