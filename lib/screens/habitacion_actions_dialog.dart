import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../providers/dashboard_provider.dart';

class HabitacionActionsDialog extends StatefulWidget {
  final Habitacion habitacion;
  final Map<String, dynamic>? reservaActual;

  const HabitacionActionsDialog({
    Key? key,
    required this.habitacion,
    this.reservaActual,
  }) : super(key: key);

  @override
  State<HabitacionActionsDialog> createState() =>
      _HabitacionActionsDialogState();
}

class _HabitacionActionsDialogState extends State<HabitacionActionsDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Habitación ${widget.habitacion.numero}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHabitacionInfo(),
            const SizedBox(height: 16),
            if (widget.reservaActual != null) _buildReservaInfo(),
            const SizedBox(height: 16),
            _buildAcciones(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildHabitacionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Habitación',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bed, size: 16),
                const SizedBox(width: 8),
                Text('Tipo: ${widget.habitacion.tipo}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getEstadoIcon(widget.habitacion.estado),
                  size: 16,
                  color: _getEstadoColor(widget.habitacion.estado),
                ),
                const SizedBox(width: 8),
                Text(
                  'Estado: ${widget.habitacion.estado.displayName}',
                  style: TextStyle(
                    color: _getEstadoColor(widget.habitacion.estado),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Precio: S/. ${widget.habitacion.precioNoche.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaInfo() {
    final reserva = widget.reservaActual!;
    final fechaEntrada = DateTime.parse(reserva['fecha_entrada']);
    final fechaSalida = DateTime.parse(reserva['fecha_salida']);
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reserva Actual',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Cliente: ${reserva['cliente_nombre'] ?? 'N/A'}'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Check-in: ${formatoFecha.format(fechaEntrada)}'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Check-out: ${formatoFecha.format(fechaSalida)}'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total: S/. ${(reserva['total'] ?? 0).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Disponibles',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._getAccionesDisponibles(),
      ],
    );
  }

  List<Widget> _getAccionesDisponibles() {
    List<Widget> acciones = [];

    switch (widget.habitacion.estado) {
      case EstadoHabitacion.libre:
        acciones.add(
          _buildBotonAccion(
            'Marcar como Mantenimiento',
            Icons.build,
            Colors.orange,
            () => _cambiarEstado(EstadoHabitacion.mantenimiento),
          ),
        );
        break;

      case EstadoHabitacion.reservado:
        if (widget.reservaActual != null) {
          final fechaEntrada = DateTime.parse(
            widget.reservaActual!['fecha_entrada'],
          );
          final hoy = DateTime.now();

          if (fechaEntrada.year == hoy.year &&
              fechaEntrada.month == hoy.month &&
              fechaEntrada.day == hoy.day) {
            acciones.add(
              _buildBotonAccion(
                'Realizar Check-in',
                Icons.login,
                Colors.green,
                () => _realizarCheckIn(),
              ),
            );
          }
        }

        acciones.add(
          _buildBotonAccion(
            'Cancelar Reserva',
            Icons.cancel,
            Colors.red,
            () => _cancelarReserva(),
          ),
        );
        break;

      case EstadoHabitacion.ocupado:
        acciones.add(
          _buildBotonAccion(
            'Realizar Check-out',
            Icons.logout,
            Colors.blue,
            () => _realizarCheckOut(),
          ),
        );
        break;

      case EstadoHabitacion.limpieza:
        acciones.add(
          _buildBotonAccion(
            'Completar Limpieza',
            Icons.cleaning_services,
            Colors.purple,
            () => _completarLimpieza(),
          ),
        );
        break;

      case EstadoHabitacion.mantenimiento:
        acciones.add(
          _buildBotonAccion(
            'Completar Mantenimiento',
            Icons.check_circle,
            Colors.green,
            () => _cambiarEstado(EstadoHabitacion.libre),
          ),
        );
        break;
    }

    return acciones;
  }

  Widget _buildBotonAccion(
    String texto,
    IconData icono,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onPressed,
          icon: Icon(icono),
          label: Text(texto),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );
  }

  IconData _getEstadoIcon(EstadoHabitacion estado) {
    switch (estado) {
      case EstadoHabitacion.libre:
        return Icons.check_circle;
      case EstadoHabitacion.ocupado:
        return Icons.person;
      case EstadoHabitacion.reservado:
        return Icons.schedule;
      case EstadoHabitacion.limpieza:
        return Icons.cleaning_services;
      case EstadoHabitacion.mantenimiento:
        return Icons.build;
    }
  }

  Color _getEstadoColor(EstadoHabitacion estado) {
    switch (estado) {
      case EstadoHabitacion.libre:
        return Colors.green;
      case EstadoHabitacion.ocupado:
        return Colors.blue;
      case EstadoHabitacion.reservado:
        return Colors.orange;
      case EstadoHabitacion.limpieza:
        return Colors.purple;
      case EstadoHabitacion.mantenimiento:
        return Colors.red;
    }
  }

  Future<void> _realizarCheckIn() async {
    if (widget.reservaActual == null) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.realizarCheckIn(widget.reservaActual!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in realizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).cargarDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar check-in: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check-out realizado. Habitación programada para limpieza.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.of(context).pop();
        Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).cargarDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar check-out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Limpieza completada. Habitación disponible.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).cargarDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar limpieza: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarEstado(EstadoHabitacion nuevoEstado) async {
    setState(() => _isLoading = true);

    try {
      if (nuevoEstado == EstadoHabitacion.mantenimiento) {
        await SupabaseService.marcarMantenimiento(
          widget.habitacion.id,
          'Habitación marcada para mantenimiento',
        );
      } else {
        // Para cambiar a libre, actualizar directamente
        await SupabaseService.client
            .from('habitacion')
            .update({'estado': nuevoEstado.name})
            .eq('id', widget.habitacion.id);
      }

      if (mounted) {
        final mensaje = nuevoEstado == EstadoHabitacion.libre
            ? 'Mantenimiento completado'
            : 'Habitación marcada para mantenimiento';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
        Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).cargarDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarReserva() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelación'),
        content: const Text('¿Está seguro de que desea cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirmar == true && widget.reservaActual != null) {
      setState(() => _isLoading = true);

      try {
        await SupabaseService.cancelarReserva(widget.reservaActual!['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva cancelada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          Provider.of<DashboardProvider>(
            context,
            listen: false,
          ).cargarDashboard();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cancelar reserva: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
