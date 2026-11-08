# Validación de Linux, 8 de noviembre de 2026

El AppImage local de Fritchii v4.1 está compilado y ha superado las comprobaciones
que pueden realizarse sin una ROG Ally. La prueba física sigue pendiente.

## Versiones y trazabilidad

- Fuente del binario: `8734d4ee80827382c9685a5aca83576ed79af9b6`.
- Empaquetado: `7e6be8cb8d89717ccf1d86decfd338fdced2a7ea`.
- Base Windows v4.1: `f6d42b87150678e001dbeb84679a9595935ce951`.
- Ubuntu 24.04, glibc 2.39, LLVM/Clang 23.1.6, CMake 3.31.6.
- Arquitectura x86_64 genérica, PGO del proyecto, ThinLTO y lld.
- SHA-256 del artefacto local:
  `bb44c2e074b5d1e75d238b2aec6b9f231f8c5bef5ce0e959448fe1fb3cb708ed`.

El flujo de GitHub Actions recompila por separado. Su AppImage puede tener otro
hash por las revisiones, marcas de tiempo y metadatos de compilación; hay que usar
el archivo `.sha256` que acompaña a cada descarga.

## Comprobaciones realizadas

- CTest: 3/3 suites correctas. Principal: 862 casos y 70.519.271 aserciones;
  SPIR-V con inlining desactivado: 851 aserciones; actualizador: 32 casos y
  1.137 aserciones.
- Python: 23 pruebas correctas y una comprobación compilada de despertar y
  cancelación de hilos.
- Afinidad: restricción/restauración real de un hilo Linux y planificación para
  topologías de 6 núcleos/12 hilos y 8 núcleos/16 hilos con hermanos SMT no adyacentes.
- La interfaz del AppImage abre con datos de usuario aislados bajo Xvfb.
- Arranque repetido en un contenedor Ubuntu 24.04 mínimo, sin Qt ni compilador,
  como UID 1001, distinto del constructor. Controlador Vulkan de software Mesa;
  fuentes y configuración de Fontconfig del sistema. Log de aplicación vacío,
  sin errores de bibliotecas faltantes ni avisos de Fontconfig.
- Arranque adicional nativo Wayland: Weston headless con renderer Pixman; el
  protocolo confirmó `xdg_toplevel.set_title` de Fritchii y el proceso permaneció
  activo. El entorno sin GPU produjo avisos EGL/Mesa; esto no valida EGL ni juegos
  sobre AMD. La comprobación X11 limpia se realizó antes de instalar Weston.
- Checksum verificado después del empaquetado final.

La prueba limpia detectó dependencias excluidas por defecto por linuxdeploy:
libusb, OpenGL (cargador, sin controladores), HarfBuzz, FriBidi, Fontconfig y ALSA.
Se incluyen explícitamente en el AppImage. Los controladores GPU se conservan
en el sistema anfitrión.

## Próxima comprobación

Seguir [la guía de pruebas en la ROG Ally](Pruebas-ROG-Ally.md). No se han medido
FPS ni validado juegos, imagen, audio, controles, Wayland o suspensión en hardware
AMD real. Un arranque con Vulkan de software no valida la emulación ni RADV.
No se han añadido parches gráficos especulativos.

Los cambios están exclusivamente en la rama `linux-appimage` de
`manuelgzz/Fritchii`. No se han enviado pull requests al repositorio original.
