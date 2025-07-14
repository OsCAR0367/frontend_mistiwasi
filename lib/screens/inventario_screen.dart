// lib/screens/inventario_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventario_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/models.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String? _habitacionFiltroSeleccionada;
  CategoriaInventario? _categoriaFiltroSeleccionada;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarInventario();
      context.read<DashboardProvider>().cargarDashboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header con botones de acción
          _buildHeader(),
          
          // Filtros y búsqueda
          _buildFiltrosSection(),
          
          // Contenido principal
          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(message: 'Cargando inventario...');
                }

                if (provider.error != null) {
                  return ErrorDisplayWidget(
                    message: provider.error!,
                    onRetry: () => provider.cargarInventario(),
                  );
                }

                final inventarioFiltrado = _filtrarInventario(provider.inventario);

                if (inventarioFiltrado.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No se encontraron artículos',
                    subtitle: 'Prueba ajustando los filtros o agrega nuevos artículos',
                  );
                }

                return _buildInventarioContent(inventarioFiltrado);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoItem(),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Artículo'),
      ),
    );
  }

  // Header con información y estadísticas
  Widget _buildHeader() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Control de Inventario',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Gestión de suministros por habitación y ubicación',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Estadísticas rápidas
          Consumer<InventarioProvider>(
            builder: (context, provider, child) {
              final inventario = provider.inventario;
              final totalItems = inventario.length;
              final itemsReposicion = inventario.where((item) => item.necesitaReposicion).length;
              final itemsDanados = inventario.where((item) => item.estado == EstadoInventario.malo || item.estado == EstadoInventario.danado).length;

              return Row(
                children: [
                  _buildStatCard(
                    'Total Items',
                    totalItems.toString(),
                    Icons.inventory_2,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Necesitan Reposición',
                    itemsReposicion.toString(),
                    Icons.warning,
                    const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Dañados',
                    itemsDanados.toString(),
                    Icons.error,
                    const Color(0xFFF44336),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Sección de filtros y búsqueda
  Widget _buildFiltrosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar artículos por nombre, descripción...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Filtros por categoría y habitación
          Row(
            children: [
              // Filtro por categoría
              Expanded(
                child: DropdownButtonFormField<CategoriaInventario?>(
                  value: _categoriaFiltroSeleccionada,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<CategoriaInventario?>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...CategoriaInventario.values.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(_getCategoriaDisplayName(categoria)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoriaFiltroSeleccionada = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Filtro por habitación
              Expanded(
                child: Consumer<DashboardProvider>(
                  builder: (context, dashboardProvider, child) {
                    final habitaciones = dashboardProvider.habitaciones;
                    
                    return DropdownButtonFormField<String?>(
                      value: _habitacionFiltroSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Habitación',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las habitaciones'),
                        ),
                        ...habitaciones.map((habitacion) {
                          return DropdownMenuItem(
                            value: habitacion.id,
                            child: Text('${habitacion.numero} - ${habitacion.propiedad?.nombre ?? "Sin propiedad"}'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _habitacionFiltroSeleccionada = value;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Botón para limpiar filtros
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _categoriaFiltroSeleccionada = null;
                    _habitacionFiltroSeleccionada = null;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Filtrar inventario basado en los criterios seleccionados
  List<ItemInventario> _filtrarInventario(List<ItemInventario> inventario) {
    return inventario.where((item) {
      // Filtro por búsqueda de texto
      bool cumpleBusqueda = _searchQuery.isEmpty ||
          item.articulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Filtro por categoría
      bool cumpleCategoria = _categoriaFiltroSeleccionada == null ||
          item.categoria == _categoriaFiltroSeleccionada;

      // Filtro por habitación
      bool cumpleHabitacion = _habitacionFiltroSeleccionada == null ||
          item.habitacionId == _habitacionFiltroSeleccionada;

      return cumpleBusqueda && cumpleCategoria && cumpleHabitacion;
    }).toList();
  }

  // Contenido principal del inventario
  Widget _buildInventarioContent(List<ItemInventario> inventario) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Tabs para vista por habitación vs vista general
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: TabBar(
                      labelColor: const Color(0xFF4CAF50),
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: const Color(0xFF4CAF50),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_list, size: 18),
                              SizedBox(width: 8),
                              Text('Lista General'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hotel, size: 18),
                              SizedBox(width: 8),
                              Text('Por Habitación'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category, size: 18),
                              SizedBox(width: 8),
                              Text('Por Categoría'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildVistaGeneral(inventario),
                        _buildVistaPorHabitacion(inventario),
                        _buildVistaPorCategoria(inventario),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vista general en lista
  Widget _buildVistaGeneral(List<ItemInventario> inventario) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: inventario.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = inventario[index];
        return _buildItemCard(item);
      },
    );
  }

  // Vista agrupada por habitación
  Widget _buildVistaPorHabitacion(List<ItemInventario> inventario) {
    final Map<String, List<ItemInventario>> inventarioPorHabitacion = {};
    
    for (final item in inventario) {
      final habitacionKey = '${item.habitacion?.numero ?? "Sin habitación"} - ${item.habitacion?.propiedad?.nombre ?? "Sin propiedad"}';
      inventarioPorHabitacion.putIfAbsent(habitacionKey, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inventarioPorHabitacion.keys.length,
      itemBuilder: (context, index) {
        final habitacion = inventarioPorHabitacion.keys.elementAt(index);
        final items = inventarioPorHabitacion[habitacion]!;

        return _buildHabitacionGroup(habitacion, items);
      },
    );
  }

  // Vista agrupada por categoría
  Widget _buildVistaPorCategoria(List<ItemInventario> inventario) {
    final Map<CategoriaInventario, List<ItemInventario>> inventarioPorCategoria = {};
    
    for (final item in inventario) {
      inventarioPorCategoria.putIfAbsent(item.categoria, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inventarioPorCategoria.keys.length,
      itemBuilder: (context, index) {
        final categoria = inventarioPorCategoria.keys.elementAt(index);
        final items = inventarioPorCategoria[categoria]!;

        return _buildCategoriaGroup(categoria, items);
      },
    );
  }

  // Card individual de item
  Widget _buildItemCard(ItemInventario item) {
    final colorEstado = _getColorForEstado(item.estado);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.necesitaReposicion 
              ? Colors.orange.shade300 
              : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del item
          Row(
            children: [
              // Icono de categoría
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForCategoria(item.categoria),
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.articulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (item.descripcion != null)
                      Text(
                        item.descripcion!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getEstadoDisplayName(item.estado),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Indicador de reposición
              if (item.necesitaReposicion)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              // Botón de acciones
              PopupMenuButton<String>(
                onSelected: (value) => _handleItemAction(value, item),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Información detallada
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.hotel,
                  '${item.habitacion?.numero ?? "N/A"} - ${item.habitacion?.propiedad?.nombre ?? "Sin propiedad"}',
                ),
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.category,
                _getCategoriaDisplayName(item.categoria),
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.inventory,
                '${item.cantidad} unidades',
              ),
            ],
          ),

          if (item.precioUnitario != null || item.proveedor != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.precioUnitario != null)
                  _buildInfoChip(
                    Icons.attach_money,
                    'S/ ${item.precioUnitario!.toStringAsFixed(2)}',
                  ),
                if (item.precioUnitario != null && item.proveedor != null)
                  const SizedBox(width: 8),
                if (item.proveedor != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.store,
                      item.proveedor!,
                    ),
                  ),
              ],
            ),
          ],

          if (item.observaciones != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.observaciones!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Chip informativo pequeño
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Grupo de habitación
  Widget _buildHabitacionGroup(String habitacion, List<ItemInventario> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          habitacion,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text('${items.length} artículos'),
        leading: const Icon(Icons.hotel, color: Color(0xFF4CAF50)),
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _buildItemCard(item),
        )).toList(),
      ),
    );
  }

  // Grupo de categoría
  Widget _buildCategoriaGroup(CategoriaInventario categoria, List<ItemInventario> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          _getCategoriaDisplayName(categoria),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text('${items.length} artículos'),
        leading: Icon(
          _getIconForCategoria(categoria),
          color: const Color(0xFF4CAF50),
        ),
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _buildItemCard(item),
        )).toList(),
      ),
    );
  }

  // Manejo de acciones de item
  void _handleItemAction(String action, ItemInventario item) {
    switch (action) {
      case 'editar':
        _mostrarDialogoEditarItem(item);
        break;
      case 'eliminar':
        _confirmarEliminarItem(item);
        break;
    }
  }

  // Diálogo para nuevo item
  void _mostrarDialogoNuevoItem() {
    showDialog(
      context: context,
      builder: (context) => const ItemInventarioDialog(),
    ).then((resultado) {
      if (resultado == true) {
        context.read<InventarioProvider>().cargarInventario();
      }
    });
  }

  // Diálogo para editar item
  void _mostrarDialogoEditarItem(ItemInventario item) {
    showDialog(
      context: context,
      builder: (context) => ItemInventarioDialog(item: item),
    ).then((resultado) {
      if (resultado == true) {
        context.read<InventarioProvider>().cargarInventario();
      }
    });
  }

  // Confirmar eliminación
  void _confirmarEliminarItem(ItemInventario item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${item.articulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<InventarioProvider>().eliminarItem(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artículo eliminado correctamente'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares para display names e iconos
  String _getCategoriaDisplayName(CategoriaInventario categoria) {
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

  IconData _getIconForCategoria(CategoriaInventario categoria) {
    switch (categoria) {
      case CategoriaInventario.ropa_cama:
        return Icons.bed;
      case CategoriaInventario.blancos:
        return Icons.dry_cleaning;
      case CategoriaInventario.mobiliario:
        return Icons.chair;
      case CategoriaInventario.decoracion:
        return Icons.palette;
      case CategoriaInventario.limpieza:
        return Icons.cleaning_services;
      case CategoriaInventario.amenities:
        return Icons.spa;
    }
  }

  Color _getColorForEstado(EstadoInventario estado) {
    switch (estado) {
      case EstadoInventario.nuevo:
        return const Color(0xFF4CAF50);
      case EstadoInventario.bueno:
        return const Color(0xFF8BC34A);
      case EstadoInventario.regular:
        return const Color(0xFFFF9800);
      case EstadoInventario.malo:
        return const Color(0xFFFF5722);
      case EstadoInventario.danado:
        return const Color(0xFFF44336);
    }
  }

  String _getEstadoDisplayName(EstadoInventario estado) {
    switch (estado) {
      case EstadoInventario.nuevo:
        return 'Nuevo';
      case EstadoInventario.bueno:
        return 'Bueno';
      case EstadoInventario.regular:
        return 'Regular';
      case EstadoInventario.malo:
        return 'Malo';
      case EstadoInventario.danado:
        return 'Dañado';
    }
  }
}

// Diálogo para crear/editar item de inventario
class ItemInventarioDialog extends StatefulWidget {
  final ItemInventario? item;

  const ItemInventarioDialog({super.key, this.item});

  @override
  State<ItemInventarioDialog> createState() => _ItemInventarioDialogState();
}

class _ItemInventarioDialogState extends State<ItemInventarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _articuloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _habitacionSeleccionada;
  CategoriaInventario _categoriaSeleccionada = CategoriaInventario.ropa_cama;
  EstadoInventario _estadoSeleccionado = EstadoInventario.nuevo;
  bool _necesitaReposicion = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _initializeWithItem(widget.item!);
    }
  }

  void _initializeWithItem(ItemInventario item) {
    _articuloController.text = item.articulo;
    _descripcionController.text = item.descripcion ?? '';
    _cantidadController.text = item.cantidad.toString();
    _precioController.text = item.precioUnitario?.toString() ?? '';
    _proveedorController.text = item.proveedor ?? '';
    _observacionesController.text = item.observaciones ?? '';
    _habitacionSeleccionada = item.habitacionId;
    _categoriaSeleccionada = item.categoria;
    _estadoSeleccionado = item.estado;
    _necesitaReposicion = item.necesitaReposicion;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.item == null ? Icons.add_circle : Icons.edit,
                  color: const Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.item == null ? 'Nuevo Artículo' : 'Editar Artículo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Artículo y categoría
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _articuloController,
                              decoration: const InputDecoration(
                                labelText: 'Artículo *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El artículo es requerido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<CategoriaInventario>(
                              value: _categoriaSeleccionada,
                              decoration: const InputDecoration(
                                labelText: 'Categoría *',
                                border: OutlineInputBorder(),
                              ),
                              items: CategoriaInventario.values.map((categoria) {
                                return DropdownMenuItem(
                                  value: categoria,
                                  child: Text(_getCategoriaDisplayName(categoria)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _categoriaSeleccionada = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Habitación
                      Consumer<DashboardProvider>(
                        builder: (context, dashboardProvider, child) {
                          final habitaciones = dashboardProvider.habitaciones;
                          
                          return DropdownButtonFormField<String>(
                            value: _habitacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Habitación *',
                              border: OutlineInputBorder(),
                            ),
                            items: habitaciones.map((habitacion) {
                              return DropdownMenuItem(
                                value: habitacion.id,
                                child: Text('${habitacion.numero} - ${habitacion.propiedad?.nombre ?? "Sin propiedad"}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _habitacionSeleccionada = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La habitación es requerida';
                              }
                              return null;
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Cantidad, estado y precio
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cantidadController,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La cantidad es requerida';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Cantidad inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<EstadoInventario>(
                              value: _estadoSeleccionado,
                              decoration: const InputDecoration(
                                labelText: 'Estado *',
                                border: OutlineInputBorder(),
                              ),
                              items: EstadoInventario.values.map((estado) {
                                return DropdownMenuItem(
                                  value: estado,
                                  child: Text(_getEstadoDisplayName(estado)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _estadoSeleccionado = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _precioController,
                              decoration: const InputDecoration(
                                labelText: 'Precio unitario',
                                border: OutlineInputBorder(),
                                prefixText: 'S/ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Proveedor
                      TextFormField(
                        controller: _proveedorController,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Necesita reposición
                      CheckboxListTile(
                        title: const Text('Necesita reposición'),
                        value: _necesitaReposicion,
                        onChanged: (value) {
                          setState(() {
                            _necesitaReposicion = value!;
                          });
                        },
                        activeColor: const Color(0xFF4CAF50),
                      ),

                      const SizedBox(height: 16),

                      // Observaciones
                      TextFormField(
                        controller: _observacionesController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _guardarItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.item == null ? 'Crear' : 'Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _guardarItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final itemData = {
        'habitacion_id': _habitacionSeleccionada,
        'categoria': _categoriaSeleccionada.name,
        'articulo': _articuloController.text,
        'descripcion': _descripcionController.text.isEmpty ? null : _descripcionController.text,
        'cantidad': int.parse(_cantidadController.text),
        'estado': _estadoSeleccionado.name,
        'necesita_reposicion': _necesitaReposicion,
        'precio_unitario': _precioController.text.isEmpty ? null : double.parse(_precioController.text),
        'proveedor': _proveedorController.text.isEmpty ? null : _proveedorController.text,
        'observaciones': _observacionesController.text.isEmpty ? null : _observacionesController.text,
        'fecha_ultima_revision': DateTime.now().toIso8601String(),
        if (widget.item == null) 'fecha_registro': DateTime.now().toIso8601String(),
      };

      if (widget.item == null) {
        await context.read<InventarioProvider>().crearItem(itemData);
      } else {
        await context.read<InventarioProvider>().actualizarItem(widget.item!.id, itemData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null ? 'Artículo creado correctamente' : 'Artículo actualizado correctamente'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getCategoriaDisplayName(CategoriaInventario categoria) {
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

  String _getEstadoDisplayName(EstadoInventario estado) {
    switch (estado) {
      case EstadoInventario.nuevo:
        return 'Nuevo';
      case EstadoInventario.bueno:
        return 'Bueno';
      case EstadoInventario.regular:
        return 'Regular';
      case EstadoInventario.malo:
        return 'Malo';
      case EstadoInventario.danado:
        return 'Dañado';
    }
  }

  @override
  void dispose() {
    _articuloController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _proveedorController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}
