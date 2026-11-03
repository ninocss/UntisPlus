import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  test('local model catalog is consistent, updated, and anonymous', () {
    final ids = <String>{};
    final files = <String>{};
    for (final m in kLocalModels) {
      expect(ids.add(m.id), isTrue, reason: 'Duplicate model id: ${m.id}');
      expect(
        files.add(m.url.split('/').last),
        isTrue,
        reason: 'Duplicate file name: ${m.url}',
      );
      expect(m.url, startsWith('https://huggingface.co/'));
      expect(m.url, endsWith('.gguf'));
      expect(m.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(m.sizeGb, greaterThan(0));
    }
    // Default model is Qwen3 1.7B
    expect(kLocalModels.first.id, 'qwen3-1.7b-q4_k_m');

    // Ultra-fast model is Qwen3 0.6B (0.37 GB)
    final ultraFast = kLocalModels.firstWhere(
      (m) => m.id == 'qwen3-0.6b-q4_k_m',
    );
    expect(ultraFast.sizeGb, 0.37);

    // Fast LFM2 model (0.68 GB)
    final lfm2 = kLocalModels.firstWhere((m) => m.id == 'lfm2-1.2b-q4_k_m');
    expect(lfm2.sizeGb, 0.68);

    // Granite hybrid model (1.81 GB)
    final granite = kLocalModels.firstWhere(
      (m) => m.id == 'granite-4.0-h-micro-q4_k_m',
    );
    expect(granite.sizeGb, 1.81);

    // Verified catalog count
    expect(kLocalModels.length, 7);
  });
}
