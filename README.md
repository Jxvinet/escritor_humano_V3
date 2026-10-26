# escritor_humano_V3

Programa para Windows que escribe texto letra a letra (como si lo teclearas tú).

No usa el portapapeles. Pulsa **F8** para empezar y **Escape** para parar.

Si haces clic en otra ventana mientras escribe, sigue en el cuadro donde empezó.

## Cómo usarlo

No hace falta instalar nada.

1. Entra en `dist/escritor_humano_V3/`
2. Abre `escritor_humano_V3.exe`
3. Cambia el texto si quieres y dale a Guardar
4. Haz clic donde quieras que escriba y pulsa F8

Esa carpeta es el programa completo: el `.exe` y lo que necesita al lado. Cópiala donde quieras y listo.

## Opciones

- **ms entre letras** y **variación**: número o la barrita (0–500)
- **Tropiezos / pausas / dudas**: casillas
- **Un tropiezo cada tantas letras**: también con barrita (8–500)
- **Ctrl+S** guarda
- **Por defecto** vuelve al texto de ejemplo

Se guardan en `ajustes.ini` y `texto.txt`.

## Archivos

| Archivo | Para qué |
|---|---|
| `dist/escritor_humano_V3/` | programa listo para usar |
| `escritor_humano_V3.ahk` | código fuente |
| `puente-navegador.ps1` | ayuda para el navegador |
| `texto.txt` / `ajustes.ini` | texto y velocidad |
| `build.ps1` | vuelve a generar la carpeta del `.exe` |

## Código fuente

Solo si quieres tocar el `.ahk` o recompilar hace falta [AutoHotkey v2](https://www.autohotkey.com/). Para usarlo del día a día, con el `.exe` basta.
