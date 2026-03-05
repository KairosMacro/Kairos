#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreads 255
#Warn VarUnset, Off

SetWorkingDir A_ScriptDir "\.."
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SendMode "Event"

#Include "%A_ScriptDir%\..\Lib"
#Include "Config.ahk"
#Include "Gdip_All.ahk"
#Include "Gdip_ImageSearch.ahk"
#Include "Roblox.ahk"
#Include "Tooltip.ahk"
#Include "Audio.ahk"
#Include "Auxiliary.ahk"
#Include "QPC.ahk"
#Include "Import.ahk"
#Include "FrameCache.ahk"
#Include "Scheduler.ahk"
#Include "WindowTracker.ahk"
#Include "Path.ahk"
#Include "JSON.ahk"
#Include "nowUnix.ahk"
#Include "DarkMode.ahk"
#Include "Dweet.ahk"

if !(pToken := Gdip_Startup())
	throw Error("GDI+ failed to start, exiting script.")

(bitmaps := Map()).CaseSense := false
#Include "%A_ScriptDir%\..\Assets\Bitmaps"
#Include "Movement.ahk"
#Include "Buffs.ahk"
#Include "Boosts.ahk"
#Include "General.ahk"
#Include "Offset.ahk"
#Include "Reset.ahk"
#Include "Sprinkler.ahk"
#Include "Icons.ahk"
#Include "Images.ahk"

TraySetIcon "Assets\Images\Kairos.ico"

OnExit(Cleanup)

Config.Load()

version := "0.1.0"

GetRobloxClientPos()

#Include "%A_ScriptDir%\..\scripts\macros"
#Include "MainGui.ahk"
#Include "PassiveScanner.ahk"
#Include "Warnings.ahk"
#Include "BoostBar.ahk"
#Include "AltMacro.ahk"
#Include "KeyAlignment.ahk"
#Include "MagnifyingGlass.ahk"
#Include "Communicator.ahk"

class State {
	static IsPaused := false
	static CurrentWalk := { pid: "", name: "" }
	static offsetY := GetYOffset(,,1)
	static FieldSize := Map(
		"sunflower", { width: 33, height: 20 }
		, "dandelion", { width: 36, height: 18 }
		, "mushroom", { width: 32, height: 23 }
		, "blueflower", { width: 43, height: 17 }
		, "clover", { width: 29, height: 26 }
		, "strawberry", { width: 22, height: 26 }
		, "spider", { width: 28, height: 26 }
		, "bamboo", { width: 39, height: 18 }
		, "pineapple", { width: 33, height: 23 }
		, "stump", { width: 11, height: 9 }
		, "cactus", { width: 33, height: 18 }
		, "pumpkin", { width: 33, height: 17 }
		, "pinetree", { width: 31, height: 23 }
		, "rose", { width: 31, height: 20 }
		, "mountaintop", { width: 24, height: 28 }
		, "pepper", { width: 27, height: 21 }
		, "coconut", { width: 30, height: 21 }
	)
	static SprinklerImages := ["saturator", "saturatorWS"]
}

WindowTracker.Start(50)
Scheduler.Start()

Scorch := PassiveScanner()
Warns := Warnings()
Boost := BoostBar()
Alt := AltMacro()
Aligner := KeyAlignment()
Mag := MagnifyingGlass()
Main := MainGui()
Comms := Communicator()
Fancy := GdipTooltip()

;SetTimer(grjknnkjrg, 1)
grjknnkjrg() {
	GetRobloxClientPos()
	index := Mod(A_TickCount // 60, 60)
	offset := 30 - Abs(index - 30)
	Fancy.Show(bitmaps["anime"], windowX + windowWidth - 230, windowY + offset, 1, 0x00000000)
}
F2:: Reload
F3:: ExitApp

Cleanup(*) {
	Critical
	Scheduler.Stop()
	WindowTracker.Stop()
	wp := Buffer(44)
	try DllCall("GetWindowPlacement", "UInt", Main.Gui.Hwnd, "Ptr", wp)
	x := NumGet(wp, 28, "Int")
	y := NumGet(wp, 32, "Int")
	Config.Set("Main", "GuiX", (x > 0) ? (x > A_ScreenWidth - 400 ? A_ScreenWidth - 400 : x) : 0)
	Config.Set("Main", "GuiY", (y > 0) ? (y > A_ScreenHeight - 220 ? A_ScreenHeight - 220 : y) : 0)
	Config.WriteIni()
	sleep 20

	try Scorch.Cleanup()
	try Warns.Cleanup()
	try Boost.Cleanup()
	try Alt.Cleanup()
	try Aligner.Cleanup()
	try Main.Cleanup()
	try Mag.Cleanup()
	try FrameCache.Clear()
	Gdip_Shutdown(pToken)
}
