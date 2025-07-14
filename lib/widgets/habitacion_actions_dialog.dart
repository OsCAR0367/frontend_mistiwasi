import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../providers/dashboard_provider.dart';
import 'confirmation_dialog.dart';
import 'custom_snackbar.dart';

class HabitacionActionsDialog extends StatefulWidget {
  final Habitacion habitacion;
  final Map<String, dynamic>? reservaActual;

  const HabitacionActionsDialog({
    super.key,
    required this.habitacion,
    this.reservaActual,
  });

  @override
  State<HabitacionActionsDialog> createState() =>
      _HabitacionActionsDialogState();
}

class _HabitacionActionsDialogState extends State<HabitacionActionsDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white, // Fondo blanco sólido
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white, // Asegurar fondo blanco
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStateColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStateColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.habitacion.estado.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habitación ${widget.habitacion.numero}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '${widget.habitacion.tipo.displayName} - ${widget.habitacion.estado.displayName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Información de reserva actual
            if (widget.reservaActual != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reserva Actual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Cliente: ${widget.reservaActual!['cliente_nombre']}'),
                    Text('Entrada: ${widget.reservaActual!['fecha_entrada']}'),
                    Text('Salida: ${widget.reservaActual!['fecha_salida']}'),
                    Text(
                      'Personas: ${widget.reservaActual!['cantidad_personas']}',
                    ),
                    Text('Estado: ${widget.reservaActual!['estado']}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Acciones disponibles
            _buildAcciones(),

            const SizedBox(height: 16),

            // Información adicional
            if (widget.habitacion.observaciones != null &&
                widget.habitacion.observaciones!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observaciones:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.habitacion.observaciones!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    switch (widget.habitacion.estado) {
      case EstadoHabitacion.libre:
        return Column(
          children: [
            _buildActionButton(
              'Nueva Reserva',
              Icons.add_business,
              Colors.green,
              () => _crearNuevaReserva(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Marcar en Mantenimiento',
              Icons.build,
              Colors.purple,
              () => _marcarMantenimiento(),
            ),
          ],
        );

      case EstadoHabitacion.reservado:
        return Column(
          children: [
            _buildActionButton(
              'Realizar Check-In',
              Icons.login,
              Colors.blue,
              () => _realizarCheckIn(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Cancelar Reserva',
              Icons.cancel,
              Colors.red,
              () => _cancelarReserva(),
            ),
          ],
        );

      case EstadoHabitacion.ocupado:
        return Column(
          children: [
            _buildActionButton(
              'Realizar Check-Out',
              Icons.logout,
              Colors.orange,
              () => _realizarCheckOut(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Ver Detalles',
              Icons.info,
              Colors.blue,
              () => _verDetalles(),
            ),
          ],
        );

      case EstadoHabitacion.limpieza:
        return Column(
          children: [
            _buildActionButton(
              'Completar Limpieza',
              Icons.check_circle,
              Colors.green,
              () => _completarLimpieza(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Reportar Problema',
              Icons.report_problem,
              Colors.red,
              () => _reportarProblema(),
            ),
          ],
        );

      case EstadoHabitacion.mantenimiento:
        return Column(
          children: [
            _buildActionButton(
              'Completar Mantenimiento',
              Icons.check_circle,
              Colors.green,
              () => _completarMantenimiento(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Extender Mantenimiento',
              Icons.schedule,
              Colors.orange,
              () => _extenderMantenimiento(),
            ),
          ],
        );
    }
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Color _getStateColor() {
    switch (widget.habitacion.estado) {
      case EstadoHabitacion.libre:
        return const Color(0xFF4CAF50);
      case EstadoHabitacion.reservado:
        return const Color(0xFFFF9800);
      case EstadoHabitacion.ocupado:
        return const Color(0xFFF44336);
      case EstadoHabitacion.limpieza:
        return const Color(0xFFFF9800);
      case EstadoHabitacion.mantenimiento:
        return const Color(0xFF9C27B0);
    }
  }

  // === ACCIONES ===

  void _crearNuevaReserva() {
    Navigator.of(context).pop();
    // Aquí se abriría el diálogo de nueva reserva con esta habitación preseleccionada
    // Ya está implementado en el dashboard
  }

  Future<void> _realizarCheckIn() async {
    if (widget.reservaActual == null) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.realizarCheckIn(widget.reservaActual!['id']);

      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        CustomSnackBar.showSuccess(
          context: context,
          message:
              'Check-in realizado exitosamente para ${widget.reservaActual!['cliente_nombre']}',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Error al realizar check-in: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _realizarCheckOut() async {
    if (widget.reservaActual == null) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.realizarCheckOut(widget.reservaActual!['id']);

      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        CustomSnackBar.showWarning(
          context: context,
          message: 'Check-out realizado. Habitación programada para limpieza.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Error al realizar check-out: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completarLimpieza() async {
    setState(() => _isLoading = true);

    try {
      await SupabaseService.completarLimpieza(widget.habitacion.id);

      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        CustomSnackBar.showSuccess(
          context: context,
          message: 'Limpieza completada. Habitación disponible.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Error al completar limpieza: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarMantenimiento() async {
    final observaciones = await _mostrarDialogoObservaciones(
      'Motivo del mantenimiento',
    );
    if (observaciones == null) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.marcarMantenimiento(
        widget.habitacion.id,
        observaciones,
      );

      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        CustomSnackBar.showWarning(
          context: context,
          message: 'Habitación marcada en mantenimiento.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Error al marcar mantenimiento: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completarMantenimiento() async {
    setState(() => _isLoading = true);

    try {
      await SupabaseService.completarMantenimiento(widget.habitacion.id);

      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        CustomSnackBar.showSuccess(
          context: context,
          message: 'Mantenimiento completado. Habitación disponible.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Error al completar mantenimiento: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarReserva() async {
    if (widget.reservaActual == null) return;

    final confirmar = await ConfirmationDialog.show(
      context: context,
      title: 'Confirmar Cancelación',
      message:
          '¿Está seguro de que desea cancelar la reserva de ${widget.reservaActual!['cliente_nombre']}? Esta acción no se puede deshacer.',
      confirmText: 'Sí, Cancelar',
      cancelText: 'No',
      type: ConfirmationDialogType.danger,
      customIcon: Icons.cancel_outlined,
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.cancelarReserva(widget.reservaActual!['id']);

      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        CustomSnackBar.showSuccess(
          context: context,
          message: 'Reserva cancelada exitosamente',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Error al cancelar la reserva: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verDetalles() {
    // Implementar vista de detalles
    CustomSnackBar.showInfo(
      context: context,
      message: 'Vista de detalles en desarrollo',
    );
  }

  void _reportarProblema() {
    // Implementar reporte de problemas
    _marcarMantenimiento();
  }

  void _extenderMantenimiento() {
    // Implementar extensión de mantenimiento
    CustomSnackBar.showWarning(
      context: context,
      message: 'Extensión de mantenimiento en desarrollo',
    );
  }

  Future<String?> _mostrarDialogoObservaciones(String titulo) async {
    return await InputDialog.show(
      context: context,
      title: titulo,
      message: 'Ingrese las observaciones para esta acción',
      hintText: 'Observaciones...',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      maxLines: 3,
      type: ConfirmationDialogType.info,
      customIcon: Icons.note_add_outlined,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Las observaciones son requeridas';
        }
        return null;
      },
    );
  }
}
