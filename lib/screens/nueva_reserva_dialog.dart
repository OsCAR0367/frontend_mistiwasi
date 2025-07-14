import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/clientes_provider.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class NuevaReservaDialog extends StatefulWidget {
  final Habitacion? habitacionPreseleccionada;

  const NuevaReservaDialog({super.key, this.habitacionPreseleccionada});

  @override
  State<NuevaReservaDialog> createState() => _NuevaReservaDialogState();
}

class _NuevaReservaDialogState extends State<NuevaReservaDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para el formulario
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Variables de estado
  DateTime _fechaEntrada = DateTime.now();
  DateTime _fechaSalida = DateTime.now().add(const Duration(days: 1));
  Habitacion? _habitacionSeleccionada;
  Cliente? _clienteSeleccionado;
  int _cantidadPersonas = 1;
  double _adelanto = 0.0;
  double _precioPersonalizado = 0.0;
  double _costoLimpieza = 30.0;
  MetodoPago _metodoPago = MetodoPago.efectivo;
  CanalReserva _canalReserva = CanalReserva.presencial;
  bool _isLoading = false;
  bool _clienteNuevo = true;
  String _codigoPais = '+51'; // Código de país editable
  String _filtroCliente = ''; // Filtro para búsqueda de clientes

  @override
  void initState() {
    super.initState();
    _habitacionSeleccionada = widget.habitacionPreseleccionada;

    // Si hay habitación preseleccionada, usar su precio
    if (_habitacionSeleccionada != null) {
      _precioPersonalizado = _habitacionSeleccionada!.precioNoche;
    }

    // Cargar clientes para autocompletado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 900,
        height: 750,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFF4CAF50).withOpacity(0.02)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header mejorado
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva Reserva',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Complete la información para crear la reserva',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido scrollable con padding mejorado
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selección de habitación
                      _buildSeccionHabitacion(),

                      const SizedBox(height: 32),

                      // Fechas de la reserva
                      _buildSeccionFechas(),

                      const SizedBox(height: 32),

                      // Cliente
                      _buildSeccionCliente(),

                      const SizedBox(height: 32),

                      // Detalles de la reserva
                      _buildSeccionDetalles(),

                      const SizedBox(height: 32),

                      // Pago
                      _buildSeccionPago(),
                    ],
                  ),
                ),
              ),

              // Footer con botones mejorados
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón pequeño de mantenimiento si hay habitación preseleccionada
                    if (_habitacionSeleccionada != null)
                      TextButton.icon(
                        onPressed: _isLoading ? null : _marcarComoMantenimiento,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text(
                          'Mantenimiento',
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Botones principales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _crearReserva,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Creando...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save),
                                    SizedBox(width: 8),
                                    Text(
                                      'Crear Reserva',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionHabitacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            children: [
              TextSpan(text: 'Habitación '),
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seleccione la habitación para la reserva',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            final habitacionesDisponibles = provider.habitaciones
                .where((h) => h.estado == EstadoHabitacion.libre)
                .toList();

            if (habitacionesDisponibles.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade600,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No hay habitaciones disponibles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Todas las habitaciones están ocupadas o reservadas. Intente con fechas diferentes.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<Habitacion>(
                value: _habitacionSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Seleccionar habitación',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.hotel, color: Color(0xFF4CAF50)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: habitacionesDisponibles.map((habitacion) {
                  return DropdownMenuItem<Habitacion>(
                    value: habitacion,
                    child: Text(
                      '${habitacion.numero} - ${habitacion.tipo.displayName} - S/.${habitacion.precioNoche}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _habitacionSeleccionada = value;
                    if (value != null) {
                      _precioPersonalizado = value.precioNoche;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Debe seleccionar una habitación';
                  }
                  return null;
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeccionFechas() {
    final diasEstadia = _fechaSalida.difference(_fechaEntrada).inDays;
    final fechasValidas = diasEstadia > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            children: [
              TextSpan(text: 'Fechas de la Reserva '),
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seleccione las fechas de entrada y salida',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _seleccionarFecha(true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de entrada',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF4CAF50),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_fechaEntrada),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: fechasValidas
                        ? Colors.grey.shade300
                        : Colors.red.shade300,
                    width: fechasValidas ? 1 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _seleccionarFecha(false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de salida',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: fechasValidas
                          ? Colors.white
                          : Colors.red.shade50,
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: fechasValidas
                            ? const Color(0xFF4CAF50)
                            : Colors.red.shade600,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_fechaSalida),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: fechasValidas
                            ? Colors.black
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Indicador de duración con validación visual
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fechasValidas
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: fechasValidas
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.red.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                fechasValidas ? Icons.check_circle : Icons.error,
                color: fechasValidas
                    ? const Color(0xFF4CAF50)
                    : Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                fechasValidas
                    ? 'Duración: $diasEstadia ${diasEstadia == 1 ? 'día' : 'días'}'
                    : 'Error: La fecha de salida debe ser posterior a la fecha de entrada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fechasValidas
                      ? const Color(0xFF4CAF50)
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionCliente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                children: [
                  TextSpan(text: 'Cliente '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red, fontSize: 20),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                isSelected: [_clienteNuevo, !_clienteNuevo],
                onPressed: (index) {
                  setState(() {
                    _clienteNuevo = index == 0;
                    if (!_clienteNuevo) {
                      _clienteSeleccionado = null;
                    }
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Nuevo'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Existente'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_clienteNuevo) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ingrese el nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF4CAF50),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _apellidoController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    hintText: 'Ingrese el apellido',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dniController,
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    hintText: '12345678',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.badge,
                      color: Color(0xFF4CAF50),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Solo números
                    LengthLimitingTextInputFormatter(8), // Máximo 8 dígitos
                  ],
                  maxLength: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El DNI es requerido';
                    }
                    if (value.length != 8) {
                      return 'El DNI debe tener 8 dígitos';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    // Dropdown de código de país
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _codigoPais,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: '+51', child: Text('+51')),
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+34', child: Text('+34')),
                          DropdownMenuItem(value: '+54', child: Text('+54')),
                          DropdownMenuItem(value: '+56', child: Text('+56')),
                          DropdownMenuItem(value: '+57', child: Text('+57')),
                          DropdownMenuItem(value: '+593', child: Text('+593')),
                          DropdownMenuItem(value: '+595', child: Text('+595')),
                          DropdownMenuItem(value: '+598', child: Text('+598')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _codigoPais = value!;
                          });
                        },
                      ),
                    ),
                    // Campo de teléfono
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          hintText: '987654321',
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 7) {
                              return 'Teléfono debe tener al menos 7 dígitos';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'cliente@email.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.email, color: Color(0xFF4CAF50)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty && !value.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
        ] else ...[
          // Barra de búsqueda para clientes
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Buscar cliente',
              hintText: 'Buscar por nombre, apellido, DNI o teléfono...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
            ),
            onChanged: (value) {
              setState(() {
                _filtroCliente = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Consumer<ClientesProvider>(
            builder: (context, provider, child) {
              // Filtrar clientes según el texto de búsqueda
              final clientesFiltrados = _filtroCliente.isEmpty
                  ? provider.clientes
                  : provider.clientes.where((cliente) {
                      final textoBusqueda = _filtroCliente;
                      return cliente.nombre.toLowerCase().contains(
                            textoBusqueda,
                          ) ||
                          (cliente.apellido?.toLowerCase().contains(
                                textoBusqueda,
                              ) ??
                              false) ||
                          (cliente.dni?.contains(_filtroCliente) ?? false) ||
                          (cliente.telefono?.contains(_filtroCliente) ??
                              false) ||
                          (cliente.email?.toLowerCase().contains(
                                textoBusqueda,
                              ) ??
                              false);
                    }).toList();

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<Cliente>(
                  value: _clienteSeleccionado,
                  decoration: InputDecoration(
                    labelText: clientesFiltrados.isEmpty
                        ? 'No se encontraron clientes'
                        : 'Seleccionar cliente (${clientesFiltrados.length} encontrados)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.person_search,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  items: clientesFiltrados.map((cliente) {
                    return DropdownMenuItem<Cliente>(
                      value: cliente,
                      child: Text(
                        '${cliente.nombreCompleto} - ${cliente.dni ?? cliente.pasaporte ?? 'Sin doc'}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _clienteSeleccionado = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Debe seleccionar un cliente';
                    }
                    return null;
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSeccionDetalles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles de la Reserva',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Información adicional sobre la reserva',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<int>(
                  value: _cantidadPersonas,
                  decoration: InputDecoration(
                    labelText: 'Cantidad de personas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.people,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  items: List.generate(6, (index) => index + 1).map((num) {
                    return DropdownMenuItem<int>(
                      value: num,
                      child: Text('$num ${num == 1 ? 'persona' : 'personas'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _cantidadPersonas = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<CanalReserva>(
                  value: _canalReserva,
                  decoration: InputDecoration(
                    labelText: 'Canal de reserva',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.source,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  items: CanalReserva.values.map((canal) {
                    return DropdownMenuItem<CanalReserva>(
                      value: canal,
                      child: Text(_getCanalDisplayName(canal)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _canalReserva = value!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Información adicional sobre la reserva...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.note_add, color: Color(0xFF4CAF50)),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSeccionPago() {
    final precioNoche = _precioPersonalizado > 0
        ? _precioPersonalizado
        : (_habitacionSeleccionada?.precioNoche ?? 0.0);
    final diasEstadia = _fechaSalida.difference(_fechaEntrada).inDays;
    final subtotal = precioNoche * diasEstadia;
    final total = subtotal + _costoLimpieza;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Pago',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure los precios y forma de pago',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Campos editables de precios
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: precioNoche.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  ), // Solo números y punto decimal
                ],
                decoration: InputDecoration(
                  labelText: 'Precio por noche',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: 'S/. ',
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                validator: (value) {
                  final precio = double.tryParse(value ?? '');
                  if (precio == null || precio <= 0) {
                    return 'Precio debe ser mayor a 0';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    final nuevoPrecio = double.tryParse(value) ?? 0.0;
                    _precioPersonalizado = nuevoPrecio < 0 ? 0.0 : nuevoPrecio;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _costoLimpieza.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  ), // Solo números y punto decimal
                ],
                decoration: InputDecoration(
                  labelText: 'Costo de limpieza',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: 'S/. ',
                  prefixIcon: const Icon(
                    Icons.cleaning_services,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                validator: (value) {
                  final costo = double.tryParse(value ?? '');
                  if (costo == null || costo < 0) {
                    return 'Costo debe ser mayor o igual a 0';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    final nuevoCosto = double.tryParse(value) ?? 30.0;
                    _costoLimpieza = nuevoCosto < 0 ? 0.0 : nuevoCosto;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Resumen de costos mejorado
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4CAF50).withOpacity(0.1),
                const Color(0xFF4CAF50).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calculate,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Resumen de Costos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCostRow(
                'Precio por noche:',
                'S/. ${precioNoche.toStringAsFixed(2)}',
              ),
              _buildCostRow(
                'Días de estadía:',
                '$diasEstadia ${diasEstadia == 1 ? 'día' : 'días'}',
              ),
              _buildCostRow(
                'Subtotal habitación:',
                'S/. ${subtotal.toStringAsFixed(2)}',
              ),
              _buildCostRow(
                'Costo de limpieza:',
                'S/. ${_costoLimpieza.toStringAsFixed(2)}',
              ),
              const Divider(thickness: 2, color: Color(0xFF4CAF50)),
              _buildCostRow(
                'TOTAL A PAGAR:',
                'S/. ${total.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  ), // Solo números y punto decimal
                ],
                decoration: InputDecoration(
                  labelText: 'Adelanto',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: 'S/. ',
                  prefixIcon: const Icon(
                    Icons.payments,
                    color: Color(0xFF4CAF50),
                  ),
                  helperText: 'Monto mínimo: S/. 0.00',
                ),
                validator: (value) {
                  final adelanto = double.tryParse(value ?? '0');
                  if (adelanto == null || adelanto < 0) {
                    return 'El adelanto no puede ser negativo';
                  }
                  if (adelanto > total) {
                    return 'El adelanto no puede ser mayor al total';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    final nuevoAdelanto = double.tryParse(value) ?? 0.0;
                    // Asegurar que nunca sea negativo
                    _adelanto = nuevoAdelanto < 0 ? 0.0 : nuevoAdelanto;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<MetodoPago>(
                  value: _metodoPago,
                  decoration: InputDecoration(
                    labelText: 'Método de pago',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.payment,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  items: MetodoPago.values.map((metodo) {
                    return DropdownMenuItem<MetodoPago>(
                      value: metodo,
                      child: Text(_getMetodoDisplayName(metodo)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _metodoPago = value!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Saldo pendiente destacado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (total - _adelanto) > 0
                ? Colors.orange.shade50
                : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (total - _adelanto) > 0
                  ? Colors.orange.shade300
                  : Colors.green.shade300,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    (total - _adelanto) > 0
                        ? Icons.pending_actions
                        : Icons.check_circle,
                    color: (total - _adelanto) > 0
                        ? Colors.orange.shade600
                        : Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Saldo pendiente:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                'S/. ${(total - _adelanto).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (total - _adelanto) > 0
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF4CAF50) : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF4CAF50) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFecha(bool esEntrada) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final fecha = await showDatePicker(
      context: context,
      initialDate: esEntrada ? _fechaEntrada : _fechaSalida,
      firstDate: hoy, // No permite fechas anteriores a hoy
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: esEntrada
          ? 'Seleccionar fecha de entrada'
          : 'Seleccionar fecha de salida',
    );

    if (fecha != null) {
      setState(() {
        if (esEntrada) {
          _fechaEntrada = fecha;
          // Si la fecha de salida es anterior o igual a la de entrada, ajustarla
          if (_fechaSalida.isBefore(fecha.add(const Duration(days: 1))) ||
              _fechaSalida.isAtSameMomentAs(fecha)) {
            _fechaSalida = fecha.add(const Duration(days: 1));
          }
        } else {
          // Validar que la fecha de salida sea posterior a la de entrada
          if (fecha.isAfter(_fechaEntrada)) {
            _fechaSalida = fecha;
          } else {
            // Mostrar mensaje de error si la fecha de salida no es válida
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'La fecha de salida debe ser posterior a la fecha de entrada',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _crearReserva() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      _mostrarError(
        'Por favor, complete todos los campos requeridos correctamente.',
      );
      return;
    }

    // Validaciones específicas antes de continuar
    final String? errorValidacion = _validarDatosReserva();
    if (errorValidacion != null) {
      _mostrarError(errorValidacion);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String clienteId;

      // Crear o usar cliente existente
      if (_clienteNuevo) {
        clienteId = await _crearNuevoCliente();
      } else {
        if (_clienteSeleccionado == null) {
          throw Exception('Debe seleccionar un cliente');
        }
        clienteId = _clienteSeleccionado!.id;
      }

      // Calcular totales con validación
      final diasEstadia = _fechaSalida.difference(_fechaEntrada).inDays;
      final precioNoche = _precioPersonalizado > 0
          ? _precioPersonalizado
          : (_habitacionSeleccionada?.precioNoche ?? 0.0);
      final subtotal = precioNoche * diasEstadia;
      final total = subtotal + _costoLimpieza;

      // Validar que el total sea coherente
      if (total <= 0) {
        throw Exception('El total de la reserva debe ser mayor a S/. 0.00');
      }

      // Crear reserva con validación adicional
      final reservaData = _construirDatosReserva(
        clienteId,
        diasEstadia,
        precioNoche,
        total,
      );

      await SupabaseService.crearReserva(reservaData);

      // Éxito: Recargar dashboard y cerrar dialog
      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();

        _mostrarExito(
          'Reserva creada exitosamente para $diasEstadia ${diasEstadia == 1 ? 'día' : 'días'}.\n'
          'Total: S/. ${total.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      if (mounted) {
        String mensajeError = 'Error al crear reserva';

        // Mensajes de error más específicos
        if (e.toString().contains('duplicate key')) {
          mensajeError =
              'Ya existe una reserva para estas fechas en esta habitación';
        } else if (e.toString().contains('foreign key')) {
          mensajeError = 'Error de datos: Cliente o habitación no válidos';
        } else if (e.toString().contains('network')) {
          mensajeError =
              'Error de conexión. Verifique su internet e intente nuevamente';
        } else {
          mensajeError = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        }

        _mostrarError(mensajeError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Valida todos los datos necesarios para crear la reserva
  String? _validarDatosReserva() {
    // Validar habitación seleccionada
    if (_habitacionSeleccionada == null) {
      return 'Debe seleccionar una habitación';
    }

    // Validar fechas
    final diasEstadia = _fechaSalida.difference(_fechaEntrada).inDays;
    if (diasEstadia <= 0) {
      return 'La fecha de salida debe ser posterior a la fecha de entrada';
    }

    if (diasEstadia > 365) {
      return 'La estadía no puede ser mayor a 365 días';
    }

    // Validar fechas no sean en el pasado
    final hoy = DateTime.now();
    final fechaEntradaSoloFecha = DateTime(
      _fechaEntrada.year,
      _fechaEntrada.month,
      _fechaEntrada.day,
    );
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);

    if (fechaEntradaSoloFecha.isBefore(hoySoloFecha)) {
      return 'La fecha de entrada no puede ser anterior a hoy';
    }

    // Validar precios
    final precioNoche = _precioPersonalizado > 0
        ? _precioPersonalizado
        : (_habitacionSeleccionada?.precioNoche ?? 0.0);
    if (precioNoche <= 0) {
      return 'El precio por noche debe ser mayor a S/. 0.00';
    }

    if (_costoLimpieza < 0) {
      return 'El costo de limpieza no puede ser negativo';
    }

    // Validar adelanto
    final total = (precioNoche * diasEstadia) + _costoLimpieza;
    if (_adelanto < 0) {
      return 'El adelanto no puede ser negativo';
    }

    if (_adelanto > total) {
      return 'El adelanto no puede ser mayor al total (S/. ${total.toStringAsFixed(2)})';
    }

    // Validar cantidad de personas
    if (_cantidadPersonas <= 0 || _cantidadPersonas > 10) {
      return 'La cantidad de personas debe estar entre 1 y 10';
    }

    // Validar cliente si es nuevo
    if (_clienteNuevo) {
      if (_nombreController.text.trim().isEmpty) {
        return 'El nombre del cliente es requerido';
      }

      if (_dniController.text.trim().isEmpty) {
        return 'El DNI del cliente es requerido';
      }

      if (_dniController.text.trim().length != 8) {
        return 'El DNI debe tener exactamente 8 dígitos';
      }

      // Validar email si se proporciona
      final email = _emailController.text.trim();
      if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
        return 'El email proporcionado no es válido';
      }

      // Validar teléfono si se proporciona
      final telefono = _telefonoController.text.trim();
      if (telefono.isNotEmpty && telefono.length < 7) {
        return 'El teléfono debe tener al menos 7 dígitos';
      }
    }

    return null; // Todo válido
  }

  /// Crea un nuevo cliente con validaciones
  Future<String> _crearNuevoCliente() async {
    final clienteData = {
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim().isNotEmpty
          ? _apellidoController.text.trim()
          : null,
      'dni': _dniController.text.trim(),
      'telefono': _telefonoController.text.trim().isNotEmpty
          ? '$_codigoPais${_telefonoController.text.trim()}'
          : null,
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim().toLowerCase()
          : null,
      'nacionalidad': 'Peruana',
      'fecha_registro': DateTime.now().toIso8601String(),
    }; // Validar que no exista un cliente con el mismo DNI
    final nuevoCliente = await SupabaseService.crearCliente(clienteData);

    if (nuevoCliente['id'] == null) {
      throw Exception('Error al crear el cliente. Intente nuevamente.');
    }

    return nuevoCliente['id'];
  }

  /// Construye los datos de la reserva
  Map<String, dynamic> _construirDatosReserva(
    String clienteId,
    int diasEstadia,
    double precioNoche,
    double total,
  ) {
    return {
      'cliente_id': clienteId,
      'habitacion_id': _habitacionSeleccionada!.id,
      'cantidad_personas': _cantidadPersonas,
      'fecha_entrada': _fechaEntrada.toIso8601String().split('T')[0],
      'fecha_salida': _fechaSalida.toIso8601String().split('T')[0],
      'precio_noche': precioNoche,
      'limpieza': _costoLimpieza,
      'total': total,
      'adelanto': _adelanto,
      'saldo_pendiente': total - _adelanto,
      'metodo_pago_adelanto': _adelanto > 0 ? _metodoPago.name : null,
      'canal_reserva': _canalReserva.name,
      'observaciones': _observacionesController.text.trim().isNotEmpty
          ? _observacionesController.text.trim()
          : null,
      'estado': 'confirmado',
      'fecha_creacion': DateTime.now().toIso8601String(),
    };
  }

  /// Muestra un mensaje de error
  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Muestra un mensaje de éxito
  void _mostrarExito(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getCanalDisplayName(CanalReserva canal) {
    switch (canal) {
      case CanalReserva.telefono:
        return 'Teléfono';
      case CanalReserva.presencial:
        return 'Presencial';
      case CanalReserva.web:
        return 'Web';
      case CanalReserva.airbnb:
        return 'Airbnb';
      case CanalReserva.booking:
        return 'Booking';
      case CanalReserva.otro:
        return 'Otro';
    }
  }

  String _getMetodoDisplayName(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.yape:
        return 'Yape';
      case MetodoPago.plin:
        return 'Plin';
      case MetodoPago.otro:
        return 'Otro';
    }
  }

  /// Marca la habitación como en mantenimiento
  Future<void> _marcarComoMantenimiento() async {
    if (_habitacionSeleccionada == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Mantenimiento'),
        content: Text(
          '¿Desea marcar la habitación ${_habitacionSeleccionada!.numero} como en mantenimiento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);

      try {
        await SupabaseService.marcarMantenimiento(
          _habitacionSeleccionada!.id,
          'Habitación marcada para mantenimiento desde formulario de reserva',
        );

        if (mounted) {
          _mostrarExito('Habitación marcada para mantenimiento exitosamente');
          Navigator.of(context).pop();

          // Recargar dashboard
          Provider.of<DashboardProvider>(
            context,
            listen: false,
          ).cargarDashboard();
        }
      } catch (e) {
        if (mounted) {
          _mostrarError(
            'Error al marcar habitación para mantenimiento: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}
