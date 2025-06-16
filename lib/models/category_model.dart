// lib/models/category_model.dart
// --- VERSIÓN FINAL ---

// Define la estructura de datos para una categoría.
class Category {
  final int? id; // ID único de la base de datos (null si es nueva)
  final String name; // Nombre de la categoría

  Category({
    this.id,
    required this.name,
  });

  // Convierte un objeto Category a un Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Crea un objeto Category desde un Map de la base de datos
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  // Sobrescribir == y hashCode para comparar objetos Category por valor
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id && // Compara por ID si ambos lo tienen
          name == other.name; // Compara por nombre

  @override
  int get hashCode => id.hashCode ^ name.hashCode; // Combina hashCodes
}
