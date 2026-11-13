# Actividad 3 — Persistencia Local (SQLite) y Consumo de Servicios Web

**Alumno:** Lira Rubén · **Grupo:** 4D
**Materia:** Programación de aplicaciones móviles — Unidad III
**Fecha:** 13/11/2026

Aplicación Flutter con arquitectura por capas que administra tareas **offline-first**:
las tareas se guardan en una base de datos SQLite embebida (`tareas_offline.db`)
y sobreviven al cierre total del proceso y a una recompilación con `flutter run`.
También consume una API REST de prueba inyectando un token JWT en la cabecera
`Authorization: Bearer`.

---

## 1. Arquitectura por capas

```text
lib/
├── main.dart
├── data/
│   ├── models/
│   │   └── tarea_model.dart              # toMap / fromMap (ORM)
│   ├── datasources/
│   │   ├── tarea_local_dao.dart          # SQLite: INSERT, SELECT optimizado
│   │   └── tarea_remota_datasource.dart  # HTTP GET + JWT + jsonDecode + rethrow
│   └── repositories/
│       └── tarea_repositorio.dart        # Une SQLite y API; la UI no conoce detalles
└── presentation/
    ├── app.dart                          # Inyección de dependencias
    └── pages/
        ├── tareas_page.dart              # FutureBuilder + CircularProgressIndicator
        └── sincronizacion_page.dart      # Consumo del servicio web autenticado
```

**Regla de oro respetada:** ningún widget contiene `INSERT`, `SELECT` ni peticiones
HTTP. Toda la persistencia está aislada en `lib/data/`.

---

## 2. Fases implementadas

### Fase 1 — Control de versiones y dependencias

- Proyecto limpio de Flutter.
- `.gitignore` estricto: excluye `/build`, `.dart_tool/`, `android/.gradle/`,
  `ios/.generated/`, binarios, keystores e IDE.
- Ramas: `main` → `develop` → `feature/persistencia-datos`.
- Dependencias instaladas con `flutter pub add sqflite path http`.

### Fase 2 — Modelado y serialización

`TareaModel` es inmutable (`id`, `titulo`, `completada`) y traduce el booleano
a entero porque SQLite no tiene tipo booleano nativo:

```dart
'completada': completada ? 1 : 0
```

`fromMap` acepta tanto filas de SQLite (`titulo`, `completada`) como JSON de la
API (`title`, `completed`).

### Fase 3 — DAO local y optimización SQL

- Base de datos: `tareas_offline.db`, tabla `tareas` con
  `id INTEGER PRIMARY KEY AUTOINCREMENT`.
- `insertarTarea()` usa `ConflictAlgorithm.replace`.
- `obtenerTareasPendientes()`:
  - `columns: ['id', 'titulo', 'completada']` (no `SELECT *`).
  - `where: 'completada = ?'` y `whereArgs: [0]` (previene inyección SQL).

### Fase 4 — Servicio web con JWT

`TareaRemotaDatasource.sincronizarTareasNube(tokenJwt)`:

- `http.get` a `https://jsonplaceholder.typicode.com/todos` (servicio typicode).
- Cabecera obligatoria `Authorization: Bearer $tokenJwt`.
- Valida `statusCode == 200`, decodifica con `jsonDecode` y mapea los primeros
  5 resultados a `TareaModel`.
- Ante error de red o código distinto de 200, captura y propaga con `rethrow`.

### Fase 5 — Integración visual y Git

- `FutureBuilder` con `CircularProgressIndicator` mientras se leen las tareas.
- Alta de tareas mediante diálogo y FAB; cada alta se inserta en SQLite y se
  recarga la lista.
- Pantalla secundaria para ejecutar el GET autenticado e importar las tareas
  remotas a SQLite.
- Commit formal en la rama de trabajo.

---

## 3. Cómo ejecutar

```bash
cd lira_ruben_4D
flutter pub get
flutter emulators --launch Medium_Phone_API_37.0
flutter run
```

La app abre en **“Mis tareas”**. Cada tarea nueva se escribe en la memoria Flash
del emulador. El icono de nube abre el consumo del servicio web.

### Prueba de persistencia (video)

1. Abrir la app y agregar **2 tareas nuevas**.
2. Detener por completo la ejecución en Visual Studio Code (detener `flutter run`
   y cerrar el proceso de la app).
3. Volver a compilar con `flutter run`.
4. Verificar que las **2 tareas siguen listadas**: se leyeron desde
   `tareas_offline.db` en la memoria Flash.

El video de la demostración está en
[`evidencia/prueba_persistencia.mp4`](evidencia/prueba_persistencia.mp4) (72 s,
720 × 1600, sin audio). La verificación técnica completa, la
transcripción de comandos y la consulta directa al archivo SQLite están en
[`evidencia/VERIFICACION.md`](evidencia/VERIFICACION.md).

**Resultado comprobado:**

```text
[OK] Estudiar persistencia SQLite
[OK] Configurar API REST con JWT
PERSISTENCIA CONFIRMADA: las dos tareas siguen almacenadas.
```

Además se reinició el emulador en frío y el archivo `tareas_offline.db` conservó
las dos filas, demostrando que los datos están en la memoria Flash del AVD.

---

## 4. Historial Git

```text
main
└── chore: esqueleto limpio de Flutter con .gitignore estricto
    └── develop
        └── feature/persistencia-datos
            └── feat: implementar persistencia local SQLite y consumo HTTP con JWT
```

## 5. Pruebas

```bash
flutter test
flutter analyze
```

- 4 pruebas unitarias del mapeo ORM (`toMap` / `fromMap` / `copyWith`).
- `flutter analyze` sin advertencias.
