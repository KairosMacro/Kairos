RunPath(movement, name := "", vars := "") {
	DetectHiddenWindows true
	if WinExist("ahk_pid " State.currentWalk.pid " ahk_class AutoHotkey")
		EndPath()
	script :=
		(
			'
	#SingleInstance Off
	#NoTrayIcon
	ProcessSetPriority("AboveNormal")
	KeyHistory 0
	ListLines 0
	OnExit(ExitFunc)

	#Include "%A_ScriptDir%\Lib\"
	#Include "Gdip_All.ahk"
	#Include "Gdip_ImageSearch.ahk"
	#Include "Roblox.ahk"
	#Include "QPC.ahk"
	#Include "Hypersleep.ahk"
	#Include "Move.ahk"

	movespeed := ' Alt.Movespeed '
	both			:= (Mod(movespeed*1000, 1265) = 0) || (Mod(Round((movespeed+0.005)*1000), 1265) = 0)
	HastyGuards	 := (both || Mod(movespeed*1000, 1100) < 0.00001)
	GiftedHasty	:= (both || Mod(movespeed*1000, 1150) < 0.00001)
	BaseMovespeed  := round(movespeed / (both ? 1.265 : (HastyGuards ? 1.1 : (GiftedHasty ? 1.15 : 1))), 0)

	(bitmaps := Map()).CaseSense := false
	pToken := Gdip_Startup()
	#Include "%A_ScriptDir%\Assets\Bitmaps\"
	#Include "Offset.ahk"
	#Include "Movement.ahk"
	offsetY := ' State.offsetY '
	' KeyVars() '
	' vars '
	index := 0
	start()
	return

	F13::
		start(hk?) {
			global index
			index++
			Send "{F14 down}"
			' movement '
			Send "{F14 up}"
		}
	
	F16:: {
		static keyStates := Map(LeftKey, false, RightKey, false, FwdKey, false, BackKey, false, "LButton", false, "RButton", false, SC_E, false)
		if A_IsPaused
			for k, v in keyStates
				if (v = true) 
					send "{" k " down}"
		else {
			for k, v in keyStates {
				keyStates[k] := GetKeyState(k)
				send "{" k " up}"
			}
		}
		Pause -1
	}
	ExitFunc(*) {
		Send "{' LeftKey ' up}{' RightKey ' up}{' FwdKey ' up}{' BackKey ' up}{' SC_Space ' up}{F14 up}{' SC_E ' up}"
		try Gdip_Shutdown(pToken)
	}
	'
		)
	shell := ComObject("WScript.Shell")
	exec := shell.Exec('"' exe_path64 '" /script /force *')
	exec.StdIn.Write(script), exec.StdIn.Close()
	if WinWait("ahk_class AutoHotkey ahk_pid " exec.ProcessID, , 2) {
		DetectHiddenWindows false
		State.currentWalk := { pid: exec.ProcessID, name: name }
		return true
	} else {
		DetectHiddenWindows false
		return false
	}
}

walk(dist, dir1, dir2?) {
	return
	(
		'Send "{' dir1 ' down}' (IsSet(dir2) ? '{' dir2 ' down}"' : '"') '
		move(' dist ')
		Send "{' dir1 ' up}' (IsSet(dir2) ? '{' dir2 ' up}"' : '"')
	)
}

KeyVars() {
	return
	(
		'
	FwdKey:="' FwdKey '"
	LeftKey:="' LeftKey '"
	BackKey:="' BackKey '"
	RightKey:="' RightKey '"
	RotLeft:="' RotLeft '"
	RotRight:="' RotRight '"
	RotUp:="' RotUp '"
	RotDown:="' RotDown '"
	ZoomIn:="' ZoomIn '"
	ZoomOut:="' ZoomOut '"
	SC_E:="' SC_E '"
	SC_R:="' SC_R '"
	SC_L:="' SC_L '"
	SC_Esc:="' SC_Esc '"
	SC_Enter:="' SC_Enter '"
	SC_LShift:="' SC_LShift '"
	SC_Space:="' SC_Space '"
	SC_1:="' SC_1 '"
	TCFBKey:="' TCFBKey '"
	AFCFBKey:="' AFCFBKey '"
	TCLRKey:="' TCLRKey '"
	AFCLRKey:="' AFCLRKey '"
	'
	)
}

