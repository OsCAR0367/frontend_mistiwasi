// ================================

// lib/providers/reservas_provider.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class ReservasProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  List<Reserva> _reservasActivas = [];
  List<Reserva> _reservasMes = [];
  List<Propiedad> _propiedades = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String? _propiedadSeleccionada; // null = todas las propiedades

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Reserva> get reservasActivas => _reservasActivas;
  List<Reserva> get reservasMes => _reservasMes;
  List<Propiedad> get propiedades => _propiedades;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  String? get propiedadSeleccionada => _propiedadSeleccionada;

  // Filtros
  List<Reserva> get reservasMesFiltradas {
    if (_propiedadSeleccionada == null) return _reservasMes;
    return _reservasMes.where((reserva) => 
      reserva.habitacion?.propiedadId == _propiedadSeleccionada
    ).toList();
  }

  void setPropiedadSeleccionada(String? propiedadId) {
    _propiedadSeleccionada = propiedadId;
    notifyListeners();
  }

  Future<void> cargarDatos() async {
    await Future.wait([
      cargarPropiedades(),
      cargarReservasPorMes(_fechaSeleccionada),
    ]);
  }

  Future<void> cargarPropiedades() async {
    try {
      print('Cargando propiedades...');
      final propiedadesData = await SupabaseService.getPropiedades();
      print('Propiedades obtenidas: ${propiedadesData.length}');
      print('Datos de propiedades: $propiedadesData');
      
      _propiedades = propiedadesData
          .map((p) {
            try {
              return Propiedad.fromJson(p);
            } catch (e) {
              print('Error parsing propiedad: $e, data: $p');
              return null;
            }
          })
          .where((p) => p != null)
          .cast<Propiedad>()
          .toList();
          
      print('Propiedades cargadas exitosamente: ${_propiedades.length}');
      notifyListeners();
    } catch (e) {
      print('Error cargando propiedades: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cargarReservasActivas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reservasData = await SupabaseService.getReservasActivas();
      _reservasActivas = reservasData
          .map((r) => Reserva.fromJson(r))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarReservasPorMes(DateTime fecha) async {
    _fechaSeleccionada = fecha;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reservasData = await SupabaseService.getReservasPorMes(
        fecha.year, 
        fecha.month
      );
      
      _reservasMes = reservasData
          .map((r) {
            try {
              return Reserva.fromJson(r);
            } catch (e) {
              print('Error parsing reserva: $e, data: $r');
              return null;
            }
          })
          .where((reserva) => reserva != null)
          .cast<Reserva>()
          .toList();
          
      print('Reservas cargadas: ${_reservasMes.length}');
    } catch (e) {
      print('Error en cargarReservasPorMes: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarEstadoReserva(String reservaId, EstadoReserva nuevoEstado) async {
    try {
      await SupabaseService.actualizarEstadoReserva(reservaId, nuevoEstado.name);
      
      // Actualizar local
      final index = _reservasActivas.indexWhere((r) => r.id == reservaId);
      if (index != -1) {
        // Recargar datos para mantener consistencia
        await cargarReservasActivas();
      }
      
      // También actualizar mes si está cargado
      if (_reservasMes.any((r) => r.id == reservaId)) {
        await cargarReservasPorMes(_fechaSeleccionada);
      }
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Reserva> reservasPorDia(DateTime dia) {
    try {
      return reservasMesFiltradas.where((reserva) {
        final fechaEntrada = DateTime(
          reserva.fechaEntrada.year,
          reserva.fechaEntrada.month,
          reserva.fechaEntrada.day,
        );
        final fechaSalida = DateTime(
          reserva.fechaSalida.year,
          reserva.fechaSalida.month,
          reserva.fechaSalida.day,
        );
        final fechaDia = DateTime(dia.year, dia.month, dia.day);
        
        // La reserva incluye el día si:
        // - El día es igual o posterior a la fecha de entrada
        // - El día es anterior a la fecha de salida (check-out no incluye el último día)
        return (fechaDia.isAtSameMomentAs(fechaEntrada) || fechaDia.isAfter(fechaEntrada)) &&
               fechaDia.isBefore(fechaSalida);
      }).toList();
    } catch (e) {
      print('Error en reservasPorDia: $e');
      return [];
    }
  }

  // Método para obtener habitaciones por propiedad
  List<String> habitacionesPorPropiedad(String propiedadId) {
    final reservasProp = _reservasMes.where((reserva) => 
      reserva.habitacion?.propiedadId == propiedadId
    ).toList();
    
    final habitaciones = <String>{};
    for (var reserva in reservasProp) {
      if (reserva.habitacion?.numero != null) {
        habitaciones.add(reserva.habitacion!.numero);
      }
    }
    return habitaciones.toList()..sort();
  }

  // Método para obtener el estado de una habitación en una fecha específica
  EstadoReserva? getEstadoHabitacionEnFecha(String numeroHabitacion, DateTime fecha) {
    try {
      final reservasDelDia = reservasPorDia(fecha);
      final reservaHabitacion = reservasDelDia.firstWhere(
        (reserva) => reserva.habitacion?.numero == numeroHabitacion,
        orElse: () => throw StateError('No encontrada'),
      );
      return reservaHabitacion.estado;
    } catch (e) {
      return null; // Habitación libre
    }
  }

  // Método para obtener todas las habitaciones únicas en el mes
  List<String> getAllHabitaciones() {
    final habitaciones = <String>{};
    for (var reserva in _reservasMes) {
      if (reserva.habitacion?.numero != null) {
        habitaciones.add(reserva.habitacion!.numero);
      }
    }
    return habitaciones.toList()..sort();
  }

  // Método para obtener resumen de ocupación por día
  Map<String, dynamic> getResumenOcupacionDia(DateTime fecha) {
    final reservasDelDia = reservasPorDia(fecha);
    final estados = <EstadoReserva, int>{};
    
    for (var reserva in reservasDelDia) {
      estados[reserva.estado] = (estados[reserva.estado] ?? 0) + 1;
    }
    
    return {
      'total_reservas': reservasDelDia.length,
      'confirmadas': estados[EstadoReserva.confirmado] ?? 0,
      'check_in': estados[EstadoReserva.check_in] ?? 0,
      'check_out': estados[EstadoReserva.check_out] ?? 0,
      'canceladas': estados[EstadoReserva.cancelado] ?? 0,
      'no_show': estados[EstadoReserva.no_show] ?? 0,
    };
  }

  void setFechaSeleccionada(DateTime fecha) {
    if (_fechaSeleccionada.year != fecha.year || _fechaSeleccionada.month != fecha.month) {
      _fechaSeleccionada = fecha;
      cargarReservasPorMes(fecha);
    } else {
      _fechaSeleccionada = fecha;
      notifyListeners();
    }
  }

  void irMesAnterior() {
    final nuevaFecha = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1, 1);
    setFechaSeleccionada(nuevaFecha);
  }

  void irMesSiguiente() {
    final nuevaFecha = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 1);
    setFechaSeleccionada(nuevaFecha);
  }

  void irHoy() {
    final hoy = DateTime.now();
    setFechaSeleccionada(hoy);
  }
}