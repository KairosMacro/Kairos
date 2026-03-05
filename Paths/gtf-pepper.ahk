; hive
gotoRamp()
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
walk(2, RightKey)
walk(2, FwdKey, RightKey)
walk(15, RightKey)
walk(2, RightKey, BackKey)
walk(12, RightKey)
; first ramp
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
walk(5, RightKey)
walk(3, FwdKey, RightKey)
walk(4, FwdKey)
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
; towards the edge
walk(16, FwdKey)
walk(3, RightKey, FwdKey)
; on the edge
send "{" FwdKey " down}"
HyperSleep(200)
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
HyperSleep(600)
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
HyperSleep(600)
walk(13, FwdKey)
; pepper or coconut ?
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
; towards spirit
walk(25, FwdKey, RightKey)
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
walk(8, RightKey, FwdKey)
walk(15, RightKey)
; pepper
send "{" SC_Space " down}"
HyperSleep(100)
send "{" SC_Space " up}"
walk(14, RightKey)
send "{" RotRight " 2}"
