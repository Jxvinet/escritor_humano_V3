#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Event"
SetKeyDelay 0, 1
Persistent(true)

; ============================================================
; TECLA QUE EMPIEZA A ESCRIBIR
; Cambia solo esta línea, guarda el archivo y, en el icono de la
; bandeja, clic derecho, Reload Script.
;
;   "F8"      F8
;   "F9"      F9
;   "^F8"     Ctrl+F8
;   "!q"      Alt+Q
;   "^!F8"    Ctrl+Alt+F8
;
; Si usas una tecla de un teclado Razer, en Synapse esa tecla
; solo tiene que enviar esta misma tecla. El texto no va en Synapse.
; ============================================================
global TECLA := "F8"

global CARPETA := A_ScriptDir
global ARCHIVO := CARPETA "\texto.txt"
global AJUSTES := CARPETA "\ajustes.ini"
global TEXTO_POR_DEFECTO := "Este es el texto por defecto para F8. Cámbialo si quieres, pulsa Guardar, haz clic en el cuadro donde deba escribirse y vuelve a pulsar F8. Escape cancela la escritura en cualquier momento."

global g := 0
global edTexto := 0
global edMs := 0
global edVar := 0
global sldMs := 0
global sldVar := 0
global chkPausas := 0
global chkErrores := 0
global chkDudas := 0
global edCada := 0
global sldCada := 0
global edPrueba := 0
global txtEstado := 0
global txtContador := 0
global escribiendo := false
global pendiente := false
global cancelar := false
global hwndDestino := 0
global ctrlDestino := 0
global posDestino := 0
global textoCargado := ""
global hPipeChrome := 0
global uiaActivo := false
global modoUia := false
global modoFijo := false
global forzarHwnd := 0
global costeEnvio := 0
global sincronizando := false

OnExit(AlSalir)

Iniciar()

Iniciar() {
    global g, edTexto, edMs, edVar, sldMs, sldVar, chkPausas, chkErrores, chkDudas, edCada, sldCada, edPrueba, txtEstado, txtContador
    PrepararAviso()
    if !DirExist(CARPETA)
        DirCreate(CARPETA)
    if !FileExist(AJUSTES)
        GuardarAjustes(120, 80, 1, 1, 100, 1)

    g := Gui(, "escritor_humano_V3")
    g.BackColor := "1E1E1E"
    g.MarginX := 22
    g.MarginY := 16
    g.SetFont("s10 cD4D4D4", "Segoe UI")
    g.OnEvent("Close", CerrarABandeja)

    g.SetFont("s9 cD4D4D4", "Segoe UI")
    g.AddText("xm", "escritor_humano_V3\texto.txt")
    g.SetFont("s9 c8A8A8A", "Segoe UI")
    g.AddText("x+14 yp+1", "Ctrl+S guarda")
    txtContador := g.AddText("x+14 yp w220 Right", "0 caracteres")

    g.SetFont("s10 cD4D4D4", "Segoe UI")
    edTexto := g.AddEdit("xm y+8 w700 h180 WantReturn VScroll")
    edTexto.OnEvent("Change", TextoCambio)

    g.SetFont("s10 cC8C8C8", "Segoe UI")
    g.AddText("xm y+14", "ms entre letras")
    edMs := g.AddEdit("xm y+4 w70 Number Limit3", "120")
    edMs.OnEvent("Change", EdMsCambio)
    sldMs := g.Add("Slider", "x+10 yp+2 w140 h18 Range0-500", 120)
    sldMs.OnEvent("Change", SldMsCambio)

    g.AddText("xm y+10", "ms de variación aleatoria")
    edVar := g.AddEdit("xm y+4 w70 Number Limit3", "80")
    edVar.OnEvent("Change", EdVarCambio)
    sldVar := g.Add("Slider", "x+10 yp+2 w140 h18 Range0-500", 80)
    sldVar.OnEvent("Change", SldVarCambio)

    chkPausas := g.AddCheckbox("xm y+12 Checked", "Pausas humanas en puntos, comas y espacios")
    chkErrores := g.AddCheckbox("xm y+8 Checked", "Tropiezos: a veces borra y vuelve a escribir")
    chkDudas := g.AddCheckbox("xm y+8 Checked", "Pausas de duda: a veces se para antes de una palabra")

    g.AddText("xm y+12", "Un tropiezo cada tantas letras (random)")
    edCada := g.AddEdit("xm y+4 w70 Number Limit5", "100")
    edCada.OnEvent("Change", EdCadaCambio)
    sldCada := g.Add("Slider", "x+10 yp+2 w140 h18 Range8-500", 100)
    sldCada.OnEvent("Change", SldCadaCambio)

    g.AddText("xm y+12", "Campo de prueba. F8.")
    edPrueba := g.AddEdit("xm y+6 w700 h78 WantReturn VScroll")

    btnGuardar := g.AddButton("xm y+16 w150 h34", "Guardar")
    btnGuardar.OnEvent("Click", Guardar)
    btnAbrir := g.AddButton("x+10 yp w150 h34", "Abrir texto.txt")
    btnAbrir.OnEvent("Click", AbrirTexto)
    btnRecargar := g.AddButton("x+10 yp w150 h34", "Recargar")
    btnRecargar.OnEvent("Click", RecargarArchivo)
    btnDefecto := g.AddButton("x+10 yp w150 h34", "Por defecto")
    btnDefecto.OnEvent("Click", RestaurarTextoPorDefecto)

    g.SetFont("s9 c9A9A9A", "Segoe UI")
    txtEstado := g.AddText("xm y+12 w520", "Iniciando...")
    g.SetFont("s8 c6A6A6A", "Segoe UI")
    g.AddText("x+8 yp+3", "by: javinet")
    picAyuda := g.Add("Picture", "x702 yp-4 w20 h20 BackgroundTrans", A_ScriptDir "\ayuda.png")
    picAyuda.OnEvent("Click", MostrarAyuda)

    for ctrl in [edTexto, edMs, edVar, edCada, edPrueba, chkPausas, chkErrores, chkDudas, btnGuardar, btnAbrir, btnRecargar, btnDefecto]
        DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    OnMessage(0x0133, PintarCaja)
    OnMessage(0x0138, PintarSiEsEdit)
    OnMessage(0x0114, BarraEnMovimiento)

    AplicarAjustesDesdeArchivo()
    CargarTextoPorDefecto()
    ConfigurarBandeja()
    HotIfWinActive("ahk_id " g.Hwnd)
    Hotkey("^s", GuardarConAtajo, "On")
    HotIf()

    nombreHotkey := TECLA
    if (SubStr(nombreHotkey, 1, 1) != "$")
        nombreHotkey := "$" nombreHotkey
    try Hotkey(nombreHotkey, AlPulsar, "On")
    catch as e {
        MsgBox("No se pudo registrar la tecla " TECLA ".`n`n" e.Message "`n`nEdita TECLA al principio de escritor_humano_V3.ahk", "escritor_humano_V3", "Icon!")
        ExitApp
    }

    ChromeLanzar()
    if (A_Args.Length >= 1 && A_Args[1] = "probar") {
        try FileDelete(A_Temp "\eh-probar-ya.txt")
        try FileDelete(A_Temp "\eh-probar-hecho.txt")
        SetTimer(EsperarOrdenDePrueba, -200)
    }

    pos := LeerPosicionVentana()
    if (pos.x != "" && pos.y != "")
        g.Show("x" pos.x " y" pos.y)
    else
        g.Show()
    ModoOscuro(g.Hwnd)
    PonerIcono(g.Hwnd)
    QuitarSeleccion(edTexto)
    ActualizarContador()
    ActualizarEstadoListo()
}

