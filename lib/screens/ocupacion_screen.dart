import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reservas_provider.dart';
import '../models/models.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../services/supabase_service.dart';

class OcupacionScreen extends StatefulWidget {
  const OcupacionScreen({super.key});

  @override
  State<OcupacionScreen> createState() => _OcupacionScreenState();
}

class _OcupacionScreenState extends State<OcupacionScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
    });
  }

  void _cargarReservas() {
    context.read<ReservasProvider>().cargarReservasPorMes(_fechaSeleccionada);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ocupación de Habitaciones',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Vista mensual de reservas y ocupación',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Controles de navegación mensual
                Row(
                  children: [
                    Consumer<ReservasProvider>(
                      builder: (context, provider, child) {
                        return DropdownButton<String>(
                          value: provider.propiedadSeleccionada,
                          hint: const Text('Todas las propiedades'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas las propiedades'),
                            ),
                            ...provider.propiedades.map((propiedad) {
                              return DropdownMenuItem<String>(
                                value: propiedad.id,
                                child: Text(propiedad.nombre),
                              );
                            }),
                          ],
                          onChanged: (String? value) {
                            provider.setPropiedadSeleccionada(value);
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(width: 16),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _fechaSeleccionada = DateTime(
                            _fechaSeleccionada.year,
                            _fechaSeleccionada.month - 1,
                          );
                        });
                        _cargarReservas();
                      },
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Mes anterior',
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        _formatearMesAnio(_fechaSeleccionada),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _fechaSeleccionada = DateTime(
                            _fechaSeleccionada.year,
                            _fechaSeleccionada.month + 1,
                          );
                        });
                        _cargarReservas();
                      },
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Mes siguiente',
                    ),

                    const SizedBox(width: 16),

                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _fechaSeleccionada = DateTime.now();
                        });
                        _cargarReservas();
                      },
                      icon: const Icon(Icons.today),
                      label: const Text('Hoy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Leyenda de colores
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('🟢 Libre', const Color(0xFF4CAF50)),
                _buildLegendItem('🟡 Reservado', const Color(0xFFFF9800)),
                _buildLegendItem('🔴 Ocupado', const Color(0xFFF44336)),
                _buildLegendItem('🟠 Limpieza', const Color(0xFFFF9800)),
                _buildLegendItem('🟣 Mantenimiento', const Color(0xFF9C27B0)),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Consumer<ReservasProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(message: 'Cargando ocupación...');
                }

                if (provider.error != null) {
                  return ErrorDisplayWidget(
                    message: provider.error!,
                    onRetry: _cargarReservas,
                  );
                }

                return _buildCalendar(provider);
              },
            ),
          ),
        ],
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
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(ReservasProvider provider) {
    final daysInMonth = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      1,
    );
    final weekdayOfFirstDay = firstDayOfMonth.weekday;

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
          // Headers de días de la semana
          Row(
            children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                .map(
                  (day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const Divider(),

          // Calendario
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 42, // 6 semanas x 7 días
              itemBuilder: (context, index) {
                final dayNumber = index - (weekdayOfFirstDay - 1) + 1;

                if (dayNumber <= 0 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final fecha = DateTime(
                  _fechaSeleccionada.year,
                  _fechaSeleccionada.month,
                  dayNumber,
                );
                final reservasDelDia = provider.reservasPorDia(fecha);
                final esHoy = _esHoy(fecha);

                return _buildDayCell(fecha, reservasDelDia, esHoy);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime fecha, List<Reserva> reservas, bool esHoy) {
    final hasReservations = reservas.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: esHoy
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : hasReservations
            ? Colors.white
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: esHoy
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : hasReservations
            ? Border.all(color: Colors.grey.shade300, width: 1)
            : null,
        boxShadow: hasReservations
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
          onTap: () => _mostrarDialogoDia(fecha, reservas),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Número del día con estilo mejorado
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: esHoy
                        ? const Color(0xFF4CAF50)
                        : hasReservations
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      fecha.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: esHoy ? FontWeight.bold : FontWeight.w600,
                        color: esHoy
                            ? Colors.white
                            : hasReservations
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Indicadores de reservas mejorados
                if (hasReservations) ...[
                  Expanded(
                    child: Column(
                      children: [
                        // Mostrar hasta 2 reservas como chips
                        ...reservas.take(2).map((reserva) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getColorForEstado(reserva.estado),
                                  _getColorForEstado(reserva.estado).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _getColorForEstado(reserva.estado).withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                reserva.habitacion?.numero ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        // Indicador de más reservas si hay más de 2
                        if (reservas.length > 2) ...[
                          const SizedBox(height: 2),
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '+${reservas.length - 2}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // Espacio vacío para días sin reservas
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  void _mostrarDialogoDia(DateTime fecha, List<Reserva> reservas) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 20,
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header mejorado
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  borderRadius: const BorderRadius.only(
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
                            DateFormat('EEEE, dd MMMM yyyy', 'es').format(fecha),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            reservas.isEmpty 
                                ? 'Sin reservas - Click para ver habitaciones disponibles'
                                : '${reservas.length} ${reservas.length == 1 ? 'reserva' : 'reservas'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido del dialog
              Expanded(
                child: DefaultTabController(
                  length: 3, // Cambiado de 2 a 3 tabs
                  child: Column(
                    children: [
                      // TabBar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: TabBar(
                          labelColor: const Color(0xFF4CAF50),
                          unselectedLabelColor: Colors.grey.shade600,
                          indicatorColor: const Color(0xFF4CAF50),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.list, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Reservas (${reservas.length})'),
                                ],
                              ),
                            ),
                            const Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text('Nueva Reserva'),
                                ],
                              ),
                            ),
                            const Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cleaning_services, size: 16),
                                  SizedBox(width: 8),
                                  Text('Limpieza/Mant.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TabBarView
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Lista de reservas
                            _buildReservasTab(fecha, reservas),
                            // Tab 2: Nueva reserva  
                            _buildNuevaReservaTab(fecha),
                            // Tab 3: Limpieza y mantenimiento
                            _buildLimpiezaMantenimientoTab(fecha),
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
      ),
    );
  }

  Widget _buildReservasTab(DateTime fecha, List<Reserva> reservas) {
    if (reservas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reservas para este día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todas las habitaciones están disponibles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: reservas.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reserva = reservas[index];
          return _buildReservaCardDetallada(reserva, fecha);
        },
      ),
    );
  }

  Widget _buildNuevaReservaTab(DateTime fecha) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información de la fecha
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hotel,
                    color: Colors.white,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Para el ${DateFormat('EEEE, dd MMMM yyyy', 'es').format(fecha)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lista de habitaciones disponibles
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getHabitacionesDisponiblesParaFecha(fecha),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Buscando habitaciones disponibles...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar habitaciones',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
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
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay habitaciones disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todas las habitaciones están ocupadas para esta fecha',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: habitaciones.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final habitacion = habitaciones[index];
                    return _buildHabitacionDisponibleCard(habitacion, fecha);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservaCardDetallada(Reserva reserva, DateTime fecha) {
    final colorEstado = _getColorForEstado(reserva.estado);
    
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
      child: Column(
        children: [
          // Header con información principal
          Container(
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
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hotel, color: Colors.white, size: 20),
                        Text(
                          reserva.habitacion?.numero ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitación ${reserva.habitacion?.numero ?? "N/A"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reserva.habitacion?.propiedad?.direccion ?? 'Sin dirección',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón cerrar
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Información del cliente y saldo
                Row(
                  children: [
                    // Cliente
                    Expanded(
                      flex: 2,
                      child: _buildInfoCard(
                        icon: Icons.person,
                        iconColor: const Color(0xFF9C27B0),
                        label: 'Cliente #',
                        value: reserva.cliente?.nombreCompleto ?? 'N/A',
                        subtitle: reserva.cliente?.telefono,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Saldo
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.account_balance_wallet,
                        iconColor: const Color(0xFF4CAF50),
                        label: 'Saldo',
                        value: 'S/. ${reserva.total.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reservas (cantidad)
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.bookmark,
                        iconColor: const Color(0xFFFF9800),
                        label: 'Reservas',
                        value: '1', // Por ahora fijo, podrías cambiarlo por lógica real
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
                        value: DateFormat('dd/MM/yyyy').format(reserva.fechaEntrada),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.access_time,
                        iconColor: const Color(0xFFFF9800),
                        label: 'Duración',
                        value: '${_calcularDiasEstadia(reserva.fechaEntrada, reserva.fechaSalida)} día${_calcularDiasEstadia(reserva.fechaEntrada, reserva.fechaSalida) != 1 ? 's' : ''}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.logout,
                        iconColor: const Color(0xFFF44336),
                        label: 'Check-out',
                        value: DateFormat('dd/MM/yyyy').format(reserva.fechaSalida),
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
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: const Color(0xFF4CAF50),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: S/. ${reserva.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
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
                      Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: const Color(0xFF9C27B0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Acciones Disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBotonesAccion(reserva),
                    ],
                  ),
                ),
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
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(Reserva reserva) {
    final esHoy = _esHoy(DateTime.now());
    final puedeHacerCheckIn = reserva.estado == EstadoReserva.confirmado && esHoy;
    final puedeHacerCheckOut = reserva.estado == EstadoReserva.check_in;
    final puedeCancelar = reserva.estado == EstadoReserva.confirmado || reserva.estado == EstadoReserva.check_in;

    return Column(
      children: [
        if (puedeHacerCheckIn) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _realizarCheckIn(reserva.id),
              icon: _isLoading ? const SizedBox(
                width: 18, 
                height: 18, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ) : const Icon(Icons.login, size: 18),
              label: Text(_isLoading ? 'Procesando...' : 'Realizar Check-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (puedeHacerCheckOut) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _realizarCheckOut(reserva.id),
              icon: _isLoading ? const SizedBox(
                width: 18, 
                height: 18, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ) : const Icon(Icons.logout, size: 18),
              label: Text(_isLoading ? 'Procesando...' : 'Realizar Check-out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (puedeCancelar) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _cancelarReserva(reserva.id),
              icon: _isLoading ? const SizedBox(
                width: 18, 
                height: 18, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF44336))
              ) : const Icon(Icons.cancel, size: 18),
              label: Text(_isLoading ? 'Procesando...' : 'Cancelar Reserva'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF44336),
                side: const BorderSide(color: Color(0xFFF44336)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Método para obtener habitaciones disponibles para una fecha específica
  Future<List<Map<String, dynamic>>> _getHabitacionesDisponiblesParaFecha(DateTime fecha) async {
    try {
      print('🏨 Buscando habitaciones disponibles para ${DateFormat('dd/MM/yyyy').format(fecha)}');
      
      final habitaciones = await SupabaseService.getHabitacionesDisponibles(fecha, fecha);
      
      print('📋 Habitaciones disponibles encontradas: ${habitaciones.length}');
      for (final habitacion in habitaciones) {
        print('  - ${habitacion['numero']} (${habitacion['tipo']}) - ${habitacion['propiedad_nombre']}');
      }
      
      return habitaciones;
    } catch (e) {
      print('❌ Error al obtener habitaciones disponibles: $e');
      rethrow;
    }
  }

  // Widget para mostrar cada habitación disponible
  Widget _buildHabitacionDisponibleCard(Map<String, dynamic> habitacion, DateTime fecha) {
    final numero = habitacion['numero']?.toString() ?? 'N/A';
    final tipo = habitacion['tipo']?.toString() ?? 'Sin tipo';
    final propiedadNombre = habitacion['propiedad_nombre']?.toString() ?? 'Sin propiedad';
    final capacidad = habitacion['capacidad']?.toString() ?? '0';
    final precio = habitacion['precio']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
        ),
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
            // Header de la habitación
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.hotel,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitación $numero',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        tipo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DISPONIBLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Información de la habitación
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.location_on_outlined,
                    'Propiedad',
                    propiedadNombre,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.people_outline,
                    'Capacidad',
                    '$capacidad personas',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Precio y botón de reservar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio por noche',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'S/ $precio',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormularioReserva(habitacion, fecha),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: const Text('Reservar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper para mostrar información de la habitación
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
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

  // Método para mostrar el formulario de nueva reserva
  void _mostrarFormularioReserva(Map<String, dynamic> habitacion, DateTime fecha) {
    showDialog(
      context: context,
      builder: (context) => _buildFormularioReservaDialog(habitacion, fecha),
    );
  }

  // Dialog para crear nueva reserva
  Widget _buildFormularioReservaDialog(Map<String, dynamic> habitacion, DateTime fecha) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del dialog
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
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
                        'Nueva Reserva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Habitación ${habitacion['numero']} - ${habitacion['propiedad_nombre']}',
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

            const SizedBox(height: 20),

            // Contenido del formulario
            Text(
              'Formulario de reserva',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.construction,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El formulario de reserva está en desarrollo. Próximamente podrás crear reservas desde aquí.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Función helper para calcular días de estadia
  int _calcularDiasEstadia(DateTime fechaEntrada, DateTime fechaSalida) {
    final entrada = DateTime(fechaEntrada.year, fechaEntrada.month, fechaEntrada.day);
    final salida = DateTime(fechaSalida.year, fechaSalida.month, fechaSalida.day);
    return salida.difference(entrada).inDays;
  }

  // Métodos para acciones de reservas
  Future<void> _realizarCheckIn(String reservaId) async {
    try {
      setState(() => _isLoading = true);
      
      await SupabaseService.realizarCheckIn(reservaId);
      
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in realizado exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        _cargarReservas(); // Recargar datos
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

  Future<void> _realizarCheckOut(String reservaId) async {
    try {
      setState(() => _isLoading = true);
      
      await SupabaseService.realizarCheckOut(reservaId);
      
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-out realizado exitosamente'),
            backgroundColor: Color(0xFFFF9800),
          ),
        );
        _cargarReservas(); // Recargar datos
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

  Future<void> _cancelarReserva(String reservaId) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        
        await SupabaseService.cancelarReserva(reservaId);
        
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar el diálogo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reserva cancelada exitosamente'),
              backgroundColor: Color(0xFFF44336),
            ),
          );
          _cargarReservas(); // Recargar datos
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

  Widget _buildLimpiezaMantenimientoTab(DateTime fecha) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información de la fecha
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.1),
                  const Color(0xFF9C27B0).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cleaning_services,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estados de Habitaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Habitaciones en limpieza y mantenimiento',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lista de habitaciones en limpieza y mantenimiento
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: SupabaseService.getHabitacionesLimpiezaMantenimiento(fecha),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF9C27B0),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando estados de habitaciones...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar estados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
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
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Todas las habitaciones están listas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay habitaciones en limpieza o mantenimiento',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: habitaciones.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final habitacion = habitaciones[index];
                    return _buildHabitacionEstadoCard(habitacion);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitacionEstadoCard(Map<String, dynamic> habitacion) {
    final numero = habitacion['numero']?.toString() ?? 'N/A';
    final tipo = habitacion['tipo']?.toString() ?? 'Sin tipo';
    final estado = habitacion['estado']?.toString() ?? 'libre';
    final propiedadNombre = habitacion['propiedad_nombre']?.toString() ?? 'Sin propiedad';
    final isLimpieza = estado == 'limpieza';
    final isMantenimiento = estado == 'mantenimiento';
    
    Color backgroundColor;
    Color borderColor;
    IconData icon;
    String estadoText;
    
    if (isLimpieza) {
      backgroundColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFFF9800);
      icon = Icons.cleaning_services;
      estadoText = 'EN LIMPIEZA';
    } else if (isMantenimiento) {
      backgroundColor = const Color(0xFFF3E5F5);
      borderColor = const Color(0xFF9C27B0);
      icon = Icons.build;
      estadoText = 'MANTENIMIENTO';
    } else {
      backgroundColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade400;
      icon = Icons.help_outline;
      estadoText = estado.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3)),
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
        child: Row(
          children: [
            // Icono y número de habitación
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: borderColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: borderColor, size: 20),
                  Text(
                    numero,
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Información de la habitación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habitación $numero',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    propiedadNombre,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estadoText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
