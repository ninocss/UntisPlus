// local_model_download.dart
part of '../main.dart';

/// The four magic bytes that every GGUF file starts with.
const String _kGgufMagic = 'GGUF';

/// Minimum size (1 MiB) below which a file can never be a usable GGUF model.
const int _kMinGgufSize = 1024 * 1024;

/// Reads the GGUF magic header of [file], or null when the file is shorter
/// than the magic or cannot be read.
Future<String?> _readGgufMagic(File file) async {
  final raf = await file.open();
  try {
    final bytes = await raf.read(4);
    if (bytes.length < 4) return null;
    return String.fromCharCodes(bytes);
  } finally {
    await raf.close();
  }
}

/// Lightweight validator shared by download, settings and startup: the file
/// must exist, be at least 1 MiB, start with the four-byte `GGUF` magic and —
/// when [model] is given — be close to the advertised model size.
///
/// This gate is deliberately cheap (it reads exactly 4 bytes). Full integrity
/// of freshly downloaded files is enforced separately by
/// [_verifyLocalModelChecksum].
Future<bool> _isValidLocalModelFile(
  String path, {
  LocalModelInfo? model,
}) async {
  try {
    final file = File(path);
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < _kMinGgufSize) return false;
    if (await _readGgufMagic(file) != _kGgufMagic) return false;
    if (model != null) {
      final expectedBytes = (model.sizeGb * 1024 * 1024 * 1024).toInt();
      // Reject both truncated downloads (below 60%) and swapped/larger files
      // (above 150%).
      if (length < expectedBytes * 0.6 || length > expectedBytes * 1.5) {
        return false;
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Returns true when an existing partial download is worth resuming: it is not
/// empty, is smaller than the advertised model size and still starts with the
/// GGUF magic. A corrupt earlier attempt (e.g. an old HTTP error page or
/// interstitial body persisted before the status check existed) is not resumed
/// — appending fresh bytes to it would both waste bandwidth and carry stale
/// bytes forward into the final model, so a restart is forced instead.
Future<bool> _isResumableGgufPartial(
  File partFile, {
  required int expectedBytes,
}) async {
  try {
    final length = await partFile.length();
    if (length <= 0) return false;
    if (expectedBytes > 0 && length >= expectedBytes) return false;
    return await _readGgufMagic(partFile) == _kGgufMagic;
  } catch (_) {
    return false;
  }
}

/// Verifies the file at [path] against the SHA-256 digest pinned on [model].
/// A downloaded model is only promoted to the final path after this passes.
/// Models without a pinned digest (empty `sha256`) are accepted so the catalog
/// can grow without blocking downloads, but every pinned model must keep its
/// digest in sync with the upstream artifact.
Future<bool> _verifyLocalModelChecksum(
  String path,
  LocalModelInfo model,
) async {
  if (model.sha256.isEmpty) return true;
  try {
    final file = File(path);
    if (!await file.exists()) return false;
    return await _sha256OfFile(file) == model.sha256;
  } catch (_) {
    return false;
  }
}

/// Streams [file] through SHA-256 without buffering it in memory and returns
/// the lowercase hex digest.
Future<String> _sha256OfFile(File file) async {
  final sink = const DartSha256().newHashSink();
  final raf = await file.open();
  const chunkSize = 1 << 20; // 1 MiB
  final buffer = Uint8List(chunkSize);
  try {
    while (true) {
      final read = await raf.readInto(buffer, 0, chunkSize);
      if (read == 0) break;
      sink.addSlice(buffer, 0, read, false);
    }
  } finally {
    await raf.close();
  }
  sink.close();
  final hash = await sink.hash();
  return hash.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// Downloads [url] to [targetPath] with connect/receive timeouts and
/// resumable transfer support.
///
/// If a partial file already exists at [targetPath], the download continues
/// from that byte offset via an HTTP `Range` request, so an interrupted
/// transfer (e.g. the app being suspended on iOS, or a dropped connection)
/// can be retried without starting from zero. The existing partial is only
/// resumed when it still looks like a GGUF prefix; a corrupt partial is
/// restarted from scratch.
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
    } else if (existing > 0 &&
        !await _isResumableGgufPartial(
          partFile,
          expectedBytes: expectedBytes,
        )) {
      // Never append fresh bytes to a corrupt old partial (error page,
      // interstitial, or unrelated file). Wipe it and restart cleanly.
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
      // Only 200 (full body) and 206 (partial body) are accepted. Redirect
      // landing pages, HTML error pages and interstitial bodies must never be
      // persisted into the partial file.
      validateStatus: (status) =>
          status != null && (status == 200 || status == 206),
    ),
    cancelToken: cancelToken,
  );

  // Belt and suspenders: Dio already rejects anything but 200/206 via
  // [validateStatus], but never stream a body that was not explicitly
  // accepted as a model response.
  if (response.statusCode != 200 && response.statusCode != 206) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: 'Unexpected HTTP status ${response.statusCode}',
    );
  }

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