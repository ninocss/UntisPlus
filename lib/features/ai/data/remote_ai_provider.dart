import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// A file that is available only while an assistant request is pending.
class AiChatAttachment {
  const AiChatAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.textExcerpt = '',
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
  final String textExcerpt;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isText => textExcerpt.isNotEmpty;
}

/// Runtime values shared by remote AI providers.
///
/// Keeping localized attachment copy here avoids coupling the transport layer
/// to global application state.
class AiGenerationSettings {
  const AiGenerationSettings({
    required this.temperature,
    required this.maxTokens,
    required this.topP,
    required this.formatAttachmentText,
    required this.formatUnsupportedAttachment,
  });

  final double temperature;
  final int maxTokens;
  final double topP;
  final String Function(AiChatAttachment attachment) formatAttachmentText;
  final String Function(AiChatAttachment attachment)
  formatUnsupportedAttachment;
}

abstract interface class AIProvider {
  Stream<String> streamResponse({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String model,
    List<AiChatAttachment> attachments = const [],
  });

  Future<void> dispose();
}

/// Decodes server-sent events across arbitrary HTTP chunk boundaries.
Stream<String> decodeSseDataEvents(Stream<List<int>> bytes) async* {
  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    final trimmed = line.trim();
    final data = line.startsWith('data:')
        ? line.substring(5).trim()
        // Some compatible APIs ignore `stream: true` and return one JSON body.
        : trimmed.startsWith('{')
        ? trimmed
        : '';
    if (data.isNotEmpty) yield data;
  }
}

abstract class RemoteAIProvider implements AIProvider {
  RemoteAIProvider({
    required this.apiKey,
    required this.settings,
    required this.useGeminiProtocol,
    this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String? baseUrl;
  final bool useGeminiProtocol;
  final AiGenerationSettings settings;
  final http.Client _client;

  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request);

  @override
  Future<void> dispose() async => _client.close();
}

class GeminiProvider extends RemoteAIProvider {
  GeminiProvider({
    required super.apiKey,
    required super.settings,
    String? endpoint,
    super.client,
  }) : _endpoint = endpoint,
       super(useGeminiProtocol: true);

  final String? _endpoint;

  @override
  Stream<String> streamResponse({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String model,
    List<AiChatAttachment> attachments = const [],
  }) async* {
    final lastUserIndex = history.lastIndexWhere(
      (message) => message['role'] == 'user',
    );
    final contents = history.indexed
        .map((entry) {
          final index = entry.$1;
          final message = entry.$2;
          final parts = <Map<String, dynamic>>[
            {'text': message['content'] ?? ''},
          ];
          if (index == lastUserIndex) {
            for (final attachment in attachments) {
              if (attachment.isImage || attachment.isPdf) {
                parts.add({
                  'inlineData': {
                    'mimeType': attachment.mimeType,
                    'data': base64Encode(attachment.bytes),
                  },
                });
              }
              if (attachment.isText) {
                parts.add({'text': settings.formatAttachmentText(attachment)});
              }
            }
          }
          return <String, dynamic>{
            'role': message['role'] == 'user' ? 'user' : 'model',
            'parts': parts,
          };
        })
        .toList(growable: false);

    final request = http.Request('POST', _geminiEndpoint(model))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': contents,
        'generationConfig': {
          'maxOutputTokens': settings.maxTokens,
          'temperature': settings.temperature,
          'topP': settings.topP,
        },
      });

    final response = await send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API: ${await response.stream.bytesToString()}');
    }

    await for (final data in decodeSseDataEvents(response.stream)) {
      if (data == '[DONE]') return;
      final decoded = _tryDecodeObject(data);
      final candidates = decoded?['candidates'];
      if (candidates is! List || candidates.isEmpty) continue;
      final content = candidates.first is Map
          ? (candidates.first as Map)['content']
          : null;
      final parts = content is Map ? content['parts'] : null;
      if (parts is! List) continue;
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          yield part['text'] as String;
        }
      }
    }
  }

  Uri _geminiEndpoint(String model) {
    final endpoint =
        _endpoint ??
        'https://generativelanguage.googleapis.com/v1beta/models/'
            '$model:streamGenerateContent?alt=sse&key=$apiKey';
    final uri = Uri.parse(endpoint);
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (!uri.queryParameters.containsKey('alt')) 'alt': 'sse',
        if (!uri.queryParameters.containsKey('key')) 'key': apiKey,
      },
    );
  }
}

