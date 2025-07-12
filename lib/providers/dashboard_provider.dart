// providers/dashboard_provider.dart
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

// providers/reservas_provider.dart
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

// providers/clientes_provider.dart
class ClientesProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  String _filtroTexto = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Cliente> get clientes => _clientes;
  List<Cliente> get clientesFiltrados => _clientesFiltrados;
  String get filtroTexto => _filtroTexto;

  Future<void> cargarClientes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final clientesData = await SupabaseService.getClientes();
      _clientes = clientesData
          .map((c) => Cliente.fromJson(c))
          .toList();
      _clientesFiltrados = _clientes;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filtrarClientes(String texto) {
    _filtroTexto = texto;
    
    if (texto.isEmpty) {
      _clientesFiltrados = _clientes;
    } else {
      _clientesFiltrados = _clientes.where((cliente) {
        final textoLower = texto.toLowerCase();
        return cliente.nombre.toLowerCase().contains(textoLower) ||
               (cliente.apellido?.toLowerCase().contains(textoLower) ?? false) ||
               (cliente.dni?.contains(texto) ?? false) ||
               (cliente.telefono?.contains(texto) ?? false) ||
               (cliente.email?.toLowerCase().contains(textoLower) ?? false);
      }).toList();
    }
    
    notifyListeners();
  }

  Future<void> buscarClientes(String query) async {
    if (query.length < 2) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final clientesData = await SupabaseService.buscarClientes(query);
      _clientesFiltrados = clientesData
          .map((c) => Cliente.fromJson(c))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Cliente?> crearCliente(Map<String, dynamic> clienteData) async {
    try {
      final nuevoClienteData = await SupabaseService.crearCliente(clienteData);
      final nuevoCliente = Cliente.fromJson(nuevoClienteData);
      
      _clientes.insert(0, nuevoCliente);
      _clientesFiltrados = _clientes;
      notifyListeners();
      
      return nuevoCliente;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}

// providers/inventario_provider.dart
class InventarioProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  List<ItemInventario> _inventario = [];
  List<ItemInventario> _inventarioFiltrado = [];
  String? _habitacionFiltro;
  CategoriaInventario? _categoriaFiltro;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ItemInventario> get inventario => _inventario;
  List<ItemInventario> get inventarioFiltrado => _inventarioFiltrado;
  String? get habitacionFiltro => _habitacionFiltro;
  CategoriaInventario? get categoriaFiltro => _categoriaFiltro;

  Future<void> cargarInventario() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final inventarioData = await SupabaseService.getInventario();
      _inventario = inventarioData
          .map((i) => ItemInventario.fromJson(i))
          .toList();
      _aplicarFiltros();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filtrarPorHabitacion(String? habitacionId) {
    _habitacionFiltro = habitacionId;
    _aplicarFiltros();
    notifyListeners();
  }

  void filtrarPorCategoria(CategoriaInventario? categoria) {
    _categoriaFiltro = categoria;
    _aplicarFiltros();
    notifyListeners();
  }

  void _aplicarFiltros() {
    _inventarioFiltrado = _inventario.where((item) {
      bool cumpleHabitacion = _habitacionFiltro == null || 
                             item.habitacionId == _habitacionFiltro;
      bool cumpleCategoria = _categoriaFiltro == null || 
                            item.categoria == _categoriaFiltro;
      return cumpleHabitacion && cumpleCategoria;
    }).toList();
  }

  Future<void> crearItemInventario(Map<String, dynamic> itemData) async {
    try {
      final nuevoItemData = await SupabaseService.crearInventario(itemData);
      final nuevoItem = ItemInventario.fromJson(nuevoItemData);
      
      _inventario.insert(0, nuevoItem);
      _aplicarFiltros();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> actualizarItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await SupabaseService.actualizarInventario(itemId, updates);
      
      // Recargar inventario para mantener consistencia
      await cargarInventario();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<ItemInventario> itemsQueNecesitanReposicion() {
    return _inventario.where((item) => item.necesitaReposicion).toList();
  }

  Map<CategoriaInventario, int> estadisticasPorCategoria() {
    final Map<CategoriaInventario, int> stats = {};
    
    for (var categoria in CategoriaInventario.values) {
      stats[categoria] = _inventario
          .where((item) => item.categoria == categoria)
          .length;
    }
    
    return stats;
  }
}