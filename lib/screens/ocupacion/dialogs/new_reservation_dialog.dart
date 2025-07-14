import 'package:flutter/material.dart';
import '../../nueva_reserva_dialog.dart';
import '../../../models/models.dart';

class NewReservationDialog extends StatefulWidget {
  final Map<String, dynamic> habitacion;
  final DateTime fecha;
  final VoidCallback onRecargarReservas;

  const NewReservationDialog({
    super.key,
    required this.habitacion,
    required this.fecha,
    required this.onRecargarReservas,
  });

  @override
  State<NewReservationDialog> createState() => _NewReservationDialogState();
}

class _NewReservationDialogState extends State<NewReservationDialog> {
  @override
  Widget build(BuildContext context) {
    final numero = widget.habitacion['numero']?.toString() ?? 'N/A';
    final tipo = widget.habitacion['tipo']?.toString() ?? 'Sin tipo';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(numero, tipo),
            const SizedBox(height: 20),
            _buildContent(),
            const SizedBox(height: 20),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String numero, String tipo) {
    return Row(
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
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Habitación $numero ($tipo)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // En lugar de mostrar contenido, abrir directamente el formulario completo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirFormularioCompleto(context);
    });

    return const SizedBox.shrink(); // No mostrar contenido
  }

  Widget _buildActions(BuildContext context) {
    return const SizedBox.shrink(); // No mostrar botones ya que se abre automáticamente
  }

  void _abrirFormularioCompleto(BuildContext context) {
    // Cerrar el diálogo actual
    Navigator.of(context).pop();

    // Crear un objeto Habitacion a partir de los datos del mapa
    final habitacion = _crearHabitacionDesdeMap();

    // Abrir el formulario completo de reservas
    showDialog(
      context: context,
      builder: (context) =>
          NuevaReservaDialog(habitacionPreseleccionada: habitacion),
    );
  }

  Habitacion _crearHabitacionDesdeMap() {
    // Convertir el Map<String, dynamic> a un objeto Habitacion
    final numero = widget.habitacion['numero']?.toString() ?? '';
    final tipo =
        widget.habitacion['tipo']?.toString().toLowerCase() ?? 'normal';
    final capacidad = widget.habitacion['capacidad'] ?? 2;
    final precio = (widget.habitacion['precio'] ?? 90.0).toDouble();

    // Mapear el tipo de habitación
    TipoHabitacion tipoHabitacion;
    switch (tipo) {
      case 'doble':
        tipoHabitacion = TipoHabitacion.doble;
        break;
      case 'triple':
        tipoHabitacion = TipoHabitacion.triple;
        break;
      case 'departamento':
        tipoHabitacion = TipoHabitacion.departamento;
        break;
      case 'monoambiente':
        tipoHabitacion = TipoHabitacion.monoambiente;
        break;
      default:
        tipoHabitacion = TipoHabitacion.normal;
    }

    return Habitacion(
      id: widget.habitacion['id']?.toString() ?? numero,
      numero: numero,
      tipo: tipoHabitacion,
      capacidad: capacidad,
      precio: precio,
      estado: EstadoHabitacion.libre,
      piso: 1,
      activa: true,
      fechaCreacion: DateTime.now(),
    );
  }
}