EsperarOrdenDePrueba() {
    global forzarHwnd
    destino := A_Temp "\eh-probar-ya.txt"
    hecho := A_Temp "\eh-probar-hecho.txt"
    forzarHwnd := 0
    loop 400 {
        if FileExist(destino) {
            txt := Trim(FileRead(destino, "UTF-8"))
            if IsInteger(txt)
                forzarHwnd := Integer(txt)
            break
        }
        Sleep(50)
    }
    try FileDelete(destino)
    EmpezarAEscribir()
    try FileAppend("ok", hecho, "UTF-8")
}

PrepararAviso() {
    id := "escritor.humano.V3.j3"
    DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "WStr", id)
    icono := A_ScriptDir "\icono-j.ico"
    lnkMenu := A_AppData "\Microsoft\Windows\Start Menu\Programs\escritor_humano_V3.lnk"
    lnkLocal := A_ScriptDir "\escritor_humano_V3.lnk"
    if A_IsCompiled {
        destino := A_ScriptFullPath
        args := ""
    } else {
        destino := A_AhkPath
        args := '"' A_ScriptFullPath '"'
    }
    try FileCreateShortcut(destino, lnkMenu, A_ScriptDir, args, "escritor_humano_V3", icono)
    try FileCreateShortcut(destino, lnkLocal, A_ScriptDir, args, "escritor_humano_V3", icono)
    ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    try RunWait('"' ps '" -NoProfile -ExecutionPolicy Bypass -File "' A_ScriptDir '\fijar-icono-aviso.ps1" "' lnkMenu '" "' id '"', , "Hide")
    try RunWait('"' ps '" -NoProfile -ExecutionPolicy Bypass -File "' A_ScriptDir '\fijar-icono-aviso.ps1" "' lnkLocal '" "' id '"', , "Hide")
}

PonerIcono(hwnd) {
    icono := A_ScriptDir "\icono-j.ico"
    if !FileExist(icono)
        return
    TraySetIcon(icono)
    grande := DllCall("LoadImage", "Ptr", 0, "Str", icono, "UInt", 1, "Int", 0, "Int", 0, "UInt", 0x10, "Ptr")
    pequeno := DllCall("LoadImage", "Ptr", 0, "Str", icono, "UInt", 1, "Int", 16, "Int", 16, "UInt", 0x10, "Ptr")
    if grande
        DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x80, "Ptr", 1, "Ptr", grande)
    if pequeno
        DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x80, "Ptr", 0, "Ptr", pequeno)
}

ModoOscuro(hwnd) {
    modo := 1
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Int*", modo, "Int", 4)
}

PintarSiEsEdit(wParam, lParam, *) {
    buf := Buffer(256)
    DllCall("GetClassName", "Ptr", lParam, "Ptr", buf, "Int", 128)
    if (StrGet(buf) != "Edit")
        return
    return PintarCaja(wParam)
}

PintarCaja(wParam, *) {
    static pincel := 0
    if !pincel
        pincel := DllCall("CreateSolidBrush", "UInt", 0x3C3C3C, "Ptr")
    DllCall("SetBkColor", "Ptr", wParam, "UInt", 0x3C3C3C)
    DllCall("SetTextColor", "Ptr", wParam, "UInt", 0xD4D4D4)
    return pincel
}

ConfigurarBandeja() {
    A_IconTip := "escritor_humano_V3`n" DescribirTecla(TECLA) " escribe`nEscape cancela`nCtrl+S guarda"
    try A_TrayMenu.Delete()
    catch {
    }
    A_TrayMenu.Add("Mostrar ventana", MostrarVentana)
    A_TrayMenu.Add("Guardar texto y ajustes", Guardar)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Salir", (*) => ExitApp())
    A_TrayMenu.Default := "Mostrar ventana"
    A_TrayMenu.ClickCount := 1
}

MostrarVentana(*) {
    g.Show()
    try WinActivate("ahk_id " g.Hwnd)
}

