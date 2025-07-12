// === ENUMS ===
enum TipoHabitacion { normal, doble, triple, departamento, monoambiente }
enum EstadoHabitacion { libre, reservado, ocupado, limpieza, mantenimiento }
enum MetodoPago { efectivo, transferencia, tarjeta, yape, plin, otro }
enum EstadoReserva { confirmado, check_in, check_out, cancelado, no_show }
enum CanalReserva { telefono, presencial, web, airbnb, booking, otro }
enum CategoriaGasto { lavanderia, telefono, minibar, transporte, multa, otro }
enum CategoriaInventario { ropa_cama, blancos, mobiliario, decoracion, limpieza, amenities }
enum EstadoInventario { nuevo, bueno, regular, malo, dañado }

// === EXTENSIONES PARA ENUMS ===
extension TipoHabitacionExtension on TipoHabitacion {
  String get displayName {
    switch (this) {
      case TipoHabitacion.normal:
        return 'Normal';
      case TipoHabitacion.doble:
        return 'Doble';
      case TipoHabitacion.triple:
        return 'Triple';
      case TipoHabitacion.departamento:
        return 'Departamento';
      case TipoHabitacion.monoambiente:
        return 'Monoambiente';
    }
  }

  static TipoHabitacion fromString(String value) {
    return TipoHabitacion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoHabitacion.normal,
    );
  }
}

extension EstadoHabitacionExtension on EstadoHabitacion {
  String get displayName {
    switch (this) {
      case EstadoHabitacion.libre:
        return 'Libre';
      case EstadoHabitacion.reservado:
        return 'Reservado';
      case EstadoHabitacion.ocupado:
        return 'Ocupado';
      case EstadoHabitacion.limpieza:
        return 'Limpieza';
      case EstadoHabitacion.mantenimiento:
        return 'Mantenimiento';
    }
  }

  String get emoji {
    switch (this) {
      case EstadoHabitacion.libre:
        return '🟢';
      case EstadoHabitacion.reservado:
        return '🟡';
      case EstadoHabitacion.ocupado:
        return '🔴';
      case EstadoHabitacion.limpieza:
        return '🟠';
      case EstadoHabitacion.mantenimiento:
        return '🟣';
    }
  }

  static EstadoHabitacion fromString(String value) {
    return EstadoHabitacion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoHabitacion.libre,
    );
  }
}

// === MODELOS ===
class Propiedad {
  final String id;
  final String nombre;
  final String direccion;
  final int totalHabitaciones;
  final String? propietarioId;
  final bool activa;
  final DateTime fechaCreacion;
  final int totalPisos;

  Propiedad({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.totalHabitaciones,
    this.propietarioId,
    required this.activa,
    required this.fechaCreacion,
    required this.totalPisos,
  });

  factory Propiedad.fromJson(Map<String, dynamic> json) {
    return Propiedad(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      totalHabitaciones: json['total_habitaciones'],
      propietarioId: json['propietario_id'],
      activa: json['activa'] ?? true,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      totalPisos: json['total_pisos'] ?? 1,
    );
  }
}

class Habitacion {
  final String id;
  final String propiedadId;
  final String numero;
  final TipoHabitacion tipo;
  final double precioNoche;
  final int capacidadMaxima;
  final EstadoHabitacion estado;
  final String? observaciones;
  final String? detalle;
  final int piso;
  final String? wifiPassword;
  final bool activa;
  final DateTime fechaCreacion;
  final Propiedad? propiedad;

  Habitacion({
    required this.id,
    required this.propiedadId,
    required this.numero,
    required this.tipo,
    required this.precioNoche,
    required this.capacidadMaxima,
    required this.estado,
    this.observaciones,
    this.detalle,
    required this.piso,
    this.wifiPassword,
    required this.activa,
    required this.fechaCreacion,
    this.propiedad,
  });

