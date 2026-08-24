import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Primary CTA — gradient pill with sparkle well (left) and arrow well (right),
/// hover lift + shadow growth (matches the approved CSS).
class NexoraPrimaryButton extends StatefulWidget {
  const NexoraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// [compact] reduces height on small screens.
  final bool compact;

  @override
  State<NexoraPrimaryButton> createState() => _NexoraPrimaryButtonState();
}

class _NexoraPrimaryButtonState extends State<NexoraPrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 60.0 : 66.0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: height,
          width: double.infinity,
          transform: Matrix4.translationValues(0, _hovered && !_pressed ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _hovered ? AppColors.primaryShadowHover : AppColors.primaryShadow,
                blurRadius: _hovered ? 24 : 16,
                offset: Offset(0, _hovered ? 10 : 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 22,
                child: _Well(
                  width: 38,
                  height: 38,
                  radius: 12,
                  child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.background),
                ),
              ),
              Text(widget.label, style: AppTextStyles.primaryButton.copyWith(color: AppColors.background)),
              Positioned(
                right: 18,
                child: _Well(
                  width: 42,
                  height: 42,
                  radius: 21,
                  child: Icon(
                    rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                    size: 24,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary CTA — glassy dark pill with violet border, hover tint.
class NexoraSecondaryButton extends StatefulWidget {
  const NexoraSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<NexoraSecondaryButton> createState() => _NexoraSecondaryButtonState();
}

class _NexoraSecondaryButtonState extends State<NexoraSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 58,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.purple.withValues(alpha: 0.12) : AppColors.card,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _hovered ? AppColors.purple : AppColors.borderViolet,
            ),
          ),
          child: Text(widget.label, style: AppTextStyles.secondaryButton),
        ),
      ),
    );
  }
}

class _Well extends StatelessWidget {
  const _Well({
    required this.width,
    required this.height,
    required this.radius,
    required this.child,
  });

  final double width;
  final double height;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: child),
    );
  }
}
