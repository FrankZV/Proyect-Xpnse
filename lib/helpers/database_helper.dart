// lib/helpers/database_helper.dart
// --- VERSIÓN LIMPIA (Desde Cero) ---

import 'package:sqflite/sqflite.dart'; // Importa el paquete sqflite
import 'package:path/path.dart'; // Necesario para unir paths (join)
import 'package:path_provider/path_provider.dart'; // Para obtener el directorio de documentos
import '../models/expense_model.dart'; // Importa el modelo de datos de gasto
import '../models/category_model.dart'; // Importa el modelo de categoría
import 'dart:io'; // Necesario para usar Directory

// Clase Singleton para manejar la base de datos
class DatabaseHelper {
  // Instancia única privada
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  // Constructor factory que devuelve la instancia única
  factory DatabaseHelper() => _instance;
  // Constructor privado interno
  DatabaseHelper._internal();

  // Variable estática para la base de datos (puede ser null inicialmente)
  static Database? _database;
  // --- Versión inicial de la base de datos ---
  static const int _dbVersion = 1;
  // Nombre de la base de datos
  final String _dbName = 'expenses_app_v$_dbVersion.db';
  // Nombres de las tablas
  final String _expensesTable = 'expenses';
  final String _categoriesTable = 'categories';

  // Lista inicial de categorías que se insertarán al crear la base de datos
  final List<Category> _initialCategories = [
    Category(name: 'Alimentación'),
    Category(name: 'Transporte'),
    Category(name: 'Vivienda'),
    Category(name: 'Ocio'),
    Category(name: 'Salud'),
    Category(name: 'Ropa'),
    Category(name: 'Facturas'),
    Category(name: 'Otros'),
  ];

  // Getter asíncrono para obtener la instancia de la base de datos
  Future<Database> get database async {
    // Si la base de datos ya está inicializada, la devuelve
    if (_database != null) return _database!;
    // Si no, la inicializa
    _database = await _initDatabase();
    return _database!;
  }

  // Método privado para inicializar la base de datos
  Future<Database> _initDatabase() async {
    // Obtiene el directorio de documentos de la aplicación
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // Crea la ruta completa al archivo de la base de datos
    String path = join(documentsDirectory.path, _dbName);
    print("Database path: $path"); // Útil para depuración
    // Abre la base de datos.
    return await openDatabase(
      path,
      version: _dbVersion, // Especifica la versión actual de la DB
      onCreate: _onCreate, // Se ejecuta si la DB no existe
      // No necesitamos onUpgrade si partimos de cero con la versión 1
    );
  }

  // Método que se ejecuta cuando la base de datos se crea por primera vez (onCreate)
  Future<void> _onCreate(Database db, int version) async {
    print("Creating database version $version...");
    // Usamos un batch para ejecutar múltiples operaciones atómicamente
    Batch batch = db.batch();

    // 1. Crear tabla de categorías
    batch.execute('''
      CREATE TABLE $_categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE -- Nombre de categoría debe ser único
      )
    ''');
    print("Batch: Categories table creation added.");

    // 2. Insertar categorías iniciales
    for (var category in _initialCategories) {
      // Creamos el mapa y quitamos el ID nulo para que funcione el autoincremento
      batch.insert(_categoriesTable, category.toMap()..remove('id'));
    }
    print("Batch: Initial categories insertion added.");

    // 3. Crear tabla de gastos con clave foránea a categorías
    batch.execute('''
      CREATE TABLE $_expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL, -- Guardamos como ISO8601 String
        categoryId INTEGER NOT NULL, -- Columna para el ID de categoría
        FOREIGN KEY (categoryId) REFERENCES $_categoriesTable(id) -- Restricción de clave foránea
          ON DELETE RESTRICT -- Impide eliminar categoría si tiene gastos asociados
      )
    ''');
    print("Batch: Expenses table creation added.");

    // 4. Crear índices para mejorar rendimiento (opcional pero recomendado)
    batch.execute('CREATE INDEX idx_expense_date ON $_expensesTable(date)');
    batch.execute(
        'CREATE INDEX idx_expense_category ON $_expensesTable(categoryId)');
    print("Batch: Indexes creation added.");

    // Ejecutar todas las operaciones del batch
    await batch.commit(
        noResult:
            true); // noResult: true es más eficiente si no necesitas los resultados
    print("Database onCreate batch committed successfully.");
  }

  // --- Métodos CRUD para Categorías ---