class OpenAICompatibleProvider extends RemoteAIProvider {
  OpenAICompatibleProvider({
    required super.apiKey,
    required super.settings,
    required this.endpoint,
    super.baseUrl,
    super.client,
  }) : super(useGeminiProtocol: false);

  final String endpoint;

  @override
  Stream<String> streamResponse({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String model,
    List<AiChatAttachment> attachments = const [],
  }) async* {
    final lastUserIndex = history.lastIndexWhere(
      (message) => message['role'] == 'user',
    );
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      for (final entry in history.indexed)
        if (entry.$1 != lastUserIndex)
          Map<String, dynamic>.from(entry.$2)
        else
          {
            'role': 'user',
            'content': <Map<String, dynamic>>[
              {'type': 'text', 'text': entry.$2['content'] ?? ''},
              for (final attachment in attachments)
                _openAiAttachmentPart(attachment),
            ],
          },
    ];

    final request = http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      })
      ..body = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': settings.temperature,
        'max_tokens': settings.maxTokens,
        'top_p': settings.topP,
        'stream': true,
      });

    final response = await send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API: ${await response.stream.bytesToString()}');
    }

    await for (final data in decodeSseDataEvents(response.stream)) {
      if (data == '[DONE]') return;
      final decoded = _tryDecodeObject(data);
      final choices = decoded?['choices'];
      if (choices is! List || choices.isEmpty || choices.first is! Map) {
        continue;
      }
      final choice = choices.first as Map;
      final delta = choice['delta'];
      if (delta is Map && delta['content'] is String) {
        yield delta['content'] as String;
        continue;
      }
      final message = choice['message'];
      final content = message is Map ? message['content'] : null;
      if (content is String && content.isNotEmpty) {
        yield content;
      } else if (choice['text'] is String &&
          choice['text'].toString().isNotEmpty) {
        yield choice['text'].toString();
      }
    }
  }

  Map<String, dynamic> _openAiAttachmentPart(AiChatAttachment attachment) {
    if (attachment.isImage) {
      return {
        'type': 'image_url',
        'image_url': {
          'url':
              'data:${attachment.mimeType};base64,${base64Encode(attachment.bytes)}',
        },
      };
    }
    return {
      'type': 'text',
      'text': attachment.isText
          ? settings.formatAttachmentText(attachment)
          : settings.formatUnsupportedAttachment(attachment),
    };
  }
}

Map<String, dynamic>? _tryDecodeObject(String value) {
  try {
    final decoded = jsonDecode(value);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded.cast<String, dynamic>())
        : null;
  } catch (_) {
    return null;
  }
}

String normalizedAiBaseUrl(String value) {
  var normalized = value.trim();
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String openAiCompatibleEndpoint(String rawBaseUrl) {
  final base = normalizedAiBaseUrl(rawBaseUrl);
  if (base.isEmpty) return '';
  if (base.endsWith('/chat/completions')) return base;
  if (base.endsWith('/v1')) return '$base/chat/completions';
  if (base.endsWith('/v1/chat')) return '$base/completions';
  return '$base/v1/chat/completions';
}

String geminiCompatibleEndpoint(String rawBaseUrl, String model) {
  final base = normalizedAiBaseUrl(rawBaseUrl);
  if (base.isEmpty) return '';
  if (base.contains('/models/')) return base;
  if (base.contains('/v1beta') || base.contains('/v1')) {
    return '$base/models/$model:generateContent';
  }
  return '$base/v1beta/models/$model:generateContent';
}
