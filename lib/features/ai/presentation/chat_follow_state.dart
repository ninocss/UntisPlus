/// Following stops as soon as a user gesture starts, before layout/streaming
/// can move the reading position. Programmatic scroll endings do not opt out.
class ChatFollowState {
  bool _following = true;
  bool _userScrolling = false;
  bool get shouldFollow => _following && !_userScrolling;

  void beginUserScroll() {
    _userScrolling = true;
    _following = false;
  }

  void endScroll(double distanceFromEnd) {
    if (!_userScrolling) return;
    _userScrolling = false;
    _following = distanceFromEnd.isFinite && distanceFromEnd <= 80;
  }

  void resume() {
    _userScrolling = false;
    _following = true;
  }
}
