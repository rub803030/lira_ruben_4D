/// Modelo de dominio inmutable que representa una tarea.
///
/// Esta clase es el puente entre el mundo orientado a objetos de Dart y las
/// filas tabulares de SQLite (mapeo objeto-relacional).
class TareaModel {
  final int? id;
  final String titulo;
  final bool completada;

  const TareaModel({
    this.id,
    required this.titulo,
    this.completada = false,
  });

  /// Serializacion hacia SQLite.
  ///
  /// SQLite no posee un tipo booleano nativo, por lo que `completada` se
  /// traduce a un entero: 1 = completada, 0 = pendiente.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'titulo': titulo,
      'completada': completada ? 1 : 0,
    };
  }

  /// Deserializacion desde una fila de SQLite o desde un objeto JSON.
  ///
  /// Se aceptan las llaves en espanol (`titulo`, `completada`) y las llaves
  /// que devuelve la API de prueba (`title`, `completed`).
  factory TareaModel.fromMap(Map<String, dynamic> map) {
    final Object? valorCompletada = map['completada'] ?? map['completed'];
    final Object? valorTitulo = map['titulo'] ?? map['title'] ?? '';

    return TareaModel(
      id: (map['id'] as num?)?.toInt(),
      titulo: valorTitulo.toString(),
      completada: valorCompletada == 1 || valorCompletada == true,
    );
  }

  TareaModel copyWith({
    int? id,
    String? titulo,
    bool? completada,
  }) {
    return TareaModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      completada: completada ?? this.completada,
    );
  }

  @override
  String toString() {
    return 'TareaModel(id: $id, titulo: $titulo, completada: $completada)';
  }
}
