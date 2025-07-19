import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../styles/app_theme.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class ToastMessage extends StatelessWidget {
  final String message;
  final ToastType type;
  final String? title;
  final VoidCallback? onAction;
  final String? actionText;
  final Duration? duration;

  const ToastMessage({
    super.key,
    required this.message,
    this.type = ToastType.info,
    this.title,
    this.onAction,
    this.actionText,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = _getColors(type);
    final icon = _getIcon(type);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors['border']!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors['shadow']!,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors['background']!,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colors['icon']!,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.getTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionText ?? 'Ação',
                  style: TextStyle(
                    color: colors['icon']!,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getColors(ToastType type) {
    switch (type) {
      case ToastType.success:
        return {
          'background': AppTheme.successColor.withValues(alpha: 0.1),
          'icon': AppTheme.successColor,
          'border': AppTheme.successColor.withValues(alpha: 0.2),
          'shadow': AppTheme.successColor.withValues(alpha: 0.1),
        };
      case ToastType.error:
        return {
          'background': AppTheme.errorColor.withValues(alpha: 0.1),
          'icon': AppTheme.errorColor,
          'border': AppTheme.errorColor.withValues(alpha: 0.2),
          'shadow': AppTheme.errorColor.withValues(alpha: 0.1),
        };
      case ToastType.warning:
        return {
          'background': AppTheme.warningColor.withValues(alpha: 0.1),
          'icon': AppTheme.warningColor,
          'border': AppTheme.warningColor.withValues(alpha: 0.2),
          'shadow': AppTheme.warningColor.withValues(alpha: 0.1),
        };
      case ToastType.info:
        return {
          'background': AppTheme.primaryColor.withValues(alpha: 0.1),
          'icon': AppTheme.primaryColor,
          'border': AppTheme.primaryColor.withValues(alpha: 0.2),
          'shadow': AppTheme.primaryColor.withValues(alpha: 0.1),
        };
    }
  }

  IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return PhosphorIcons.checkCircle();
      case ToastType.error:
        return PhosphorIcons.xCircle();
      case ToastType.warning:
        return PhosphorIcons.warning();
      case ToastType.info:
        return PhosphorIcons.info();
    }
  }
}

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  static ToastService get instance => _instance;

  void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onAction,
    String? actionText,
    Duration? duration,
  }) {
    _showToast(
      context,
      ToastMessage(
        message: message,
        type: ToastType.success,
        title: title,
        onAction: onAction,
        actionText: actionText,
        duration: duration,
      ),
    );
  }

  void showError(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onAction,
    String? actionText,
    Duration? duration,
  }) {
    _showToast(
      context,
      ToastMessage(
        message: message,
        type: ToastType.error,
        title: title,
        onAction: onAction,
        actionText: actionText,
        duration: duration,
      ),
    );
  }

  void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onAction,
    String? actionText,
    Duration? duration,
  }) {
    _showToast(
      context,
      ToastMessage(
        message: message,
        type: ToastType.warning,
        title: title,
        onAction: onAction,
        actionText: actionText,
        duration: duration,
      ),
    );
  }

  void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onAction,
    String? actionText,
    Duration? duration,
  }) {
    _showToast(
      context,
      ToastMessage(
        message: message,
        type: ToastType.info,
        title: title,
        onAction: onAction,
        actionText: actionText,
        duration: duration,
      ),
    );
  }

  void _showToast(BuildContext context, ToastMessage toast) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: toast,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(toast.duration ?? const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }
}
