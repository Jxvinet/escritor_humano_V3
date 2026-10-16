# escritor_humano_V3

Programa para Windows que escribe texto letra a letra (como si lo teclearas tú).

No usa el portapapeles. Pulsa **F8** para empezar y **Escape** para parar.

Si haces clic en otra ventana mientras escribe, sigue en el cuadro donde empezó.

## Cómo usarlo

### Con el .exe (lo más fácil)

1. Entra en la carpeta `dist/escritor_humano_V3/`
2. Abre `escritor_humano_V3.exe`
3. Cambia el texto si quieres, dale a Guardar
4. Haz clic donde quieras que escriba y pulsa F8

También puedes descomprimir `dist/escritor_humano_V3-windows.zip` en cualquier sitio.

### Con el código (.ahk)

Hace falta tener [AutoHotkey v2](https://www.autohotkey.com/) instalado.

- Doble clic en `iniciar.bat`, o
- Doble clic en `escritor_humano_V3.ahk`

## Opciones de la ventana

- **ms entre letras** y **variación**: número o la barrita (0–500)
- **Tropiezos / pausas / dudas**: casillas para activarlos
- **Un tropiezo cada tantas letras**: también tiene barrita (8–500)
- **Ctrl+S** guarda
- **Por defecto** vuelve a poner el texto de ejemplo

Los valores se guardan en `ajustes.ini` y el texto en `texto.txt`.

## Archivos

| Archivo | Para qué |
|---|---|
| `escritor_humano_V3.ahk` | código principal |
| `puente-navegador.ps1` | para que funcione bien en Chrome y similares |
| `texto.txt` | el texto que escribe |
| `ajustes.ini` | velocidad y opciones |
| `dist/` | el .exe y el zip listos para usar |
| `build.ps1` | por si quieres volver a compilar el .exe |

## Nota

Lo hice para uso local en mi PC. Si lo usas, es bajo tu responsabilidad.
