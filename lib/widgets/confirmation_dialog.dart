import 'package:flutter/material.dart';

/// Enum para definir el tipo de acción del diálogo
enum ConfirmationDialogType { info, success, warning, danger, question }

/// Widget personalizado para diálogos de confirmación profesionales
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ConfirmationDialogType type;
  final IconData? customIcon;
  final bool barrierDismissible;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.type = ConfirmationDialogType.question,
    this.customIcon,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType();
    final icon = customIcon ?? _getIconForType();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header compacto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors['primary']!.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Icono más pequeño
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colors['primary']!,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: colors['primary']!.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 30, color: Colors.white),
                  ),

                  const SizedBox(height: 16),

                  // Título más compacto
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido más compacto
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // Mensaje
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Botones más compactos
                  Row(
                    children: [
                      // Botón cancelar
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                            onCancel?.call();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            cancelText ?? 'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Botón confirmar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                            onConfirm?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors['primary']!,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            confirmText ?? 'Confirmar',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getColorsForType() {
    switch (type) {
      case ConfirmationDialogType.success:
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF45A049),
          'background': const Color(0xFF4CAF50),
        };
      case ConfirmationDialogType.warning:
        return {
          'primary': const Color(0xFFFF9800),
          'secondary': const Color(0xFFF57C00),
          'background': const Color(0xFFFF9800),
        };
      case ConfirmationDialogType.danger:
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFD32F2F),
          'background': const Color(0xFFF44336),
        };
      case ConfirmationDialogType.info:
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF1976D2),
          'background': const Color(0xFF2196F3),
        };
      case ConfirmationDialogType.question:
      default:
        return {
          'primary': const Color(0xFF9C27B0),
          'secondary': const Color(0xFF7B1FA2),
          'background': const Color(0xFF9C27B0),
        };
    }
  }

  IconData _getIconForType() {
    switch (type) {
      case ConfirmationDialogType.success:
        return Icons.check_circle_outline;
      case ConfirmationDialogType.warning:
        return Icons.warning_amber_outlined;
      case ConfirmationDialogType.danger:
        return Icons.error_outline;
      case ConfirmationDialogType.info:
        return Icons.info_outline;
      case ConfirmationDialogType.question:
      default:
        return Icons.help_outline;
    }
  }

  /// Helper method para mostrar un diálogo de confirmación de manera sencilla
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    ConfirmationDialogType type = ConfirmationDialogType.question,
    IconData? customIcon,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        type: type,
        customIcon: customIcon,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

/// Widget para diálogos de input profesionales
class InputDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? hintText;
  final String? initialValue;
  final String? confirmText;
  final String? cancelText;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ConfirmationDialogType type;
  final IconData? customIcon;

  const InputDialog({
    super.key,
    required this.title,
    required this.message,
    this.hintText,
    this.initialValue,
    this.confirmText,
    this.cancelText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.type = ConfirmationDialogType.question,
    this.customIcon,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();

  /// Helper method para mostrar un diálogo de input de manera sencilla
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? hintText,
    String? initialValue,
    String? confirmText,
    String? cancelText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ConfirmationDialogType type = ConfirmationDialogType.question,
    IconData? customIcon,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InputDialog(
        title: title,
        message: message,
        hintText: hintText,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        type: type,
        customIcon: customIcon,
      ),
    );
  }
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType();
    final icon = widget.customIcon ?? _getIconForType();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          minWidth: 320,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header compacto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors['primary']!.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Icono más pequeño
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colors['primary']!,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: colors['primary']!.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 25, color: Colors.white),
                    ),

                    const SizedBox(height: 12),

                    // Título compacto
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Contenido en scroll si es necesario
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Mensaje
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Campo de texto compacto
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _errorText != null
                                ? Colors.red.shade300
                                : colors['primary']!.withOpacity(0.3),
                            width: 1.5,
                          ),
                          color: Colors.grey.shade50,
                        ),
                        child: TextFormField(
                          controller: _controller,
                          keyboardType: widget.keyboardType,
                          maxLines: widget.maxLines,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            errorText: _errorText,
                            errorStyle: const TextStyle(fontSize: 12),
                          ),
                          validator: widget.validator,
                          onChanged: (value) {
                            if (_errorText != null) {
                              setState(() {
                                _errorText = null;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botones compactos
                      Row(
                        children: [
                          // Botón cancelar
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                widget.cancelText ?? 'Cancelar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Botón confirmar
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _onConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors['primary']!,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                widget.confirmText ?? 'Confirmar',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text.trim());
      if (error != null) {
        setState(() {
          _errorText = error;
        });
        return;
      }
    }

    Navigator.of(context).pop(_controller.text.trim());
  }

  Map<String, Color> _getColorsForType() {
    switch (widget.type) {
      case ConfirmationDialogType.success:
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF45A049),
          'background': const Color(0xFF4CAF50),
        };
      case ConfirmationDialogType.warning:
        return {
          'primary': const Color(0xFFFF9800),
          'secondary': const Color(0xFFF57C00),
          'background': const Color(0xFFFF9800),
        };
      case ConfirmationDialogType.danger:
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFD32F2F),
          'background': const Color(0xFFF44336),
        };
      case ConfirmationDialogType.info:
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF1976D2),
          'background': const Color(0xFF2196F3),
        };
      case ConfirmationDialogType.question:
      default:
        return {
          'primary': const Color(0xFF9C27B0),
          'secondary': const Color(0xFF7B1FA2),
          'background': const Color(0xFF9C27B0),
        };
    }
  }

  IconData _getIconForType() {
    switch (widget.type) {
      case ConfirmationDialogType.success:
        return Icons.check_circle_outline;
      case ConfirmationDialogType.warning:
        return Icons.warning_amber_outlined;
      case ConfirmationDialogType.danger:
        return Icons.error_outline;
      case ConfirmationDialogType.info:
        return Icons.info_outline;
      case ConfirmationDialogType.question:
      default:
        return Icons.help_outline;
    }
  }
}
