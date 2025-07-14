import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../services/supabase_service.dart';

class ReservaDetailedCard extends StatefulWidget {
  final Reserva reserva;
  final DateTime fecha;
  final VoidCallback onRecargarReservas;

  const ReservaDetailedCard({
    super.key,
    required this.reserva,
    required this.fecha,
    required this.onRecargarReservas,
  });

  @override
  State<ReservaDetailedCard> createState() => _ReservaDetailedCardState();
}

class _ReservaDetailedCardState extends State<ReservaDetailedCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorEstado = _getColorForEstado(widget.reserva.estado);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, colorEstado.withOpacity(0.02)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorEstado.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [_buildHeader(colorEstado), _buildContent()]),
    );
  }

  Widget _buildHeader(Color colorEstado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorEstado, colorEstado.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Número de habitación
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bed, color: Colors.white, size: 16),
                  Text(
                    widget.reserva.habitacion?.numero ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habitación ${widget.reserva.habitacion?.numero ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reserva.cliente?.nombre ?? 'Cliente',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getEstadoDisplayName(widget.reserva.estado),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.person,
                  iconColor: const Color(0xFF2196F3),
                  label: 'Cliente #',
                  value: widget.reserva.cliente?.nombre ?? 'Cliente',
                  subtitle: widget.reserva.cliente?.telefono?.isNotEmpty == true
                      ? widget.reserva.cliente!.telefono
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.monetization_on,
                  iconColor: const Color(0xFF4CAF50),
                  label: 'Saldo',
                  value: 'S/. ${widget.reserva.total.toStringAsFixed(2)}',
                  subtitle: '${widget.reserva.cantidadPersonas} huéspedes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.bookmark,
                  iconColor: const Color(0xFFFF9800),
                  label: 'Reservas',
                  value: '1',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Check-in, Duración, Check-out
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.login,
                  iconColor: const Color(0xFF4CAF50),
                  label: 'Check-in',
                  value: DateFormat(
                    'dd/MM/yyyy',
                  ).format(widget.reserva.fechaEntrada),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.schedule,
                  iconColor: const Color(0xFF9C27B0),
                  label: 'Duración',
                  value:
                      '${_calcularDiasEstadia(widget.reserva.fechaEntrada, widget.reserva.fechaSalida)} días',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.logout,
                  iconColor: const Color(0xFFFF5722),
                  label: 'Check-out',
                  value: DateFormat(
                    'dd/MM/yyyy',
                  ).format(widget.reserva.fechaSalida),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total con formato destacado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF4CAF50).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: S/. ${widget.reserva.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Acciones disponibles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚙️ Acciones Disponibles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBotonesAccion(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    final esHoy = _esHoy(DateTime.now());
    final puedeHacerCheckIn =
        widget.reserva.estado == EstadoReserva.confirmado && esHoy;
    final puedeHacerCheckOut = widget.reserva.estado == EstadoReserva.check_in;
    final puedeCancelar =
        widget.reserva.estado == EstadoReserva.confirmado ||
        widget.reserva.estado == EstadoReserva.check_in;

    return Column(
      children: [
        if (puedeHacerCheckIn) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _realizarCheckIn(),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login, size: 18),
              label: Text(_isLoading ? 'Procesando...' : 'Realizar Check-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (puedeHacerCheckOut) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _realizarCheckOut(),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(_isLoading ? 'Procesando...' : 'Realizar Check-out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (puedeCancelar) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _cancelarReserva(),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF44336),
                      ),
                    )
                  : const Icon(Icons.cancel, size: 18),
              label: Text(_isLoading ? 'Procesando...' : 'Cancelar Reserva'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF44336),
                side: const BorderSide(color: Color(0xFFF44336)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Métodos para acciones de reservas
  Future<void> _realizarCheckIn() async {
    try {
      setState(() => _isLoading = true);

      await SupabaseService.realizarCheckIn(widget.reserva.id);

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in realizado exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        widget.onRecargarReservas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al realizar check-in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _realizarCheckOut() async {
    try {
      setState(() => _isLoading = true);

      await SupabaseService.realizarCheckOut(widget.reserva.id);

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-out realizado exitosamente'),
            backgroundColor: Color(0xFFFF9800),
          ),
        );
        widget.onRecargarReservas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al realizar check-out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarReserva() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);

        await SupabaseService.cancelarReserva(widget.reserva.id);

        if (mounted) {
          Navigator.of(context).pop(); // Cerrar el diálogo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reserva cancelada exitosamente'),
              backgroundColor: Color(0xFFF44336),
            ),
          );
          widget.onRecargarReservas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al cancelar reserva: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Funciones helper
  Color _getColorForEstado(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmado:
        return const Color(0xFFFF9800);
      case EstadoReserva.check_in:
        return const Color(0xFFF44336);
      case EstadoReserva.check_out:
        return const Color(0xFF4CAF50);
      case EstadoReserva.cancelado:
        return const Color(0xFF9E9E9E);
      case EstadoReserva.no_show:
        return const Color(0xFF795548);
    }
  }

  String _getEstadoDisplayName(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmado:
        return 'CONFIRMADO';
      case EstadoReserva.check_in:
        return 'CHECK-IN';
      case EstadoReserva.check_out:
        return 'CHECK-OUT';
      case EstadoReserva.cancelado:
        return 'CANCELADO';
      case EstadoReserva.no_show:
        return 'NO SHOW';
    }
  }

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  int _calcularDiasEstadia(DateTime fechaEntrada, DateTime fechaSalida) {
    final entrada = DateTime(
      fechaEntrada.year,
      fechaEntrada.month,
      fechaEntrada.day,
    );
    final salida = DateTime(
      fechaSalida.year,
      fechaSalida.month,
      fechaSalida.day,
    );
    return salida.difference(entrada).inDays;
  }
}
