gotoRamp()
gotoCannon()
send "{" RotLeft " 2}{" SC_E " down}{" FwdKey " down}"
HyperSleep(100)
send "{" SC_E " up}"
HyperSleep(1800)
send "{" SC_Space " 2}"
HyperSleep(2600)
loop 2
	send("{" RotLeft "}"), HyperSleep(500)
send "{" LeftKey " down}"
HyperSleep(1500)
send "{" FwdKey " up}{" LeftKey " up}{" SC_Space "}"
sleep 1000
walk(5, FwdKey, LeftKey)
walk(2, LeftKey)
walk(15.2, BackKey, RightKey)
walk(5.5, RightKey)
