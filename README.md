# escritor_humano_V3

Programa para Windows que escribe texto letra a letra (como si lo teclearas tú). No usa el portapapeles.

**F8** empieza. **Escape** para. Si haces clic en otra ventana mientras escribe, sigue en el cuadro donde empezó.

## Cómo usarlo

No hace falta instalar AutoHotkey ni nada más. En Windows basta copiar la carpeta y abrir el `.exe`.

1. Entra en `dist/escritor_humano_V3/`
2. Abre `escritor_humano_V3.exe`
3. El cuadro de arriba arranca siempre con un texto de ejemplo. Cámbialo si quieres y pulsa **Guardar** (o **Ctrl+S**). F8 escribe lo guardado en `texto.txt`, no lo que haya sin guardar en el cuadro.
4. Haz clic donde quieras que escriba y pulsa F8

Esa carpeta es el programa completo: el `.exe` y lo que necesita al lado. Cópiala donde quieras.

Cerrar la ventana no cierra el programa: se queda en la bandeja, junto al reloj. Un clic en el icono la vuelve a mostrar. Para salir del todo: clic derecho en el icono, **Salir**.

## Opciones

- **ms entre letras** y **variación**: número o la barrita (0–500)
- **Tropiezos / pausas / dudas**: casillas
- **Un tropiezo cada tantas letras**: también con barrita (8–500)
- **Por defecto** pone otra vez el texto de ejemplo en el cuadro

Los números y las casillas se guardan en `ajustes.ini` y se recuerdan al volver a abrir. El texto de ejemplo se vuelve a cargar cada vez que arrancas el programa; **Guardar** lo deja en `texto.txt` hasta que lo cierres.

## Archivos

| Archivo | Para qué |
|---|---|
| `dist/escritor_humano_V3/` | programa listo para usar |
| `escritor_humano_V3.ahk` | código fuente |
| `puente-navegador.ps1` | escritura en el navegador |
| `fijar-icono-aviso.ps1` | icono de los avisos de Windows |
| `texto.txt` / `ajustes.ini` | texto de ejemplo y velocidad |
| `build.ps1` | vuelve a generar la carpeta del `.exe` |
| `iniciar.bat` | abre el código fuente si tienes AutoHotkey v2 |

## Código fuente

Solo si quieres tocar el `.ahk` o recompilar hace falta [AutoHotkey v2](https://www.autohotkey.com/). Para usarlo del día a día, con el `.exe` basta.
