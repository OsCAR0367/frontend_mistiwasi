import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/custom_snackbar.dart';

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
    print(
      '🏠 HabitacionActionsDialog - Habitación: ${widget.habitacion.numero}',
    );
    print(
      '📋 ReservaActual: ${widget.reservaActual != null ? widget.reservaActual!['id'] ?? 'sin ID' : 'null'}',
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 24,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFF4CAF50).withOpacity(0.02)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header profesional con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono de habitación
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
                    child: const Icon(
                      Icons.hotel,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Información de la habitación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habitación ${widget.habitacion.numero}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.habitacion.propiedad?.nombre ??
                                  'Sin ubicación',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón cerrar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHabitacionInfo(),
                    const SizedBox(height: 20),
                    if (widget.reservaActual != null) ...[
                      _buildReservaInfo(),
                      const SizedBox(height: 20),
                    ],
                    _buildAcciones(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitacionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Información de la Habitación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Grid de información
          Row(
            children: [
              // Tipo de habitación
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.bed, color: const Color(0xFF2196F3), size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.habitacion.tipo.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Estado
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(
                      widget.habitacion.estado,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getEstadoColor(
                        widget.habitacion.estado,
                      ).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getEstadoIcon(widget.habitacion.estado),
                        color: _getEstadoColor(widget.habitacion.estado),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.habitacion.estado.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getEstadoColor(widget.habitacion.estado),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Precio
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: const Color(0xFFFF9800),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Precio/Noche',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/. ${widget.habitacion.precioNoche.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservaInfo() {
    final reserva = widget.reservaActual!;
    final fechaEntrada = DateTime.parse(reserva['fecha_entrada']);
    final fechaSalida = DateTime.parse(reserva['fecha_salida']);
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final diasEstadia = fechaSalida.difference(fechaEntrada).inDays;
    final total = (reserva['total'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la reserva
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_seat,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserva Actual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Información del huésped',
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

          const SizedBox(height: 20),

          // Información del cliente expandida con más datos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Header del cliente
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(reserva['cliente_nombre'] ?? 'N/A'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reserva['cliente_nombre'] ?? 'Cliente no disponible',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (reserva['cliente_dni'] != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  color: Colors.grey.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DNI: ${reserva['cliente_dni']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (reserva['cliente_telefono'] != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: Colors.grey.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reserva['cliente_telefono'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (reserva['cliente_email'] != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    reserva['cliente_email'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Información adicional del cliente en cards
                Row(
                  children: [
                    // ID Cliente
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF9C27B0).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_pin,
                              color: const Color(0xFF9C27B0),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cliente #',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${reserva['cliente_id'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C27B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Saldo Pendiente (simulado - puedes conectar con datos reales)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: const Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saldo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'S/. 0.00',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Total de Reservas (simulado)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF9800).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              color: const Color(0xFFFF9800),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reservas',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${(DateTime.now().difference(DateTime.parse(reserva['fecha_entrada']))).inDays + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detalles de la reserva
          Row(
            children: [
              // Check-in
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.login,
                        color: const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check-in',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatoFecha.format(fechaEntrada),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Duración
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFFFF9800),
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duración',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$diasEstadia ${diasEstadia == 1 ? 'día' : 'días'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Check-out
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF44336).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.logout,
                        color: const Color(0xFFF44336),
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check-out',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatoFecha.format(fechaSalida),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF44336),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2196F3).withOpacity(0.1),
                  const Color(0xFF2196F3).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: const Color(0xFF2196F3),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: S/. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'N/A';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return words[0].substring(0, 1).toUpperCase();
    }
  }

  Widget _buildAcciones() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app,
                  color: const Color(0xFF9C27B0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Acciones Disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Lista de acciones
          ..._getAccionesDisponibles(),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icono, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
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
      } else if (nuevoEstado == EstadoHabitacion.libre) {
        // Para completar mantenimiento, usar el método específico
        await SupabaseService.completarMantenimiento(widget.habitacion.id);
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
    final confirmar = await ConfirmationDialog.show(
      context: context,
      title: 'Confirmar Cancelación',
      message:
          '¿Está seguro de que desea cancelar esta reserva? Esta acción no se puede deshacer.',
      confirmText: 'Sí, Cancelar',
      cancelText: 'No',
      type: ConfirmationDialogType.danger,
      customIcon: Icons.cancel_outlined,
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
          // Notificar al DashboardProvider para que recargue los datos
          Provider.of<DashboardProvider>(
            context,
            listen: false,
          ).loadDashboardData();
          Navigator.of(context).pop();
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
