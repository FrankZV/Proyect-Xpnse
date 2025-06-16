// lib/screens/home_screen.dart
// --- VERSIÓN FINAL ---

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart'; // Importa modelo de categoría
import 'add_edit_expense_screen.dart';
import 'category_list_screen.dart'; // Importa pantalla de lista de categorías

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado para la lista de gastos y total
  late Future<List<Expense>> _expenseListFuture;
  double _totalExpenses = 0.0;

  // Helpers y formateadores
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_SV', symbol: '\$');
  final DateFormat _dateFormat = DateFormat.yMd('es_SV');

  // Estado para los Filtros
  String _selectedFilterType = 'Todos'; // Tipo de filtro actual
  DateTime? _selectedFilterDate; // Fecha para filtros de Año, Mes, Día
  int? _selectedFilterCategoryId; // ID para filtro de Categoría
  late Future<List<Category>>
      _categoriesFuture; // Future para cargar categorías del filtro

  @override
  void initState() {
    super.initState();
    // Carga inicial de categorías para el dropdown de filtro
    _categoriesFuture = _dbHelper.getCategories();
    // Carga inicial de gastos (sin filtros aplicados)
    _refreshExpenseList();
  }

  // Recarga la lista de gastos y el total aplicando los filtros actuales
  void _refreshExpenseList() {
    DateTime? startDate;
    DateTime? endDate;
    int? categoryId = _selectedFilterCategoryId;

    // Calcula las fechas de inicio/fin según el tipo de filtro y la fecha seleccionada
    if (_selectedFilterDate != null) {
      switch (_selectedFilterType) {
        case 'Año':
          startDate = DateTime(_selectedFilterDate!.year, 1, 1);
          endDate =
              DateTime(_selectedFilterDate!.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'Mes':
          startDate = DateTime(
              _selectedFilterDate!.year, _selectedFilterDate!.month, 1);
          endDate = DateTime(
              _selectedFilterDate!.year,
              _selectedFilterDate!.month + 1,
              0,
              23,
              59,
              59,
              999); // Día 0 del mes siguiente = último día del mes actual
          break;
        case 'Día':
          startDate = DateTime(_selectedFilterDate!.year,
              _selectedFilterDate!.month, _selectedFilterDate!.day);
          endDate = DateTime(
              _selectedFilterDate!.year,
              _selectedFilterDate!.month,
              _selectedFilterDate!.day,
              23,
              59,
              59,
              999);
          break;
      }
    }

    // Si el filtro NO es por categoría, nos aseguramos de que el ID de categoría sea null
    if (_selectedFilterType != 'Categoría') {
      categoryId = null;
    }

    // Actualiza el estado para que FutureBuilder recargue
    setState(() {
      _expenseListFuture = _dbHelper.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryIdFilter: categoryId,
      );
      // Recalcula el total con los mismos filtros
      _calculateTotal(
        startDate: startDate,
        endDate: endDate,
        categoryIdFilter: categoryId,
      );
    });
  }

  // Calcula el total basado en los filtros proporcionados
  void _calculateTotal(
      {DateTime? startDate, DateTime? endDate, int? categoryIdFilter}) async {
    try {
      double total = await _dbHelper.getTotalExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryIdFilter: categoryIdFilter,
      );
      if (mounted) {
        // Verifica si el widget sigue en el árbol
        setState(() {
          _totalExpenses = total;
        });
      }
    } catch (e) {
      print("Error calculating total: $e");
      if (mounted) {
        setState(() {
          _totalExpenses = 0.0;
        }); // Poner a 0 si hay error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al calcular total: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // Navega a la pantalla de añadir/editar gasto
  void _navigateToAddEditScreen({Expense? expense}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddEditExpenseScreen(expense: expense)),
    );
    // Si se guardó/editó algo (result == true), refresca la lista
    if (result == true && mounted) {
      _refreshExpenseList();
    }
  }

  // Navega a la pantalla de gestión de categorías
  void _navigateToCategoryList() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryListScreen()),
    );
    // Si algo cambió en categorías, recarga las categorías para el filtro
    // y refresca la lista de gastos (por si se eliminó una categoría usada, etc.)
    if (result == true && mounted) {
      setState(() {
        _categoriesFuture = _dbHelper.getCategories();
      });
      _refreshExpenseList();
    }
  }

  // Muestra diálogo de confirmación para eliminar gasto
  void _confirmDeleteExpense(int expenseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content:
              const Text('¿Estás seguro de que deseas eliminar este gasto?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
                  await _dbHelper.deleteExpense(expenseId);
                  Navigator.of(context).pop(); // Cierra diálogo
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Gasto eliminado'),
                          backgroundColor: Colors.green),
                    );
                    _refreshExpenseList(); // Refresca la lista
                  }
                } catch (e) {
                  Navigator.of(context).pop(); // Cierra diálogo
                  print("Error al eliminar gasto: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error al eliminar: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Construcción de la Interfaz ---

  // Construye los controles de filtro (Dropdowns, DatePicker)
  Widget _buildFilterControls() {
    return Container(
      color: Colors.grey[100], // Fondo ligero para destacar los controles
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Espaciado
            children: <Widget>[
              // Dropdown para tipo de filtro
              Expanded(
                // Permite que el dropdown ocupe espacio flexible
                flex: 2, // Más espacio para el tipo
                child: DropdownButton<String>(
                  value: _selectedFilterType,
                  isExpanded: true, // Ocupa el ancho disponible
                  underline: Container(
                      height: 1, color: Colors.grey), // Línea sutil debajo
                  items: <String>['Todos', 'Año', 'Mes', 'Día', 'Categoría']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilterType = newValue;
                        // Resetea valores no aplicables al nuevo filtro
                        if (newValue == 'Todos' || newValue == 'Categoría')
                          _selectedFilterDate = null;
                        if (newValue != 'Categoría')
                          _selectedFilterCategoryId = null;
                        // Poner fecha por defecto si se elige filtro de fecha y no hay una
                        if ((newValue == 'Año' ||
                                newValue == 'Mes' ||
                                newValue == 'Día') &&
                            _selectedFilterDate == null) {
                          _selectedFilterDate = DateTime.now();
                        }
                      });
                      _refreshExpenseList(); // Aplica el nuevo filtro
                    }
                  },
                ),
              ),
              const SizedBox(width: 8), // Espacio

              // Controles específicos del filtro (Fecha o Categoría)
              Expanded(
                // Ocupa el resto del espacio
                flex: 3, // Más espacio para fecha/categoría
                child: _buildSpecificFilterControl(),
              ),
            ],
          ),
          // Muestra descripción del filtro activo
          if (_selectedFilterType != 'Todos')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _buildFilterDescription(), // Texto descriptivo del filtro
                style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Widget para el control específico (DatePicker o Dropdown de Categoría)
  Widget _buildSpecificFilterControl() {
    // Si el filtro es por fecha
    if (_selectedFilterType == 'Año' ||
        _selectedFilterType == 'Mes' ||
        _selectedFilterType == 'Día') {
      return TextButton.icon(
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(
          _selectedFilterDate != null
              ? (_selectedFilterType == 'Año'
                  ? DateFormat.y('es_SV')
                      .format(_selectedFilterDate!) // Solo año
                  : _selectedFilterType == 'Mes'
                      ? DateFormat.yMMM('es_SV')
                          .format(_selectedFilterDate!) // Año y Mes
                      : _dateFormat
                          .format(_selectedFilterDate!)) // Fecha completa
              : 'Seleccionar',
          style: TextStyle(color: Theme.of(context).primaryColor),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () async {
          final DatePickerMode initialMode = _selectedFilterType == 'Año'
              ? DatePickerMode.year
              : DatePickerMode.day;
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedFilterDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            locale: const Locale('es', 'SV'),
            initialDatePickerMode: initialMode,
          );
          if (picked != null) {
            setState(() {
              _selectedFilterDate = picked;
            });
            _refreshExpenseList(); // Aplica filtro con nueva fecha
          }
        },
      );
    }
    // Si el filtro es por categoría
    else if (_selectedFilterType == 'Categoría') {
      return FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)));
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Text('No hay cat.',
                style: TextStyle(color: Colors.grey));
          }
          final categories = snapshot.data!;
          // Asegura que el ID seleccionado existe
          if (_selectedFilterCategoryId != null &&
              !categories.any((c) => c.id == _selectedFilterCategoryId)) {
            _selectedFilterCategoryId = null; // Resetea si no existe
          }
          return DropdownButton<int>(
            value: _selectedFilterCategoryId,
            hint: const Text('Categoría'),
            isExpanded: true, // Ocupa el ancho
            underline: Container(height: 0), // Sin línea debajo
            items: categories.map((Category category) {
              return DropdownMenuItem<int>(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedFilterCategoryId = newValue;
              });
              _refreshExpenseList(); // Aplica filtro
            },
          );
        },
      );
    }
    // Si el filtro es 'Todos', no muestra nada extra
    else {
      return const SizedBox.shrink(); // Widget vacío
    }
  }

  // Genera el texto descriptivo del filtro aplicado
  String _buildFilterDescription() {
    switch (_selectedFilterType) {
      case 'Año':
        return 'Año: ${_selectedFilterDate != null ? DateFormat.y('es_SV').format(_selectedFilterDate!) : '...'}';
      case 'Mes':
        return 'Mes: ${_selectedFilterDate != null ? DateFormat.yMMM('es_SV').format(_selectedFilterDate!) : '...'}';
      case 'Día':
        return 'Día: ${_selectedFilterDate != null ? _dateFormat.format(_selectedFilterDate!) : '...'}';
      case 'Categoría':
        if (_selectedFilterCategoryId != null) {
          // Intenta encontrar el nombre de la categoría seleccionada (requiere que _categoriesFuture esté resuelto)
          // Esto es un poco ineficiente aquí, sería mejor tener la lista disponible.
          // Por simplicidad, mostramos un texto genérico o buscamos en el snapshot si está disponible.
          return 'Categoría seleccionada'; // Simplificado
        } else {
          return 'Filtrando por categoría (ninguna seleccionada)';
        }
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos Personales'),
        actions: [
          // Botón para gestionar categorías
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Gestionar Categorías',
            onPressed: _navigateToCategoryList,
          ),
        ],
        // Muestra el total filtrado en la parte inferior del AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Total Filtrado: ${_currencyFormat.format(_totalExpenses)}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ),
      body: Column(
        // Columna principal: Filtros arriba, Lista abajo
        children: [
          // Sección de controles de filtro
          _buildFilterControls(),
          const Divider(height: 1, thickness: 1), // Separador

          // Lista de gastos (ocupa el espacio restante)
          Expanded(
            child: RefreshIndicator(
              // Permite refrescar deslizando hacia abajo
              onRefresh: () async {
                _refreshExpenseList();
              },
              child: FutureBuilder<List<Expense>>(
                future:
                    _expenseListFuture, // El future que carga los gastos filtrados
                builder: (context, snapshot) {
                  // Muestra indicador de carga
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Muestra error si falla la carga
                  else if (snapshot.hasError) {
                    print(
                        'Error en FutureBuilder HomeScreen: ${snapshot.error}');
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error al cargar gastos:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ));
                  }
                  // Muestra mensaje si no hay datos que coincidan con el filtro
                  else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No hay gastos que coincidan con el filtro actual.\n\nIntenta cambiar el filtro o presiona "+" para añadir un gasto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  // Muestra la lista de gastos si todo está bien
                  else {
                    final expenses = snapshot.data!;
                    return ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        // Construye la tarjeta para cada gasto
                        return Card(
                          elevation: 2.0,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 5.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 10.0),
                            leading: CircleAvatar(
                              // Muestra la inicial de la categoría (obtenida del JOIN)
                              child: Text(
                                  expense.category?.name.isNotEmpty ?? false
                                      ? expense.category!.name[0].toUpperCase()
                                      : '?'),
                              backgroundColor: Theme.of(context)
                                  .primaryColorLight
                                  .withOpacity(0.8),
                              foregroundColor: Colors.white,
                            ),
                            title: Text(expense.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(
                              // Muestra nombre de categoría y fecha
                              '${expense.category?.name ?? 'Sin categoría'} - ${_dateFormat.format(expense.date)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Row(
                              // Iconos de acciones a la derecha
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Muestra el monto formateado
                                Text(
                                  _currencyFormat.format(expense.amount),
                                  style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                // Botón Editar
                                IconButton(
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.blueGrey, size: 22),
                                  onPressed: () => _navigateToAddEditScreen(
                                      expense: expense),
                                  tooltip: 'Editar Gasto',
                                  splashRadius: 20,
                                  visualDensity:
                                      VisualDensity.compact, // Más compacto
                                ),
                                // Botón Eliminar
                                IconButton(
                                  icon: Icon(Icons.delete_forever_outlined,
                                      color: Colors.red[400], size: 22),
                                  onPressed: () =>
                                      _confirmDeleteExpense(expense.id!),
                                  tooltip: 'Eliminar Gasto',
                                  splashRadius: 20,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            onTap: () => _navigateToAddEditScreen(
                                expense: expense), // Editar al tocar la fila
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      // Botón flotante para añadir nuevo gasto
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditScreen(),
        tooltip: 'Añadir Nuevo Gasto',
        icon: const Icon(Icons.add),
        label: const Text("Añadir"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 6.0,
      ),
    );
  }
}
