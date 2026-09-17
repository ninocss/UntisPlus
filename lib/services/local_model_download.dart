// local_model_download.dart
part of '../main.dart';

/// Downloads [url] to [targetPath] with connect/receive timeouts and
/// resumable transfer support.
///
/// If a partial file already exists at [targetPath], the download continues
/// from that byte offset via an HTTP `Range` request, so an interrupted
/// transfer (e.g. the app being suspended on iOS, or a dropped connection)
/// can be retried without starting from zero.
///
/// [expectedBytes] is the advertised model size. When the existing partial
/// file has reached that size it is assumed stale and restarted.
///
/// Returns the final number of bytes written. Throws on failure; the partial
/// file is left in place so a later attempt can resume it.
Future<int> _downloadLocalModelFile({
  required String url,
  required String targetPath,
  required CancelToken cancelToken,
  required void Function(int received, int total) onProgress,
  int expectedBytes = 0,
}) async {
  final dio = Dio();
  final partFile = File(targetPath);
  var start = 0;
  if (await partFile.exists()) {
    final existing = await partFile.length();
    if (expectedBytes > 0 && existing >= expectedBytes) {
      await partFile.delete();
    } else {
      start = existing;
    }
  }

  final response = await dio.get<ResponseBody>(
    url,
    options: Options(
      responseType: ResponseType.stream,
      headers: {
        'User-Agent': 'UntisPlus/1.0',
        if (start > 0) 'Range': 'bytes=$start-',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
    cancelToken: cancelToken,
  );

  // A 200 (instead of 206) means the server ignored our Range header and the
  // body starts at byte 0 again.
  final startOffset = response.statusCode == 206 ? start : 0;
  if (startOffset == 0 && await partFile.exists()) {
    await partFile.delete();
  }

  final body = response.data;
  if (body == null) {
    throw Exception('Download returned an empty response');
  }
  final contentLength = body.contentLength;
  final total = contentLength > 0 ? contentLength + startOffset : 0;

  final raf = await partFile.open(mode: FileMode.append);
  var received = startOffset;
  try {
    await for (final chunk in body.stream) {
      await raf.writeFrom(chunk);
      received += chunk.length;
      onProgress(received, total);
    }
  } finally {
    await raf.close();
  }
  return received;
}