MostrarAyuda(*) {
    static ayuda := 0
    if IsObject(ayuda) {
        try {
            if WinExist(ayuda.Hwnd) {
                ayuda.Show()
                return
            }
        }
    }
    ayuda := Gui("+Owner" g.Hwnd, "Cómo funciona")
    ayuda.BackColor := "1E1E1E"
    ayuda.MarginX := 18
    ayuda.MarginY := 14
    ayuda.SetFont("s10 cD4D4D4", "Segoe UI")
    ayuda.OnEvent("Close", CerrarAyuda)
    edAyuda := ayuda.Add("Edit", "w560 h420 ReadOnly WantReturn VScroll", TextoDeAyuda())
    btnCerrar := ayuda.Add("Button", "xm y+12 w120 h32", "Cerrar")
    btnCerrar.OnEvent("Click", (*) => ayuda.Hide())
    DllCall("uxtheme\SetWindowTheme", "Ptr", edAyuda.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("uxtheme\SetWindowTheme", "Ptr", btnCerrar.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    ayuda.Show()
    ModoOscuro(ayuda.Hwnd)
    PonerIcono(ayuda.Hwnd)
    try DllCall("SendMessage", "Ptr", edAyuda.Hwnd, "UInt", 0xB1, "Ptr", 0, "Ptr", 0)
}

CerrarAyuda(guiAyuda) {
    guiAyuda.Hide()
    return true
}

TextoDeAyuda() {
    return "
    (
escritor_humano_V3 escribe letra a letra, como una persona. No pega y no usa el portapapeles.

CÓMO USARLO
1. Al abrir, el cuadro grande trae un texto por defecto en español. Cámbialo si quieres y pulsa Guardar.
   También puedes editar texto.txt (en la carpeta escritor_humano_V3) y pulsar Recargar archivo.
2. Haz clic donde quieras que aparezca el texto.
3. Pulsa F8.
4. Solo Escape lo para. Si haces clic en otra ventana, en otro cuadro, en el escritorio o en un navegador (Chrome u otro), sigue escribiendo en el recuadro donde empezó.

QUÉ ES CADA COSA

escritor_humano_V3\texto.txt
El archivo del que sale el texto al pulsar F8. Va junto al programa. Cada vez que abres la ventana, el cuadro grande arranca con el texto por defecto en español; Guardar lo deja fijo en el archivo.

ms entre letras
Pausa entre una letra y la siguiente, en milisegundos. Más alto = más lento. Puedes escribir el número o mover la barra (0 a 500).

ms de variación aleatoria
Cada letra espera un poco más o un poco menos, al azar. Con 120 de base y 80 de variación, cada letra cae entre 40 y 200 ms. Número o barra (0 a 500).

Pausas humanas
Añade tiempo después de un punto, una coma o un espacio, para que el ritmo no sea uniforme.

Tropiezos
De vez en cuando escribe una tecla de más o de al lado, borra con calma y deja otra vez la letra correcta. El texto final es el del archivo.

Pausas de duda
Al empezar, y a veces antes de una palabra, se detiene un poco más, como si pensara.

Un tropiezo cada tantas letras (random)
No es exacto. Si pones 100, el tropiezo puede caer pronto o al final de ese tramo. Un número más alto hace que tropiece menos. Número o barra (8 a 500). En un texto corto puede no haber ninguno.

Campo de prueba. F8.
Haz clic en ese cuadro y pulsa F8 para probar el ritmo. Si el cursor está en otro programa, F8 escribe allí.

Guardar / Ctrl+S
Guarda el cuadro grande y los números (también en ajustes.ini).

Abrir texto.txt
Abre el archivo con el Bloc de notas.

Recargar
Vuelve a poner en el cuadro lo que hay guardado en texto.txt.

Por defecto
Restablece el texto corto de ejemplo en español.

escritor_humano_V3.lnk / escritor_humano_V3.exe
Acceso directo con el icono de la J, o el ejecutable de la carpeta dist. No hace falta el .bat.

Cerrar la ventana no cierra el programa: sigue en la bandeja del reloj. Clic en el icono la muestra otra vez. Para salir del todo, clic derecho y Salir.

Si usas el código fuente (.ahk), la tecla está al principio del archivo, en global TECLA := "F8". Cámbiala, guarda y reinicia el programa.
    )"
}

CerrarABandeja(guiCerrada) {
    GuardarPosicionVentana()
    guiCerrada.Hide()
    TrayTip("Sigue en la bandeja. " DescribirTecla(TECLA) " escribe. Clic en el icono para volver.", "escritor_humano_V3", "Mute")
    return true
}

GuardarConAtajo(*) {
    if escribiendo
        return
    Guardar()
}

Guardar(*) {
    global textoCargado
    ms := NormalizarMs(edMs.Value, 120)
    vari := NormalizarMs(edVar.Value, 80)
    cada := NormalizarCada(edCada.Value)
    PonerMs(ms)
    PonerVar(vari)
    PonerCada(cada)
    try {
        GuardarTextoPlano(edTexto.Value)
        GuardarAjustes(ms, vari, chkPausas.Value, chkErrores.Value, cada, chkDudas.Value)
        GuardarPosicionVentana()
    } catch as e {
        txtEstado.Value := "No se pudo guardar: " e.Message
        return
    }
    textoCargado := edTexto.Value
    ActualizarContador()
    txtEstado.Value := "Guardado. " StrLen(edTexto.Value) " caracteres en texto.txt."
}

RestaurarTextoPorDefecto(*) {
    global textoCargado
    edTexto.Value := TEXTO_POR_DEFECTO
    textoCargado := TEXTO_POR_DEFECTO
    QuitarSeleccion(edTexto)
    ActualizarContador()
    txtEstado.Value := "Texto por defecto cargado. Pulsa Guardar si quieres fijarlo en texto.txt."
}

TextoCambio(*) {
    ActualizarContador()
}

ActualizarContador() {
    global txtContador, edTexto
    if !IsObject(txtContador)
        return
    n := StrLen(edTexto.Value)
    txtContador.Value := n " caracteres"
}

AbrirTexto(*) {
    try Run('notepad.exe "' ARCHIVO '"')
    catch
        Run(ARCHIVO)
}

RecargarArchivo(*) {
    try CargarTextoEnCuadro()
    catch as e {
        txtEstado.Value := "No se pudo leer texto.txt: " e.Message
        return
    }
    ActualizarContador()
    ActualizarEstadoListo()
}

AlPulsar(*) {
    global pendiente, escribiendo
    if (escribiendo || pendiente)
        return
    pendiente := true
    SetTimer(EmpezarAEscribir, -40)
}

EmpezarAEscribir() {
    global pendiente, escribiendo, cancelar, hwndDestino, ctrlDestino, posDestino, uiaActivo, modoUia, modoFijo, costeEnvio, forzarHwnd
    pendiente := false
    if escribiendo
        return

    k := TeclaFisica(TECLA)
    if (k != "")
        KeyWait(k, "T0.5")

    if (!forzarHwnd && WinActive(g.Hwnd) && !edPrueba.Focused) {
        TrayTip("Haz clic en el campo de prueba, o en el otro programa, y pulsa " DescribirTecla(TECLA) " otra vez.", "escritor_humano_V3", "Mute")
        txtEstado.Value := "El cursor sigue en esta ventana. Elige el destino y pulsa " DescribirTecla(TECLA) "."
        return
    }

    ms := NormalizarMs(edMs.Value, 120)
    vari := NormalizarMs(edVar.Value, 80)
    humano := chkPausas.Value
    errores := chkErrores.Value
    dudas := chkDudas.Value
    cada := NormalizarCada(edCada.Value)
    PonerMs(ms)
    PonerVar(vari)
    PonerCada(cada)
    try GuardarAjustes(ms, vari, humano, errores, cada, dudas)
    catch {
    }

    try texto := LeerTexto()
    catch as e {
        TrayTip(e.Message, "escritor_humano_V3", "Mute")
        txtEstado.Value := "No se pudo leer texto.txt."
        return
    }
    if (texto = "") {
        TrayTip("texto.txt está vacío.", "escritor_humano_V3", "Mute")
        txtEstado.Value := "texto.txt está vacío."
        return
    }

    avisarSinGuardar := (edTexto.Value != textoCargado)
    if (forzarHwnd) {
        hwndDestino := forzarHwnd
        ctrlDestino := forzarHwnd
        forzarHwnd := 0
    } else {
        hwndDestino := WinExist("A")
        ctrlDestino := ControlGetFocus("A")
        if !ctrlDestino
            ctrlDestino := hwndDestino
    }
    posDestino := 0
    RecordarPosicion()
    modoUia := false
    modoFijo := false
    uiaActivo := false
    costeEnvio := 0
    if !EsCajaDeTexto(ctrlDestino)
        uiaActivo := UiaBind(hwndDestino, ctrlDestino)
    if (EsVentanaNavegador(hwndDestino) && !uiaActivo)
        txtEstado.Value := "Este cuadro del navegador no se pudo enganchar. Si cambias de sitio, puede que no siga."
    if avisarSinGuardar
        TrayTip("Hay cambios sin guardar en la ventana. Se escribe el archivo texto.txt.", "escritor_humano_V3", "Mute")

    escribiendo := true
    cancelar := false
    motivo := "ok"
    detalleError := ""
    try {
        if !DormirCancelable(30) {
            motivo := "escape"
        } else {
            i := 1
            largo := StrLen(texto)
            recientes := ""
            esperaTropiezo := 0
            esperaDuda := Random(1, 4)
            acaboDeTropezar := false
            if errores
                esperaTropiezo := NuevaEspera(cada, true)
            if (dudas && !DormirCancelable(PausaDeArranque(ms))) {
                motivo := "escape"
            } else
            while (i <= largo) {
                if (CancelacionPulsada() || cancelar) {
                    motivo := "escape"
                    break
                }
                ch := SubStr(texto, i, 1)
                avance := 1
                enviado := ch
                if (ch = "`r" || ch = "`n") {
                    enviado := "`n"
                    recientes := ""
                    EnviarCaracter("`n")
                    if (ch = "`r" && SubStr(texto, i + 1, 1) = "`n")
                        avance := 2
                } else {
                    elegible := errores && esperaTropiezo <= 0 && (EsBorrable(ch) || StrLen(recientes) >= 3)
                    if elegible {
                        r := Tropiezo(ch, recientes, ms, hwndDestino)
                        recientes := r[2]
                        if (r[1] = "nada") {
                            EnviarCaracter(ch)
                            recientes := AnadirReciente(recientes, ch)
                        } else if (r[1] != "ok") {
                            motivo := r[1]
                            break
                        } else {
                            esperaTropiezo := NuevaEspera(cada)
                            acaboDeTropezar := true
                        }
                    } else {
                        EnviarCaracter(ch)
                        recientes := AnadirReciente(recientes, ch)
                        if (errores && esperaTropiezo > 0)
                            esperaTropiezo--
                    }
                }
                i += avance
                if (i <= largo) {
                    pausa := PausaDe(enviado, ms, vari, humano)
                    if acaboDeTropezar {
                        pausa += Round(ms * 0.7) + Random(50, 160)
                        acaboDeTropezar := false
                    }
                    if (dudas && (enviado = " " || enviado = "`n" || enviado = Chr(160))) {
                        if (esperaDuda <= 0) {
                            pausa += PausaDeDuda(ms)
                            esperaDuda := Random(6, 13)
                        } else {
                            esperaDuda--
                        }
                    }
                    if !DormirTrasLetra(pausa) {
                        motivo := "escape"
                        break
                    }
                }
            }
        }
    } catch as e {
        motivo := "error"
        detalleError := e.Message
    } finally {
        escribiendo := false
        cancelar := false
        pendiente := false
    }

    if (motivo = "escape") {
        txtEstado.Value := "Cancelado con Escape."
        TrayTip("Escritura cancelada.", "escritor_humano_V3", "Mute")
    } else if (motivo = "ventana") {
        txtEstado.Value := "Se paró porque cambió la ventana activa."
        TrayTip("Se paró porque cambió la ventana activa. Pulsa " DescribirTecla(TECLA) " para empezar de nuevo.", "escritor_humano_V3", "Mute")
    } else if (motivo = "error") {
        txtEstado.Value := "Error al escribir: " detalleError
        TrayTip(detalleError, "escritor_humano_V3", "Mute")
    } else {
        txtEstado.Value := "Listo. Se escribió el contenido de texto.txt."
    }

    if (edTexto.Value = textoCargado) {
        try CargarTextoEnCuadro()
    }
}

EsBorrable(ch) {
    return RegExMatch(ch, "^[0-9A-Za-zÁÉÍÓÚÜÑáéíóúüñ]$")
}

TeclaVecina(ch) {
    mayus := false
    letra := ch
    if RegExMatch(ch, "^[A-Z]$") {
        mayus := true
        letra := Chr(Ord(ch) + 32)
    }
    grupo := ""
    if (letra = "a")
        grupo := "sqzw"
    else if (letra = "b")
        grupo := "vngh"
    else if (letra = "c")
        grupo := "xvdf"
    else if (letra = "d")
        grupo := "sfercx"
    else if (letra = "e")
        grupo := "wrsd"
    else if (letra = "f")
        grupo := "dgrtcv"
    else if (letra = "g")
        grupo := "fhtybv"
    else if (letra = "h")
        grupo := "gjyunb"
    else if (letra = "i")
        grupo := "uokj"
    else if (letra = "j")
        grupo := "hkuinm"
    else if (letra = "k")
        grupo := "jliom"
    else if (letra = "l")
        grupo := "kop"
    else if (letra = "m")
        grupo := "njk"
    else if (letra = "n")
        grupo := "bmhj"
    else if (letra = "o")
        grupo := "iplk"
    else if (letra = "p")
        grupo := "ol"
    else if (letra = "q")
        grupo := "was"
    else if (letra = "r")
        grupo := "etdf"
    else if (letra = "s")
        grupo := "adwezx"
    else if (letra = "t")
        grupo := "ryfg"
    else if (letra = "u")
        grupo := "yihj"
    else if (letra = "v")
        grupo := "cbfg"
    else if (letra = "w")
        grupo := "qeas"
    else if (letra = "x")
        grupo := "zcsd"
    else if (letra = "y")
        grupo := "tugh"
    else if (letra = "z")
        grupo := "asx"
    if (grupo = "")
        return ""
    malo := SubStr(grupo, Random(1, StrLen(grupo)), 1)
    if mayus
        malo := Chr(Ord(malo) - 32)
    return malo
}

AnadirReciente(recientes, ch) {
    if !EsBorrable(ch)
        return ""
    recientes .= ch
    if (StrLen(recientes) > 16)
        recientes := SubStr(recientes, -16)
    return recientes
}

MirarDestino(hwndDestino) {
    global cancelar
    if (CancelacionPulsada() || cancelar)
        return "escape"
    return "ok"
}

PausaControlada(ms, hwndDestino) {
    if !DormirTrasLetra(ms)
        return "escape"
    return MirarDestino(hwndDestino)
}

SigueEnElRecuadro() {
    global hwndDestino, ctrlDestino
    if (WinExist("A") != hwndDestino)
        return false
    if !ctrlDestino || (ctrlDestino = hwndDestino)
        return true
    actual := ControlGetFocus("A")
    return actual = ctrlDestino
}

EnviarCaracter(ch) {
    global uiaActivo, costeEnvio, hwndDestino
    t0 := A_TickCount
    if (uiaActivo) {
        UiaTecla(ch)
        costeEnvio := A_TickCount - t0
        return
    }
    if EsVentanaNavegador(hwndDestino) {
        costeEnvio := A_TickCount - t0
        return
    }
    if SigueEnElRecuadro() {
        try {
            if (ch = "`n" || ch = "`r")
                SendEvent("{Enter}")
            else
                SendEvent("{Text}" ch)
        }
        RecordarPosicion()
        costeEnvio := A_TickCount - t0
        return
    }
    EnviarAlRecuadroOriginal(ch)
    costeEnvio := A_TickCount - t0
}

EnviarRetroceso() {
    global uiaActivo, costeEnvio, hwndDestino
    t0 := A_TickCount
    if (uiaActivo) {
        UiaTecla("`b")
        costeEnvio := A_TickCount - t0
        return
    }
    if EsVentanaNavegador(hwndDestino) {
        costeEnvio := A_TickCount - t0
        return
    }
    if SigueEnElRecuadro() {
        try SendEvent("{Backspace}")
        RecordarPosicion()
        costeEnvio := A_TickCount - t0
        return
    }
    EnviarAlRecuadroOriginal("`b")
    costeEnvio := A_TickCount - t0
}

CapturaTeclado() {
    global hwndDestino
    hwnd := WinExist("A")
    if !hwnd || (hwnd = hwndDestino)
        return false
    try clase := WinGetClass("ahk_id " hwnd)
    catch
        clase := ""
    if (SubStr(clase, 1, 4) = "eter")
        return true
    try nombre := StrLower(WinGetProcessName("ahk_id " hwnd))
    catch
        return false
    return InStr(nombre, "metin2")
}

SigueAqui() {
    global uiaActivo
    if !SigueEnElRecuadro()
        return false
    if !uiaActivo
        return true
    return UiaMismo()
}

EsVentanaNavegador(hwnd) {
    try clase := WinGetClass("ahk_id " hwnd)
    catch
        return false
    return InStr(clase, "Chrome_WidgetWin") || InStr(clase, "Mozilla") || InStr(clase, "ApplicationFrameWindow")
}

ChromeLanzar() {
    ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    Run('"' ps '" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' A_ScriptDir '\puente-navegador.ps1"', , "Hide")
}

ChromeSoltar() {
    global hPipeChrome
    if hPipeChrome {
        DllCall("CloseHandle", "Ptr", hPipeChrome)
        hPipeChrome := 0
    }
}

ChromeAsegurar() {
    global hPipeChrome
    if hPipeChrome
        return true
    loop 40 {
        h := DllCall("CreateFileW", "Str", "\\.\pipe\escritor_humano_v3_chrome", "UInt", 0xC0000000, "UInt", 0, "Ptr", 0, "UInt", 3, "UInt", 0, "Ptr", 0, "Ptr")
        if (h != -1 && h != 0) {
            hPipeChrome := h
            return true
        }
        if (A_Index = 1)
            ChromeLanzar()
        Sleep(50)
    }
    return false
}

ChromeEscribir(linea) {
    global hPipeChrome
    if !hPipeChrome
        return false
    linea .= "`n"
    n := StrPut(linea, "UTF-8") - 1
    if (n < 1)
        return false
    buf := Buffer(n + 1)
    StrPut(linea, buf, "UTF-8")
    escrito := 0
    ok := DllCall("WriteFile", "Ptr", hPipeChrome, "Ptr", buf, "UInt", n, "UInt*", &escrito, "Ptr", 0)
    if !ok {
        ChromeSoltar()
        return false
    }
    return true
}

ChromeLeerLinea() {
    global hPipeChrome, cancelar
    if !hPipeChrome
        return ""
    buf := Buffer(8192)
    n := 0
    inicio := A_TickCount
    loop {
        if (cancelar || CancelacionPulsada())
            return ""
        disp := 0
        if !DllCall("PeekNamedPipe", "Ptr", hPipeChrome, "Ptr", 0, "UInt", 0, "Ptr", 0, "UInt*", &disp, "Ptr", 0) {
            ChromeSoltar()
            return ""
        }
        if (disp > 0) {
            leido := 0
            uno := Buffer(1)
            if !DllCall("ReadFile", "Ptr", hPipeChrome, "Ptr", uno, "UInt", 1, "UInt*", &leido, "Ptr", 0) {
                ChromeSoltar()
                return ""
            }
            if (leido != 1)
                continue
            c := NumGet(uno, 0, "UChar")
            if (c = 10)
                break
            if (c != 13 && n < 8000) {
                NumPut("UChar", c, buf, n)
                n++
            }
        } else if (A_TickCount - inicio > 3000) {
            ChromeSoltar()
            return ""
        } else {
            Sleep(5)
        }
    }
    if (n < 1)
        return ""
    return StrGet(buf, n, "UTF-8")
}

ChromeRpc(cmd) {
    if !ChromeAsegurar()
        return ""
    if !ChromeEscribir(cmd)
        return ""
    return ChromeLeerLinea()
}

EscaparJson(s) {
    q := Chr(34)
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, q, "\" q)
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`t", "\t")
    return s
}

JsonCampo(nombre, valor, texto := false) {
    q := Chr(34)
    if texto
        return q . nombre . q . ":" . q . valor . q
    return q . nombre . q . ":" . valor
}

LineaCmd(cmd, extra := "") {
    q := Chr(34)
    s := "{" . JsonCampo("cmd", cmd, true)
    if (extra != "")
        s .= "," . extra
    return s . "}"
}

RespuestaOk(resp) {
    return InStr(resp, Chr(34) . "ok" . Chr(34) . ":true")
}

UiaBind(hwnd, ctrl) {
    if !hwnd
        hwnd := 0
    if !ctrl
        ctrl := 0
    resp := ChromeRpc(LineaCmd("bind", JsonCampo("hwnd", hwnd) . "," . JsonCampo("ctrl", ctrl)))
    return RespuestaOk(resp)
}

UiaMismo() {
    resp := ChromeRpc(LineaCmd("mismo"))
    if (resp = "")
        return true
    return InStr(resp, Chr(34) . "mismo" . Chr(34) . ":true")
}

UiaFoto() {
    return RespuestaOk(ChromeRpc(LineaCmd("foto")))
}

UiaNota(ch) {
    if (ch = "`b")
        resp := ChromeRpc(LineaCmd("nota", JsonCampo("bs", "true")))
    else
        resp := ChromeRpc(LineaCmd("nota", JsonCampo("t", EscaparJson(ch), true)))
    return RespuestaOk(resp)
}

UiaInsertar(ch) {
    if (ch = "`n" || ch = "`r")
        ch := "`n"
    resp := ChromeRpc(LineaCmd("ins", JsonCampo("t", EscaparJson(ch), true)))
    return RespuestaOk(resp)
}

UiaBorrar() {
    return RespuestaOk(ChromeRpc(LineaCmd("ins", JsonCampo("bs", "true"))))
}

UiaTecla(ch) {
    if (ch = "`b")
        return RespuestaOk(ChromeRpc(LineaCmd("tecla", JsonCampo("bs", "true"))))
    if (ch = "`n" || ch = "`r")
        ch := "`n"
    return RespuestaOk(ChromeRpc(LineaCmd("tecla", JsonCampo("t", EscaparJson(ch), true))))
}

UiaEnfocar() {
    return RespuestaOk(ChromeRpc(LineaCmd("enfocar")))
}

AlSalir(*) {
    global hPipeChrome
    try GuardarPosicionVentana()
    if !hPipeChrome {
        h := DllCall("CreateFileW", "Str", "\\.\pipe\escritor_humano_v3_chrome", "UInt", 0xC0000000, "UInt", 0, "Ptr", 0, "UInt", 3, "UInt", 0, "Ptr", 0, "Ptr")
        if (h = -1 || h = 0)
            return
        hPipeChrome := h
    }
    ChromeEscribir(LineaCmd("salir"))
    Sleep(40)
    ChromeSoltar()
}

EsCajaDeTexto(hwnd) {
    try clase := WinGetClass("ahk_id " hwnd)
    catch
        return false
    return InStr(clase, "Edit") || InStr(clase, "RICHEDIT")
}

RecordarPosicion() {
    global posDestino, ctrlDestino
    if !EsCajaDeTexto(ctrlDestino)
        return
    inicio := Buffer(4, 0)
    fin := Buffer(4, 0)
    DllCall("SendMessage", "Ptr", ctrlDestino, "UInt", 0x00B0, "Ptr", inicio.Ptr, "Ptr", fin.Ptr)
    posDestino := NumGet(fin, 0, "UInt")
}

EnviarAlRecuadroOriginal(ch) {
    global posDestino, ctrlDestino
    if !ctrlDestino
        return
    if EsCajaDeTexto(ctrlDestino) {
        if (ch = "`b") {
            if (posDestino > 0)
                posDestino--
            DllCall("SendMessage", "Ptr", ctrlDestino, "UInt", 0x00B1, "Ptr", posDestino, "Ptr", posDestino + 1)
            vacio := Buffer(2, 0)
            DllCall("SendMessage", "Ptr", ctrlDestino, "UInt", 0x00C2, "Ptr", 1, "Ptr", vacio.Ptr)
            return
        }
        texto := (ch = "`n" || ch = "`r") ? "`r`n" : ch
        DllCall("SendMessage", "Ptr", ctrlDestino, "UInt", 0x00B1, "Ptr", posDestino, "Ptr", posDestino)
        buf := Buffer(StrPut(texto, "UTF-16"))
        StrPut(texto, buf, "UTF-16")
        DllCall("SendMessage", "Ptr", ctrlDestino, "UInt", 0x00C2, "Ptr", 1, "Ptr", buf.Ptr)
        posDestino += StrLen(texto)
        return
    }
    try clase := WinGetClass("ahk_id " ctrlDestino)
    catch
        return
    if (InStr(clase, "Chrome") || InStr(clase, "Mozilla"))
        return
    if (ch = "`b")
        codigo := 8
    else if (ch = "`n" || ch = "`r")
        codigo := 13
    else
        codigo := Ord(ch)
    DllCall("PostMessage", "Ptr", ctrlDestino, "UInt", 0x0102, "Ptr", codigo, "Ptr", 0)
}

RetrocesoEnCaja(hwnd) {
    inicio := Buffer(4, 0)
    fin := Buffer(4, 0)
    DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x00B0, "Ptr", inicio.Ptr, "Ptr", fin.Ptr)
    a := NumGet(inicio, 0, "UInt")
    b := NumGet(fin, 0, "UInt")
    if (a = 0 && b = 0)
        return
    if (a = b && a > 0)
        a--
    DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x00B1, "Ptr", a, "Ptr", b)
    vacio := Buffer(2, 0)
    DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x00C2, "Ptr", 1, "Ptr", vacio.Ptr)
}

