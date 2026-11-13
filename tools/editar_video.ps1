# Ensambla el video de evidencia a partir de las tomas del emulador.
# Requiere ffmpeg en el PATH.

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$video = Join-Path $raiz 'evidencia\video'
$evidencia = Join-Path $raiz 'evidencia'
$temporal = Join-Path $video 'temporal'
New-Item -ItemType Directory -Force -Path $temporal | Out-Null

function Invoke-Ffmpeg {
    param([string[]]$Argumentos)
    & ffmpeg -hide_banner -loglevel error -y @Argumentos
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg fallo con los argumentos: $($Argumentos -join ' ')"
    }
}

# Duraciones de cada bloque del video.
$dIntro = 10.5
$dAgregar = 22.3
$dDetener = 9.5
$dCerrada = 6.0
$dTerminal = 6.0
$dPersisten = 10.5
$dExito = 7.5

# 1. Tarjeta de presentacion.
Invoke-Ffmpeg @(
    '-loop', '1', '-i', (Join-Path $video 'intro.png'),
    '-t', "$dIntro", '-r', '30',
    '-vf', 'scale=720:1600,format=yuv420p',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg1.mp4')
)

# 2. Tomas de la app agregando las dos tareas (aceleradas 2.5x).
Invoke-Ffmpeg @(
    '-i', (Join-Path $evidencia 'seg_a3.mp4'),
    '-filter_complex', '[0:v]setpts=PTS/2.5,fps=30,scale=720:1600,tpad=stop_mode=clone:stop_duration=1,format=yuv420p[v]',
    '-map', '[v]', '-t', "$dAgregar", '-an',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg2.mp4')
)

# 3. Tarjeta: detener la ejecucion.
Invoke-Ffmpeg @(
    '-loop', '1', '-i', (Join-Path $video 'detener.png'),
    '-t', "$dDetener", '-r', '30',
    '-vf', 'scale=720:1600,format=yuv420p',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg3.mp4')
)

# 4. Pantalla del emulador con la app cerrada, con rotulo.
Invoke-Ffmpeg @(
    '-loop', '1', '-i', (Join-Path $video 'b1_frame.png'),
    '-loop', '1', '-i', (Join-Path $video 'rotulo_cerrada.png'),
    '-filter_complex', '[0:v]scale=800:1778,zoompan=z=min(zoom+0.0006\,1.08):d=180:s=720x1600:fps=30[bg];[bg][1:v]overlay=0:0,format=yuv420p[v]',
    '-map', '[v]', '-t', "$dCerrada", '-an',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg4.mp4')
)

# 5. Tarjeta tipo terminal: volver a compilar con flutter run.
Invoke-Ffmpeg @(
    '-loop', '1', '-i', (Join-Path $video 'terminal.png'),
    '-t', "$dTerminal", '-r', '30',
    '-vf', 'scale=720:1600,format=yuv420p',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg5.mp4')
)

# 6. App reabierta mostrando las dos tareas, con rotulo.
Invoke-Ffmpeg @(
    '-i', (Join-Path $evidencia 'seg_b2d.mp4'),
    '-loop', '1', '-i', (Join-Path $video 'rotulo_persisten.png'),
    '-filter_complex', '[0:v]scale=720:1600,fps=30,tpad=stop_mode=clone:stop_duration=1,format=yuv420p[bg];[bg][1:v]overlay=0:0,format=yuv420p[v]',
    '-map', '[v]', '-t', "$dPersisten", '-an',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg6.mp4')
)

# 7. Tarjeta final.
Invoke-Ffmpeg @(
    '-loop', '1', '-i', (Join-Path $video 'exito.png'),
    '-t', "$dExito", '-r', '30',
    '-vf', 'scale=720:1600,format=yuv420p',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    (Join-Path $temporal 'seg7.mp4')
)

# 8. Concatenacion.
$lista = Join-Path $temporal 'lista.txt'
$lineas = 1..7 | ForEach-Object {
    $ruta = (Join-Path $temporal "seg$_.mp4") -replace '\\', '/'
    "file '$ruta'"
}
Set-Content -Path $lista -Value $lineas -Encoding ASCII

Invoke-Ffmpeg @(
    '-f', 'concat', '-safe', '0', '-i', $lista,
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
    '-pix_fmt', 'yuv420p', '-r', '30', '-an',
    (Join-Path $temporal 'video_silencioso.mp4')
)

# 9. Mezcla de narracion sincronizada con cada bloque.
$tAgregar = $dIntro
$tDetener = $tAgregar + $dAgregar
$tCerrada = $tDetener + $dDetener
$tTerminal = $tCerrada + $dCerrada
$tPersisten = $tTerminal + $dTerminal
$tExito = $tPersisten + $dPersisten

function Ms([double]$segundos) { [int](($segundos + 0.5) * 1000) }

$filtro = @(
    "[1:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=500|500[a1]",
    "[2:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=$(Ms $tAgregar)|$(Ms $tAgregar)[a2]",
    "[3:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=$(Ms $tDetener)|$(Ms $tDetener)[a3]",
    "[4:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=$(Ms $tCerrada)|$(Ms $tCerrada)[a4]",
    "[5:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=$(Ms $tTerminal)|$(Ms $tTerminal)[a5]",
    "[6:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=$(Ms $tPersisten)|$(Ms $tPersisten)[a6]",
    "[7:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo,adelay=$(Ms $tExito)|$(Ms $tExito)[a7]",
    "[a1][a2][a3][a4][a5][a6][a7]amix=inputs=7:normalize=0,alimiter=limit=0.95,apad[a]"
) -join ';'

$duracionTotal = $tExito + $dExito

Invoke-Ffmpeg @(
    '-i', (Join-Path $temporal 'video_silencioso.mp4'),
    '-i', (Join-Path $video 'intro.wav'),
    '-i', (Join-Path $video 'agregar.wav'),
    '-i', (Join-Path $video 'detener.wav'),
    '-i', (Join-Path $video 'cerrada.wav'),
    '-i', (Join-Path $video 'recompilar.wav'),
    '-i', (Join-Path $video 'persistencia.wav'),
    '-i', (Join-Path $video 'exito.wav'),
    '-filter_complex', $filtro,
    '-map', '0:v', '-map', '[a]',
    '-c:v', 'copy', '-c:a', 'aac', '-b:a', '160k',
    '-t', "$duracionTotal",
    (Join-Path $evidencia 'prueba_persistencia.mp4')
)

Write-Output "Video final: $(Join-Path $evidencia 'prueba_persistencia.mp4')"
Write-Output "Duracion: $duracionTotal segundos"
