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
  final PageController _pageController = PageController();

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
                        DateFormat('MMMM yyyy', 'es_ES').format(_fechaSeleccionada),
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
    final daysInMonth = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1);
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
                .map((day) => Expanded(
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
                    ))
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
                
                final fecha = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, dayNumber);
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
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: esHoy ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: esHoy ? Border.all(color: const Color(0xFF4CAF50), width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: reservas.isNotEmpty ? () => _mostrarDetallesDelDia(fecha, reservas) : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Número del día
                Text(
                  fecha.day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: esHoy ? FontWeight.bold : FontWeight.w500,
                    color: esHoy ? const Color(0xFF4CAF50) : const Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Indicadores de reservas
                if (reservas.isNotEmpty) ...[
                  Expanded(
                    child: Column(
                      children: reservas.take(3).map((reserva) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getColorForEstado(reserva.estado),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Text(
                              reserva.habitacion?.numero ?? '',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (reservas.length > 3)
                    Text(
                      '+${reservas.length - 3}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
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
    return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
  }

  void _mostrarDetallesDelDia(DateTime fecha, List<Reserva> reservas) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reservas del ${DateFormat('d MMMM yyyy', 'es_ES').format(fecha)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Lista de reservas
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final reserva = reservas[index];
                    return _buildReservaCard(reserva);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Info del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.cliente?.nombreCompleto ?? 'Cliente no disponible',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reserva.cliente?.telefono != null)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            reserva.cliente!.telefono!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Botón WhatsApp
              if (reserva.cliente?.telefono != null)
                IconButton(
                  onPressed: () => _abrirWhatsApp(reserva.cliente!.telefono!),
                  icon: const Icon(
                    Icons.chat,
                    color: Color(0xFF25D366),
                  ),
                  tooltip: 'Abrir WhatsApp',
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Info de la reserva
          Row(
            children: [
              // Habitación
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Habitación ${reserva.habitacion?.numero ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForEstado(reserva.estado).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getEstadoDisplayName(reserva.estado),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getColorForEstado(reserva.estado),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Fechas
              Text(
                '${DateFormat('dd/MM').format(reserva.fechaEntrada)} - ${DateFormat('dd/MM').format(reserva.fechaSalida)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          if (reserva.observaciones != null && reserva.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Observaciones: ${reserva.observaciones}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

  Future<void> _abrirWhatsApp(String telefono) async {
    final url = 'https://wa.me/51$telefono';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir WhatsApp para: $telefono'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}