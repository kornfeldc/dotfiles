#Requires AutoHotkey v2.0
; === Config ===
borderColor := "6495ED"   ; e.g. "FF3B30" or "Red"
;borderColor := "Yellow"   ; e.g. "FF3B30" or "Red"
borderWidth := 1       ; px
opacity     := 100     ; 0..255 (255=opaque)
pollMs      := 40      ; ms
sizeBuffer  := 9 

; === Four overlay GUIs (layered + click-through + topmost) ===
global gTop := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020")
global gBot := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020")
global gLft := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020")
global gRgt := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020")

for g in [gTop, gBot, gLft, gRgt] {
    g.BackColor := borderColor
    g.Show("NA Hide")  ; create the window hidden (non-activating)

    ; Robustly apply transparency after the window exists.
    ok := false
    Loop 10 {
        try {
            WinSetTransparent(opacity, g.Hwnd) ; pass HWND directly
            ok := true
            break
        } catch {
            Sleep 15
        }
    }
    if !ok {
        ; Fallback via API (rarely needed)
        hwnd := g.Hwnd
        DllCall("SetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr", (DllCall("GetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr") | 0x00080000 | 0x20)) ; WS_EX_LAYERED|WS_EX_TRANSPARENT
        DllCall("SetLayeredWindowAttributes", "ptr", hwnd, "uint", 0, "uchar", opacity, "uint", 0x02) ; LWA_ALPHA
    }
}

; Track last rect to reduce moves
global lastHwnd := 0, lastX := 0, lastY := 0, lastW := 0, lastH := 0

SetTimer(UpdateBorder, pollMs)
OnExit(Shutdown)

UpdateBorder() {
    global gTop, gBot, gLft, gRgt, borderWidth
    global lastHwnd, lastX, lastY, lastW, lastH

    active := WinExist("A")
    if !IsValidTarget(active) {
        HideBorders()
        lastHwnd := 0
        return
    }

    mm := WinGetMinMax("ahk_id " active)
    if (mm = -1) { ; minimized
        HideBorders()
        lastHwnd := 0
        return
    }

    ; ignore our own overlays
    if (active = gTop.Hwnd || active = gBot.Hwnd || active = gLft.Hwnd || active = gRgt.Hwnd)
        return

    try {
        WinGetPos(&x, &y, &w, &h, "ahk_id " active)
        if (w <= 0 || h <= 0) {
            HideBorders()
            lastHwnd := 0
            return
        }
    } catch {
        HideBorders()
        lastHwnd := 0
        return
    }

    if (active = lastHwnd && x = lastX && y = lastY && w = lastW && h = lastH)
        return

    lastHwnd := active, lastX := x, lastY := y, lastW := w, lastH := h

    t := borderWidth
    ; place borders just outside the window so they remain visible when maximized
    gTop.Show(Format("NA x{} y{} w{} h{}", x - t + sizeBuffer,     y - t + sizeBuffer,     (w + 2*t)-(sizeBuffer*2), t))
    gBot.Show(Format("NA x{} y{} w{} h{}", x - t + sizeBuffer,     y + h - sizeBuffer,     (w + 2*t)-(sizeBuffer*2), t))
    gLft.Show(Format("NA x{} y{} w{} h{}", x - t + sizeBuffer,     y + sizeBuffer,         t,       h-(sizeBuffer*2)))
    gRgt.Show(Format("NA x{} y{} w{} h{}", x + w - sizeBuffer,     y + sizeBuffer,         t,       h-(sizeBuffer*2)))
}

IsValidTarget(hwnd) {
    if !hwnd
        return false
    try {
        cls := WinGetClass("ahk_id " hwnd)
        exe := WinGetProcessName("ahk_id " hwnd)
        if (cls = "Shell_TrayWnd"               ; taskbar
         || cls = "Shell_SecondaryTrayWnd"      ; 2nd monitor taskbar
         || cls = "Button"                      ; stray buttons/menus
         || cls = "#32768"                      ; context menus
         || cls = "Progman"                     ; desktop
         || cls = "WorkerW"                     ; desktop host
         || cls = "NotifyIconOverflowWindow")   ; tray overflow
            return false

        ; === custom blacklist ===
        if (exe = "Raycast.exe")      ; by process name
            return false
        if (cls = "RaycastWindow")    ; or by class name
            return false
        if (InStr(WinGetTitle("ahk_id " hwnd), "Raycast")) ; or by title
            return false
        ; ========================

        style := WinGetStyle("ahk_id " hwnd)
        exstyle := WinGetExStyle("ahk_id " hwnd)
        ; WS_POPUP (0x80000000) without typical overlapped frame bits tends to be popups
        if ((style & 0x80000000) && !(style & 0x00CF0000))  ; popup & not overlapped
            return false
    } catch {
        return false
    }
    return true
}

HideBorders() {
    global gTop, gBot, gLft, gRgt
    for g in [gTop, gBot, gLft, gRgt]
        g.Show("Hide")
}

Shutdown(*) {
    for g in [gTop, gBot, gLft, gRgt] {
        try g.Destroy()
    }
}