PausaEntreRetrocesos(ms, primero := false) {
    if primero
        d := Round(ms * 0.9) + Random(70, 160)
    else
        d := Round(ms * 0.72) + Random(45, 110)
    if (d < 45)
        d := 45
    return d
}

PausaAlReescribir(ms) {
    base := ms
    if (base < 40)
        base := 40
    d := base + Random(-Round(base * 0.2), Round(base * 0.25))
    suelo := Round(base * 0.7)
    if (d < suelo)
        d := suelo
    return d
}

PausaDarseCuenta(ms) {
    return Round(ms * 1.15) + Random(110, 280)
}

PausaTrasBorrar(ms) {
    return Round(ms * 0.9) + Random(90, 240)
}

PausaDeArranque(ms) {
    return Round(ms * 1.2) + Random(80, 240)
}

PausaDeDuda(ms) {
    d := Round(ms * 2.8) + Random(280, 720)
    if (Random(1, 8) = 1)
        d += Random(400, 900)
    return d
}

NuevaEspera(cada, primera := false) {
    if primera {
        bajo := Round(cada * 0.2)
        alto := cada * 2
    } else {
        bajo := Round(cada * 0.55)
        alto := Round(cada * 1.45)
    }
    if (bajo < 0)
        bajo := 0
    if (alto < bajo)
        alto := bajo
    return Random(bajo, alto)
}

