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
          .inFilter('estado', ['confirmado', 'check_in'])
          .order('fecha_entrada');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener reservas activas: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getReservasPorMes(
    int year,
    int month,
  ) async {
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

  static Future<Map<String, dynamic>> crearReserva(
    Map<String, dynamic> reservaData,
  ) async {
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

  static Future<void> actualizarEstadoReserva(
    String reservaId,
    String nuevoEstado,
  ) async {
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
          .or(
            'nombre.ilike.%$query%,apellido.ilike.%$query%,dni.ilike.%$query%,telefono.ilike.%$query%',
          )
          .order('nombre');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  static Future<Map<String, dynamic>> crearCliente(
    Map<String, dynamic> clienteData,
  ) async {
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

  static Future<List<Map<String, dynamic>>> getInventarioPorHabitacion(
    String habitacionId,
  ) async {
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

  static Future<Map<String, dynamic>> crearInventario(
    Map<String, dynamic> inventarioData,
  ) async {
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

  static Future<void> actualizarInventario(
    String inventarioId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('inventario').update(updates).eq('id', inventarioId);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  // === DASHBOARD ===
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔄 Obteniendo estadísticas del dashboard...');

      // Obtener todas las habitaciones
      final habitaciones = await getHabitaciones();

      // Obtener reservas del día actual y próximas
      final hoy = DateTime.now();
      final hoyStr = hoy.toIso8601String().split('T')[0];

      // Obtener reservas que afectan el día de hoy
      final reservasHoy = await _client
          .from('reserva')
          .select('''
            *,
            habitacion:habitacion_id(id, numero),
            cliente:cliente_id(nombre, apellido)
          ''')
          .inFilter('estado', ['confirmado', 'check_in', 'check_out'])
          .lte('fecha_entrada', hoyStr)
          .gte('fecha_salida', hoyStr)
          .order('fecha_entrada');

      print('📊 Habitaciones obtenidas: ${habitaciones.length}');
      print('📋 Reservas del día: ${reservasHoy.length}');

      // Crear un mapa para rastrear el estado actual de cada habitación
      Map<String, String> estadosCalculados = {};

      // Procesar cada habitación
      for (var habitacion in habitaciones) {
        final habitacionId = habitacion['id'];
        final estadoDB = habitacion['estado']?.toString() ?? 'libre';

        // Buscar si hay reserva activa para esta habitación hoy
        final reservasParaHabitacion = reservasHoy
            .where((r) => r['habitacion_id'] == habitacionId)
            .toList();

        String estadoFinal;
        Map<String, dynamic>? reservaHoy;

        if (reservasParaHabitacion.isNotEmpty) {
          // Tomar la primera reserva encontrada
          reservaHoy = reservasParaHabitacion.first;

          // Hay reserva para hoy, determinar estado según el estado de la reserva
          final estadoReserva =
              reservaHoy['estado']?.toString() ?? 'confirmado';
          final fechaEntrada = DateTime.parse(reservaHoy['fecha_entrada']);

          if (estadoReserva == 'check_in') {
            // Cliente ya hizo check-in, habitación ocupada
            estadoFinal = 'ocupado';
          } else if (estadoReserva == 'check_out') {
            // Cliente hizo check-out, habitación necesita limpieza
            estadoFinal = 'limpieza';
          } else if (estadoReserva == 'confirmado' &&
              fechaEntrada.isAtSameMomentAs(
                DateTime(hoy.year, hoy.month, hoy.day),
              )) {
            // Reserva confirmada para hoy, habitación reservada
            estadoFinal = 'reservado';
          } else {
            // Reserva confirmada pero no para hoy
            estadoFinal = 'ocupado';
          }
        } else {
          // No hay reserva para hoy, usar el estado actual de la base de datos
          // pero aplicar algunas reglas de lógica de negocio
          if (estadoDB == 'mantenimiento') {
            // Mantener estado de mantenimiento
            estadoFinal = 'mantenimiento';
          } else if (estadoDB == 'limpieza') {
            // Mantener estado de limpieza
            estadoFinal = 'limpieza';
          } else if (estadoDB == 'libre') {
            // Habitación libre
            estadoFinal = 'libre';
          } else {
            // Para cualquier otro estado sin reserva activa, considerar libre
            estadoFinal = 'libre';
          }
        }

        estadosCalculados[habitacionId] = estadoFinal;

        // Actualizar el estado en la habitación
        habitacion['estado'] = estadoFinal;
        habitacion['estado_calculado'] = true;

        // Si hay reserva, agregar información adicional
        if (reservaHoy != null) {
          habitacion['reserva_actual'] = {
            'id': reservaHoy['id'],
            'estado': reservaHoy['estado'],
            'cliente_nombre':
                '${reservaHoy['cliente']['nombre']} ${reservaHoy['cliente']['apellido'] ?? ''}',
            'fecha_entrada': reservaHoy['fecha_entrada'],
            'fecha_salida': reservaHoy['fecha_salida'],
            'cantidad_personas': reservaHoy['cantidad_personas'],
            'total': reservaHoy['total'],
          };
        }
      }

      // Contar por estado calculado
      int libres = 0,
          reservadas = 0,
          ocupadas = 0,
          limpieza = 0,
          mantenimiento = 0;

      for (var estado in estadosCalculados.values) {
        switch (estado) {
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

      final result = {
        'total_habitaciones': habitaciones.length,
        'habitaciones_libres': libres,
        'habitaciones_reservadas': reservadas,
        'habitaciones_ocupadas': ocupadas,
        'habitaciones_limpieza': limpieza,
        'habitaciones_mantenimiento': mantenimiento,
        'reservas_activas': reservasHoy.length,
        'habitaciones': habitaciones,
        'fecha_calculo': hoyStr,
      };

      print(
        '✅ Stats calculadas con estados dinámicos: libres=$libres, reservadas=$reservadas, ocupadas=$ocupadas, limpieza=$limpieza, mantenimiento=$mantenimiento',
      );
      return result;
    } catch (e) {
      print('❌ Error en getDashboardStats: $e');
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
      final response = await _client.rpc(
        'verificar_disponibilidad',
        params: {
          'p_habitacion_id': habitacionId,
          'p_fecha_entrada': fechaEntrada.toIso8601String().split('T')[0],
          'p_fecha_salida': fechaSalida.toIso8601String().split('T')[0],
        },
      );

      return response as bool;
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }

  // === CHECK-IN / CHECK-OUT ===
  static Future<Map<String, dynamic>> realizarCheckIn(String reservaId) async {
    try {
      // Actualizar estado de la reserva a check_in
      final reserva = await _client
          .from('reserva')
          .update({
            'estado': 'check_in',
            'fecha_check_in': DateTime.now().toIso8601String(),
          })
          .eq('id', reservaId)
          .select('''
            *,
            habitacion:habitacion_id(id, numero),
            cliente:cliente_id(nombre, apellido)
          ''')
          .single();

      // Actualizar estado de la habitación a ocupado
      await _client
          .from('habitacion')
          .update({'estado': 'ocupado'})
          .eq('id', reserva['habitacion_id']);

      print('✅ Check-in realizado para reserva $reservaId');
      return reserva;
    } catch (e) {
      print('❌ Error en check-in: $e');
      throw Exception('Error al realizar check-in: $e');
    }
  }

  static Future<Map<String, dynamic>> realizarCheckOut(String reservaId) async {
    try {
      // Actualizar estado de la reserva a check_out
      final reserva = await _client
          .from('reserva')
          .update({
            'estado': 'check_out',
            'fecha_check_out': DateTime.now().toIso8601String(),
          })
          .eq('id', reservaId)
          .select('''
            *,
            habitacion:habitacion_id(id, numero),
            cliente:cliente_id(nombre, apellido)
          ''')
          .single();

      // Programar limpieza automáticamente
      await _client
          .from('habitacion')
          .update({'estado': 'limpieza'})
          .eq('id', reserva['habitacion_id']);

      print(
        '✅ Check-out realizado y limpieza programada para reserva $reservaId',
      );
      return reserva;
    } catch (e) {
      print('❌ Error en check-out: $e');
      throw Exception('Error al realizar check-out: $e');
    }
  }

  static Future<void> completarLimpieza(String habitacionId) async {
    try {
      // Cambiar estado de habitación a libre después de completar limpieza
      await _client
          .from('habitacion')
          .update({
            'estado': 'libre',
            'observaciones': null, // Limpiar observaciones
          })
          .eq('id', habitacionId);

      print('✅ Limpieza completada para habitación $habitacionId');
    } catch (e) {
      print('❌ Error al completar limpieza: $e');
      throw Exception('Error al completar limpieza: $e');
    }
  }

  static Future<void> marcarMantenimiento(
    String habitacionId,
    String? observaciones,
  ) async {
    try {
      final updates = {'estado': 'mantenimiento'};
      if (observaciones != null && observaciones.isNotEmpty) {
        updates['observaciones'] = observaciones;
      }

      await _client.from('habitacion').update(updates).eq('id', habitacionId);

      print('✅ Habitación $habitacionId marcada en mantenimiento');
    } catch (e) {
      print('❌ Error al marcar mantenimiento: $e');
      throw Exception('Error al marcar en mantenimiento: $e');
    }
  }

  static Future<void> completarMantenimiento(String habitacionId) async {
    try {
      await _client
          .from('habitacion')
          .update({'estado': 'libre'})
          .eq('id', habitacionId);

      print('✅ Mantenimiento completado para habitación $habitacionId');
    } catch (e) {
      print('❌ Error al completar mantenimiento: $e');
      throw Exception('Error al completar mantenimiento: $e');
    }
  }

  // === GESTIÓN DE ESTADOS AVANZADA ===
  static Future<List<Map<String, dynamic>>>
  getHabitacionesParaLimpieza() async {
    try {
      final response = await _client
          .from('habitacion')
          .select('''
            id, numero, estado,
            propiedad:propiedad_id(nombre)
          ''')
          .eq('estado', 'limpieza')
          .order('numero');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener habitaciones para limpieza: $e');
    }
  }

  static Future<List<Map<String, dynamic>>>
  getHabitacionesEnMantenimiento() async {
    try {
      final response = await _client
          .from('habitacion')
          .select('''
            id, numero, estado, observaciones,
            propiedad:propiedad_id(nombre)
          ''')
          .eq('estado', 'mantenimiento')
          .order('numero');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener habitaciones en mantenimiento: $e');
    }
  }

  // === REPORTES Y ESTADÍSTICAS AVANZADAS ===
  static Future<Map<String, dynamic>> getOcupacionDiaria(String fecha) async {
    try {
      final reservas = await _client
          .from('reserva')
          .select('''
            id, estado, cantidad_personas,
            habitacion:habitacion_id(id, numero, capacidad_maxima),
            cliente:cliente_id(nombre, apellido)
          ''')
          .lte('fecha_entrada', fecha)
          .gte('fecha_salida', fecha)
          .inFilter('estado', ['confirmado', 'check_in']);

      return {
        'fecha': fecha,
        'reservas': reservas,
        'habitaciones_ocupadas': reservas.length,
        'personas_hospedadas': reservas.fold<int>(
          0,
          (sum, r) => sum + (r['cantidad_personas'] as int? ?? 0),
        ),
      };
    } catch (e) {
      throw Exception('Error al obtener ocupación diaria: $e');
    }
  }

  // === CANCELAR RESERVA ===
  static Future<void> cancelarReserva(String reservaId) async {
    try {
      await _client
          .from('reserva')
          .update({
            'estado': 'cancelado',
          })
          .eq('id', reservaId);
    } catch (e) {
      throw Exception('Error al cancelar reserva: $e');
    }
  }
}
