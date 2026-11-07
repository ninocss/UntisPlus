import 'package:flutter_test/flutter_test.dart';
import 'package:fllama/fllama.dart';
import 'package:untisplus/features/ai/data/local_model_provider.dart';

void main() {
  group('local model diagnostics', () {
    test('recognizes the additional inference-context failure', () {
      expect(
        isFllamaLoadError('Error: Failed to create inference context'),
        isTrue,
      );
      expect(isFllamaLoadError('generated answer'), isFalse);
    });

    test('recognizes context window overflow errors', () {
      expect(
        isFllamaContextExceededError(
          'Error: request (1200 tokens) exceeds the available context size (1024 tokens), try increasing it',
        ),
        isTrue,
      );
      expect(
        isFllamaContextExceededError('stopped due to running out of context capacity'),
        isTrue,
      );
      expect(
        isFllamaContextExceededError('failed to find a slot for request'),
        isTrue,
      );
      expect(
        isFllamaContextExceededError('normal generated reply without errors'),
        isFalse,
      );
    });

    test('returns the last useful native log line', () {
      expect(
        lastMeaningfulNativeLine('first\n\n  final detail  \n'),
        'final detail',
      );
      expect(lastMeaningfulNativeLine(' \n '), isNull);
    });

    test('bounds long native log details', () {
      final detail = lastMeaningfulNativeLine(List.filled(240, 'x').join());
      expect(detail, hasLength(200));
    });
  });

  group('context budget', () {
    test('scales native context to compensate for fllama parallel slots', () {
      expect(kLocalModelParallelSlots, 4);
      expect(nativeContextSizeForSlot(4096), 16384);
      expect(nativeContextSizeForSlot(2048), 8192);
      expect(nativeContextSizeForSlot(1024), 4096);
    });

    test('caps answer reserve to avoid context starvation', () {
      expect(effectiveLocalMaxTokens(2600, 4096), 1024);
      expect(effectiveLocalMaxTokens(512, 4096), 512);
      expect(effectiveLocalMaxTokens(1, 4096), 64);
    });

    test('keeps a long question and drops the oldest history', () {
      final question = List.filled(900, 'wort').join(' ');
      final messages = [
        Message(Role.system, 'rules'),
        Message(Role.user, List.filled(2000, 'alt').join(' ')),
        Message(Role.assistant, 'antwort'),
        Message(Role.user, question),
      ];
      final fitted = fitMessagesToBudget(messages, budget: 3000);
      expect(fitted.first.text, 'rules');
      expect(fitted.last.text, question);
      expect(fitted.length, lessThan(messages.length));
      final total = fitted.fold<int>(
        0,
        (sum, m) => sum + estimateLocalTokens(m.text),
      );
      expect(total, lessThanOrEqualTo(3000));
    });

    test('shortens an oversized system prompt but keeps its rules', () {
      final system = '${'kontext ' * 5000}REGELN-ENDE';
      final fitted = fitMessagesToBudget([
        Message(Role.system, system),
        Message(Role.user, 'Was habe ich morgen?'),
      ], budget: 1500);
      expect(fitted.first.text, endsWith('REGELN-ENDE'));
      expect(fitted.last.text, 'Was habe ich morgen?');
      expect(estimateLocalTokens(fitted.first.text), lessThan(1500));
    });
  });

  group('stripThinkingBlocks', () {
    test('removes closed and unclosed reasoning', () {
      expect(stripThinkingBlocks('<think>a</think>\n\nHi'), 'Hi');
      expect(stripThinkingBlocks('<think>still'), '');
      expect(stripThinkingBlocks('Hi <think>x'), 'Hi ');
      expect(stripThinkingBlocks('plain'), 'plain');
      expect(
        stripThinkingBlocks(
          '<think>internal reasoning\nstep 2</think>Answer text',
        ),
        'Answer text',
      );
    });
  });
}