ReescribirTrozo(trozo, ms, hwndDestino) {
    loop parse trozo {
        EnviarCaracter(A_LoopField)
        if (A_Index < StrLen(trozo)) {
            est := PausaControlada(PausaAlReescribir(ms), hwndDestino)
            if (est != "ok")
                return est
        }
    }
    return MirarDestino(hwndDestino)
}

; Borra algo de lo ya escrito, espera, y deja otra vez el texto correcto.
; El archivo no cambia: el tropiezo se corrige solo.
Tropiezo(ch, recientes, ms, hwndDestino) {
    est := "ok"
    tiene := StrLen(recientes) >= 3
    vecino := TeclaVecina(ch)
    dado := Random(1, 10)
    tipo := ""
    if (tiene && dado <= 4)
        tipo := "trozo"
    else if (vecino != "" && dado <= 8)
        tipo := "vecino"
    else if EsBorrable(ch)
        tipo := "repite"
    else if tiene
        tipo := "trozo"
    if (tipo = "")
        return ["nada", recientes]

    if (tipo = "trozo") {
        n := StrLen(recientes)
        if (dado = 1)
            n := Min(n, 5)
        else
            n := Random(2, Min(3, n))
        trozo := SubStr(recientes, -n)
        loop n {
            EnviarRetroceso()
            est := PausaControlada(PausaEntreRetrocesos(ms, A_Index = 1), hwndDestino)
            if (est != "ok")
                return [est, recientes]
        }
        est := PausaControlada(PausaDarseCuenta(ms), hwndDestino)
        if (est != "ok")
            return [est, SubStr(recientes, 1, StrLen(recientes) - n)]
        est := ReescribirTrozo(trozo, ms, hwndDestino)
        if (est != "ok")
            return [est, recientes]
    } else if (tipo = "vecino") {
        EnviarCaracter(vecino)
        est := PausaControlada(PausaDarseCuenta(ms), hwndDestino)
        if (est != "ok")
            return [est, recientes]
        EnviarRetroceso()
        est := PausaControlada(PausaTrasBorrar(ms), hwndDestino)
        if (est != "ok")
            return [est, recientes]
    } else {
        EnviarCaracter(ch)
        est := PausaControlada(PausaDarseCuenta(ms), hwndDestino)
        if (est != "ok")
            return [est, AnadirReciente(recientes, ch)]
        EnviarRetroceso()
        est := PausaControlada(PausaTrasBorrar(ms), hwndDestino)
        if (est != "ok")
            return [est, recientes]
    }

    EnviarCaracter(ch)
    return [MirarDestino(hwndDestino), AnadirReciente(recientes, ch)]
}

