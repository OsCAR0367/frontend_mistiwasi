import 'package:flutter/material.dart';

/// Enum para definir el tipo de notificación
enum NotificationType { success, error, warning, info }

/// Widget personalizado para mostrar notificaciones profesionales
class CustomSnackBar {
  /// Muestra una notificación personalizada
  static void show({
    required BuildContext context,
    required String message,
    String? title,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
    IconData? customIcon,
  }) {
    final colors = _getColorsForType(type);
    final icon = customIcon ?? _getIconForType(type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),

              const SizedBox(width: 16),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: title != null ? 14 : 16,
                        color: Colors.white,
                        fontWeight: title != null
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de acción opcional
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: colors['primary'],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 12,
        duration: duration,
        action: null, // Deshabilitamos la acción por defecto
      ),
    );
  }

  /// Muestra una notificación de éxito
  static void showSuccess({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      message: message,
      title: title ?? 'Éxito',
      type: NotificationType.success,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Muestra una notificación de error
  static void showError({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      message: message,
      title: title ?? 'Error',
      type: NotificationType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Muestra una notificación de advertencia
  static void showWarning({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      message: message,
      title: title ?? 'Advertencia',
      type: NotificationType.warning,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Muestra una notificación informativa
  static void showInfo({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context: context,
      message: message,
      title: title ?? 'Información',
      type: NotificationType.info,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static Map<String, Color> _getColorsForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF45A049),
        };
      case NotificationType.error:
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFD32F2F),
        };
      case NotificationType.warning:
        return {
          'primary': const Color(0xFFFF9800),
          'secondary': const Color(0xFFF57C00),
        };
      case NotificationType.info:
      default:
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF1976D2),
        };
    }
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }
}

/// Widget de loading personalizado para operaciones
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    required this.message,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor espere...',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
