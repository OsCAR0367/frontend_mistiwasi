import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/clientes_provider.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class NuevaReservaDialog extends StatefulWidget {
  final Habitacion? habitacionPreseleccionada;

  const NuevaReservaDialog({
    super.key,
    this.habitacionPreseleccionada,
  });

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
  MetodoPago _metodoPago = MetodoPago.efectivo;
  CanalReserva _canalReserva = CanalReserva.presencial;
  bool _isLoading = false;
  bool _clienteNuevo = true;

  @override
  void initState() {
    super.initState();
    _habitacionSeleccionada = widget.habitacionPreseleccionada;
    
    // Cargar clientes para autocompletado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nueva Reserva',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selección de habitación
                      _buildSeccionHabitacion(),
                      
                      const SizedBox(height: 24),
                      
                      // Fechas de la reserva
                      _buildSeccionFechas(),
                      
                      const SizedBox(height: 24),
                      
                      // Cliente
                      _buildSeccionCliente(),
                      
                      const SizedBox(height: 24),
                      
                      // Detalles de la reserva
                      _buildSeccionDetalles(),
                      
                      const SizedBox(height: 24),
                      
                      // Pago
                      _buildSeccionPago(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _crearReserva,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Crear Reserva'),
                  ),
                ],
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
        const Text(
          'Habitación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return DropdownButtonFormField<Habitacion>(
              value: _habitacionSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Seleccionar habitación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.hotel),
              ),
              items: provider.habitaciones
                  .where((h) => h.estado == EstadoHabitacion.libre)
                  .map((habitacion) {
                return DropdownMenuItem<Habitacion>(
                  value: habitacion,
                  child: Text(
                    '${habitacion.numero} - ${habitacion.tipo.displayName} (${habitacion.propiedad?.nombre ?? ''})',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _habitacionSeleccionada = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Debe seleccionar una habitación';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeccionFechas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fechas de la Reserva',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _seleccionarFecha(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de entrada',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_fechaEntrada),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _seleccionarFecha(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de salida',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_fechaSalida),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duración: ${_fechaSalida.difference(_fechaEntrada).inDays} días',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
            const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ToggleButtons(
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
          ],
        ),
        const SizedBox(height: 12),
        if (_clienteNuevo) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'DNI',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixText: '+51 ',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ] else ...[
          Consumer<ClientesProvider>(
            builder: (context, provider, child) {
              return DropdownButtonFormField<Cliente>(
                value: _clienteSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar cliente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: provider.clientes.map((cliente) {
                  return DropdownMenuItem<Cliente>(
                    value: cliente,
                    child: Text(
                      '${cliente.nombreCompleto} - ${cliente.dni ?? cliente.pasaporte ?? 'Sin doc'}',
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _cantidadPersonas,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de personas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
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
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<CanalReserva>(
                value: _canalReserva,
                decoration: const InputDecoration(
                  labelText: 'Canal de reserva',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.source),
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
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSeccionPago() {
    final precioNoche = _habitacionSeleccionada?.precioNoche ?? 0.0;
    final diasEstadia = _fechaSalida.difference(_fechaEntrada).inDays;
    final subtotal = precioNoche * diasEstadia;
    const limpieza = 30.0;
    final total = subtotal + limpieza;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Pago',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Resumen de costos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Precio por noche:'),
                  Text('S/. ${precioNoche.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Días de estadía:'),
                  Text('$diasEstadia días'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:'),
                  Text('S/. ${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Limpieza:'),
                  Text('S/. ${limpieza.toStringAsFixed(2)}'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'S/. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Adelanto',
                  border: OutlineInputBorder(),
                  prefixText: 'S/. ',
                ),
                onChanged: (value) {
                  setState(() {
                    _adelanto = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<MetodoPago>(
                value: _metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
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
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Saldo pendiente: S/. ${(total - _adelanto).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha(bool esEntrada) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esEntrada ? _fechaEntrada : _fechaSalida,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() {
        if (esEntrada) {
          _fechaEntrada = fecha;
          if (_fechaSalida.isBefore(_fechaEntrada.add(const Duration(days: 1)))) {
            _fechaSalida = _fechaEntrada.add(const Duration(days: 1));
          }
        } else {
          _fechaSalida = fecha;
        }
      });
    }
  }

  Future<void> _crearReserva() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String clienteId;

      // Crear o usar cliente existente
      if (_clienteNuevo) {
        // Validar que al menos DNI esté presente para cliente nuevo
        if (_dniController.text.isEmpty) {
          throw Exception('El DNI es requerido para crear un nuevo cliente');
        }

        final clienteData = {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim().isNotEmpty 
              ? _apellidoController.text.trim() 
              : null,
          'dni': _dniController.text.trim(),
          'telefono': _telefonoController.text.trim().isNotEmpty 
              ? _telefonoController.text.trim() 
              : null,
          'email': _emailController.text.trim().isNotEmpty 
              ? _emailController.text.trim() 
              : null,
          'nacionalidad': 'Peruana',
        };

        final nuevoCliente = await SupabaseService.crearCliente(clienteData);
        clienteId = nuevoCliente['id'];
      } else {
        if (_clienteSeleccionado == null) {
          throw Exception('Debe seleccionar un cliente');
        }
        clienteId = _clienteSeleccionado!.id;
      }

      // Calcular totales
      final precioNoche = _habitacionSeleccionada!.precioNoche;
      final diasEstadia = _fechaSalida.difference(_fechaEntrada).inDays;
      final subtotal = precioNoche * diasEstadia;
      const limpieza = 30.0;
      final total = subtotal + limpieza;

      // Crear reserva
      final reservaData = {
        'cliente_id': clienteId,
        'habitacion_id': _habitacionSeleccionada!.id,
        'cantidad_personas': _cantidadPersonas,
        'fecha_entrada': _fechaEntrada.toIso8601String().split('T')[0],
        'fecha_salida': _fechaSalida.toIso8601String().split('T')[0],
        'precio_noche': precioNoche,
        'limpieza': limpieza,
        'total': total,
        'adelanto': _adelanto,
        'saldo_pendiente': total - _adelanto,
        'metodo_pago_adelanto': _adelanto > 0 ? _metodoPago.name : null,
        'canal_reserva': _canalReserva.name,
        'observaciones': _observacionesController.text.trim().isNotEmpty 
            ? _observacionesController.text.trim() 
            : null,
        'estado': 'confirmado',
      };

      await SupabaseService.crearReserva(reservaData);

      // Recargar dashboard
      if (mounted) {
        context.read<DashboardProvider>().cargarDashboard();
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva creada exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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