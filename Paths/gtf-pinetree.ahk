gotoRamp()
gotoCannon()
send "{" RotRight " 3}{" SC_E " down}{" FwdKey " down}"
HyperSleep(100)
send "{" SC_E " up}"
HyperSleep(900)
send "{" FwdKey " up}{" SC_Space " 2}"
HyperSleep(5900)
send "{" SC_Space "}"
walk(6, FwdKey)
walk(4, FwdKey, LeftKey)
send "{" RotRight "}"
walk(16, BackKey, RightKey)
walk(5, BackKey)
