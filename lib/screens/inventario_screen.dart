import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String? _habitacionSeleccionada;
  CategoriaInventario? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarInventario();
      context.read<DashboardProvider>().cargarDashboard();
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
                          'Control de Inventario',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          'Gestión de suministros por habitación',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoNuevoItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Item'),
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
                
                // Filtros
                Row(
                  children: [
                    // Filtro por habitación
                    Expanded(
                      child: Consumer<DashboardProvider>(
                        builder: (context, dashboardProvider, child) {
                          return DropdownButtonFormField<String>(
                            value: _habitacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por habitación',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.hotel),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todas las habitaciones'),
                              ),
                              ...dashboardProvider.habitaciones.map((habitacion) {
                                return DropdownMenuItem<String>(
                                  value: habitacion.id,
                                  child: Text(
                                    '${habitacion.numero} - ${habitacion.propiedad?.nombre ?? ''}',
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _habitacionSeleccionada = value;
                              });
                              context.read<InventarioProvider>()
                                  .filtrarPorHabitacion(value);
                            },
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Filtro por categoría
                    Expanded(
                      child: DropdownButtonFormField<CategoriaInventario>(
                        value: _categoriaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por categoría',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: [
                          const DropdownMenuItem<CategoriaInventario>(
                            value: null,
                            child: Text('Todas las categorías'),
                          ),
                          ...CategoriaInventario.values.map((categoria) {
                            return DropdownMenuItem<CategoriaInventario>(
                              value: categoria,
                              child: Text(_getCategoriaDisplayName(categoria)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _categoriaSeleccionada = value;
                          });
                          context.read<InventarioProvider>()
                              .filtrarPorCategoria(value);
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Botón para items que necesitan reposición
                    Consumer<InventarioProvider>(
                      builder: (context, provider, child) {
                        final itemsReposicion = provider.itemsQueNecesitanReposicion();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: itemsReposicion.isNotEmpty 
                                ? Colors.orange.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: itemsReposicion.isNotEmpty 
                                  ? Colors.orange.shade300
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: itemsReposicion.isNotEmpty 
                                    ? Colors.orange.shade600
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reposición: ${itemsReposicion.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: itemsReposicion.isNotEmpty 
                                      ? Colors.orange.shade600
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.inventario.isEmpty) {
                  return const LoadingWidget(message: 'Cargando inventario...');
                }

                if (provider.error != null) {
                  return ErrorDisplayWidget(
                    message: provider.error!,
                    onRetry: () => provider.cargarInventario(),
                  );
                }

                if (provider.inventarioFiltrado.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No hay items de inventario',
                    subtitle: provider.inventario.isEmpty 
                        ? 'Agrega el primer item para comenzar'
                        : 'No se encontraron items con los filtros aplicados',
                    action: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoNuevoItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                }

                return _buildInventarioList(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventarioList(InventarioProvider provider) {
    // Agrupar por categoría
    final Map<CategoriaInventario, List<ItemInventario>> itemsPorCategoria = {};
    for (var item in provider.inventarioFiltrado) {
      if (!itemsPorCategoria.containsKey(item.categoria)) {
        itemsPorCategoria[item.categoria] = [];
      }
      itemsPorCategoria[item.categoria]!.add(item);
    }

    return Container(
      margin: const EdgeInsets.all(24),
      child: ListView.builder(
        itemCount: itemsPorCategoria.keys.length,
        itemBuilder: (context, index) {
          final categoria = itemsPorCategoria.keys.elementAt(index);
          final items = itemsPorCategoria[categoria]!;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de categoría
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getCategoriaColor(categoria).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCategoriaColor(categoria).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoriaIcon(categoria),
                          color: _getCategoriaColor(categoria),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _getCategoriaDisplayName(categoria),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getCategoriaColor(categoria),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoriaColor(categoria),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${items.length} items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de items
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, itemIndex) {
                    final item = items[itemIndex];
                    return _buildItemRow(item);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemRow(ItemInventario item) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Información del item
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.articulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (item.descripcion != null && item.descripcion!.isNotEmpty)
                  Text(
                    item.descripcion!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          // Habitación
          Expanded(
            flex: 2,
            child: Text(
              item.habitacion?.numeroCompleto ?? 'Sin asignar',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Cantidad
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.cantidad.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Estado
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getEstadoColor(item.estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.estadoDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getEstadoColor(item.estado),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Indicador de reposición
          if (item.necesitaReposicion)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.warning,
                color: Colors.orange.shade600,
                size: 16,
              ),
            ),
          
          const SizedBox(width: 16),
          
          // Acciones
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
              PopupMenuItem(
                value: 'reposicion',
                child: Row(
                  children: [
                    Icon(
                      item.necesitaReposicion ? Icons.check : Icons.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(item.necesitaReposicion 
                        ? 'Marcar como repuesto' 
                        : 'Marcar para reposición'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'editar':
                  _mostrarDialogoEditarItem(item);
                  break;
                case 'reposicion':
                  _toggleReposicion(item);
                  break;
                case 'eliminar':
                  _confirmarEliminar(item);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  String _getCategoriaDisplayName(CategoriaInventario categoria) {
    switch (categoria) {
      case CategoriaInventario.ropa_cama:
        return 'Ropa de Cama';
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

  IconData _getCategoriaIcon(CategoriaInventario categoria) {
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

  Color _getCategoriaColor(CategoriaInventario categoria) {
    switch (categoria) {
      case CategoriaInventario.ropa_cama:
        return const Color(0xFF2196F3);
      case CategoriaInventario.blancos:
        return const Color(0xFF9C27B0);
      case CategoriaInventario.mobiliario:
        return const Color(0xFF795548);
      case CategoriaInventario.decoracion:
        return const Color(0xFFE91E63);
      case CategoriaInventario.limpieza:
        return const Color(0xFF4CAF50);
      case CategoriaInventario.amenities:
        return const Color(0xFFFF9800);
    }
  }

  Color _getEstadoColor(EstadoInventario estado) {
    switch (estado) {
      case EstadoInventario.nuevo:
        return const Color(0xFF4CAF50);
      case EstadoInventario.bueno:
        return const Color(0xFF2196F3);
      case EstadoInventario.regular:
        return const Color(0xFFFF9800);
      case EstadoInventario.malo:
        return const Color(0xFFF44336);
      case EstadoInventario.dañado:
        return const Color(0xFF9E9E9E);
    }
  }

  void _mostrarDialogoNuevoItem() {
    showDialog(
      context: context,
      builder: (context) => const DialogoNuevoItem(),
    );
  }

  void _mostrarDialogoEditarItem(ItemInventario item) {
    showDialog(
      context: context,
      builder: (context) => DialogoEditarItem(item: item),
    );
  }

  void _toggleReposicion(ItemInventario item) {
    context.read<InventarioProvider>().actualizarItem(
      item.id,
      {'necesita_reposicion': !item.necesitaReposicion},
    );
  }

  void _confirmarEliminar(ItemInventario item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${item.articulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar eliminación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de eliminar pendiente de implementar'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// Diálogo para nuevo item (implementación básica)
class DialogoNuevoItem extends StatelessWidget {
  const DialogoNuevoItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nuevo Item de Inventario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Función pendiente de implementar'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para editar item (implementación básica)
class DialogoEditarItem extends StatelessWidget {
  final ItemInventario item;
  
  const DialogoEditarItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Editar: ${item.articulo}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Función pendiente de implementar'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}