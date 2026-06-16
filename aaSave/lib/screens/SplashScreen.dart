import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _size;
  late Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // LOGO : 0 → 300 → 0
    _size = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 300.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 300.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // BACKGROUND : 1 → 0 (disparition)
    _bgOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: _bgOpacity.value == 0,

              child: Opacity(
                opacity: _bgOpacity.value, // 👈 fond qui disparaît

                child: Container(
                  color: Colors.black,

                  child: Center(
                    child: SizedBox(
                      width: _size.value,
                      height: _size.value,
                      child: Image.asset("assets/logo.png"),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
