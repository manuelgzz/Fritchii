# Prueba física en ROG Ally

El AppImage x86_64 corresponde a las CPU AMD de la ROG Ally. Esta compilación
parte del código completo de Fritchii v4.1 para Windows, con adaptaciones del
proceso de compilación para Linux. Requiere glibc 2.39 o posterior.

Las pruebas de compilación, shaders y arranque de la interfaz en una pantalla
virtual no sustituyen una prueba con la GPU AMD, su controlador y el juego.
NVIDIA DLSS mediante Streamline no está disponible en esta versión para Linux.
La asignación de hilos a núcleos y la consulta de refresco mediante DWM también
son específicas de Windows; no se presume que sus mejoras de rendimiento se
reproduzcan automáticamente en Linux.

## Antes de empezar

Anota el modelo de Ally, distribución, versión de Mesa/controlador Vulkan, TDP,
modo conectado/batería, memoria reservada a la GPU y versión del juego. No cambies
varios de estos valores a la vez al comparar resultados.

Verifica el archivo y dale permiso de ejecución:

```sh
sha256sum -c Fritchii-v4.1-Linux-x86_64.AppImage.sha256
chmod +x Fritchii-v4.1-Linux-x86_64.AppImage
./Fritchii-v4.1-Linux-x86_64.AppImage
```

Si no hay FUSE, usa `APPIMAGE_EXTRACT_AND_RUN=1` delante del último comando.
El host debe proporcionar un controlador Vulkan funcional.

## Ocarina of Time

Empieza con Vulkan, resolución 1x y los ajustes que aplica Fritchii. El primer
arranque permite elegir la tasa de fotogramas del juego. Primero confirma
estabilidad; después compara 30 y 60 FPS con la misma escena y TDP. No se promete
que todos los modelos puedan sostener 60 FPS.

1. Comprueba que funcionan los controles integrados y que el juego inicia.
2. Recorre una misma zona durante varios minutos. Anota FPS, tirones, consumo de
   RAM y errores del registro, distinguiendo la primera compilación de shaders
   de una segunda ejecución con caché.
3. Observa el agua y la cascada del río Zora: busca parpadeos alternos.
4. Comprueba exposición, hierba y vegetación en Hyrule Field, y la geometría del
   cementerio de Kakariko.
5. Revisa niebla, transparencias y destellos blancos, especialmente con la GPU
   AMD. Las correcciones de v4.1 están en el código; falta validarlas en la Ally.
6. Reproduce una cinemática para comprobar imagen, sonido y sincronización.
7. Guarda, cierra y vuelve a abrir: verifica partidas, ajustes y reutilización de
   cachés. Prueba también pantalla completa y, si lo utilizas, suspensión/reanudación.

## Qué enviar si falla

Indica el commit de `*-build-info.txt`, los datos del equipo, los ajustes, el
lugar exacto y los pasos para reproducirlo. Adjunta una captura y el registro de
esa sesión, revisados para retirar información personal. No hacen falta juegos,
claves ni firmware.

Con esa evidencia se puede distinguir un problema del emulador de uno del
controlador o de falta de memoria antes de cambiar sincronización, shaders o
precisión de GPU.
