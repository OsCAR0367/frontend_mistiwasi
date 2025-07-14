import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reservas_provider.dart';
import '../../../models/models.dart';
import '../dialogs/day_details_dialog.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final VoidCallback onRecargarReservas;

  const CalendarWidget({
    super.key,
    required this.fechaSeleccionada,
    required this.onRecargarReservas,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservasProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildWeekDays(),
              const SizedBox(height: 16),
              _buildCalendarGrid(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatearMesAnio(fechaSeleccionada),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Row(
          children: [
            _buildLegendItem('Disponible', Colors.grey.shade200),
            const SizedBox(width: 16),
            _buildLegendItem('Con reservas', const Color(0xFF4CAF50)),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return Row(
      children: days
          .map(
            (day) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(ReservasProvider provider) {
    final daysInMonth = DateTime(
      fechaSeleccionada.year,
      fechaSeleccionada.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      fechaSeleccionada.year,
      fechaSeleccionada.month,
      1,
    );
    final weekdayOfFirstDay = firstDayOfMonth.weekday;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: daysInMonth + weekdayOfFirstDay - 1,
      itemBuilder: (context, index) {
        if (index < weekdayOfFirstDay - 1) {
          return const SizedBox.shrink();
        }

        final day = index - weekdayOfFirstDay + 2;
        final fecha = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month,
          day,
        );
        final reservas = provider.reservasPorDia(fecha);
        final esHoy = _esHoy(fecha);

        return _buildDayCell(context, fecha, reservas, esHoy);
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime fecha,
    List<Reserva> reservas,
    bool esHoy,
  ) {
    final hasReservations = reservas.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: esHoy
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: esHoy
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : null,
        boxShadow: hasReservations
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarDialogoDia(context, fecha, reservas),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fecha.day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: esHoy
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1A1A1A),
                    fontSize: 14,
                  ),
                ),
                if (hasReservations) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reservas.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _mostrarDialogoDia(
    BuildContext context,
    DateTime fecha,
    List<Reserva> reservas,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DayDetailsDialog(
        fecha: fecha,
        reservas: reservas,
        onRecargarReservas: onRecargarReservas,
      ),
    );
  }

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  String _formatearMesAnio(DateTime fecha) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }
}