; Pausa entre letras, en milisegundos.
; El valor que pongas no tiene un tope bajo: 50, 80, 120, 200 o más.
; La variación se suma o se resta al azar. Las pausas humanas son extra.
PausaDe(ch, ms, vari, humano) {
    if (vari > 0)
        d := ms + Random(-vari, vari)
    else
        d := ms
    if (d < 0)
        d := 0
    if !humano
        return Integer(d)
    if (ch = "." || ch = "!" || ch = "?" || ch = "…")
        d += Round(ms * 2.5) + Random(40, 159)
    else if (ch = ",")
        d += Round(ms * 1.2) + Random(20, 89)
    else if (ch = " " || ch = Chr(160))
        d += Round(ms * 0.4) + Random(10, 44)
    else if (ch = "`n")
        d += Round(ms * 2) + Random(20, 80)
    return Integer(d)
}

CancelacionPulsada() {
    return GetKeyState("Escape", "P") || GetKeyState("Escape")
}

DormirTrasLetra(ms) {
    global costeEnvio
    coste := costeEnvio
    costeEnvio := 0
    if (coste > 0) {
        if (coste >= ms)
            ms := 0
        else
            ms -= coste
    }
    return DormirCancelable(ms)
}

DormirCancelable(ms) {
    global cancelar
    if (ms < 0)
        ms := 0
    fin := A_TickCount + ms
    loop {
        if (cancelar || CancelacionPulsada()) {
            cancelar := true
            return false
        }
        resta := fin - A_TickCount
        if (resta <= 0)
            return true
        Sleep(Min(30, resta))
    }
}

