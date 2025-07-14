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
      print('🔄 Iniciando carga del dashboard...');

      final stats = await SupabaseService.getDashboardStats();
      print('📊 Stats obtenidas: $stats');

      final propiedadesData = await SupabaseService.getPropiedades();
      print('🏠 Propiedades obtenidas: ${propiedadesData.length}');

      // Validar que stats tenga la estructura correcta
      if (stats['habitaciones'] != null) {
        _habitaciones = (stats['habitaciones'] as List)
            .map((h) => Habitacion.fromJson(h))
            .toList();
        print('🏨 Habitaciones procesadas: ${_habitaciones.length}');
      } else {
        print('⚠️ No se encontraron habitaciones en stats');
        _habitaciones = [];
      }

      _propiedades = propiedadesData.map((p) => Propiedad.fromJson(p)).toList();

      // Conversión segura de stats con validación de tipos
      _estadisticas = {
        'total': _convertToInt(stats['total_habitaciones']),
        'libres': _convertToInt(stats['habitaciones_libres']),
        'reservadas': _convertToInt(stats['habitaciones_reservadas']),
        'ocupadas': _convertToInt(stats['habitaciones_ocupadas']),
        'limpieza': _convertToInt(stats['habitaciones_limpieza']),
        'mantenimiento': _convertToInt(stats['habitaciones_mantenimiento']),
        'reservas_activas': _convertToInt(stats['reservas_activas']),
      };

      print('📈 Estadísticas procesadas: $_estadisticas');
    } catch (e) {
      print('❌ Error en cargarDashboard: $e');
      _error = e.toString();

      // Valores por defecto en caso de error
      _estadisticas = {
        'total': 0,
        'libres': 0,
        'reservadas': 0,
        'ocupadas': 0,
        'limpieza': 0,
        'mantenimiento': 0,
        'reservas_activas': 0,
      };
      _habitaciones = [];
      _propiedades = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Función helper para convertir valores a int de forma segura
  int _convertToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  // Alias para compatibilidad con código existente
  Future<void> loadDashboardData() async {
    await cargarDashboard();
  }
}
