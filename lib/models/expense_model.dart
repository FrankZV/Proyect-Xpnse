// lib/models/expense_model.dart
// --- VERSIÓN FINAL (Corregida) ---

import 'category_model.dart'; // Importa el modelo de categoría

// Define la estructura de datos para un gasto.
class Expense {
  final int? id; // ID de la base de datos (nullable para gastos nuevos)
  final String description; // Descripción del gasto
  // --- Almacenamos el ID de la categoría ---
  final int categoryId; // ID de la categoría a la que pertenece
  final double amount; // Monto del gasto
  final DateTime date; // Fecha en que se realizó el gasto

  // --- Campo opcional para tener acceso fácil al objeto Category (obtenido por JOIN) ---
  final Category? category;

  Expense({
    this.id,
    required this.description,
    required this.categoryId, // Ahora requerimos el ID
    required this.amount,
    required this.date,
    this.category, // Parámetro opcional
  });

  // Método para convertir un objeto Expense a un Map para la base de datos.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'categoryId': categoryId, // Guarda el ID de la categoría
      'amount': amount,
      'date': date.toIso8601String(), // Guarda fecha como String ISO 8601
    };
    // No incluimos 'category' (el objeto) aquí.
  }

  // Factory constructor para crear un objeto Expense desde un Map (resultado de un JOIN).
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['expenseId'] as int?, // Usa alias 'expenseId' del JOIN
      description: map['description'] as String,
      categoryId: map['categoryId'] as int,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String), // Parsea fecha desde String
      // Crea el objeto Category asociado si los datos están presentes en el map (del JOIN)
      category: map['categoryId'] != null && map['categoryName'] != null
          ? Category(
              id: map['categoryId'] as int,
              name: map['categoryName'] as String,
              // Añade otros campos de Category si los incluiste en el JOIN y modelo
            )
          : null, // Si no hay categoría asociada (raro con LEFT JOIN, posible si se borró mal)
    );
  }
}
