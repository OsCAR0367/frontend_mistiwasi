import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/clientes_provider.dart';
import '../models/models.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Base de Clientes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          'Historial de huéspedes y datos de contacto',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoNuevoCliente(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Nuevo Cliente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Barra de búsqueda
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre, DNI, teléfono o email...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF666666)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      context.read<ClientesProvider>().filtrarClientes(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Consumer<ClientesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.clientes.isEmpty) {
                  return const LoadingWidget(message: 'Cargando clientes...');
                }

                if (provider.error != null) {
                  return ErrorDisplayWidget(
                    message: provider.error!,
                    onRetry: () => provider.cargarClientes(),
                  );
                }

                if (provider.clientesFiltrados.isEmpty) {
                  return EmptyStateWidget(
                    icon: provider.filtroTexto.isNotEmpty 
                        ? Icons.search_off
                        : Icons.people_outline,
                    title: provider.filtroTexto.isNotEmpty 
                        ? 'No se encontraron clientes'
                        : 'No hay clientes registrados',
                    subtitle: provider.filtroTexto.isNotEmpty 
                        ? 'Intenta con otros términos de búsqueda'
                        : 'Agrega el primer cliente para comenzar',
                    action: provider.filtroTexto.isEmpty 
                        ? ElevatedButton.icon(
                            onPressed: () => _mostrarDialogoNuevoCliente(),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Agregar Cliente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                          )
                        : null,
                  );
                }

                return _buildClientesList(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientesList(ClientesProvider provider) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Documento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Contacto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Última Estadía',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Estadías',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 60), // Para las acciones
              ],
            ),
          ),
          
          // Lista de clientes
          Expanded(
            child: ListView.separated(
              itemCount: provider.clientesFiltrados.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cliente = provider.clientesFiltrados[index];
                return _buildClienteRow(cliente);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteRow(Cliente cliente) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Información del cliente
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cliente.blacklist 
                      ? Colors.red.shade100
                      : const Color(0xFF4CAF50).withOpacity(0.1),
                  child: Icon(
                    cliente.blacklist ? Icons.block : Icons.person,
                    color: cliente.blacklist 
                        ? Colors.red.shade600
                        : const Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Nombre y nacionalidad
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        cliente.nacionalidad,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (cliente.blacklist)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BLACKLIST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Documento
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cliente.dni != null)
                  Text(
                    'DNI: ${cliente.dni}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (cliente.pasaporte != null)
                  Text(
                    'Pasaporte: ${cliente.pasaporte}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          
          // Contacto
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cliente.telefono != null)
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cliente.telefono!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                if (cliente.email != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cliente.email!,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Última estadía
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cliente.fechaUltimaEstadia != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(cliente.fechaUltimaEstadia!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Sin estadías',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          
          // Total de estadías
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cliente.totalEstadias.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Acciones
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cliente.telefono != null)
                  IconButton(
                    onPressed: () => _abrirWhatsApp(cliente.telefono!),
                    icon: const Icon(
                      Icons.chat,
                      color: Color(0xFF25D366),
                      size: 20,
                    ),
                    tooltip: 'WhatsApp',
                  ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'historial',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16),
                          SizedBox(width: 8),
                          Text('Historial'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        // TODO: Implementar edición
                        break;
                      case 'historial':
                        // TODO: Mostrar historial de reservas
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNuevoCliente() {
    showDialog(
      context: context,
      builder: (context) => const DialogoNuevoCliente(),
    );
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    final url = 'https://wa.me/51$telefono';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir WhatsApp para: $telefono'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class DialogoNuevoCliente extends StatefulWidget {
  const DialogoNuevoCliente({super.key});

  @override
  State<DialogoNuevoCliente> createState() => _DialogoNuevoClienteState();
}

class _DialogoNuevoClienteState extends State<DialogoNuevoCliente> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _pasaporteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _nacionalidadController = TextEditingController(text: 'Peruana');
  final _notasController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuevo Cliente',
                    style: TextStyle(
                      fontSize: 20,
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
              
              // Campos del formulario
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
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length != 8) {
                          return 'El DNI debe tener 8 dígitos';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pasaporteController,
                      decoration: const InputDecoration(
                        labelText: 'Pasaporte',
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
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        prefixText: '+51 ',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nacionalidadController,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidad',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                    onPressed: _isLoading ? null : _guardarCliente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
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
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar que al menos DNI o pasaporte esté presente
    if (_dniController.text.isEmpty && _pasaporteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe proporcionar al menos DNI o Pasaporte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clienteData = {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim().isNotEmpty 
            ? _apellidoController.text.trim() 
            : null,
        'dni': _dniController.text.trim().isNotEmpty 
            ? _dniController.text.trim() 
            : null,
        'pasaporte': _pasaporteController.text.trim().isNotEmpty 
            ? _pasaporteController.text.trim() 
            : null,
        'telefono': _telefonoController.text.trim().isNotEmpty 
            ? _telefonoController.text.trim() 
            : null,
        'email': _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
        'nacionalidad': _nacionalidadController.text.trim(),
        'notas': _notasController.text.trim().isNotEmpty 
            ? _notasController.text.trim() 
            : null,
      };

      final nuevoCliente = await context.read<ClientesProvider>().crearCliente(clienteData);
      
      if (nuevoCliente != null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente creado exitosamente'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear cliente: $e'),
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

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _pasaporteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _nacionalidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}