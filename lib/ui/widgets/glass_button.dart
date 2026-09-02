import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tombol Apple Glossy Glass Button menggunakan Material & InkWell untuk jaminan responsif 100%
class GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.isPrimary
                ? AppTheme.electricBlue.withOpacity(_isHovered ? 0.45 : 0.25)
                : AppTheme.glassShadow,
            blurRadius: _isHovered ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled ? widget.onPressed : null,
          onHover: (hovering) {
            setState(() => _isHovered = hovering);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.isPrimary
                  ? (_isHovered
                      ? const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF0052CC)],
                        )
                      : AppTheme.electricGradient)
                  : (_isHovered
                      ? LinearGradient(
                          colors: [Colors.white, Colors.blue.shade50],
                        )
                      : AppTheme.glassGlossGradient),
              border: Border.all(
                color: widget.isPrimary
                    ? Colors.white.withOpacity(0.4)
                    : (_isHovered ? AppTheme.electricBlue : AppTheme.glassBorder),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isPrimary ? Colors.white : AppTheme.electricBlue,
                      ),
                    ),
                  )
                else
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.isPrimary
                        ? Colors.white
                        : (_isHovered ? AppTheme.electricBlue : AppTheme.royalBlue),
                  ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : (_isHovered ? AppTheme.electricBlue : AppTheme.textPrimary),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
