// lib/screens/add_edit_category_screen.dart
// --- VERSIÓN FINAL ---

import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/category_model.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category; // Categoría a editar (null si es nueva)

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Helper de DB
  late TextEditingController _nameController; // Controlador para el nombre
  bool _isEditing = false; // Indica si estamos editando

  @override
  void initState() {
    super.initState();
    _isEditing = widget.category != null;
    // Inicializa el controlador con el nombre existente si editamos
    _nameController =
        TextEditingController(text: _isEditing ? widget.category!.name : '');
  }

  @override
  void dispose() {
    _nameController.dispose(); // Libera el controlador
    super.dispose();
  }

  // Guarda o actualiza la categoría
  void _saveCategory() async {
    // Valida el formulario
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim(); // Obtiene y limpia el nombre

      // Validación extra por si acaso (aunque el validator ya lo hace)
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El nombre de la categoría no puede estar vacío.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      // Crea el objeto Category
      final category = Category(
        id: _isEditing ? widget.category!.id : null, // Mantiene ID si edita
        name: name,
      );

      // Intenta guardar/actualizar en la DB
      try {
        int result;
        if (_isEditing) {
          result = await _dbHelper.updateCategory(category);
        } else {
          result = await _dbHelper.insertCategory(category);
        }

        // Maneja el resultado (éxito o error por duplicado)
        if (mounted) {
          if (result == -1) {
            // Código de error por nombre duplicado
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Error: Ya existe una categoría con el nombre "$name".'),
                  backgroundColor: Colors.orange),
            );
          } else if (result == 0 && !_isEditing) {
            // Ignorado por duplicado en insert
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('La categoría "$name" ya existe.'),
                  backgroundColor: Colors.orange),
            );
          } else {
            // Éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(_isEditing
                      ? 'Categoría actualizada'
                      : 'Categoría guardada'),
                  backgroundColor: Colors.green),
            );
            Navigator.of(context).pop(true); // Vuelve indicando éxito
          }
        }
      } catch (e) {
        // Otros errores
        print("Error saving category: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al guardar la categoría: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Categoría' : 'Añadir Categoría'),
        actions: [
          // Botón Guardar en AppBar
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Guardar Categoría',
            onPressed: _saveCategory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar botón
            children: <Widget>[
              // Campo de texto para el nombre
              TextFormField(
                controller: _nameController,
                autofocus: true, // Foco automático al abrir
                decoration: InputDecoration(
                  labelText: 'Nombre de la Categoría',
                  hintText: 'Ej: Educación',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                textCapitalization:
                    TextCapitalization.sentences, // Primera letra mayúscula
                // Valida que no esté vacío
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce un nombre para la categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Botón principal para guardar
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(
                    _isEditing ? 'Actualizar Categoría' : 'Guardar Categoría'),
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
