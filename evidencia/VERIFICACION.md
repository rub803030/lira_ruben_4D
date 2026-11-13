# Evidencia de la prueba de persistencia real

**Actividad 3 — Persistencia Local (SQLite) y Consumo de Servicios Web**
**Alumno:** Lira Rubén · **Grupo:** 4D · **Fecha:** 13/11/2026

---

## 1. Video de la prueba

| Dato | Valor |
|---|---|
| Archivo | [`prueba_persistencia.mp4`](prueba_persistencia.mp4) |
| Duración | 72.3 segundos |
| Resolución | 720 × 1600 (vertical) |
| Video | H.264, 30 fps |
| Audio | Sin audio |
| Tamaño | 1.6 MB |

### Guion y línea de tiempo

| Tiempo | Escena |
|---|---|
| 0:00 | Portada: Actividad 3, Lira Rubén, grupo 4D |
| 0:10 | App abierta con la lista vacía. Se agregan **2 tareas nuevas** |
| 0:33 | **Paso 1:** detener por completo la ejecución (`Ctrl + C` / cerrar la app) |
| 0:42 | Emulador mostrando la **app cerrada** (sin proceso activo) |
| 0:48 | **Paso 2:** volver a compilar con `flutter run -d emulator-5554` |
| 0:54 | App reabierta: **las 2 tareas siguen almacenadas** |
| 1:05 | Tarjeta final: prueba superada, datos leídos desde `tareas_offline.db` |

Las tareas utilizadas en la prueba son:

1. `Estudiar persistencia SQLite` (ID #1)
2. `Configurar API REST con JWT` (ID #2)

---

## 2. Procedimiento ejecutado (transcripción real)

```text
PS C:\Users\rubnl\Downloads\nuevovo\lira_ruben_4D> flutter run -d emulator-5554
Installing build\app\outputs\flutter-apk\app-debug.apk...        1,768ms
Syncing files to device sdk gphone64 x86 64...                     370ms

Flutter run key commands.
r Hot reload.
R Hot restart.
q Quit (terminate the application on the device).

A Dart VM Service on sdk gphone64 x86 64 is available at:
http://127.0.0.1:52837/1EP2DaZc2kc=/

[se agregan las 2 tareas desde la interfaz]

PS C:\Users\rubnl\Downloads\nuevovo\lira_ruben_4D> adb shell am force-stop com.ruben.lira_ruben_4d
PS C:\Users\rubnl\Downloads\nuevovo\lira_ruben_4D> adb shell pidof com.ruben.lira_ruben_4d
(vacío: el proceso ya no existe)

PS C:\Users\rubnl\Downloads\nuevovo\lira_ruben_4D> flutter run -d emulator-5554
Installing build\app\outputs\flutter-apk\app-debug.apk...
Syncing files to device sdk gphone64 x86 64...

Flutter run key commands.
A Dart VM Service on sdk gphone64 x86 64 is available at:
http://127.0.0.1:52837/1EP2DaZc2kc=/
```

Verificación automática después del reinicio:

```text
PS ...> python tools\demo_android.py --verificar
Dispositivo: sdk_gphone64_x86_64
Paquete: com.ruben.lira_ruben_4d
  [OK] Estudiar persistencia SQLite
  [OK] Configurar API REST con JWT
PERSISTENCIA CONFIRMADA: las dos tareas siguen almacenadas.
```

---

## 3. Verificación directa del archivo SQLite

El archivo se extrajo del almacenamiento privado de la app:

```powershell
adb exec-out run-as com.ruben.lira_ruben_4d cat databases/tareas_offline.db > evidencia/tareas_offline.db
python tools\verificar_bd.py
```

Salida real:

```text
Archivo: ...\evidencia\tareas_offline.db
Tamano: 20480 bytes
Tablas: ['android_metadata', 'sqlite_sequence', 'tareas']
Esquema:
CREATE TABLE tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        completada INTEGER NOT NULL DEFAULT 0
      )
Filas en la tabla tareas:
  id=1 | titulo='Estudiar persistencia SQLite' | completada=0
  id=2 | titulo='Configurar API REST con JWT' | completada=0
```

El archivo [`tareas_offline.db`](tareas_offline.db) se conserva en esta carpeta como
evidencia binaria. Además, después de grabar el video se reinició el emulador en
frío y el archivo seguía conteniendo las dos filas, lo que confirma que los datos
están en la memoria Flash del AVD y no en la RAM.

---

## 4. Capturas

- [`estado_inicial.png`](estado_inicial.png): app recién instalada, sin tareas.
- [`persistencia_final.png`](persistencia_final.png): app después de detener el
  proceso y volver a ejecutar `flutter run`, con las dos tareas.

---

## 5. Tomas originales

En [`fuentes/`](fuentes/) se conservan las tomas sin editar:

- `alta_de_tareas.mp4`: interacción real agregando las dos tareas.
- `app_reabierta.mp4`: app después del reinicio, con las tareas almacenadas.

---

## 6. Cómo reproducir la prueba

```bash
# 1. Compilar y ejecutar
flutter run -d emulator-5554

# 2. Agregar dos tareas desde la interfaz o con el script
python tools/demo_android.py --agregar

# 3. Detener por completo la ejecución (Ctrl+C en la terminal y cerrar la app)
adb shell am force-stop com.ruben.lira_ruben_4d

# 4. Volver a compilar
flutter run -d emulator-5554

# 5. Verificar
python tools/demo_android.py --verificar
```
