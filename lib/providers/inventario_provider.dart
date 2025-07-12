// lib/providers/inventario_provider.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

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