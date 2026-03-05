@echo off
cd %~dp0

rem https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands

if exist "scripts\Main.ahk" (
	if exist "scripts\executables\AutoHotkey64.exe" (
		start "" "%~dp0scripts\executables\AutoHotkey64.exe" "%~dp0scripts\Main.ahk"
		exit
	)
)
