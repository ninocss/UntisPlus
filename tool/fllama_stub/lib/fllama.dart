enum Role { system, user, assistant }

class Message {
  const Message(this.role, this.content);

  final Role role;
  final String content;
}

typedef FllamaLogger = void Function(String line);
typedef FllamaCallback =
    void Function(String response, String openaiResponseJsonString, bool done);

class OpenAiRequest {
  const OpenAiRequest({
    required this.messages,
    required this.modelPath,
    required this.contextSize,
    required this.maxTokens,
    required this.numGpuLayers,
    required this.temperature,
    required this.topP,
    required this.frequencyPenalty,
    required this.presencePenalty,
    this.logger,
  });

  final List<Message> messages;
  final String modelPath;
  final int contextSize;
  final int maxTokens;
  final int numGpuLayers;
  final double temperature;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final FllamaLogger? logger;
}

Future<int> fllamaChat(OpenAiRequest request, FllamaCallback callback) async {
  throw UnsupportedError(
    'The local AI native runtime is intentionally disabled in core tests.',
  );
}

bool fllamaOutputIndicatesLoadError(String text) => false;
