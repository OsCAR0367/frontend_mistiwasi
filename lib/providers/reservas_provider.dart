// lib/providers/reservas_provider.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class ReservasProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  List<Reserva> _reservasActivas = [];
  List<Reserva> _reservasMes = [];
  DateTime _fechaSeleccionada = DateTime.now();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Reserva> get reservasActivas => _reservasActivas;
  List<Reserva> get reservasMes => _reservasMes;
  DateTime get fechaSeleccionada => _fechaSeleccionada;

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
          .map((r) => Reserva.fromJson(r))
          .toList();
    } catch (e) {
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
    return _reservasMes.where((reserva) {
      return reserva.fechaEntrada.isBefore(dia.add(const Duration(days: 1))) &&
             reserva.fechaSalida.isAfter(dia);
    }).toList();
  }
}