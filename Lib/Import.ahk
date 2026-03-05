exe_path32 := A_AhkPath
exe_path64 := (A_Is64bitOS && FileExist("scripts\executables\AutoHotkey64.exe")) ? (A_WorkingDir "\scripts\executables\AutoHotkey64.exe") : A_AhkPath

CloseScripts(hb := 0) {
	list := WinGetList("ahk_class AutoHotkey ahk_exe " exe_path32)
	if (exe_path32 != exe_path64)
		list.Push(WinGetList("ahk_class AutoHotkey ahk_exe " exe_path64)*)
	for hwnd in list
		if !((hwnd = A_ScriptHwnd) || ((hb = 1) && A_Args.Has(2) && (hwnd = A_Args[2])))
			try WinClose "ahk_id " hwnd
}

TCFBKey := FwdKey := "sc011" ; w
TCLRKey := LeftKey := "sc01e" ; a
AFCFBKey := BackKey := "sc01f" ; s
AFCLRKey := RightKey := "sc020" ; d
RotLeft := "sc033" ; ,
RotRight := "sc034" ; .
RotUp := "sc149" ; PgUp
RotDown := "sc151" ; PgDn
ZoomIn := "sc017" ; i
ZoomOut := "sc018" ; o
SC_E := "sc012" ; e
SC_R := "sc013" ; r
SC_L := "sc026" ; l
SC_Esc := "sc001" ; Esc
SC_Enter := "sc01c" ; Enter
SC_LShift := "sc02a" ; LShift
SC_Space := "sc039" ; Space
SC_1 := "sc002" ; 1
SC_Slash := "sc035" ; /

importPaths() {
	pathtypes := ["gtb", "gtc", "gtf", "gtp", "gtq", "wf"]
	global paths := Map()
	paths.CaseSense := 0

	for pathtype in pathtypes {
		(paths[pathtype] := Map()).CaseSense := 0

		loop files A_WorkingDir "\Paths\" pathtype "-*.ahk", "R" {
			name := StrReplace(StrReplace(A_LoopFileName, pathtype "-"), ".ahk")
			contents := FileRead(A_LoopFilePath)
			paths[pathtype][name] := contents
		}
	}
}

importPatterns()
{
	global patterns := Map()
	patterns.CaseSense := 0
	global patternlist := []

	imported := ""

	import := ""
	Loop Files A_WorkingDir "\Patterns\*.ahk"
	{
		file := FileOpen(A_LoopFilePath, "r"), pattern := file.Read(), file.Close()
		if RegexMatch(pattern, "im)patterns\[")
			MsgBox
		(
			"Pattern '" A_LoopFileName "' seems to be deprecated!
			This means the pattern will NOT work!
			Check for an updated version of the pattern
			or ask the creator to update it"
		), "Error", 0x40010 " T60"
		if !InStr(imported, imported_pattern := '("' (pattern_name := StrReplace(A_LoopFileName, "." A_LoopFileExt)) '")`r`n' pattern '`r`n`r`n')
		{
			script :=
				(
					'
			#NoTrayIcon
			#SingleInstance Off
			#Warn All, StdOut

			' KeyVars() '

			size:=1, reps:=1, facingcorner:=0
			FieldName:=FieldPattern:=FieldPatternSize:=FieldReturnType:=FieldSprinklerLoc:=FieldRotateDirection:=""
			FieldUntilPack:=FieldPatternReps:=FieldPatternShift:=FieldSprinklerDist:=FieldRotateTimes:=FieldDriftCheck:=FieldPatternInvertFB:=FieldPatternInvertLR:=FieldUntilMins:=0
			fieldWidth := 11
			fieldHeight := 9
			altNumber := 1
			index := 0
			field := ""
			walk(param1, param2?) => ""
			move(param1, param2?, param3?) => ""
			HyperSleep(param1) => ""
			Gdip_ImageSearch(*) => ""
			Gdip_BitmapFromBase64(*) => ""

			' pattern '

			'
				)

			exec := ComObject("WScript.Shell").Exec('"' exe_path64 '" /script /Validate /ErrorStdOut *'), exec.StdIn.Write(script), exec.StdIn.Close()
			if (stdout := exec.StdOut.ReadAll())
			{
				MsgBox
				(
					"Unable to import '" pattern_name "' pattern!
				Click 'OK' to continue loading the macro without this pattern installed, otherwise fix the error and reload the macro.

				The error found on loading is stated below:
				" stdout
				), "Unable to Import Pattern!", 0x40010 " T60"
				continue
			}
		}

		import .= imported_pattern
		patternlist.Push(pattern_name)
		patterns[pattern_name] := pattern
	}
}
