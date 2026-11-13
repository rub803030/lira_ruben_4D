import 'package:flutter_test/flutter_test.dart';
import 'package:lira_ruben_4d/data/models/tarea_model.dart';

void main() {
  group('TareaModel - mapeo objeto-relacional', () {
    test('toMap convierte el booleano a entero 1/0', () {
      const TareaModel pendiente = TareaModel(id: 7, titulo: 'Estudiar SQLite');
      const TareaModel completada =
          TareaModel(id: 8, titulo: 'Subir commit', completada: true);

      expect(pendiente.toMap(), <String, dynamic>{
        'id': 7,
        'titulo': 'Estudiar SQLite',
        'completada': 0,
      });
      expect(completada.toMap()['completada'], 1);
    });

    test('fromMap reconstruye una fila de SQLite', () {
      final TareaModel tarea = TareaModel.fromMap(<String, dynamic>{
        'id': 3,
        'titulo': 'Tarea local',
        'completada': 1,
      });

      expect(tarea.id, 3);
      expect(tarea.titulo, 'Tarea local');
      expect(tarea.completada, isTrue);
    });

    test('fromMap acepta el JSON que devuelve la API remota', () {
      final TareaModel tarea = TareaModel.fromMap(<String, dynamic>{
        'userId': 1,
        'id': 2,
        'title': 'delectus aut autem',
        'completed': false,
      });

      expect(tarea.id, 2);
      expect(tarea.titulo, 'delectus aut autem');
      expect(tarea.completada, isFalse);
    });

    test('copyWith conserva los valores no modificados', () {
      const TareaModel original = TareaModel(id: 1, titulo: 'Original');
      final TareaModel copia = original.copyWith(completada: true);

      expect(copia.id, 1);
      expect(copia.titulo, 'Original');
      expect(copia.completada, isTrue);
    });
  });
}
