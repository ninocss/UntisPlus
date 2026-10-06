import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/ai/presentation/chat_follow_state.dart';

void main() {
  test(
    'a gesture pauses streaming scroll before the first distance update',
    () {
      final follow = ChatFollowState();
      expect(follow.shouldFollow, isTrue);
      follow.beginUserScroll();
      expect(follow.shouldFollow, isFalse);
      follow.endScroll(250);
      expect(follow.shouldFollow, isFalse);
      follow.resume();
      expect(follow.shouldFollow, isTrue);
    },
  );
  test(
    'returning to the end resumes; programmatic endings do not change intent',
    () {
      final follow = ChatFollowState();
      follow.endScroll(200);
      expect(follow.shouldFollow, isTrue);
      follow.beginUserScroll();
      follow.endScroll(40);
      expect(follow.shouldFollow, isTrue);
      follow.beginUserScroll();
      follow.endScroll(double.infinity);
      expect(follow.shouldFollow, isFalse);
    },
  );
}
