// lib/screens/category_list_screen.dart
// --- VERSIÓN FINAL ---

import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/category_model.dart';
import 'add_edit_category_screen.dart'; // Pantalla para añadir/editar categoría

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Category>>
      _categoryListFuture; // Future para cargar categorías
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Helper de DB

  @override
  void initState() {
    super.initState();
    _refreshCategoryList(); // Carga inicial
  }

  // Recarga la lista de categorías desde la base de datos
  void _refreshCategoryList() {
    setState(() {
      _categoryListFuture = _dbHelper.getCategories();
    });
  }

  // Navega a la pantalla para añadir o editar una categoría
  void _navigateToAddEditCategory({Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );
    // Si se guardó/editó algo (result == true), refresca la lista
    if (result == true && mounted) {
      _refreshCategoryList();
    }
  }

  // Muestra diálogo de confirmación para eliminar categoría
  void _confirmDeleteCategory(Category category) {
    // Verifica primero si la categoría está en uso (más eficiente que esperar error de DB)
    _dbHelper.isCategoryInUse(category.id!).then((isInUse) {
      if (isInUse) {
        // Muestra mensaje si está en uso y no continúa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error: No se puede eliminar. La categoría está asignada a uno o más gastos.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4), // Más tiempo para leer
          ),
        );
        return;
      }

      // Si no está en uso, muestra el diálogo de confirmación
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
                '¿Estás seguro de que deseas eliminar la categoría "${category.name}"?'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
                onPressed: () async {
                  try {
                    await _dbHelper.deleteCategory(category.id!);
                    Navigator.of(context).pop(); // Cierra diálogo
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Categoría "${category.name}" eliminada'),
                            backgroundColor: Colors.green),
                      );
                      _refreshCategoryList(); // Refresca la lista
                    }
                  } catch (e) {
                    Navigator.of(context).pop(); // Cierra diálogo
                    print("Error deleting category: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          // Muestra mensaje de error (puede ser el de 'categoría en uso' si la verificación falló)
                          content: Text(
                              'Error al eliminar: ${e.toString().replaceFirst("Exception: ", "")}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      );
    }).catchError((error) {
      // Maneja error de la verificación isCategoryInUse
      print("Error checking if category is in use: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al verificar uso de categoría: $error'),
              backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoryListFuture, // Carga las categorías
        builder: (context, snapshot) {
          // Muestra indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Muestra error si falla
          else if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar categorías: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          // Muestra mensaje si no hay categorías
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No hay categorías definidas.\n\nPresiona "+" para añadir la primera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Colors.grey),
                ),
              ),
            );
          }
          // Muestra la lista de categorías
          else {
            final categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                // Tarjeta para cada categoría
                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      // Icono simple con la inicial
                      child: Text(category.name.isNotEmpty
                          ? category.name[0].toUpperCase()
                          : '?'),
                      backgroundColor:
                          Theme.of(context).primaryColorLight.withOpacity(0.8),
                      foregroundColor: Colors.white,
                    ),
                    title: Text(category.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Row(
                      // Botones de acción
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blueGrey, size: 22),
                          tooltip: 'Editar Categoría',
                          splashRadius: 20,
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _navigateToAddEditCategory(category: category),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red[400], size: 22),
                          tooltip: 'Eliminar Categoría',
                          splashRadius: 20,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _confirmDeleteCategory(category),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToAddEditCategory(
                        category: category), // Editar al tocar
                  ),
                );
              },
            );
          }
        },
      ),
      // Botón flotante para añadir nueva categoría
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditCategory(),
        tooltip: 'Añadir Nueva Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }
}
