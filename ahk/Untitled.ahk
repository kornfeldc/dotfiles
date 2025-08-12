+!j::Send "{Down}"
+!k::Send "{Up}"
+!h::Send "{Left}"
+!l::Send "{Right}"
+!2::Send "'"

^::Send "<"
°::Send ">"
´::Send "|"

RAlt & j::Send "{Down}"
RAlt & k::Send "{Up}"
RAlt & h::Send "{Left}"
RAlt & l::Send "{Right}"
RAlt & 2::Send "'"
RAlt & 1::Send "{Home}"
RAlt & 4::Send "{End}"

RAlt & a::Send "#1"
RAlt & s::Send "#2"
RAlt & t::Send "#3"
RAlt & r::Send "{LWin down}4{LWin up}"
RAlt & o::Send "#5"

#Up::WinMaximize("A")
#Down::WinMinimize("A")
+^!j:: WinMinimize("A") ; also minimize with shift control alt j

+^!h::Send("#{Left}") ; windows left as shift als control h
+^!l::Send("#{Right}") ; windows right as shift als control l

#ä:: { ; Win + ä to move the mouse
    WinGetPos &x, &y, &width, &height, "A" ; Get the active window’s position and size
    MouseMove x + (width / 2), y + (height / 2) ; Move the cursor to the center
}
