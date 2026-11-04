import 'package:flutter/material.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';

/// 44×44 rounded square icon button used in top bars.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: color ?? p.text,
              semanticLabel: tooltip,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar: back/close button + title + optional actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.close = false,
  });

  final String title;
  final List<Widget> actions;
  final bool close;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SquareIconButton(
            icon: close
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: context.displayFont,
                fontFamilyFallback: const ['Noto Sans Khmer'],
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Small uppercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: p.muted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Rounded pill button (Copy / Share chips).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: StadiumBorder(side: BorderSide(color: p.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: p.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big full-width button.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
    this.icon,
    this.height = 54,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;
  final IconData? icon;
  final double height;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = outlined ? p.surface : (background ?? p.accent);
    final fg = outlined ? p.text : (foreground ?? p.onAccent);
    return SizedBox(
      height: height,
      child: Material(
        color: onPressed == null ? bg.withValues(alpha: .5) : bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: outlined ? BorderSide(color: p.border) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
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

/// Bordered card container.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? p.border),
      ),
      child: child,
    );
  }
}

/// Gold "PREMIUM" tag.
class PremiumTag extends StatelessWidget {
  const PremiumTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2A230E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6B5A22)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppPalette.gold,
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: action,
        duration: const Duration(seconds: 3),
      ),
    );
}