  factory Habitacion.fromJson(Map<String, dynamic> json) {
    return Habitacion(
      id: json['id'],
      propiedadId: json['propiedad_id'],
      numero: json['numero'],
      tipo: TipoHabitacionExtension.fromString(json['tipo']),
      precioNoche: (json['precio_noche'] as num).toDouble(),
      capacidadMaxima: json['capacidad_maxima'],
      estado: EstadoHabitacionExtension.fromString(json['estado']),
      observaciones: json['observaciones'],
      detalle: json['detalle'],
      piso: json['piso'] ?? 1,
      wifiPassword: json['wifi_password'],
      activa: json['activa'] ?? true,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      propiedad: json['propiedad'] != null ? Propiedad.fromJson(json['propiedad']) : null,
    );
  }

  String get numeroCompleto => '$numero (${propiedad?.nombre ?? ''})';
}

class Cliente {
  final String id;
  final String nombre;
  final String? apellido;
  final String? dni;
  final String? pasaporte;
  final String? telefono;
  final String? email;
  final String nacionalidad;
  final String? notas;
  final bool blacklist;
  final DateTime fechaRegistro;
  final DateTime? fechaUltimaEstadia;
  final int totalEstadias;

  Cliente({
    required this.id,
    required this.nombre,
    this.apellido,
    this.dni,
    this.pasaporte,
    this.telefono,
    this.email,
    required this.nacionalidad,
    this.notas,
    required this.blacklist,
    required this.fechaRegistro,
    this.fechaUltimaEstadia,
    required this.totalEstadias,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      dni: json['dni'],
      pasaporte: json['pasaporte'],
      telefono: json['telefono'],
      email: json['email'],
      nacionalidad: json['nacionalidad'] ?? 'Peruana',
      notas: json['notas'],
      blacklist: json['blacklist'] ?? false,
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      fechaUltimaEstadia: json['fecha_ultima_estadia'] != null 
          ? DateTime.parse(json['fecha_ultima_estadia']) 
          : null,
      totalEstadias: json['total_estadias'] ?? 0,
    );
  }

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
  String get whatsappUrl => telefono != null ? 'https://wa.me/51$telefono' : '';
}

class Reserva {
  final String id;
  final String clienteId;
  final String habitacionId;
  final int cantidadPersonas;
  final String? encargadoId;
  final DateTime fechaEntrada;
  final DateTime fechaSalida;
  final double precioNoche;
  final double limpieza;
  final double gastosAdicionales;
  final double descuentos;
  final double total;
  final double adelanto;
  final double saldoPendiente;
  final MetodoPago? metodoPagoAdelanto;
  final EstadoReserva estado;
  final CanalReserva? canalReserva;
  final String? observaciones;
  final DateTime fechaCreacion;
  final DateTime? fechaCheckIn;
  final DateTime? fechaCheckOut;
  final Cliente? cliente;
  final Habitacion? habitacion;

