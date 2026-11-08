# Prueba física en ROG Ally

El AppImage x86_64 corresponde a las CPU AMD de la ROG Ally. Esta compilación
parte del código completo de Fritchii v4.1 para Windows, con adaptaciones del
proceso de compilación para Linux. Requiere glibc 2.39 o posterior.

Las pruebas de compilación, shaders y arranque de la interfaz en una pantalla
virtual no sustituyen una prueba con la GPU AMD, su controlador y el juego.
NVIDIA DLSS mediante Streamline no está disponible en esta versión para Linux.
La asignación de hilos a núcleos incorpora el port de Linux del PR #15 de Frizti.
Su rendimiento en la Ally debe compararse con la afinidad desactivada. La consulta
de refresco mediante DWM sigue siendo específica de Windows.

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

## Bazzite

Haz la primera configuración en **modo escritorio**. Extrae el ZIP descargado de
GitHub Actions, abre una terminal en esa carpeta y ejecuta los comandos anteriores.
Comprueba la versión del sistema con `getconf GNU_LIBC_VERSION`: debe ser 2.39 o
posterior. El AppImage utiliza los controladores Mesa/Vulkan de Bazzite; no requiere
modificar la imagen del sistema para instalar Qt.

En los ajustes del emulador selecciona Vulkan y la GPU AMD integrada. Configura
los controles con el dispositivo que detecte SDL y comprueba los botones antes de
abrir el juego. Completa también los diálogos de primera ejecución en el escritorio.

Después añade el AppImage a Steam como juego externo y pruébalo en **modo juego**,
con el mismo TDP y ajustes. Es una aplicación Linux nativa: deja desactivada la
compatibilidad con Proton para ese acceso. Si usas la alternativa sin FUSE, las
opciones de lanzamiento de Steam son `APPIMAGE_EXTRACT_AND_RUN=1 %command%`.

Compara ambas sesiones: imagen, foco de ventana, pantalla completa, controles y
suspensión/reanudación. Si aparece un problema de ventana únicamente en modo juego,
una comparación con `QT_QPA_PLATFORM=xcb %command%` permite probar XWayland. Anota
el resultado y conserva los registros de ambas sesiones antes de cambiar otros
ajustes; es una comprobación de diagnóstico, no un requisito de lanzamiento.

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
8. Repite la misma ruta con afinidad automática y con
   `EDEN_NX2_PIN_THREADS=0 ./Fritchii-v4.1-Linux-x86_64.AppImage`. Compara sobre
   todo los tirones y tiempos de fotograma, manteniendo TDP y ajustes iguales.
   La afinidad automática solo se activa cuando la topología cumple los mínimos
   del planificador; el registro indica el plan elegido.

## Qué enviar si falla

Indica el commit de `*-build-info.txt`, los datos del equipo, los ajustes, el
lugar exacto y los pasos para reproducirlo. Adjunta una captura y el registro de
esa sesión, revisados para retirar información personal. No hacen falta juegos,
claves ni firmware.

Con esa evidencia se puede distinguir un problema del emulador de uno del
controlador o de falta de memoria antes de cambiar sincronización, shaders o
precisión de GPU.
