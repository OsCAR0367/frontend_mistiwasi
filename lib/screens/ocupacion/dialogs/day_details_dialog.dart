import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../widgets/reserva_detailed_card.dart';
import '../widgets/available_rooms_tab.dart';
import '../widgets/cleaning_maintenance_tab.dart';

class DayDetailsDialog extends StatefulWidget {
  final DateTime fecha;
  final List<Reserva> reservas;
  final VoidCallback onRecargarReservas;

  const DayDetailsDialog({
    super.key,
    required this.fecha,
    required this.reservas,
    required this.onRecargarReservas,
  });

  @override
  State<DayDetailsDialog> createState() => _DayDetailsDialogState();
}

class _DayDetailsDialogState extends State<DayDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildReservasTab(),
                          AvailableRoomsTab(
                            fecha: widget.fecha,
                            onRecargarReservas: widget.onRecargarReservas,
                          ),
                          CleaningMaintenanceTab(fecha: widget.fecha),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'EEEE, dd \'de\' MMMM',
                    'es_ES',
                  ).format(widget.fecha),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.reservas.length} reserva${widget.reservas.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: const TabBar(
        indicatorColor: Color(0xFF4CAF50),
        labelColor: Color(0xFF4CAF50),
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(icon: Icon(Icons.event_note), text: 'Reservas'),
          Tab(icon: Icon(Icons.add_circle_outline), text: 'Nueva Reserva'),
          Tab(icon: Icon(Icons.cleaning_services), text: 'Limpieza/Mant.'),
        ],
      ),
    );
  }

  Widget _buildReservasTab() {
    if (widget.reservas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Sin reservas para este día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay reservas programadas para ${DateFormat('dd/MM/yyyy').format(widget.fecha)}',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: widget.reservas.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reserva = widget.reservas[index];
          return ReservaDetailedCard(
            reserva: reserva,
            fecha: widget.fecha,
            onRecargarReservas: widget.onRecargarReservas,
          );
        },
      ),
    );
  }
}