NormalizarEntero(valor, defecto) {
    valor := Trim(valor)
    if !IsInteger(valor)
        return defecto
    n := Integer(valor)
    if (n < 0)
        n := 0
    if (n > 120000)
        n := 120000
    return n
}

NormalizarMs(valor, defecto) {
    valor := Trim(valor)
    if !IsInteger(valor)
        return defecto
    n := Integer(valor)
    if (n < 0)
        n := 0
    if (n > 500)
        n := 500
    return n
}

NormalizarCada(valor) {
    n := NormalizarEntero(valor, 100)
    if (n < 8)
        n := 8
    if (n > 500)
        n := 500
    return n
}

LeerTexto() {
    if !FileExist(ARCHIVO)
        return ""
    return QuitarSaltoFinal(FileRead(ARCHIVO, "UTF-8"))
}

QuitarSaltoFinal(txt) {
    if (txt = "")
        return ""
    n := StrLen(txt)
    if (n >= 2 && SubStr(txt, n - 1, 1) = "`r" && SubStr(txt, n, 1) = "`n")
        return SubStr(txt, 1, n - 2)
    ult := SubStr(txt, n, 1)
    if (ult = "`n" || ult = "`r")
        return SubStr(txt, 1, n - 1)
    return txt
}

CargarTextoEnCuadro() {
    global textoCargado
    edTexto.Value := LeerTexto()
    textoCargado := edTexto.Value
    QuitarSeleccion(edTexto)
}

QuitarSeleccion(ctrl) {
    try DllCall("SendMessage", "Ptr", ctrl.Hwnd, "UInt", 0xB1, "Ptr", 0, "Ptr", 0)
}

GuardarTextoPlano(txt) {
    txt := StrReplace(txt, "`r`n", "`n")
    txt := StrReplace(txt, "`r", "`n")
    txt := StrReplace(txt, "`n", "`r`n")
    f := FileOpen(ARCHIVO, "w", "UTF-8")
    if !f
        throw Error("No se pudo abrir texto.txt para guardar.")
    f.Write(txt)
    f.Close()
}

AplicarAjustesDesdeArchivo() {
    ms := 120
    vari := 80
    pausas := 1
    errores := 1
    cada := 100
    dudas := 1
    try {
        if FileExist(AJUSTES) {
            contenido := FileRead(AJUSTES, "UTF-8")
            loop parse contenido, "`n", "`r" {
                linea := Trim(A_LoopField)
                if (linea = "" || SubStr(linea, 1, 1) = ";")
                    continue
                if RegExMatch(linea, "i)^ms\s*=\s*(\d+)\s*$", &m)
                    ms := NormalizarMs(m[1], 120)
                else if RegExMatch(linea, "i)^variacion\s*=\s*(\d+)\s*$", &m)
                    vari := NormalizarMs(m[1], 80)
                else if RegExMatch(linea, "i)^pausas\s*=\s*([01])\s*$", &m)
                    pausas := (m[1] = "1") ? 1 : 0
                else if RegExMatch(linea, "i)^errores\s*=\s*([01])\s*$", &m)
                    errores := (m[1] = "1") ? 1 : 0
                else if RegExMatch(linea, "i)^cada\s*=\s*(\d+)\s*$", &m)
                    cada := NormalizarCada(m[1])
                else if RegExMatch(linea, "i)^dudas\s*=\s*([01])\s*$", &m)
                    dudas := (m[1] = "1") ? 1 : 0
            }
        }
    } catch {
        ms := 120
        vari := 80
        pausas := 1
        errores := 1
        cada := 100
        dudas := 1
    }
    PonerMs(ms)
    PonerVar(vari)
    chkPausas.Value := pausas
    chkErrores.Value := errores
    PonerCada(cada)
    chkDudas.Value := dudas
}

