# Bazzite: fuentes y cinemáticas AV1

La primera prueba física abrió el juego y mostró cierta lentitud en la cinemática
inicial. El checksum fue correcto. El terminal mostró avisos de Fontconfig,
fallos de inicialización VAAPI y uso de `libdav1d`. Esos datos no bastan para
atribuir toda la lentitud al decodificador.

## Correcciones

- Se utiliza Fontconfig del sistema, con sus propias reglas. La copia de Ubuntu
  24.04 era 2.15 y no entiende algunas reglas 2.18 de Bazzite/Fedora 45.
- Los cargadores VAAPI y VDPAU también se toman del sistema. La copia de libva
  incluida buscaba controladores en `/usr/lib/x86_64-linux-gnu/dri`, mientras que
  Fedora/Bazzite los instala en `/usr/lib64/dri`.
- Se comprueba si el decodificador acepta un motor antes de crear su dispositivo.
  `libdav1d` no acepta motores GPU: probar CUDA/VAAPI/VDPAU para ese decodificador
  generaba errores y trabajo innecesarios.
- La selección de formato hardware respeta el dispositivo que se inicializó.
  La descarga de fotogramas mantiene el formato del controlador, los colores y
  las marcas de tiempo.

No hay que instalar controladores NVIDIA en la Ally para resolver esos mensajes.

## Prueba opcional de AV1 por VAAPI

La decodificación AV1 sigue por CPU de forma predeterminada. Para probar la nueva
ruta VAAPI con la opción de emulación NVDEC en GPU:

```sh
EDEN_NX2_AV1_VAAPI=1 ./Fritchii-v4.1-Linux-x86_64.AppImage
```

El registro debe indicar `Using vaapi GPU decoder (av1)` y
`nx2 video: selected decoder av1`. Si VAAPI no puede inicializarse, se abre el
decodificador habitual por CPU y se registra la alternativa.

Compara la misma cinemática, TDP, alimentación y límite de FPS con el lanzamiento
normal. Anota fluidez, sincronización de audio, colores y FPS. La inicialización
del dispositivo no demuestra por sí sola que la película se decodifique bien.
Si la prueba opcional produce pantalla negra, errores o regresiones, cierra la
aplicación y vuelve a abrirla sin la variable: se recupera la ruta CPU habitual.

En Steam, las opciones equivalentes son `EDEN_NX2_AV1_VAAPI=1 %command%`. Sin
FUSE, añade también `APPIMAGE_EXTRACT_AND_RUN=1`.

## Validación sin la Ally

- CTest: 3/3 suites correctas; 864 casos en la principal. Dos casos nuevos
  comprueban un fotograma rojo AV1 sintético de 64x64, sus colores y timestamp,
  con preferencias CPU/GPU y la prueba VAAPI activada/desactivada. También se
  comprueba la elección de formato con metadatos de dispositivo VAAPI.
- Sin dispositivo VAAPI disponible, la prueba AV1 vuelve a CPU y produce el
  fotograma correcto. No se incluye contenido de juegos en las pruebas.
- 23 pruebas Python y el ensayo real de despertar/cancelación de hilos correctos.
- La interfaz del nuevo AppImage abre en Ubuntu 24.04 como otro usuario, usando
  los cargadores del sistema y sin Qt instalado.
- Se reprodujeron los avisos exactos de `48-guessfamily.conf` con la biblioteca
  antigua frente a Fontconfig 2.18.3 de Fedora 45. El nuevo AppDir carga 2.18.3 y
  lee las reglas sin avisos. El comprobador rechaza el paquete con la biblioteca
  antigua. El flujo incorpora la misma comprobación en Fedora 45.

Pendiente: reproducción y rendimiento de AV1/VAAPI en la GPU real de la Ally.
Las pruebas virtuales validan la alternativa CPU y la selección de formatos;
no validan la aceleración AMD ni garantizan una mejora de FPS.

Se revisaron el archivo de FFmpeg de Eglantine/nx2, sus PRs e incidencias y la
rama `fix/mingw-ffmpeg-av1` (PR 675). Ese cambio añade dav1d al paquete MinGW;
no resuelve la selección de AV1 hardware ni las rutas de Bazzite. No se enviaron
pull requests al proyecto original.
