import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reservas_provider.dart';
import '../widgets/loading_widget.dart';
import 'ocupacion/widgets/calendar_widget.dart';

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
          _buildHeader(),
          Expanded(
            child: Consumer<ReservasProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const LoadingWidget();
                }

                if (provider.error != null) {
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
                          'Error al cargar datos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarReservas,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                return CalendarWidget(
                  fechaSeleccionada: _fechaSeleccionada,
                  onRecargarReservas: _cargarReservas,
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
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF4CAF50), size: 28),
          const SizedBox(width: 12),
          const Text(
            'Calendario de Ocupación',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
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
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _fechaSeleccionada = DateTime.now();
                  });
                  _cargarReservas();
                },
                child: const Text(
                  'Hoy',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
        ],
      ),
    );
  }
}
