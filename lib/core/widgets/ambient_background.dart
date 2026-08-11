import 'package:flutter/material.dart';

/// Ambient app background: navy gradient + signature glows, shared by the
/// pre-auth screens so they feel like part of the main app shell.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020510), Color(0xFF060919), Color(0xFF0A051E)],
          stops: [0, 0.4, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 90,
            left: -80,
            child: _Glow(size: 300, color: Color(0x0F00D4AA)),
          ),
          const Positioned(
            bottom: 60,
            right: -60,
            child: _Glow(size: 380, color: Color(0x0F8B7EFF)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