PathVars() {
	return
	(
		'
	HiveSlot := ' Alt.HiveSlot '
	IsClaimed := ' Alt.ClaimHiveEnabled '
	CoordMode "Mouse", "Screen"
	CoordMode "Pixel", "Screen"

	gotoRamp() {
		if (IsClaimed) {
			walk(5, FwdKey)
			walk(9.2*HiveSlot-4, RightKey)
		} else {
			walk(30, FwdKey, RightKey)
			walk(5, RightKey)
		}
	}

	gotoCannon() {
		static pBMCannon := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAABsAAAAMAQMAAACpyVQ1AAAABlBMVEUAAAD3//lCqWtQAAAAAXRSTlMAQObYZgAAAEdJREFUeAEBPADD/wDAAGBgAMAAYGAA/gBgYAD+AGBgAMAAYGAAwABgYADAAGBgAMAAYGAAwABgYADAAGBgAMAAYGAAwABgYDdgEn1l8cC/AAAAAElFTkSuQmCC")

		hwnd := GetRobloxHWND()
		GetRobloxClientPos(hwnd)
		SendEvent "{Click " windowX+350 " " windowY+offsetY+100 " 0}"

		success := 0
		Loop 10
		{
			Send "{" SC_Space " down}{" RightKey " down}"
			Sleep 100
			Send "{" SC_Space " up}"
			walk(2, RightKey)
			walk(1.5, FwdKey, RightKey)
			Send "{" RightKey " down}"

			DllCall("GetSystemTimeAsFileTime","int64p",&s:=0)
			n := s, f := s+100000000
			while (n < f)
			{
				pBMScreen := Gdip_BitmapFromScreen(windowX+windowWidth//2-200 "|" windowY+offsetY "|400|125")
				if (Gdip_ImageSearch(pBMScreen, pBMCannon, , , , , , 2, , 2) = 1)
				{
					success := 1, Gdip_DisposeImage(pBMScreen)
					break
				}
				Gdip_DisposeImage(pBMScreen)
				DllCall("GetSystemTimeAsFileTime","int64p",&n)
			}
			Send "{" RightKey " up}"

			if (success = 1) ; check that cannon was not overrun, at the expense of a small delay
			{
				Loop 10
				{
					if (A_Index = 10)
					{
						success := 0
						break
					}
					Sleep 500
					pBMScreen := Gdip_BitmapFromScreen(windowX+windowWidth//2-200 "|" windowY+offsetY "|400|125")
					if (Gdip_ImageSearch(pBMScreen, pBMCannon, , , , , , 2, , 2) = 1)
					{
						Gdip_DisposeImage(pBMScreen)
						break 2
					}
					else
						walk(1.5, LeftKey)
					Gdip_DisposeImage(pBMScreen)
				}
			}

			if (success = 0)
			{
				Reset()
				gotoRamp()
			}
		}
		if (success = 0)
			ExitApp
	}

	Reset()
	{
		static hivedown := 0
		static pBMR := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAACgAAAAGCAAAAACUM4P3AAAAAnRSTlMAAHaTzTgAAAAXdEVYdFNvZnR3YXJlAFBob3RvRGVtb24gOS4wzRzYMQAAAyZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0n77u/JyBpZD0nVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkJz8+Cjx4OnhtcG1ldGEgeG1sbnM6eD0nYWRvYmU6bnM6bWV0YS8nIHg6eG1wdGs9J0ltYWdlOjpFeGlmVG9vbCAxMi40NCc+CjxyZGY6UkRGIHhtbG5zOnJkZj0naHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyc+CgogPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9JycKICB4bWxuczpleGlmPSdodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyc+CiAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjQwPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+NjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiA8L3JkZjpEZXNjcmlwdGlvbj4KCiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0nJwogIHhtbG5zOnRpZmY9J2h0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvJz4KICA8dGlmZjpJbWFnZUxlbmd0aD42PC90aWZmOkltYWdlTGVuZ3RoPgogIDx0aWZmOkltYWdlV2lkdGg+NDA8L3RpZmY6SW1hZ2VXaWR0aD4KICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgPHRpZmY6WFJlc29sdXRpb24+OTYvMTwvdGlmZjpYUmVzb2x1dGlvbj4KICA8dGlmZjpZUmVzb2x1dGlvbj45Ni8xPC90aWZmOllSZXNvbHV0aW9uPgogPC9yZGY6RGVzY3JpcHRpb24+CjwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9J3InPz77yGiWAAAAI0lEQVR42mNUYyAOMDJggOUMDAyRmAqXMxAHmBiobjWxngEAj7gC+wwAe1AAAAAASUVORK5CYII=")

		(bitmaps:=Map()).CaseSense := 0
		#include "%A_ScriptDir%\Assets\Bitmaps\Reset.ahk"

		success := 0
		hwnd := GetRobloxHWND()
		GetRobloxClientPos(hwnd)
		SendEvent "{Click " windowX+350 " " windowY+offsetY+100 " 0}"

		Loop 10
		{
			ActivateRoblox()
			GetRobloxClientPos(hwnd)
			PrevKeyDelay := A_KeyDelay
			SetKeyDelay 250
			SendEvent "{" SC_Esc "}{" SC_R "}{" SC_Enter "}"
			SetKeyDelay PrevKeyDelay

			n := 0
			while ((n < 2) && (A_Index <= 80))
			{
				Sleep 100
				pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY "|" windowWidth "|50")
				n += (Gdip_ImageSearch(pBMScreen, pBMR, , , , , , 10) = (n = 0))
				Gdip_DisposeImage(pBMScreen)
			}
			Sleep 1000

			if hivedown
				Send "{" RotDown "}"
			region := windowX "|" windowY+3*windowHeight//4 "|" windowWidth "|" windowHeight//4
			sconf := windowWidth**2//3200
			Loop 4 {
				sleep 250
				pBMScreen := Gdip_BitmapFromScreen(region), s := 0
				for i, k in bitmaps["hive"] {
					s := Max(s, Gdip_ImageSearch(pBMScreen, k, , , , , , 4, , , sconf))
					if (s >= sconf) {						
						Gdip_DisposeImage(pBMScreen)
						success := 1
						Send "{" RotRight " 4}"
						if hivedown
							Send "{" RotUp "}"
						SendEvent "{" ZoomOut " 5}"
						break 3
					}
				}
				Gdip_DisposeImage(pBMScreen)
				Send "{" RotRight " 4}"
				if (A_Index = 2)
				{
					if hivedown := !hivedown
						Send "{" RotDown "}"
					else
						Send "{" RotUp "}"
				}
			}
		}
		for k,v in bitmaps["hive"]
			Gdip_DisposeImage(v)
		if (success = 0)
			ExitApp
	}
	'
	)
}

PatternVars(field := "Stump") { ; stump default b/c it's smallest
	return
	(
		'
	nm_CameraRotation(Dir, count) {
		Static LR := 0, UD := 0, init := OnExit((*) => send("{" Rot%(LR > 0 ? "Left" : "Right")% " " Mod(Abs(LR), 8) "}{" Rot%(UD > 0 ? "Up" : "Down")% " " Abs(UD) "}"), -1)
		send "{" Rot%Dir% " " count "}"
		Switch Dir,0 {
			Case "Left": LR -= count
			Case "Right": LR += count
						Case "Up": UD -= count
						Case "Down": UD += count
		}
	}
	field := "' field '"
	fieldWidth := ' State.fieldSize[field].width '
	fieldHeight := ' State.fieldSize[field].height '
	altNumber := ' Alt.AltNumber '
	size := ' Alt.PatternSize '
	reps := ' Alt.PatternWidth '
	'
	)
}

EndPath() {
	DetectHiddenWindows true
	try WinClose "ahk_class AutoHotkey ahk_pid " State.currentWalk.pid
	State.currentWalk := { pid: "", name: "" }
	DetectHiddenWindows false
}

FieldDriftCompensation() {
	GetRobloxClientPos()
	winUp := Floor(windowHeight / 2.14), winDown := Floor(windowHeight / 1.88)
	winLeft := Floor(windowWidth / 2.14), winRight := Floor(windowWidth / 1.88)

	hmove := vmove := 0
	if ((LocateSprinkler(&x, &y) = 1) && !(x >= winLeft && x <= winRight && y >= winUp && y <= winDown)) {
		if ((x < winleft) && (hmove := LeftKey))
			sendinput "{" LeftKey " down}"
		else if ((x > winRight) && (hmove := RightKey))
			sendinput "{" RightKey " down}"
		if ((y < winUp) && (vmove := FwdKey))
			sendinput "{" FwdKey " down}"
		else if ((y > winDown) && (vmove := BackKey))
			sendinput "{" BackKey " down}"
		while (hmove || vmove) {
			if (((hmove = LeftKey) && (x >= winLeft)) || ((hmove = RightKey) && (x <= winRight))) {
				sendinput "{" hmove " up}"
				hmove := ""
			}
			if (((vmove = FwdKey) && (y >= winUp)) || ((vmove = BackKey) && (y <= winDown))) {
				sendinput "{" vmove " up}"
				vmove := ""
			}
			Sleep 20
			if ((A_Index >= 300)) {
				sendinput "{" LeftKey " up}{" RightKey " up}{" FwdKey " up}{" BackKey " up}"
				break
			}
			if (LocateSprinkler(&x, &y) = 0) {
				sendinput "{" LeftKey " up}{" RightKey " up}{" FwdKey " up}{" BackKey " up}"
				Loop 25 {
					Sleep 20
					if (LocateSprinkler(&x, &y) = 1) {
						sendinput (hmove ? "{" hmove " down}" : "") (vmove ? "{" vmove " down}" : "")
						continue 2
					}
				}
				break
			}
		}
	}
}

LocateSprinkler(&X := "", &Y := "") { ; find client coordinates of approximately closest saturator to player/center
	n := State.SprinklerImages.Length

	hwnd := GetRobloxHWND()
	GetRobloxClientPos(hwnd)
	pBMScreen := Gdip_BitmapFromScreen(windowX "|" (windowY + State.offsetY + 75) "|" (hWidth := windowWidth) "|" (hHeight := windowHeight - State.offsetY - 75) "|")
	Gdip_LockBits(pBMScreen, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmapData, 1)
	hWidth := NumGet(hBitmapData, 0, "UInt"), hHeight := NumGet(hBitmapData, 4, "UInt")

	local n1width, n1height, n1Stride, n1Scan, n1BitmapData
		, n2width, n2height, n2Stride, n2Scan, n2BitmapData
		, n3width, n3height, n3Stride, n3Scan, n3BitmapData
	for i, k in State.SprinklerImages
	{
		Gdip_GetImageDimensions(bitmaps[k], &n%i%Width, &n%i%Height)
		Gdip_LockBits(bitmaps[k], 0, 0, n%i%Width, n%i%Height, &n%i%Stride, &n%i%Scan, &n%i%BitmapData)
		n%i%Width := NumGet(n%i%BitmapData, 0, "UInt"), n%i%Height := NumGet(n%i%BitmapData, 4, "UInt")
	}

	d := 11 ; divisions (odd positive integer such that w,h > n%i%Width,n%i%Height for all i<=n)
	m := d // 2 ; midpoint of d (along with m + 1), used frequently in calculations
	v := 50 ; variation
	w := hWidth // d, h := hHeight // d

	; to search from centre (approximately), we will split the rectangle like a pinwheel configuration and search outwards (notice SearchDirection)
	Loop m + 1
	{
		if (A_Index = 1)
		{
			; initial rectangle (center)
			d1 := m, d2 := m + 1
			OuterX1 := d1 * w, OuterX2 := d2 * w
			OuterY1 := d1 * h, OuterY2 := d2 * h
			Loop n
				if (Gdip_MultiLockedBitsSearch(hStride, hScan, hWidth, hHeight, n%A_Index%Stride, n%A_Index%Scan, n%A_Index%Width, n%A_Index%Height, &pos, OuterX1, OuterY1, OuterX2 - n%A_Index%Width + 1, OuterY2 - n%A_Index%Height + 1, v, 1, 1) > 0)
					break 2
		}
		else
		{
			; upper-right
			dx1 := m + 2 - A_Index, dx2 := m + A_Index
			OuterX1 := dx1 * w, OuterX2 := dx2 * w
			dy1 := m + 1 - A_Index, dy2 := m + 2 - A_Index
			OuterY1 := dy1 * h, OuterY2 := dy2 * h
			Loop n
				if (Gdip_MultiLockedBitsSearch(hStride, hScan, hWidth, hHeight, n%A_Index%Stride, n%A_Index%Scan, n%A_Index%Width, n%A_Index%Height, &pos, OuterX1, OuterY1, OuterX2 - n%A_Index%Width + 1, OuterY2 - n%A_Index%Height + 1, v, 2, 1) > 0)
					break 2

			; lower-right
			dx1 := m - 1 + A_Index, dx2 := m + A_Index
			OuterX1 := dx1 * w, OuterX2 := dx2 * w
			dy1 := m + 2 - A_Index, dy2 := m + A_Index
			OuterY1 := dy1 * h, OuterY2 := dy2 * h
			Loop n
				if (Gdip_MultiLockedBitsSearch(hStride, hScan, hWidth, hHeight, n%A_Index%Stride, n%A_Index%Scan, n%A_Index%Width, n%A_Index%Height, &pos, OuterX1, OuterY1, OuterX2 - n%A_Index%Width + 1, OuterY2 - n%A_Index%Height + 1, v, 5, 1) > 0)
					break 2

			; lower-left
			dx1 := m + 1 - A_Index, dx2 := m - 1 + A_Index
			OuterX1 := dx1 * w, OuterX2 := dx2 * w
			dy1 := m - 1 + A_Index, dy2 := m + A_Index
			OuterY1 := dy1 * h, OuterY2 := dy2 * h
			Loop n
				if (Gdip_MultiLockedBitsSearch(hStride, hScan, hWidth, hHeight, n%A_Index%Stride, n%A_Index%Scan, n%A_Index%Width, n%A_Index%Height, &pos, OuterX1, OuterY1, OuterX2 - n%A_Index%Width + 1, OuterY2 - n%A_Index%Height + 1, v, 4, 1) > 0)
					break 2

			; upper-left
			dx1 := m + 1 - A_Index, dx2 := m + 2 - A_Index
			OuterX1 := dx1 * w, OuterX2 := dx2 * w
			dy1 := m + 1 - A_Index, dy2 := m - 1 + A_Index
			OuterY1 := dy1 * h, OuterY2 := dy2 * h
			Loop n
				if (Gdip_MultiLockedBitsSearch(hStride, hScan, hWidth, hHeight, n%A_Index%Stride, n%A_Index%Scan, n%A_Index%Width, n%A_Index%Height, &pos, OuterX1, OuterY1, OuterX2 - n%A_Index%Width + 1, OuterY2 - n%A_Index%Height + 1, v, 7, 1) > 0)
					break 2
		}
	}

	Gdip_UnlockBits(pBMScreen, &hBitmapData)
	for i, k in State.sprinklerImages
		Gdip_UnlockBits(bitmaps[k], &n%i%BitmapData)
	Gdip_DisposeImage(pBMScreen)

	if pos
	{
		x := SubStr(pos, 1, InStr(pos, ",") - 1), y := 75 + SubStr(pos, InStr(pos, ",") + 1)
		return 1
	}
	else
	{
		x := "", y := ""
		return 0
	}
}