  // Insertar una nueva categoría
  Future<int> insertCategory(Category category) async {
    final db = await database;
    Map<String, dynamic> catMap = category.toMap()..remove('id');
    try {
      return await db.insert(_categoriesTable, catMap,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      print("Error inserting category '${category.name}': $e");
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        return -1; // Indicar duplicado
      }
      rethrow;
    }
  }

  // Obtener todas las categorías ordenadas por nombre
  Future<List<Category>> getCategories() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps =
          await db.query(_categoriesTable, orderBy: 'name ASC');
      return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
    } catch (e) {
      print("Error getting categories: $e");
      return [];
    }
  }

  // Actualizar una categoría existente
  Future<int> updateCategory(Category category) async {
    final db = await database;
    try {
      return await db.update(
        _categoriesTable,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      print("Error updating category ID ${category.id}: $e");
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        return -1; // Indicar duplicado
      }
      rethrow;
    }
  }

  // Verificar si una categoría está siendo usada por algún gasto
  Future<bool> isCategoryInUse(int categoryId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        _expensesTable,
        where: 'categoryId = ?',
        whereArgs: [categoryId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print("Error checking if category $categoryId is in use: $e");
      return true; // Asumir que sí por seguridad si hay error
    }
  }

  // Eliminar una categoría (solo si no está en uso)
  Future<int> deleteCategory(int id) async {
    if (await isCategoryInUse(id)) {
      print("Attempt to delete category $id failed: Category is in use.");
      throw Exception('La categoría está en uso y no se puede eliminar.');
    }
    final db = await database;
    print("Deleting category $id (not in use).");
    try {
      return await db.delete(
        _categoriesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("Error deleting category $id: $e");
      rethrow;
    }
  }

  // --- Métodos CRUD para Gastos (Actualizados para usar categoryId y filtros) ---

  // Insertar un nuevo gasto
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    Map<String, dynamic> expenseMap = expense.toMap()..remove('id');
    if (expenseMap['categoryId'] == null) {
      throw ArgumentError("Cannot insert expense: categoryId is null.");
    }
    try {
      return await db.insert(_expensesTable, expenseMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error inserting expense: $e");
      rethrow;
    }
  }

  // Obtener gastos con JOIN y filtros opcionales
  Future<List<Expense>> getExpenses(
      {DateTime? startDate, DateTime? endDate, int? categoryIdFilter}) async {
    final db = await database;
    String query = '''
      SELECT
        e.id as expenseId, e.description, e.amount, e.date, e.categoryId,
        c.name as categoryName
      FROM $_expensesTable e
      LEFT JOIN $_categoriesTable c ON e.categoryId = c.id
    ''';
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('e.date >= ?');
      whereArgs.add(DateTime(startDate.year, startDate.month, startDate.day)
          .toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('e.date <= ?');
      whereArgs.add(
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
              .toIso8601String());
    }
    if (categoryIdFilter != null) {
      whereClauses.add('e.categoryId = ?');
      whereArgs.add(categoryIdFilter);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }
    query += ' ORDER BY e.date DESC, e.id DESC';

    print("Executing query: $query with args: $whereArgs");
    try {
      final List<Map<String, dynamic>> maps =
          await db.rawQuery(query, whereArgs);
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } catch (e) {
      print("Error getting expenses: $e");
      return [];
    }
  }

  // Actualizar un gasto existente
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    if (expense.categoryId == null) {
      throw ArgumentError("Cannot update expense: categoryId is null.");
    }
    try {
      return await db.update(
        _expensesTable,
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    } catch (e) {
      print("Error updating expense ID ${expense.id}: $e");
      rethrow;
    }
  }

  // Eliminar un gasto por su ID
  Future<int> deleteExpense(int id) async {
    final db = await database;
    try {
      return await db.delete(
        _expensesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("Error deleting expense ID $id: $e");
      rethrow;
    }
  }

  // Obtener el total de gastos, aplicando los mismos filtros que getExpenses
  Future<double> getTotalExpenses(
      {DateTime? startDate, DateTime? endDate, int? categoryIdFilter}) async {
    final db = await database;
    String query = 'SELECT SUM(amount) as total FROM $_expensesTable';
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(DateTime(startDate.year, startDate.month, startDate.day)
          .toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
              .toIso8601String());
    }
    if (categoryIdFilter != null) {
      whereClauses.add('categoryId = ?');
      whereArgs.add(categoryIdFilter);
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    print("Executing total query: $query with args: $whereArgs");
    try {
      final List<Map<String, dynamic>> result =
          await db.rawQuery(query, whereArgs);
      double total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      return total;
    } catch (e) {
      print("Error calculating total expenses: $e");
      return 0.0;
    }
  }
}
