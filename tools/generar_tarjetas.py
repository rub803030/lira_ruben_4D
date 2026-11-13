"""Genera las tarjetas y los rotulos del video de evidencia.

Requiere Pillow. Las imagenes se guardan en evidencia/video/.
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFont

ANCHO, ALTO = 720, 1600
SALIDA = os.path.join(os.path.dirname(os.path.dirname(__file__)), "evidencia", "video")
FUENTES = r"C:\Windows\Fonts"


def fuente(nombre: str, tamano: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(os.path.join(FUENTES, nombre), tamano)


def degradado(color_inicio: tuple[int, int, int], color_fin: tuple[int, int, int]) -> Image.Image:
    imagen = Image.new("RGB", (ANCHO, ALTO))
    pixeles = imagen.load()
    for y in range(ALTO):
        t = y / (ALTO - 1)
        color = tuple(
            int(color_inicio[i] + (color_fin[i] - color_inicio[i]) * t)
            for i in range(3)
        )
        for x in range(ANCHO):
            pixeles[x, y] = color
    return imagen


def centrar(dibujo: ImageDraw.ImageDraw, texto: str, y: int, font, relleno, ancho=ANCHO) -> None:
    caja = dibujo.textbbox((0, 0), texto, font=font)
    x = (ancho - (caja[2] - caja[0])) // 2
    dibujo.text((x, y), texto, font=font, fill=relleno)


def envolver(texto: str, font, ancho_max: int) -> list[str]:
    palabras = texto.split()
    lineas: list[str] = []
    actual = ""
    for palabra in palabras:
        prueba = f"{actual} {palabra}".strip()
        if font.getlength(prueba) <= ancho_max:
            actual = prueba
        else:
            if actual:
                lineas.append(actual)
            actual = palabra
    if actual:
        lineas.append(actual)
    return lineas


def parrafo_centrado(
    dibujo: ImageDraw.ImageDraw,
    texto: str,
    y: int,
    font,
    relleno,
    ancho_max: int = 620,
    interlineado: int = 10,
) -> int:
    for linea in envolver(texto, font, ancho_max):
        centrar(dibujo, linea, y, font, relleno)
        y += font.size + interlineado
    return y


def circulo_decorativo(imagen: Image.Image, xy: tuple[int, int], radio: int, color, alfa: int) -> None:
    capa = Image.new("RGBA", imagen.size, (0, 0, 0, 0))
    dibujo = ImageDraw.Draw(capa)
    dibujo.ellipse(
        (xy[0] - radio, xy[1] - radio, xy[0] + radio, xy[1] + radio),
        fill=(*color, alfa),
    )
    imagen.alpha_composite(capa)


def tarjeta_intro() -> None:
    imagen = degradado((30, 27, 75), (79, 70, 229)).convert("RGBA")
    circulo_decorativo(imagen, (640, 120), 190, (255, 255, 255), 18)
    circulo_decorativo(imagen, (60, 1480), 260, (255, 255, 255), 14)

    dibujo = ImageDraw.Draw(imagen)
    centrar(dibujo, "UNIDAD III  ·  APLICACIONES MÓVILES", 180, fuente("segoeui.ttf", 22), (199, 210, 254))

    dibujo.rounded_rectangle((280, 250, 440, 306), radius=28, fill=(67, 56, 202))
    centrar(dibujo, "SQLite", 261, fuente("segoeuib.ttf", 26), (255, 255, 255))

    centrar(dibujo, "Actividad 3", 380, fuente("segoeuib.ttf", 92), (255, 255, 255))
    dibujo.rectangle((300, 510, 420, 516), fill=(165, 180, 252))

    y = 560
    for linea in ("Persistencia local", "(SQLite) y consumo", "de servicios web"):
        centrar(dibujo, linea, y, fuente("segoeuib.ttf", 44), (224, 231, 255))
        y += 58

    dibujo.rounded_rectangle((80, 1030, 640, 1320), radius=28, fill=(49, 46, 129))
    centrar(dibujo, "Lira Rubén", 1080, fuente("segoeuib.ttf", 46), (255, 255, 255))
    centrar(dibujo, "Grupo 4D", 1150, fuente("segoeui.ttf", 32), (199, 210, 254))
    centrar(dibujo, "13 / 11 / 2026", 1210, fuente("segoeui.ttf", 28), (165, 180, 252))

    centrar(
        dibujo,
        "Prueba de persistencia real en emulador Android",
        1410,
        fuente("segoeui.ttf", 24),
        (224, 231, 255),
    )

    imagen.convert("RGB").save(os.path.join(SALIDA, "intro.png"))


def tarjeta_detener() -> None:
    imagen = degradado((15, 23, 42), (30, 41, 59)).convert("RGBA")
    dibujo = ImageDraw.Draw(imagen)

    centrar(dibujo, "PASO 1", 260, fuente("segoeuib.ttf", 26), (248, 113, 113))

    dibujo.ellipse((300, 340, 420, 460), fill=(220, 38, 38))
    dibujo.rounded_rectangle((342, 382, 378, 418), radius=4, fill=(255, 255, 255))

    centrar(dibujo, "Detener por completo", 540, fuente("segoeuib.ttf", 52), (248, 250, 252))
    centrar(dibujo, "la ejecución", 600, fuente("segoeuib.ttf", 52), (248, 250, 252))

    parrafo_centrado(
        dibujo,
        "Se cierra el proceso de la app en el emulador y se detiene flutter run en Visual Studio Code.",
        720,
        fuente("segoeui.ttf", 30),
        (203, 213, 225),
    )

    dibujo.rounded_rectangle((90, 980, 630, 1120), radius=18, fill=(2, 6, 23))
    centrar(dibujo, "Visual Studio Code", 1010, fuente("segoeui.ttf", 24), (148, 163, 184))
    centrar(dibujo, "Ctrl + C   ·   q", 1060, fuente("consola.ttf", 34), (248, 113, 113))

    centrar(dibujo, "La app queda cerrada: no hay proceso activo.", 1280, fuente("segoeui.ttf", 24), (148, 163, 184))

    imagen.convert("RGB").save(os.path.join(SALIDA, "detener.png"))


def tarjeta_terminal() -> None:
    imagen = degradado((8, 13, 26), (15, 23, 42)).convert("RGB")
    dibujo = ImageDraw.Draw(imagen)

    centrar(dibujo, "PASO 2  ·  VOLVER A COMPILAR", 120, fuente("segoeuib.ttf", 26), (129, 140, 248))

    dibujo.rounded_rectangle((32, 210, 688, 1330), radius=18, fill=(17, 24, 39))
    dibujo.rounded_rectangle((32, 210, 688, 268), radius=18, fill=(31, 41, 55))
    dibujo.rectangle((32, 250, 688, 268), fill=(31, 41, 55))
    for i, color in enumerate(((239, 68, 68), (234, 179, 8), (34, 197, 94))):
        dibujo.ellipse((56 + i * 28, 230, 72 + i * 28, 246), fill=color)
    centrar(dibujo, "Terminal — lira_ruben_4D", 226, fuente("segoeui.ttf", 20), (148, 163, 184))

    mono = fuente("consola.ttf", 20)
    mono_chico = fuente("consola.ttf", 18)
    y = 300
    x = 58

    def linea(texto: str, color=(226, 232, 240), font=mono, salto=32) -> None:
        nonlocal y
        dibujo.text((x, y), texto, font=font, fill=color)
        y += salto

    linea("PS C:\\...\\lira_ruben_4D>", (74, 222, 128))
    linea("flutter run -d emulator-5554", (226, 232, 240))
    linea("Installing app-debug.apk...", (148, 163, 184), mono_chico, 26)
    linea("Syncing files to device...", (148, 163, 184), mono_chico, 26)
    linea("Flutter run key commands.", (148, 163, 184), mono_chico, 26)
    linea("q Quit (terminate the app)", (148, 163, 184), mono_chico, 34)

    linea("[ ejecución detenida ]", (248, 113, 113), fuente("segoeuib.ttf", 22), 52)

    linea("PS C:\\...\\lira_ruben_4D>", (74, 222, 128))
    linea("flutter run -d emulator-5554", (226, 232, 240))
    linea("Installing app-debug.apk...", (148, 163, 184), mono_chico, 26)
    linea("Syncing files to device...", (148, 163, 184), mono_chico, 26)
    linea("Flutter run key commands.", (148, 163, 184), mono_chico, 26)
    linea("A Dart VM Service is available", (148, 163, 184), mono_chico, 26)

    centrar(dibujo, "La base de datos permanece intacta", 1400, fuente("segoeuib.ttf", 30), (165, 180, 252))
    centrar(dibujo, "en la memoria Flash del emulador.", 1444, fuente("segoeui.ttf", 26), (148, 163, 184))

    imagen.save(os.path.join(SALIDA, "terminal.png"))


def tarjeta_exito() -> None:
    imagen = degradado((6, 78, 59), (16, 185, 129)).convert("RGBA")
    circulo_decorativo(imagen, (640, 1500), 240, (255, 255, 255), 16)

    dibujo = ImageDraw.Draw(imagen)
    dibujo.ellipse((290, 230, 430, 370), fill=(255, 255, 255))
    dibujo.line((330, 300, 352, 322, 392, 278), fill=(5, 150, 105), width=12, joint="curve")

    centrar(dibujo, "PRUEBA SUPERADA", 430, fuente("segoeuib.ttf", 58), (255, 255, 255))
    centrar(dibujo, "Las 2 tareas persisten", 530, fuente("segoeuib.ttf", 38), (209, 250, 229))

    dibujo.rounded_rectangle((50, 660, 670, 980), radius=24, fill=(6, 95, 70))
    filas = (
        ("1", "Estudiar persistencia SQLite", "ID #1"),
        ("2", "Configurar API REST con JWT", "ID #2"),
    )
    y = 710
    for numero, titulo, identificador in filas:
        dibujo.ellipse((86, y + 4, 130, y + 48), fill=(255, 255, 255))
        dibujo.text((98, y + 10), numero, font=fuente("segoeuib.ttf", 24), fill=(5, 150, 105))
        dibujo.text((150, y), titulo, font=fuente("segoeuib.ttf", 26), fill=(255, 255, 255))
        dibujo.text((150, y + 40), identificador, font=fuente("segoeui.ttf", 22), fill=(209, 250, 229))
        y += 120

    centrar(dibujo, "Leídas desde tareas_offline.db", 1080, fuente("segoeuib.ttf", 30), (255, 255, 255))
    centrar(dibujo, "en la memoria Flash del emulador", 1130, fuente("segoeui.ttf", 26), (209, 250, 229))

    centrar(dibujo, "Cierre total  →  flutter run  →  datos intactos", 1290, fuente("segoeui.ttf", 26), (167, 243, 208))

    imagen.convert("RGB").save(os.path.join(SALIDA, "exito.png"))


def rotulo(nombre: str, texto: str, color=(15, 23, 42)) -> None:
    imagen = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
    dibujo = ImageDraw.Draw(imagen)
    font = fuente("segoeuib.ttf", 28)
    ancho_texto = int(font.getlength(texto))
    caja_ancho = min(ANCHO - 40, ancho_texto + 60)
    x1 = (ANCHO - caja_ancho) // 2
    y1 = 1370
    dibujo.rounded_rectangle((x1, y1, x1 + caja_ancho, y1 + 76), radius=18, fill=(15, 23, 42, 215))
    centrar(dibujo, texto, y1 + 20, font, (255, 255, 255))
    imagen.save(os.path.join(SALIDA, f"{nombre}.png"))


def main() -> None:
    os.makedirs(SALIDA, exist_ok=True)
    tarjeta_intro()
    tarjeta_detener()
    tarjeta_terminal()
    tarjeta_exito()
    rotulo("rotulo_cerrada", "Aplicación cerrada: proceso terminado")
    rotulo("rotulo_persisten", "Las 2 tareas siguen almacenadas")
    print(f"Tarjetas generadas en {SALIDA}")


if __name__ == "__main__":
    main()
