import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animation.value * 5),
              child: Text(
                '.',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animation.value * 5),
              child: Text(
                '.',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animation.value * 5),
              child: Text(
                '.',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
