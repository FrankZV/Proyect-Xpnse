// lib/screens/add_edit_expense_screen.dart
// --- VERSIÓN FINAL ---

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart'; // Importa el modelo de categoría

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense; // Gasto a editar (null si es nuevo)

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Controladores para los campos
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  bool _isEditing = false;

  // Variables para el Dropdown de Categorías
  int? _selectedCategoryId; // ID de la categoría seleccionada
  late Future<List<Category>>
      _categoriesFuture; // Future para cargar categorías

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expense != null;

    // Carga las categorías de la base de datos para el dropdown
    _categoriesFuture = _dbHelper.getCategories();

    // Inicializa los controladores y estado
    _descriptionController = TextEditingController(
        text: _isEditing ? widget.expense!.description : '');
    _amountController = TextEditingController(
        text: _isEditing ? widget.expense!.amount.toStringAsFixed(2) : '');
    _selectedDate = _isEditing ? widget.expense!.date : DateTime.now();
    _selectedCategoryId = _isEditing
        ? widget.expense!.categoryId
        : null; // ID inicial si se edita
  }

  @override
  void dispose() {
    // Libera los controladores
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Muestra el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Límite inferior
      lastDate: DateTime.now()
          .add(const Duration(days: 365)), // Límite superior (ej. 1 año)
      locale: const Locale('es', 'SV'), // Idioma español
      helpText: 'Seleccionar Fecha del Gasto',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Actualiza la fecha seleccionada
      });
    }
  }

  // Guarda o actualiza el gasto
  void _saveExpense() async {
    // Valida el formulario
    if (_formKey.currentState!.validate()) {
      // Validaciones adicionales
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, selecciona una categoría.'),
              backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      final description = _descriptionController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.'));

      if (description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La descripción no puede estar vacía.'),
              backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Por favor, introduce un monto válido y mayor que cero.'),
              backgroundColor: Colors.orangeAccent),
        );
        return;
      }

      // Crea el objeto Expense
      final expense = Expense(
        id: _isEditing ? widget.expense!.id : null,
        description: description,
        categoryId: _selectedCategoryId!, // Usa el ID seleccionado
        amount: amount,
        date: _selectedDate,
      );

      // Intenta guardar/actualizar en la base de datos
      try {
        if (_isEditing) {
          await _dbHelper.updateExpense(expense);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Gasto actualizado con éxito'),
                  backgroundColor: Colors.green),
            );
          }
        } else {
          await _dbHelper.insertExpense(expense);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Gasto guardado con éxito'),
                  backgroundColor: Colors.green),
            );
          }
        }
        // Vuelve a la pantalla anterior indicando que hubo cambios
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        print('Error al guardar gasto: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al guardar el gasto: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // Si la validación del formulario falla
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, corrige los errores en el formulario.'),
            backgroundColor: Colors.orangeAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Gasto' : 'Añadir Nuevo Gasto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _saveExpense,
            tooltip: 'Guardar Gasto',
          )
        ],
      ),
      body: SingleChildScrollView(
        // Permite scroll si el contenido excede la pantalla
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Estira los widgets hijos
              children: <Widget>[
                // Campo Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Almuerzo de trabajo',
                    prefixIcon: Icon(Icons.description_outlined,
                        color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción no puede estar vacía';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Categoría (Dropdown)
                FutureBuilder<List<Category>>(
                  future: _categoriesFuture, // Carga las categorías
                  builder: (context, snapshot) {
                    // Muestra indicador de carga
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    // Muestra error si falla la carga
                    else if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                            'Error al cargar categorías: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)),
                      );
                    }
                    // Muestra mensaje si no hay categorías
                    else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                            'No hay categorías disponibles. Añade alguna desde la gestión de categorías.',
                            style: TextStyle(color: Colors.orange)),
                      );
                    }
                    // Muestra el Dropdown si todo está bien
                    else {
                      final categories = snapshot.data!;
                      // Verifica si el ID seleccionado al editar aún existe
                      if (_selectedCategoryId != null &&
                          !categories
                              .any((cat) => cat.id == _selectedCategoryId)) {
                        print(
                            "Warning: Initial category ID $_selectedCategoryId not found in current categories. Resetting selection.");
                        // Resetea la selección si la categoría ya no existe
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                          }
                        });
                      }

                      return DropdownButtonFormField<int>(
                        value: _selectedCategoryId, // ID seleccionado
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(Icons.category_outlined,
                              color: Theme.of(context).primaryColor),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        hint: const Text('Selecciona una categoría'),
                        items: categories.map((Category category) {
                          return DropdownMenuItem<int>(
                            value: category.id, // Valor es el ID
                            child: Text(category.name), // Texto es el nombre
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategoryId =
                                newValue; // Actualiza el ID seleccionado
                          });
                        },
                        // Valida que se haya seleccionado una categoría
                        validator: (value) => value == null
                            ? 'Por favor, selecciona una categoría'
                            : null,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Campo Monto
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money_outlined,
                        color: Theme.of(context).primaryColor),
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce un monto';
                    }
                    final amount = double.tryParse(value.replaceAll(',', '.'));
                    if (amount == null) {
                      return 'Introduce un número válido';
                    }
                    if (amount <= 0) {
                      return 'El monto debe ser positivo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Selector de Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fecha: ${DateFormat.yMMMEd('es_SV').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Cambiar Fecha'),
                      onPressed: () => _selectDate(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Botón principal para guardar
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt, size: 20),
                  label: Text(_isEditing ? 'Actualizar Gasto' : 'Guardar Gasto',
                      style: const TextStyle(fontSize: 18)),
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