GuardarAjustes(ms, vari, pausas, errores, cada, dudas) {
    txt := ""
    txt .= "; Milisegundos entre letras. Mas alto = mas lento.`r`n"
    txt .= "; Vale de 0 a 500. Tambien se elige con la barra.`r`n"
    txt .= "ms=" ms "`r`n"
    txt .= "; Variacion aleatoria en milisegundos (se suma o se resta).`r`n"
    txt .= "variacion=" vari "`r`n"
    txt .= "; Pausas extra en punto, coma y espacio: 1 = si, 0 = no.`r`n"
    txt .= "pausas=" (pausas ? "1" : "0") "`r`n"
    txt .= "; Tropiezos que se corrigen solos: 1 = si, 0 = no.`r`n"
    txt .= "errores=" (errores ? "1" : "0") "`r`n"
    txt .= "; De media, un tropiezo cada estas letras. Mas alto = menos tropiezos.`r`n"
    txt .= "cada=" cada "`r`n"
    txt .= "; Pausa larga antes de algunas palabras: 1 = si, 0 = no.`r`n"
    txt .= "dudas=" (dudas ? "1" : "0") "`r`n"
    f := FileOpen(AJUSTES, "w", "UTF-8")
    if !f
        throw Error("No se pudo guardar ajustes.ini.")
    f.Write(txt)
    f.Close()
}

LeerPosicionVentana() {
    out := {x: "", y: ""}
    ruta := CARPETA "\ventana.ini"
    try {
        if !FileExist(ruta)
            return out
        x := IniRead(ruta, "ventana", "x", "")
        y := IniRead(ruta, "ventana", "y", "")
        if (x != "" && y != "" && IsInteger(x) && IsInteger(y)) {
            out.x := Integer(x)
            out.y := Integer(y)
        }
    } catch {
    }
    return out
}

GuardarPosicionVentana() {
    global g
    if !IsObject(g)
        return
    try {
        g.GetPos(&x, &y)
        ruta := CARPETA "\ventana.ini"
        IniWrite(x, ruta, "ventana", "x")
        IniWrite(y, ruta, "ventana", "y")
    } catch {
    }
}

CargarTextoPorDefecto() {
    global textoCargado
    try GuardarTextoPlano(TEXTO_POR_DEFECTO)
    catch {
    }
    edTexto.Value := TEXTO_POR_DEFECTO
    textoCargado := TEXTO_POR_DEFECTO
    QuitarSeleccion(edTexto)
}

BarraEnMovimiento(wParam, lParam, msg, hwnd) {
    global sldMs, sldVar, sldCada, sincronizando
    if !IsObject(sldMs) || !IsObject(sldVar) || !IsObject(sldCada)
        return
    if (lParam != sldMs.Hwnd && lParam != sldVar.Hwnd && lParam != sldCada.Hwnd)
        return
    if sincronizando
        return
    n := DllCall("SendMessage", "Ptr", lParam, "UInt", 0x0400, "Ptr", 0, "Ptr", 0, "Ptr")
    sincronizando := true
    if (lParam = sldMs.Hwnd)
        edMs.Value := n
    else if (lParam = sldVar.Hwnd)
        edVar.Value := n
    else
        edCada.Value := n
    sincronizando := false
}

SldMsCambio(*) {
    global sincronizando
    if sincronizando
        return
    sincronizando := true
    edMs.Value := sldMs.Value
    sincronizando := false
}

EdMsCambio(*) {
    global sincronizando
    if sincronizando
        return
    if (Trim(edMs.Value) = "")
        return
    if !IsInteger(edMs.Value)
        return
    n := NormalizarMs(edMs.Value, 120)
    sincronizando := true
    sldMs.Value := n
    if (Integer(edMs.Value) != n)
        edMs.Value := n
    sincronizando := false
}

SldVarCambio(*) {
    global sincronizando
    if sincronizando
        return
    sincronizando := true
    edVar.Value := sldVar.Value
    sincronizando := false
}

EdVarCambio(*) {
    global sincronizando
    if sincronizando
        return
    if (Trim(edVar.Value) = "")
        return
    if !IsInteger(edVar.Value)
        return
    n := NormalizarMs(edVar.Value, 80)
    sincronizando := true
    sldVar.Value := n
    if (Integer(edVar.Value) != n)
        edVar.Value := n
    sincronizando := false
}

SldCadaCambio(*) {
    global sincronizando
    if sincronizando
        return
    sincronizando := true
    edCada.Value := sldCada.Value
    sincronizando := false
}

EdCadaCambio(*) {
    global sincronizando
    if sincronizando
        return
    if (Trim(edCada.Value) = "")
        return
    if !IsInteger(edCada.Value)
        return
    n := NormalizarCada(edCada.Value)
    sincronizando := true
    if (n > 500)
        sldCada.Value := 500
    else
        sldCada.Value := n
    if (Integer(edCada.Value) != n)
        edCada.Value := n
    sincronizando := false
}

PonerMs(n) {
    global sincronizando
    sincronizando := true
    edMs.Value := n
    sldMs.Value := n
    sincronizando := false
}

PonerVar(n) {
    global sincronizando
    sincronizando := true
    edVar.Value := n
    sldVar.Value := n
    sincronizando := false
}

PonerCada(n) {
    global sincronizando
    sincronizando := true
    edCada.Value := n
    if (n > 500)
        sldCada.Value := 500
    else
        sldCada.Value := n
    sincronizando := false
}

ActualizarEstadoListo() {
    txtEstado.Value := "Listo. " StrLen(edTexto.Value) " caracteres en texto.txt. Tecla " DescribirTecla(TECLA) ". Cerrar deja el programa en la bandeja."
}

DescribirTecla(tecla) {
    t := tecla
    prefijo := ""
    while (t != "" && InStr("#^!+", SubStr(t, 1, 1))) {
        c := SubStr(t, 1, 1)
        t := SubStr(t, 2)
        if (c = "#")
            prefijo .= "Win+"
        else if (c = "^")
            prefijo .= "Ctrl+"
        else if (c = "!")
            prefijo .= "Alt+"
        else if (c = "+")
            prefijo .= "Mayús+"
    }
    return prefijo t
}

TeclaFisica(tecla) {
    t := tecla
    while (t != "" && InStr("#^!+$", SubStr(t, 1, 1)))
        t := SubStr(t, 2)
    return t
}
