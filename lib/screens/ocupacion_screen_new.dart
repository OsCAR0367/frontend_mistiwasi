import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/reservas_provider.dart';
import '../models/models.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class OcupacionScreen extends StatefulWidget {
  const OcupacionScreen({super.key});

  @override
  State<OcupacionScreen> createState() => _OcupacionScreenState();
}

class _OcupacionScreenState extends State<OcupacionScreen> {
  DateTime _fechaSeleccionada = DateTime.now();

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
                                  _getColorForEstado(
                                    reserva.estado,
                                  ).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _getColorForEstado(
                                    reserva.estado,
                                  ).withOpacity(0.3),
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
                            DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(fecha),
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
                  length: 2,
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
          return _buildReservaCardSimple(reserva);
        },
      ),
    );
  }

  Widget _buildNuevaReservaTab(DateTime fecha) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Habitaciones disponibles para ${DateFormat('dd/MM/yyyy').format(fecha)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 64,
                    color: Colors.orange.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Función en desarrollo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Próximamente podrás crear reservas desde aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservaCardSimple(Reserva reserva) {
    final colorEstado = _getColorForEstado(reserva.estado);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Habitación
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: colorEstado, width: 2),
            ),
            child: Center(
              child: Text(
                reserva.habitacion?.numero ?? 'N/A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorEstado,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Información del cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reserva.cliente?.nombreCompleto ?? 'Cliente no disponible',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (reserva.cliente?.telefono != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reserva.cliente!.telefono!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Estado y precio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getEstadoDisplayName(reserva.estado),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'S/. ${reserva.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEstadoDisplayName(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmado:
        return 'Confirmado';
      case EstadoReserva.check_in:
        return 'Check-in';
      case EstadoReserva.check_out:
        return 'Check-out';
      case EstadoReserva.cancelado:
        return 'Cancelado';
      case EstadoReserva.no_show:
        return 'No Show';
    }
  }
}
