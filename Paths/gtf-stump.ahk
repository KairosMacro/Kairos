gotoRamp()
gotoCannon()
send "{" RotLeft " 2}{" SC_E " down}{" FwdKey " down}"
HyperSleep(100)
send "{" SC_E " up}"
HyperSleep(2100)
send "{" FwdKey " up}{" SC_Space " 2}"
HyperSleep(5000)
send "{" SC_Space "}"
sleep 1000
walk(4, LeftKey)
