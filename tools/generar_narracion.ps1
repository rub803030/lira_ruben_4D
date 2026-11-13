# Genera la narracion en espanol para el video de evidencia.
Add-Type -AssemblyName System.Speech

$salida = Join-Path $PSScriptRoot '..\evidencia\video'
New-Item -ItemType Directory -Force -Path $salida | Out-Null

$sintetizador = New-Object System.Speech.Synthesis.SpeechSynthesizer
$sintetizador.SelectVoice('Microsoft Helena Desktop')
$sintetizador.Rate = 0
$sintetizador.Volume = 100

$textos = [ordered]@{
    intro        = 'Actividad tres. Persistencia local con ese cu lite y consumo de servicios web. Lira Rubén, grupo cuatro D.'
    agregar      = 'Agregamos dos tareas nuevas. Cada una se guarda en la base de datos tareas offline punto de be, en la memoria Flash del emulador.'
    detener      = 'Ahora detenemos por completo la ejecución en Visual Studio Code y cerramos el proceso de la aplicación.'
    cerrada      = 'La aplicación ya no está en ejecución.'
    recompilar   = 'Volvemos a compilar con flutter run.'
    persistencia = 'Al abrir nuevamente la aplicación, las dos tareas siguen almacenadas. La persistencia quedó comprobada.'
    exito        = 'Las tareas sobreviven al cierre total del proceso. Prueba de persistencia superada.'
}

foreach ($clave in $textos.Keys) {
    $ruta = Join-Path $salida "$clave.wav"
    $sintetizador.SetOutputToWaveFile($ruta)
    $sintetizador.Speak($textos[$clave])
    $sintetizador.SetOutputToNull()
    Write-Output "Generado: $ruta"
}

$sintetizador.Dispose()
