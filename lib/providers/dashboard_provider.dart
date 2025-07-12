// lib/providers/dashboard_provider.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  List<Habitacion> _habitaciones = [];
  List<Propiedad> _propiedades = [];
  Map<String, int> _estadisticas = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Habitacion> get habitaciones => _habitaciones;
  List<Propiedad> get propiedades => _propiedades;
  Map<String, int> get estadisticas => _estadisticas;

  Future<void> cargarDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stats = await SupabaseService.getDashboardStats();
      final propiedadesData = await SupabaseService.getPropiedades();
      
      _habitaciones = (stats['habitaciones'] as List)
          .map((h) => Habitacion.fromJson(h))
          .toList();
      
      _propiedades = propiedadesData
          .map((p) => Propiedad.fromJson(p))
          .toList();
      
      _estadisticas = {
        'total': stats['total_habitaciones'],
        'libres': stats['habitaciones_libres'],
        'reservadas': stats['habitaciones_reservadas'],
        'ocupadas': stats['habitaciones_ocupadas'],
        'limpieza': stats['habitaciones_limpieza'],
        'mantenimiento': stats['habitaciones_mantenimiento'],
        'reservas_activas': stats['reservas_activas'],
      };
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Habitacion> habitacionesPorPropiedad(String propiedadId) {
    return _habitaciones.where((h) => h.propiedadId == propiedadId).toList();
  }

  Map<EstadoHabitacion, int> estadisticasPorPropiedad(String propiedadId) {
    final habitacionesPropiedad = habitacionesPorPropiedad(propiedadId);
    final Map<EstadoHabitacion, int> stats = {};
    
    for (var estado in EstadoHabitacion.values) {
      stats[estado] = habitacionesPropiedad
          .where((h) => h.estado == estado)
          .length;
    }
    
    return stats;
  }
}
