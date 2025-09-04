; ===== Config =====
;borderColor     := "BAA972"   ; light yellow (no #)
borderColor     := "FF66B3"   ; pink (no #)
borderOpacity   := 210        ; 0..255
borderThickness := 2          ; pixels
pollIntervalMs  := 20         ; ms

; Inset per side (px): positive = move inward, negative = move outward
inset := { top: 0, right: 0, bottom: 0, left: 0 }

; Optional filters
blacklistClasses := Map(
;   "Chrome_WidgetWin_1", true
)
minWindowSize := { w: 700, h: 700 }  ; draw on any size >= these

; ===== DPI awareness (Per-Monitor v2 if available) =====
try {
    DllCall("User32.dll\SetThreadDpiAwarenessContext", "ptr", -4, "ptr")  ; PER_MONITOR_AWARE_V2
} catch {
}
try {
    DllCall("Shcore.dll\SetProcessDpiAwareness", "int", 2)  ; PROCESS_PER_MONITOR_DPI_AWARE
} catch {
}

; ===== Globals =====
lastHwnd := 0
lastRect := {l:0,t:0,r:0,b:0}
borders  := CreateBorderGuis(borderColor, borderOpacity)

; Start
SetTimer(UpdateBorder, pollIntervalMs)

; ===== Implementation =====
UpdateBorder(*) {
    global lastHwnd, lastRect, borders, borderThickness, blacklistClasses, minWindowSize, inset

    hwnd := WinExist("A")
    if !IsDrawableWindow(hwnd) {
        HideBorders(borders)
        lastHwnd := 0
        return
    }

    if blacklistClasses.Has(WinGetClass(hwnd)) {
        HideBorders(borders), lastHwnd := 0
        return
    }

    rect := GetExtendedFrameBounds(hwnd)
    if !rect {
        HideBorders(borders), lastHwnd := 0
        return
    }

    w := rect.r - rect.l
    h := rect.b - rect.t
    if (w < minWindowSize.w || h < minWindowSize.h) {
        HideBorders(borders), lastHwnd := 0
        return
    }

    if (hwnd != lastHwnd
        || rect.l != lastRect.l || rect.t != lastRect.t
        || rect.r != lastRect.r || rect.b != lastRect.b) {
        DrawBorders(borders, rect, borderThickness, inset)
        lastHwnd := hwnd
        lastRect := rect
    }
}

IsDrawableWindow(hwnd) {
    if !hwnd
        return false
    try {
        if WinGetMinMax("ahk_id " hwnd) = -1  ; minimized
            return false
        if !WinActive("ahk_id " hwnd)        ; only draw for active window
            return false
        if DwmIsCloaked(hwnd)                ; skip cloaked UWP
            return false
        return true
    } catch {
        return false
    }
}

GetExtendedFrameBounds(hwnd) {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    if !hwnd
        return 0
    rectBuf := Buffer(16, 0)  ; RECT {left, top, right, bottom}
    hr := DllCall("dwmapi.dll\DwmGetWindowAttribute"
        , "ptr", hwnd
        , "int", DWMWA_EXTENDED_FRAME_BOUNDS
        , "ptr", rectBuf.Ptr
        , "int", rectBuf.Size
        , "int")
    if (hr != 0) {
        if WinGetPos(&l,&t,&w,&h, "ahk_id " hwnd)
            return { l:l, t:t, r:l+w, b:t+h }
        return 0
    }
    l := NumGet(rectBuf, 0,  "int")
    t := NumGet(rectBuf, 4,  "int")
    r := NumGet(rectBuf, 8,  "int")
    b := NumGet(rectBuf, 12, "int")
    return { l:l, t:t, r:r, b:b }
}

DwmIsCloaked(hwnd) {
    static DWMWA_CLOAKED := 14
    cloaked := 0
    if DllCall("dwmapi.dll\DwmGetWindowAttribute"
        , "ptr", hwnd
        , "int", DWMWA_CLOAKED
        , "uint*", &cloaked
        , "int", 4
        , "int") = 0
        return cloaked != 0
    return false
}

CreateBorderGuis(hexColor, opacity) {
    gTop    := NewBorderGui(hexColor, opacity)
    gBottom := NewBorderGui(hexColor, opacity)
    gLeft   := NewBorderGui(hexColor, opacity)
    gRight  := NewBorderGui(hexColor, opacity)
    return { top:gTop, bottom:gBottom, left:gLeft, right:gRight }
}

NewBorderGui(hexColor, opacity) {
    ; WS_EX_TRANSPARENT (0x20) click-through, WS_EX_NOACTIVATE (0x08000000)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000")
    g.BackColor := hexColor            ; no leading '#'
    g.MarginX := 0
    g.MarginY := 0
    g.Show("NA w1 h1 x0 y0")           ; show so we can apply styles
    WinSetTransparent(opacity, "ahk_id " . g.Hwnd)
    WinSetAlwaysOnTop(true, "ahk_id " . g.Hwnd)
    g.Hide()
    return g
}

DrawBorders(b, rect, t, inset) {
    ; Adjust the effective rectangle by inset:
    ; Positive inset moves inward; negative moves outward.
    adjL := rect.l + inset.left
    adjT := rect.t + inset.top
    adjR := rect.r - inset.right
    adjB := rect.b - inset.bottom

    ; Safety: ensure we still have a valid rectangle
    if (adjR <= adjL || adjB <= adjT) {
        HideBorders(b)
        return
    }

    winTop    := "ahk_id " . b.top.Hwnd
    winBottom := "ahk_id " . b.bottom.Hwnd
    winLeft   := "ahk_id " . b.left.Hwnd
    winRight  := "ahk_id " . b.right.Hwnd

    ; Top (aligned to adjusted top edge)
    b.top.Show("NA")
    WinMove(adjL, adjT, adjR - adjL, t, winTop)
    WinSetAlwaysOnTop(true, winTop)

    ; Bottom
    b.bottom.Show("NA")
    WinMove(adjL, adjB - t, adjR - adjL, t, winBottom)
    WinSetAlwaysOnTop(true, winBottom)

    ; Left
    b.left.Show("NA")
    WinMove(adjL, adjT, t, adjB - adjT, winLeft)
    WinSetAlwaysOnTop(true, winLeft)

    ; Right
    b.right.Show("NA")
    WinMove(adjR - t, adjT, t, adjB - adjT, winRight)
    WinSetAlwaysOnTop(true, winRight)
}

HideBorders(b) {
    b.top.Hide()
    b.bottom.Hide()
    b.left.Hide()
    b.right.Hide()
}