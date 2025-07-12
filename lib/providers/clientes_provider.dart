// lib/providers/clientes_provider.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

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