  Reserva({
    required this.id,
    required this.clienteId,
    required this.habitacionId,
    required this.cantidadPersonas,
    this.encargadoId,
    required this.fechaEntrada,
    required this.fechaSalida,
    required this.precioNoche,
    required this.limpieza,
    required this.gastosAdicionales,
    required this.descuentos,
    required this.total,
    required this.adelanto,
    required this.saldoPendiente,
    this.metodoPagoAdelanto,
    required this.estado,
    this.canalReserva,
    this.observaciones,
    required this.fechaCreacion,
    this.fechaCheckIn,
    this.fechaCheckOut,
    this.cliente,
    this.habitacion,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'],
      clienteId: json['cliente_id'],
      habitacionId: json['habitacion_id'],
      cantidadPersonas: json['cantidad_personas'],
      encargadoId: json['encargado_id'],
      fechaEntrada: DateTime.parse(json['fecha_entrada']),
      fechaSalida: DateTime.parse(json['fecha_salida']),
      precioNoche: (json['precio_noche'] as num).toDouble(),
      limpieza: (json['limpieza'] as num).toDouble(),
      gastosAdicionales: (json['gastos_adicionales'] as num).toDouble(),
      descuentos: (json['descuentos'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      adelanto: (json['adelanto'] as num).toDouble(),
      saldoPendiente: (json['saldo_pendiente'] as num).toDouble(),
      metodoPagoAdelanto: json['metodo_pago_adelanto'] != null 
          ? MetodoPago.values.firstWhere((e) => e.name == json['metodo_pago_adelanto'])
          : null,
      estado: EstadoReserva.values.firstWhere((e) => e.name == json['estado']),
      canalReserva: json['canal_reserva'] != null 
          ? CanalReserva.values.firstWhere((e) => e.name == json['canal_reserva'])
          : null,
      observaciones: json['observaciones'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaCheckIn: json['fecha_check_in'] != null 
          ? DateTime.parse(json['fecha_check_in']) 
          : null,
      fechaCheckOut: json['fecha_check_out'] != null 
          ? DateTime.parse(json['fecha_check_out']) 
          : null,
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      habitacion: json['habitacion'] != null ? Habitacion.fromJson(json['habitacion']) : null,
    );
  }

  int get diasEstadia => fechaSalida.difference(fechaEntrada).inDays;
  int get diasRestantes => fechaSalida.difference(DateTime.now()).inDays;
}

class ItemInventario {
  final String id;
  final String habitacionId;
  final CategoriaInventario categoria;
  final String articulo;
  final String? descripcion;
  final int cantidad;
  final EstadoInventario estado;
  final DateTime? fechaUltimaRevision;
  final bool necesitaReposicion;
  final double? precioUnitario;
  final String? proveedor;
  final String? observaciones;
  final DateTime fechaRegistro;
  final Habitacion? habitacion;

  ItemInventario({
    required this.id,
    required this.habitacionId,
    required this.categoria,
    required this.articulo,
    this.descripcion,
    required this.cantidad,
    required this.estado,
    this.fechaUltimaRevision,
    required this.necesitaReposicion,
    this.precioUnitario,
    this.proveedor,
    this.observaciones,
    required this.fechaRegistro,
    this.habitacion,
  });

  factory ItemInventario.fromJson(Map<String, dynamic> json) {
    return ItemInventario(
      id: json['id'],
      habitacionId: json['habitacion_id'],
      categoria: CategoriaInventario.values.firstWhere((e) => e.name == json['categoria']),
      articulo: json['articulo'],
      descripcion: json['descripcion'],
      cantidad: json['cantidad'],
      estado: EstadoInventario.values.firstWhere((e) => e.name == json['estado']),
      fechaUltimaRevision: json['fecha_ultima_revision'] != null 
          ? DateTime.parse(json['fecha_ultima_revision']) 
          : null,
      necesitaReposicion: json['necesita_reposicion'] ?? false,
      precioUnitario: json['precio_unitario'] != null 
          ? (json['precio_unitario'] as num).toDouble() 
          : null,
      proveedor: json['proveedor'],
      observaciones: json['observaciones'],
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      habitacion: json['habitacion'] != null ? Habitacion.fromJson(json['habitacion']) : null,
    );
  }

  String get categoriaDisplayName {
    switch (categoria) {
      case CategoriaInventario.ropa_cama:
        return 'Ropa de cama';
      case CategoriaInventario.blancos:
        return 'Blancos';
      case CategoriaInventario.mobiliario:
        return 'Mobiliario';
      case CategoriaInventario.decoracion:
        return 'Decoración';
      case CategoriaInventario.limpieza:
        return 'Limpieza';
      case CategoriaInventario.amenities:
        return 'Amenities';
    }
  }

  String get estadoDisplayName {
    switch (estado) {
      case EstadoInventario.nuevo:
        return 'Nuevo';
      case EstadoInventario.bueno:
        return 'Bueno';
      case EstadoInventario.regular:
        return 'Regular';
      case EstadoInventario.malo:
        return 'Malo';
      case EstadoInventario.dañado:
        return 'Dañado';
    }
  }
}