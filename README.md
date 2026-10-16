# escritor_humano_V3

Programa para Windows que escribe texto letra a letra (como si lo teclearas tú).

No usa el portapapeles. Pulsa **F8** para empezar y **Escape** para parar.

Si haces clic en otra ventana mientras escribe, sigue en el cuadro donde empezó.

## Cómo usarlo

### Con el .exe (lo más fácil)

1. Entra en `dist/escritor_humano_V3/`
2. Abre `escritor_humano_V3.exe`
3. Cambia el texto si quieres y dale a Guardar
4. Haz clic donde quieras que escriba y pulsa F8

### Con el código (.ahk)

Hace falta tener [AutoHotkey v2](https://www.autohotkey.com/) instalado.

- Doble clic en `iniciar.bat`, o
- Doble clic en `escritor_humano_V3.ahk`

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
| `escritor_humano_V3.ahk` | código |
| `puente-navegador.ps1` | ayuda para el navegador |
| `texto.txt` / `ajustes.ini` | texto y velocidad |
| `dist/escritor_humano_V3/` | carpeta del .exe (para usar sin instalar AutoHotkey) |
| `build.ps1` | vuelve a generar esa carpeta |

## Nota

Lo hice para uso local en mi PC. Si lo usas, es bajo tu responsabilidad.
