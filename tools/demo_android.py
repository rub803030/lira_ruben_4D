"""Automatiza la prueba de persistencia en el emulador Android.

Uso:
    python tools/demo_android.py --agregar
    python tools/demo_android.py --verificar

El script se comunica con la app a traves de `adb` y de la jerarquia de
accesibilidad de Android (uiautomator). No usa coordenadas fijas: localiza
cada control por su descripcion, por lo que es resistente a cambios de
resolucion o de disposicion del teclado.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

ADB = os.path.join(
    os.environ.get("LOCALAPPDATA", ""),
    "Android",
    "Sdk",
    "platform-tools",
    "adb.exe",
)
PAQUETE = "com.ruben.lira_ruben_4d"
TAREAS = ("Estudiar persistencia SQLite", "Configurar API REST con JWT")


def adb(*args: str, check: bool = True) -> str:
    resultado = subprocess.run(
        [ADB, *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if check and resultado.returncode != 0:
        raise RuntimeError(
            f"adb {' '.join(args)} fallo: {resultado.stderr or resultado.stdout}"
        )
    return resultado.stdout


def nodos() -> list[dict[str, str]]:
    adb("shell", "uiautomator", "dump", "/sdcard/ui_demo.xml")
    destino = os.path.join(tempfile.gettempdir(), "ui_demo.xml")
    adb("pull", "/sdcard/ui_demo.xml", destino)
    arbol = ET.parse(destino)
    lista: list[dict[str, str]] = []
    for nodo in arbol.iter("node"):
        lista.append(
            {
                "texto": nodo.get("text", ""),
                "desc": nodo.get("content-desc", ""),
                "clase": nodo.get("class", ""),
                "bounds": nodo.get("bounds", ""),
                "enfocado": nodo.get("focused", "false"),
            }
        )
    return lista


def centro(bounds: str) -> tuple[int, int]:
    izquierda_arriba, derecha_abajo = bounds.split("][")
    x1, y1 = (int(v) for v in izquierda_arriba.strip("[").split(","))
    x2, y2 = (int(v) for v in derecha_abajo.strip("]").split(","))
    return (x1 + x2) // 2, (y1 + y2) // 2


def esperar(predicado, descripcion: str, timeout: float = 12.0) -> dict[str, str]:
    limite = time.time() + timeout
    while time.time() < limite:
        for nodo in nodos():
            if predicado(nodo):
                return nodo
        time.sleep(0.8)
    raise TimeoutError(f"No se encontro: {descripcion}")


def tocar(nodo: dict[str, str]) -> None:
    x, y = centro(nodo["bounds"])
    adb("shell", "input", "tap", str(x), str(y))


def agregar_tarea(titulo: str) -> None:
    print(f"  -> Abriendo formulario para: {titulo}")
    tocar(esperar(lambda n: n["desc"] == "Nueva tarea", "boton Nueva tarea"))

    campo = esperar(
        lambda n: "EditText" in n["clase"],
        "campo de texto del formulario",
    )
    tocar(campo)
    time.sleep(0.5)

    print("  -> Escribiendo titulo")
    adb("shell", "input", "text", titulo.replace(" ", "%s"))

    # Esperar a que el campo contenga exactamente el titulo.
    esperar(
        lambda n: "EditText" in n["clase"] and n["texto"] == titulo,
        f"texto completo en el campo ({titulo})",
    )
    time.sleep(0.5)

    print("  -> Guardando en SQLite")
    tocar(esperar(lambda n: n["desc"] == "Guardar", "boton Guardar"))

    esperar(
        lambda n: titulo in n["desc"],
        f"tarea visible en la lista ({titulo})",
    )
    print(f"  OK: '{titulo}' visible en la lista")
    time.sleep(4.5)  # dejar que el SnackBar desaparezca


def verificar_tareas() -> bool:
    lista = nodos()
    presentes = [
        titulo
        for titulo in TAREAS
        if any(titulo in nodo["desc"] for nodo in lista)
    ]
    for titulo in TAREAS:
        estado = "OK" if titulo in presentes else "FALTA"
        print(f"  [{estado}] {titulo}")
    return len(presentes) == len(TAREAS)


def main() -> int:
    parser = argparse.ArgumentParser()
    grupo = parser.add_mutually_exclusive_group(required=True)
    grupo.add_argument(
        "--agregar",
        action="store_true",
        help="agrega las dos tareas de la prueba",
    )
    grupo.add_argument(
        "--verificar",
        action="store_true",
        help="comprueba que las dos tareas sigan en la lista",
    )
    args = parser.parse_args()

    print(f"Dispositivo: {adb('shell', 'getprop', 'ro.product.model').strip()}")
    print(f"Paquete: {PAQUETE}")

    if args.agregar:
        for titulo in TAREAS:
            agregar_tarea(titulo)
        print("Tareas agregadas correctamente.")
        return 0

    if verificar_tareas():
        print("PERSISTENCIA CONFIRMADA: las dos tareas siguen almacenadas.")
        return 0

    print("ERROR: no se encontraron las dos tareas.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
