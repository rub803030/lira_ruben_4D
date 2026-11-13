import '../datasources/tarea_local_dao.dart';
import '../datasources/tarea_remota_datasource.dart';
import '../models/tarea_model.dart';

/// Repositorio de tareas.
///
/// La capa de presentacion solo conoce este repositorio; no sabe si los datos
/// provienen de SQLite o de una API REST. Esto mantiene el desacoplamiento
/// exigido por la arquitectura por capas.
class TareaRepositorio {
  TareaRepositorio(this._local, this._remota);

  final TareaLocalDao _local;
  final TareaRemotaDatasource _remota;

  Future<List<TareaModel>> obtenerTareasPendientes() {
    return _local.obtenerTareasPendientes();
  }

  Future<int> crearTarea(String titulo) {
    final String limpio = titulo.trim();
    return _local.insertarTarea(TareaModel(titulo: limpio));
  }

  Future<int> alternarCompletada(TareaModel tarea) {
    return _local.actualizarTarea(
      tarea.copyWith(completada: !tarea.completada),
    );
  }

  Future<int> eliminarTarea(int id) {
    return _local.eliminarTarea(id);
  }

  Future<List<TareaModel>> sincronizarTareasNube(String tokenJwt) {
    return _remota.sincronizarTareasNube(tokenJwt);
  }

  /// Descarga las tareas remotas y guarda en SQLite solo las que aun no
  /// existen (comparando por titulo). Devuelve cuantas se importaron.
  Future<int> importarTareasNube(String tokenJwt) async {
    final List<TareaModel> remotas =
        await _remota.sincronizarTareasNube(tokenJwt);
    final List<TareaModel> locales = await _local.obtenerTodas();
    final Set<String> titulosLocales = locales
        .map((TareaModel tarea) => tarea.titulo.trim().toLowerCase())
        .toSet();

    int importadas = 0;
    for (final TareaModel tarea in remotas) {
      final String clave = tarea.titulo.trim().toLowerCase();
      if (titulosLocales.contains(clave)) {
        continue;
      }
      // Se inserta con id nulo para que SQLite asigne una llave nueva y no
      // sobrescriba las tareas locales con los ids de la API.
      await _local.insertarTarea(
        TareaModel(
          titulo: tarea.titulo,
          completada: tarea.completada,
        ),
      );
      titulosLocales.add(clave);
      importadas++;
    }
    return importadas;
  }

  void cerrar() {
    _remota.cerrar();
  }
}
