# Pull Request · Actividad 3 — Persistencia Local (SQLite) y Consumo de Servicios Web

## Resumen

Implementa la persistencia local de tareas con SQLite (`sqflite`) y el consumo
de un servicio web REST con autenticación JWT (`http`), siguiendo una
arquitectura por capas dentro de `lib/`.

## Cambios principales

- **Modelo ORM** `lib/data/models/tarea_model.dart`
  - `toMap()` / `fromMap()` con conversión de `bool` a `0/1` y viceversa.
- **DAO local** `lib/data/datasources/tarea_local_dao.dart`
  - Base de datos `tareas_offline.db`, tabla `tareas` con
    `id INTEGER PRIMARY KEY AUTOINCREMENT`.
  - `insertarTarea()` con `ConflictAlgorithm.replace`.
  - `obtenerTareasPendientes()` con columnas explícitas,
    `where: 'completada = ?'` y `whereArgs: [0]`.
- **Datasource remoto** `lib/data/datasources/tarea_remota_datasource.dart`
  - `sincronizarTareasNube(String tokenJwt)` con `http.get`,
    cabecera `Authorization: Bearer $tokenJwt`, validación de estado `200`,
    `jsonDecode`, lectura de los primeros 5 resultados y `rethrow` en errores.
- **Repositorio** `lib/data/repositories/tarea_repositorio.dart`
  - Coordina la lectura local y la sincronización remota sin acoplar la UI.
- **Presentación** `lib/presentation/`
  - `FutureBuilder` + `CircularProgressIndicator` para la carga.
  - Alta de tareas desde un diálogo; ninguna consulta SQL ni HTTP en widgets.
  - Pantalla de sincronización con el servicio web.

## Evidencia de persistencia

- Video: [`evidencia/prueba_persistencia.mp4`](../evidencia/prueba_persistencia.mp4)
  (72 s, narrado, 720 × 1600).
- Verificación técnica: [`evidencia/VERIFICACION.md`](../evidencia/VERIFICACION.md).
- Base extraída del emulador: [`evidencia/tareas_offline.db`](../evidencia/tareas_offline.db).

Prueba realizada en el emulador `Medium_Phone_API_37.0`: se agregaron dos
tareas, se detuvo por completo la ejecución (`flutter run` + `force-stop`), se
volvió a ejecutar la app y las dos tareas seguían listadas. Tras un reinicio en
frío del emulador, el archivo SQLite conservó las dos filas, lo que confirma
que los datos están en la memoria Flash del AVD.

## Calidad

```text
flutter analyze  -> No issues found!
flutter test     -> All tests passed! (4 pruebas)
```

## Cómo probar

```bash
flutter pub get
flutter run -d emulator-5554
# agregar 2 tareas, cerrar la app por completo y volver a ejecutar
```
