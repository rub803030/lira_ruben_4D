import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/tarea_model.dart';

/// Data Access Object (DAO) de tareas locales.
///
/// Es la unica clase autorizada para hablar con SQLite. La interfaz grafica
/// nunca ejecuta sentencias SQL: solo invoca los metodos de este DAO a traves
/// del repositorio.
class TareaLocalDao {
  static const String _nombreBaseDatos = 'tareas_offline.db';
  static const String _tabla = 'tareas';
  static const int _version = 1;

  static const List<String> _columnas = <String>['id', 'titulo', 'completada'];

  Database? _baseDatos;

  /// Abre (o reutiliza) la base de datos embebida en el almacenamiento
  /// privado de la aplicacion. El archivo .db vive en la memoria Flash.
  Future<Database> get baseDatos async {
    if (_baseDatos != null) {
      return _baseDatos!;
    }

    final String ruta = p.join(await getDatabasesPath(), _nombreBaseDatos);
    _baseDatos = await openDatabase(
      ruta,
      version: _version,
      onCreate: _crearTabla,
    );
    return _baseDatos!;
  }

  Future<void> _crearTabla(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tabla (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        completada INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Inserta una tarea. `ConflictAlgorithm.replace` permite reemplazar una
  /// fila cuando la llave primaria ya existe.
  Future<int> insertarTarea(TareaModel tarea) async {
    final Database db = await baseDatos;
    return db.insert(
      _tabla,
      tarea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Recupera solo las tareas pendientes (completada = 0).
  ///
  /// Optimizacion y seguridad:
  /// - `columns` declara explicitamente las columnas (evita SELECT *).
  /// - `where` usa el marcador posicional `?` y `whereArgs` evita la
  ///   inyeccion SQL.
  Future<List<TareaModel>> obtenerTareasPendientes() async {
    final Database db = await baseDatos;
    final List<Map<String, Object?>> filas = await db.query(
      _tabla,
      columns: _columnas,
      where: 'completada = ?',
      whereArgs: <Object?>[0],
      orderBy: 'id ASC',
    );

    return filas.map(TareaModel.fromMap).toList(growable: false);
  }

  /// Recupera todas las tareas (utiles para verificar duplicados al
  /// importar datos desde la nube).
  Future<List<TareaModel>> obtenerTodas() async {
    final Database db = await baseDatos;
    final List<Map<String, Object?>> filas = await db.query(
      _tabla,
      columns: _columnas,
      orderBy: 'id ASC',
    );

    return filas.map(TareaModel.fromMap).toList(growable: false);
  }

  Future<int> actualizarTarea(TareaModel tarea) async {
    final Database db = await baseDatos;
    return db.update(
      _tabla,
      tarea.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[tarea.id],
    );
  }

  Future<int> eliminarTarea(int id) async {
    final Database db = await baseDatos;
    return db.delete(
      _tabla,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> cerrar() async {
    await _baseDatos?.close();
    _baseDatos = null;
  }
}
