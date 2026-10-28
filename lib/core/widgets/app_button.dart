import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Primary filled blue button (#1565C0), white bold text, pill shape (radius 18), height 52.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseAppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.blue,
      foregroundColor: AppColors.white,
      disabledBackgroundColor: const Color(0xFFD5DEEC),
      disabledForegroundColor: AppColors.muted,
      height: 52,
    );
  }
}

/// Secondary button: white background, 1.5px blue border, blue bold text, height 52.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseAppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.blue,
      borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      height: 52,
    );
  }
}

/// Danger filled red button (#B3261E), white text, height 52.
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseAppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.danger,
      foregroundColor: AppColors.white,
      height: 52,
    );
  }
}

/// Danger outlined button: white background, light line border (#D3DFEF), red text, height 52.
class DangerOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DangerOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseAppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.danger,
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      height: 52,
    );
  }
}

/// Neutral outlined button: white background, light border (#D3DFEF), dark blue text (#0B3470), height 52.
class NeutralOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const NeutralOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseAppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.navy,
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      height: 52,
    );
  }
}

/// Small pill button (height 40) for card actions: Details, Book, Accept, Decline, Start call.
enum SmallButtonVariant { primary, secondary, dangerOutlined, neutralOutlined }

class SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final SmallButtonVariant variant;

  const SmallButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = SmallButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case SmallButtonVariant.primary:
        bg = AppColors.blue;
        fg = AppColors.white;
        border = null;
        break;
      case SmallButtonVariant.secondary:
        bg = AppColors.white;
        fg = AppColors.blue;
        border = const BorderSide(color: AppColors.blue, width: 1.5);
        break;
      case SmallButtonVariant.dangerOutlined:
        bg = AppColors.white;
        fg = AppColors.danger;
        border = const BorderSide(color: AppColors.line, width: 1.5);
        break;
      case SmallButtonVariant.neutralOutlined:
        bg = AppColors.white;
        fg = AppColors.navy;
        border = const BorderSide(color: AppColors.line, width: 1.5);
        break;
    }

    return _BaseAppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
      borderSide: border,
      height: 40,
      fontSize: 13,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      isFullWidth: false,
    );
  }
}

/// Text link button: bold blue text, no border.
class TextLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final double fontSize;

  const TextLinkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.blue;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: text,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: fg,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Generic adapter maintaining full backward compatibility for `AppButton`.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDanger;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDanger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isDanger) {
      return DangerButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
      );
    } else if (isSecondary) {
      return SecondaryButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
      );
    } else {
      return PrimaryButton(
        text: text,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
      );
    }
  }
}

class _BaseAppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final BorderSide? borderSide;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final bool isFullWidth;

  const _BaseAppButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    required this.backgroundColor,
    required this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.borderSide,
    required this.height,
    this.fontSize = 16,
    this.icon,
    this.padding,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabledBg = disabledBackgroundColor ?? const Color(0xFFD5DEEC);
    final disabledFg = disabledForegroundColor ?? AppColors.muted;

    final childWidget = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: disabledBg,
        disabledForegroundColor: disabledFg,
        minimumSize: Size(isFullWidth ? double.infinity : 48, height),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: borderSide ?? BorderSide.none,
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: onPressed == null ? disabledFg : foregroundColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: onPressed == null ? disabledFg : foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: text,
      child: isFullWidth ? SizedBox(width: double.infinity, height: height, child: childWidget) : childWidget,
    );
  }
}
