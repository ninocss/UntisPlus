part of '../../../main.dart';

class _AiTypingIndicator extends StatefulWidget {
  const _AiTypingIndicator({super.key});

  @override
  State<_AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<_AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_aiReduceMotion(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 20,
      width: 42,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final phase = (_controller.value + index * 0.18) * math.pi * 2;
              final wave = _aiReduceMotion(context)
                  ? 0.5
                  : (math.sin(phase) + 1) / 2;
              return Transform.translate(
                offset: Offset(0, _aiReduceMotion(context) ? 0 : -2 * wave),
                child: Opacity(
                  opacity: 0.42 + wave * 0.5,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
