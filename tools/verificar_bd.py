"""Consulta la base de datos SQLite extraida del emulador."""

from __future__ import annotations

import os
import sqlite3
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUTA = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RAIZ, "evidencia", "tareas_offline.db")

conexion = sqlite3.connect(RUTA)
print(f"Archivo: {RUTA}")
print(f"Tamano: {os.path.getsize(RUTA)} bytes")

tablas = conexion.execute(
    "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
).fetchall()
print(f"Tablas: {[tabla[0] for tabla in tablas]}")

esquema = conexion.execute(
    "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'tareas'"
).fetchone()
if esquema:
    print("Esquema:")
    print(esquema[0])

print("Filas en la tabla tareas:")
for fila in conexion.execute("SELECT id, titulo, completada FROM tareas ORDER BY id"):
    print(f"  id={fila[0]} | titulo={fila[1]!r} | completada={fila[2]}")

conexion.close()
