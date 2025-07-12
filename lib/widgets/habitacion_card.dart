// widgets/habitacion_card.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

class HabitacionCard extends StatelessWidget {
  final Habitacion habitacion;
  final VoidCallback? onTap;

  const HabitacionCard({
    super.key,
    required this.habitacion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji del estado
                Text(
                  habitacion.estado.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                
                // Número de habitación
                Text(
                  habitacion.numero,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                // Tipo de habitación
                Text(
                  habitacion.tipo.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 4),
                
                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    habitacion.estado.displayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (habitacion.estado) {
      case EstadoHabitacion.libre:
        return const Color(0xFFF1F8E9);
      case EstadoHabitacion.reservado:
        return const Color(0xFFFFF3E0);
      case EstadoHabitacion.ocupado:
        return const Color(0xFFFFEBEE);
      case EstadoHabitacion.limpieza:
        return const Color(0xFFFFF3E0);
      case EstadoHabitacion.mantenimiento:
        return const Color(0xFFF3E5F5);
    }
  }

  Color _getBorderColor() {
    switch (habitacion.estado) {
      case EstadoHabitacion.libre:
        return const Color(0xFF4CAF50);
      case EstadoHabitacion.reservado:
        return const Color(0xFFFF9800);
      case EstadoHabitacion.ocupado:
        return const Color(0xFFF44336);
      case EstadoHabitacion.limpieza:
        return const Color(0xFFFF9800);
      case EstadoHabitacion.mantenimiento:
        return const Color(0xFF9C27B0);
    }
  }

  Color _getStatusColor() {
    switch (habitacion.estado) {
      case EstadoHabitacion.libre:
        return const Color(0xFF4CAF50);
      case EstadoHabitacion.reservado:
        return const Color(0xFFFF9800);
      case EstadoHabitacion.ocupado:
        return const Color(0xFFF44336);
      case EstadoHabitacion.limpieza:
        return const Color(0xFFFF9800);
      case EstadoHabitacion.mantenimiento:
        return const Color(0xFF9C27B0);
    }
  }
}

