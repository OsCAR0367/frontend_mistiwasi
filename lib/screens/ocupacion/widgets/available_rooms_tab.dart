import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/supabase_service.dart';
import '../dialogs/new_reservation_dialog.dart';

class AvailableRoomsTab extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onRecargarReservas;

  const AvailableRoomsTab({
    super.key,
    required this.fecha,
    required this.onRecargarReservas,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getHabitacionesDisponiblesParaFecha(fecha),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar habitaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final habitaciones = snapshot.data ?? [];

                if (habitaciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hotel_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin habitaciones disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay habitaciones disponibles para esta fecha',
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Agrupar habitaciones por propiedad
                final habitacionesPorPropiedad =
                    <String, List<Map<String, dynamic>>>{};
                for (final habitacion in habitaciones) {
                  final propiedadNombre =
                      habitacion['propiedad_nombre']?.toString() ??
                      'Sin propiedad';
                  habitacionesPorPropiedad.putIfAbsent(
                    propiedadNombre,
                    () => [],
                  );
                  habitacionesPorPropiedad[propiedadNombre]!.add(habitacion);
                }

                return ListView.builder(
                  itemCount: habitacionesPorPropiedad.length,
                  itemBuilder: (context, index) {
                    final propiedadNombre = habitacionesPorPropiedad.keys
                        .elementAt(index);
                    final habitacionesPropiedad =
                        habitacionesPorPropiedad[propiedadNombre]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropiedadHeader(
                          propiedadNombre,
                          habitacionesPropiedad.length,
                        ),
                        const SizedBox(height: 12),
                        ...habitacionesPropiedad.map(
                          (habitacion) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHabitacionDisponibleCard(
                              context,
                              habitacion,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF4CAF50).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Habitaciones Disponibles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Para ${DateFormat('dd/MM/yyyy').format(fecha)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropiedadHeader(
    String propiedadNombre,
    int cantidadHabitaciones,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 8),
          Text(
            propiedadNombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$cantidadHabitaciones disponible${cantidadHabitaciones != 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitacionDisponibleCard(
    BuildContext context,
    Map<String, dynamic> habitacion,
  ) {
    final numero = habitacion['numero']?.toString() ?? 'N/A';
    final tipo = habitacion['tipo']?.toString() ?? 'Sin tipo';
    final capacidad = habitacion['capacidad']?.toString() ?? '0';
    final precio = habitacion['precio']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomHeader(numero, tipo),
            const SizedBox(height: 12),
            _buildRoomInfo(capacidad, precio),
            const SizedBox(height: 12),
            _buildPriceAndAction(context, habitacion, precio),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader(String numero, String tipo) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bed, color: Color(0xFF4CAF50), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habitación $numero',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                tipo.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'DISPONIBLE',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomInfo(String capacidad, String precio) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            Icons.people,
            'Capacidad',
            '$capacidad personas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(
            Icons.attach_money,
            'Precio por noche',
            'S/. $precio',
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndAction(
    BuildContext context,
    Map<String, dynamic> habitacion,
    String precio,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precio total',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                'S/. $precio',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _mostrarFormularioReserva(context, habitacion),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Reservar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getHabitacionesDisponiblesParaFecha(
    DateTime fecha,
  ) async {
    try {
      print(
        '🏨 Buscando habitaciones disponibles para ${DateFormat('dd/MM/yyyy').format(fecha)}',
      );

      final habitaciones = await SupabaseService.getHabitacionesDisponibles(
        fecha,
        fecha,
      );

      print('📋 Habitaciones disponibles encontradas: ${habitaciones.length}');
      for (final habitacion in habitaciones) {
        print(
          '  - ${habitacion['numero']} (${habitacion['tipo']}) - ${habitacion['propiedad_nombre']}',
        );
      }

      return habitaciones;
    } catch (e) {
      print('❌ Error al obtener habitaciones disponibles: $e');
      rethrow;
    }
  }

  void _mostrarFormularioReserva(
    BuildContext context,
    Map<String, dynamic> habitacion,
  ) {
    showDialog(
      context: context,
      builder: (context) => NewReservationDialog(
        habitacion: habitacion,
        fecha: fecha,
        onRecargarReservas: onRecargarReservas,
      ),
    );
  }
}
