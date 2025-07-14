import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
      print('Consultando tabla propiedad...');
      final response = await _client
          .from('propiedad') // Nombre en minúsculas
          .select('*')
          .eq('activa', true)
          .order('nombre');

      print('Respuesta de propiedad: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getPropiedades: $e');
      throw Exception('Error al obtener propiedades: $e');
    }
  }

  // === RESERVAS ===
  static Future<List<Map<String, dynamic>>> getReservasActivas() async {
    try {
      final response = await _client
          .from('reserva') // Tabla en minúsculas
          .select('''
            *,
            cliente:cliente_id(id, nombre, apellido, dni, telefono, email),
            habitacion:habitacion_id(
              id, numero, tipo,
              propiedad:propiedad_id(id, nombre)
            )
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

      print(
        'Buscando reservas entre ${startDate.toString()} y ${endDate.toString()}',
      );

      final response = await _client
          .from('reserva') // Nombre en minúsculas
          .select('''
            *,
            cliente:cliente_id(id, nombre, apellido, dni, telefono, email),
            habitacion:habitacion_id(
              id, numero, tipo,
              propiedad:propiedad_id(id, nombre)
            )
          ''')
          .or(
            'and(fecha_entrada.lte.${endDate.toIso8601String().split('T')[0]},fecha_salida.gte.${startDate.toIso8601String().split('T')[0]})',
          )
          .order('fecha_entrada');

      print('Reservas encontradas: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getReservasPorMes: $e');
      throw Exception('Error al obtener reservas del mes: $e');
    }
  }

  static Future<Map<String, dynamic>> crearReserva(
    Map<String, dynamic> reservaData,
  ) async {
    try {
      // Validar que la habitación esté disponible antes de crear la reserva
      final habitacionId = reservaData['habitacion_id'];
      final fechaEntrada = reservaData['fecha_entrada'];
      final fechaSalida = reservaData['fecha_salida'];

      // Verificar el estado actual de la habitación
      final habitacionResponse = await _client
          .from('habitacion')
          .select('estado, numero')
          .eq('id', habitacionId)
          .single();

      final estadoHabitacion = habitacionResponse['estado'];
      final numeroHabitacion = habitacionResponse['numero'];

      print(
        '🔍 Verificando disponibilidad de habitación $numeroHabitacion (ID: $habitacionId)',
      );
      print('📅 Fechas solicitadas: $fechaEntrada a $fechaSalida');

      // Verificar que la habitación esté en estado libre
      if (estadoHabitacion != 'libre') {
        print('❌ Habitación no disponible - Estado actual: $estadoHabitacion');
        throw Exception(
          'La habitación $numeroHabitacion no está disponible para reservas. Estado actual: $estadoHabitacion',
        );
      }

      // Verificación de conflictos simplificada
      final conflictos = await _client
          .from('reserva')
          .select('id, fecha_entrada, fecha_salida')
          .eq('habitacion_id', habitacionId)
          .inFilter('estado', ['confirmado', 'check_in']);

      // Verificar conflictos manualmente
      for (var reserva in conflictos) {
        final existeEntrada = reserva['fecha_entrada'];
        final existeSalida = reserva['fecha_salida'];

        // Hay conflicto si hay solapamiento de fechas
        if ((fechaEntrada.compareTo(existeSalida) < 0) &&
            (fechaSalida.compareTo(existeEntrada) > 0)) {
          throw Exception(
            'La habitación $numeroHabitacion ya tiene reservas conflictivas en las fechas seleccionadas',
          );
        }
      }

      // 🆕 Crear la reserva
      final response = await _client
          .from('reserva')
          .insert(reservaData)
          .select()
          .single();

      // 🆕 MANUALMENTE: Actualizar estado de habitación a reservado
      await _client
          .from('habitacion')
          .update({'estado': 'reservado'})
          .eq('id', habitacionId);

      print(
        '✅ Reserva creada y habitación $numeroHabitacion marcada como reservada',
      );
      return response;
    } catch (e) {
      print('❌ Error al crear reserva: $e');
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
            'nombre.ilike.%$query%,apellido.ilike.%$query%,dni.ilike.%$query%',
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
          .order('fecha_registro', ascending: false);

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
      throw Exception('Error al crear inventario: $e');
    }
  }

  static Future<void> actualizarInventario(
    String id,
    Map<String, dynamic> inventarioData,
  ) async {
    try {
      await _client.from('inventario').update(inventarioData).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  static Future<void> eliminarInventario(String id) async {
    try {
      await _client.from('inventario').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar inventario: $e');
    }
  }

  // === DASHBOARD ===
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final hoy = DateTime.now();
      final hoyStr = hoy.toIso8601String().split('T')[0];

      // 🔍 Obtener todas las habitaciones activas
      final habitaciones = await _client
          .from('habitacion')
          .select('''
            *,
            propiedad:propiedad_id(id, nombre, direccion)
          ''')
          .eq('activa', true)
          .order('numero');

      // 🔍 Obtener TODAS las reservas activas (no solo del día) con información completa del cliente
      final reservasActivas = await _client
          .from('reserva')
          .select('''
            *,
            habitacion:habitacion_id(id, numero),
            cliente:cliente_id(
              id, nombre, apellido, dni, telefono, email, 
              fecha_registro
            )
          ''')
          .inFilter('estado', ['confirmado', 'check_in']) // <-- MÁS PRECISO
          .order('fecha_entrada');

      print('📊 Habitaciones obtenidas: ${habitaciones.length}');
      print(
        '📋 Reservas activas (confirmadas/check-in): ${reservasActivas.length}',
      );

      // 🆕 SIMPLIFICADO: Confiar en los estados de la base de datos
      // Crear un mapa para rastrear el estado actual de cada habitación
      Map<String, String> estadosCalculados = {};

      // Procesar cada habitación
      for (var habitacion in habitaciones) {
        final habitacionId = habitacion['id'];
        final estadoDB = habitacion['estado']?.toString() ?? 'libre';
        final numeroHabitacion = habitacion['numero'];

        print('🏠 Habitación $numeroHabitacion - Estado DB: $estadoDB');

        // 🎯 LÓGICA MEJORADA: Solo mostrar como ocupado si la reserva es para HOY
        String estadoFinal = estadoDB;
        Map<String, dynamic>? reservaActual;

        // Buscar si hay reserva activa para esta habitación
        final reservasParaHabitacion = reservasActivas
            .where((r) => r['habitacion_id'] == habitacionId)
            .toList();

        if (reservasParaHabitacion.isNotEmpty) {
          reservaActual = reservasParaHabitacion.first;
          final fechaEntrada = DateTime.parse(reservaActual['fecha_entrada']);
          final fechaSalida = DateTime.parse(reservaActual['fecha_salida']);

          // Verificar si la reserva es para hoy
          final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
          final entradaFecha = DateTime(
            fechaEntrada.year,
            fechaEntrada.month,
            fechaEntrada.day,
          );
          final salidaFecha = DateTime(
            fechaSalida.year,
            fechaSalida.month,
            fechaSalida.day,
          );

          print(
            '📅 Fechas - Hoy: $hoyFecha, Entrada: $entradaFecha, Salida: $salidaFecha',
          );

          // Si la reserva incluye el día de hoy
          if ((hoyFecha.isAtSameMomentAs(entradaFecha) ||
                  hoyFecha.isAfter(entradaFecha)) &&
              hoyFecha.isBefore(salidaFecha)) {
            // La reserva es para hoy, mantener el estado de la base de datos
            print('✅ Reserva es para hoy - manteniendo estado: $estadoDB');
          } else {
            // La reserva NO es para hoy, mostrar como libre si está marcado como reservado/ocupado
            if (estadoDB == 'reservado' || estadoDB == 'ocupado') {
              estadoFinal = 'libre';
              print('🔄 Reserva NO es para hoy - cambiando a libre');
            }
          }

          print(
            '📋 Habitación $numeroHabitacion tiene reserva activa: ${reservaActual['id']}',
          );
        } else {
          // No hay reserva activa, si está marcado como reservado/ocupado, cambiarlo a libre
          if (estadoDB == 'reservado' || estadoDB == 'ocupado') {
            estadoFinal = 'libre';
            print('🔄 Sin reserva activa - cambiando de $estadoDB a libre');
          }
        }

        estadosCalculados[habitacionId] = estadoFinal;
        print('✅ Estado final para habitación $numeroHabitacion: $estadoFinal');

        // Actualizar el estado en la habitación
        habitacion['estado'] = estadoFinal;
        habitacion['estado_calculado'] = true;

        // Si hay reserva, agregar información adicional
        if (reservaActual != null) {
          print(
            '🔍 Agregando datos de reserva para habitación $numeroHabitacion: ${reservaActual['id']}',
          );
          habitacion['reserva_actual'] = {
            'id': reservaActual['id'],
            'estado': reservaActual['estado'],
            'cliente_nombre':
                '${reservaActual['cliente']['nombre']} ${reservaActual['cliente']['apellido'] ?? ''}',
            'cliente_dni': reservaActual['cliente']['dni'] ?? '',
            'cliente_telefono': reservaActual['cliente']['telefono'] ?? '',
            'cliente_email': reservaActual['cliente']['email'] ?? '',
            'fecha_entrada': reservaActual['fecha_entrada'],
            'fecha_salida': reservaActual['fecha_salida'],
            'cantidad_personas': reservaActual['cantidad_personas'],
            'total': reservaActual['total'],
          };
        } else if (estadoFinal == 'reservado') {
          print(
            '⚠️ Habitación $numeroHabitacion tiene estado reservado pero no se encontró reserva activa',
          );
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
        'reservas_activas': reservasActivas.length,
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

  // === DISPONIBILIDAD ===
  static Future<bool> verificarDisponibilidad(
    String habitacionId,
    String fechaEntrada,
    String fechaSalida,
  ) async {
    try {
      final conflictos = await _client
          .from('reserva')
          .select('id, fecha_entrada, fecha_salida')
          .eq('habitacion_id', habitacionId)
          .inFilter('estado', ['confirmado', 'check_in']);

      // Verificar conflictos manualmente
      for (var reserva in conflictos) {
        final existeEntrada = reserva['fecha_entrada'];
        final existeSalida = reserva['fecha_salida'];

        // Hay conflicto si hay solapamiento de fechas
        if ((fechaEntrada.compareTo(existeSalida) < 0) &&
            (fechaSalida.compareTo(existeEntrada) > 0)) {
          return false; // Hay conflicto
        }
      }

      return true; // No hay conflictos
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }

  // === CHECK-IN/CHECK-OUT ===
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

      // 🆕 MANUALMENTE: Actualizar estado de la habitación a ocupado
      await _client
          .from('habitacion')
          .update({'estado': 'ocupado'})
          .eq('id', reserva['habitacion_id']);

      print(
        '✅ Check-in realizado y habitación ${reserva['habitacion']['numero']} marcada como ocupada',
      );
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

      // 🆕 MANUALMENTE: Actualizar estado de la habitación a limpieza
      await _client
          .from('habitacion')
          .update({'estado': 'limpieza'})
          .eq('id', reserva['habitacion_id']);

      print(
        '✅ Check-out realizado y habitación ${reserva['habitacion']['numero']} marcada en limpieza',
      );
      return reserva;
    } catch (e) {
      print('❌ Error en check-out: $e');
      throw Exception('Error al realizar check-out: $e');
    }
  }

  static Future<void> completarLimpieza(String habitacionId) async {
    try {
      print('🧹 Completando limpieza para habitación $habitacionId...');

      // Actualizar estado de habitación a libre
      final response = await _client
          .from('habitacion')
          .update({
            'estado': 'libre',
            'observaciones': null, // Limpiar observaciones
          })
          .eq('id', habitacionId)
          .select()
          .single();

      print('✅ Limpieza completada para habitación: ${response['numero']}');
      print('🔄 Estado actualizado manualmente a: libre');
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
      print('🔧 Marcando habitación $habitacionId en mantenimiento...');

      final updates = {'estado': 'mantenimiento'};
      if (observaciones != null && observaciones.isNotEmpty) {
        updates['observaciones'] = observaciones;
      }

      final response = await _client
          .from('habitacion')
          .update(updates)
          .eq('id', habitacionId)
          .select()
          .single();

      print('✅ Habitación marcada en mantenimiento: ${response['numero']}');
      print('🔄 Estado actualizado manualmente a: mantenimiento');
    } catch (e) {
      print('❌ Error al marcar mantenimiento: $e');
      throw Exception('Error al marcar en mantenimiento: $e');
    }
  }

  static Future<void> completarMantenimiento(String habitacionId) async {
    try {
      print('🔧 Completando mantenimiento para habitación $habitacionId...');

      final response = await _client
          .from('habitacion')
          .update({
            'estado': 'libre',
            'observaciones': null, // Limpiar observaciones
          })
          .eq('id', habitacionId)
          .select()
          .single();

      print(
        '✅ Mantenimiento completado para habitación: ${response['numero']}',
      );
      print('🔄 Estado actualizado manualmente a: libre');
    } catch (e) {
      print('❌ Error al completar mantenimiento: $e');
      throw Exception('Error al completar mantenimiento: $e');
    }
  }

  // === OBTENER HABITACIONES EN LIMPIEZA Y MANTENIMIENTO ===
  static Future<List<Map<String, dynamic>>>
  getHabitacionesLimpiezaMantenimiento(DateTime fecha) async {
    try {
      print(
        '🔍 Buscando habitaciones en limpieza/mantenimiento para ${DateFormat('dd/MM/yyyy').format(fecha)}',
      );

      final habitaciones = await _client
          .from('habitacion')
          .select('''
            *,
            propiedad:propiedad_id(id, nombre, direccion)
          ''')
          .eq('activa', true)
          .inFilter('estado', ['limpieza', 'mantenimiento'])
          .order('numero');

      print(
        '🏨 Habitaciones en limpieza/mantenimiento encontradas: ${habitaciones.length}',
      );

      // Transformar datos para el calendario
      final habitacionesFormateadas = habitaciones.map((h) {
        final propiedad = h['propiedad'] as Map<String, dynamic>?;
        return {
          'id': h['id'],
          'numero': h['numero']?.toString() ?? 'N/A',
          'tipo': h['tipo']?.toString() ?? 'Estándar',
          'estado': h['estado']?.toString() ?? 'libre',
          'precio': (h['precio_noche'] ?? 0).toDouble(),
          'capacidad': h['capacidad_maxima'] ?? 2,
          'wifi_password': h['wifi_password'],
          'propiedad_id': propiedad?['id'],
          'propiedad_nombre': propiedad?['nombre'] ?? 'Sin propiedad',
          'propiedad_direccion': propiedad?['direccion'] ?? '',
        };
      }).toList();

      for (final h in habitacionesFormateadas) {
        print('  - ${h['numero']} (${h['estado']}) - ${h['propiedad_nombre']}');
      }

      return habitacionesFormateadas;
    } catch (e) {
      print('❌ Error al obtener habitaciones en limpieza/mantenimiento: $e');
      rethrow;
    }
  }

  // === OCUPACIÓN ===
  static Future<Map<String, dynamic>> getOcupacionDiaria(String fecha) async {
    try {
      final reservas = await _client
          .from('reserva')
          .select('''
            *,
            cliente:cliente_id(nombre, apellido),
            habitacion:habitacion_id(
              numero, tipo,
              propiedad:propiedad_id(nombre)
            )
          ''')
          .lte('fecha_entrada', fecha)
          .gte('fecha_salida', fecha)
          .inFilter('estado', ['confirmado', 'check_in'])
          .order('habitacion(numero)');

      final totalHabitaciones = await _client
          .from('habitacion')
          .select('count()')
          .eq('activa', true)
          .single();

      return {
        'fecha': fecha,
        'reservas': List<Map<String, dynamic>>.from(reservas),
        'total_habitaciones': totalHabitaciones['count'],
        'habitaciones_ocupadas': reservas.length,
        'porcentaje_ocupacion':
            (reservas.length / totalHabitaciones['count'] * 100).round(),
      };
    } catch (e) {
      throw Exception('Error al obtener ocupación diaria: $e');
    }
  }

  // === CANCELAR RESERVA ===
  static Future<void> cancelarReserva(String reservaId) async {
    try {
      // Obtener información de la reserva antes de cancelarla
      final reserva = await _client
          .from('reserva')
          .select('habitacion_id, estado')
          .eq('id', reservaId)
          .single();

      print(
        '🔍 Reserva a cancelar encontrada - Habitación: ${reserva['habitacion_id']}, Estado: ${reserva['estado']}',
      );

      // Actualizar estado de la reserva
      await _client
          .from('reserva')
          .update({'estado': 'cancelado'})
          .eq('id', reservaId);

      // 🆕 MANUALMENTE: Liberar habitación solo si estaba reservada o en check-in
      final estadoAnterior = reserva['estado'];
      if (estadoAnterior == 'confirmado' || estadoAnterior == 'check_in') {
        await _client
            .from('habitacion')
            .update({'estado': 'libre'})
            .eq('id', reserva['habitacion_id']);

        print('✅ Reserva cancelada y habitación liberada');
      } else {
        print(
          '✅ Reserva cancelada (habitación ya no estaba en un estado que requiera liberación)',
        );
      }
    } catch (e) {
      print('❌ Error al cancelar reserva: $e');
      throw Exception('Error al cancelar reserva: $e');
    }
  }

  // === HABITACIONES DISPONIBLES ===
  static Future<List<Map<String, dynamic>>> getHabitacionesDisponibles(
    DateTime fechaEntrada,
    DateTime fechaSalida,
  ) async {
    try {
      print(
        '🔍 Buscando habitaciones disponibles para ${fechaEntrada.toIso8601String().split('T')[0]} - ${fechaSalida.toIso8601String().split('T')[0]}',
      );

      // Primero obtener todas las habitaciones activas con información completa
      final todasHabitaciones = await _client
          .from('habitacion')
          .select('''
            id, numero, tipo, precio_noche, capacidad_maxima, wifi_password,
            propiedad:propiedad_id(id, nombre, direccion)
          ''')
          .eq('activa', true)
          .order('numero');

      print('📋 Total habitaciones activas: ${todasHabitaciones.length}');

      // Luego obtener habitaciones ocupadas en el rango de fechas
      final habitacionesOcupadas = await _client
          .from('reserva')
          .select('habitacion_id')
          .inFilter('estado', ['confirmado', 'check_in'])
          .or(
            'and(fecha_entrada.lte.${fechaSalida.toIso8601String().split('T')[0]},fecha_salida.gt.${fechaEntrada.toIso8601String().split('T')[0]})',
          );

      print('🚫 Habitaciones ocupadas: ${habitacionesOcupadas.length}');

      // Crear conjunto de IDs ocupados
      final ocupadosIds = habitacionesOcupadas
          .map((r) => r['habitacion_id'])
          .toSet();

      // Filtrar habitaciones disponibles y transformar datos
      final habitacionesDisponibles = todasHabitaciones
          .where((h) => !ocupadosIds.contains(h['id']))
          .map((h) {
            final propiedad = h['propiedad'] as Map<String, dynamic>?;
            return {
              'id': h['id'],
              'numero': h['numero']?.toString() ?? 'N/A',
              'tipo': h['tipo']?.toString() ?? 'Estándar',
              'precio': (h['precio_noche'] ?? 0).toDouble(),
              'capacidad': h['capacidad_maxima'] ?? 2,
              'wifi_password': h['wifi_password'],
              'propiedad_id': propiedad?['id'],
              'propiedad_nombre': propiedad?['nombre'] ?? 'Sin propiedad',
              'propiedad_direccion': propiedad?['direccion'] ?? '',
            };
          })
          .toList();

      print(
        '✅ Habitaciones disponibles encontradas: ${habitacionesDisponibles.length}',
      );
      for (final h in habitacionesDisponibles) {
        print(
          '  - Hab ${h['numero']} (${h['tipo']}) - ${h['propiedad_nombre']} - S/. ${h['precio']}',
        );
      }

      return habitacionesDisponibles;
    } catch (e) {
      print('❌ Error obteniendo habitaciones disponibles: $e');
      throw Exception('Error al obtener habitaciones disponibles: $e');
    }
  }
}
