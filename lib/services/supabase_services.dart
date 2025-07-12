import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Getter para acceder al cliente
  static SupabaseClient get client => _client;

  // === HABITACIONES ===
  static Future<List<Map<String, dynamic>>> getHabitaciones() async {
    try {
      final response = await _client
          .from('habitacion')
          .select('''
            *,
            propiedad:propiedad_id(id, nombre, direccion)
          ''')
          .eq('activa', true)
          .order('numero');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener habitaciones: $e');
    }
  }

  // === PROPIEDADES ===
  static Future<List<Map<String, dynamic>>> getPropiedades() async {
    try {
      final response = await _client
          .from('propiedad')
          .select('*')
          .eq('activa', true)
          .order('nombre');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener propiedades: $e');
    }
  }

  // === RESERVAS ===
  static Future<List<Map<String, dynamic>>> getReservasActivas() async {
    try {
      final response = await _client
          .from('reserva')
          .select('''
            *,
            cliente:cliente_id(id, nombre, apellido, dni, telefono, email),
            habitacion:habitacion_id(
              id, numero, tipo, wifi_password,
              propiedad:propiedad_id(id, nombre)
            ),
            usuario:encargado_id(id, nombre)
          ''')
          .in_('estado', ['confirmado', 'check_in'])
          .order('fecha_entrada');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener reservas activas: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getReservasPorMes(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      
      final response = await _client
          .from('reserva')
          .select('''
            *,
            cliente:cliente_id(id, nombre, apellido, dni, telefono, email),
            habitacion:habitacion_id(
              id, numero, tipo,
              propiedad:propiedad_id(id, nombre)
            )
          ''')
          .gte('fecha_entrada', startDate.toIso8601String().split('T')[0])
          .lte('fecha_salida', endDate.toIso8601String().split('T')[0])
          .order('fecha_entrada');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener reservas del mes: $e');
    }
  }

  static Future<Map<String, dynamic>> crearReserva(Map<String, dynamic> reservaData) async {
    try {
      final response = await _client
          .from('reserva')
          .insert(reservaData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  static Future<void> actualizarEstadoReserva(String reservaId, String nuevoEstado) async {
    try {
      await _client
          .from('reserva')
          .update({'estado': nuevoEstado})
          .eq('id', reservaId);
    } catch (e) {
      throw Exception('Error al actualizar estado de reserva: $e');
    }
  }

  // === CLIENTES ===
  static Future<List<Map<String, dynamic>>> getClientes() async {
    try {
      final response = await _client
          .from('cliente')
          .select('*')
          .order('nombre');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> buscarClientes(String query) async {
    try {
      final response = await _client
          .from('cliente')
          .select('*')
          .or('nombre.ilike.%$query%,apellido.ilike.%$query%,dni.ilike.%$query%,telefono.ilike.%$query%')
          .order('nombre');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  static Future<Map<String, dynamic>> crearCliente(Map<String, dynamic> clienteData) async {
    try {
      final response = await _client
          .from('cliente')
          .insert(clienteData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  // === INVENTARIO ===
  static Future<List<Map<String, dynamic>>> getInventario() async {
    try {
      final response = await _client
          .from('inventario')
          .select('''
            *,
            habitacion:habitacion_id(
              id, numero,
              propiedad:propiedad_id(id, nombre)
            )
          ''')
          .order('fecha_registro', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getInventarioPorHabitacion(String habitacionId) async {
    try {
      final response = await _client
          .from('inventario')
          .select('*')
          .eq('habitacion_id', habitacionId)
          .order('categoria');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener inventario por habitación: $e');
    }
  }

  static Future<Map<String, dynamic>> crearInventario(Map<String, dynamic> inventarioData) async {
    try {
      final response = await _client
          .from('inventario')
          .insert(inventarioData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Error al crear item de inventario: $e');
    }
  }

  static Future<void> actualizarInventario(String inventarioId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('inventario')
          .update(updates)
          .eq('id', inventarioId);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  // === DASHBOARD ===
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Estadísticas rápidas
      final habitaciones = await getHabitaciones();
      final reservasActivas = await getReservasActivas();
      
      // Contar por estado
      int libres = 0, reservadas = 0, ocupadas = 0, limpieza = 0, mantenimiento = 0;
      
      for (var habitacion in habitaciones) {
        switch (habitacion['estado']) {
          case 'libre':
            libres++;
            break;
          case 'reservado':
            reservadas++;
            break;
          case 'ocupado':
            ocupadas++;
            break;
          case 'limpieza':
            limpieza++;
            break;
          case 'mantenimiento':
            mantenimiento++;
            break;
        }
      }

      return {
        'total_habitaciones': habitaciones.length,
        'habitaciones_libres': libres,
        'habitaciones_reservadas': reservadas,
        'habitaciones_ocupadas': ocupadas,
        'habitaciones_limpieza': limpieza,
        'habitaciones_mantenimiento': mantenimiento,
        'reservas_activas': reservasActivas.length,
        'habitaciones': habitaciones,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas del dashboard: $e');
    }
  }

  // === UTILIDADES ===
  static Future<bool> verificarDisponibilidad(
    String habitacionId,
    DateTime fechaEntrada,
    DateTime fechaSalida,
  ) async {
    try {
      final response = await _client.rpc('verificar_disponibilidad', params: {
        'p_habitacion_id': habitacionId,
        'p_fecha_entrada': fechaEntrada.toIso8601String().split('T')[0],
        'p_fecha_salida': fechaSalida.toIso8601String().split('T')[0],
      });
      
      return response as bool;
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }
}