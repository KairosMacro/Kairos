class AltMacro {
	IsRunning := false
	IsActive := false
	slotMove := [
		[{dir:"Right", dist:4}, {dir:["Right", "Fwd"], dist:20}],
		[{dir:["Fwd", "Right"], dist:13}, {dir:"Fwd", dist:6}],
		[{dir:"Fwd", dist:20}, {dir:"Back", dist:4}],
		[{dir:["Left", "Fwd"], dist:13}, {dir:"Fwd", dist:6}],
		[{dir:"Left", dist:4}, {dir:["Left", "Fwd"], dist:20}],
		[{dir:["Left", "Fwd"], dist:12}, {dir:"Left", dist:13}, {dir:["Left", "Fwd"], dist:10}]
	]

	__New() {
		importPaths()
		importPatterns()

		this.Settings()
		this.Fancy := GdipTooltip()
	}

	Settings() {
		this.HiveSlot := Config.Get("Alt", "HiveSlot", 1)
		this.Movespeed := Config.Get("Alt", "Movespeed", 36.68)
		this.AltNumber := Config.Get("Alt", "AltNumber", 1)
		this.FieldDriftComp := Config.Get("Alt", "FieldDriftComp", 1)
		this.DefaultField := Config.Get("Alt", "DefaultField", "pepper")
		this.Pattern := Config.Get("Alt", "Pattern", "GeneralBooster")
		this.UseTool := Config.Get("Alt", "UseTool", 1)
		this.IgnoreInactiveHoney := Config.Get("Alt", "IgnoreInactiveHoney", 0)

		this.PatternSize := Config.Get("Alt", "PatternSize", 5)
		this.PatternWidth := Config.Get("Alt", "PatternWidth", 5)
		this.RotationAmount := Config.Get("Alt", "RotationAmount", 0)
		this.RotationDirection := Config.Get("Alt", "RotationDirection", "right")
		this.ShiftLock := Config.Get("Alt", "ShiftLock", 0)
		this.SprinklerLocation := Config.Get("Alt", "SprinklerLocation", "Center")
		this.SprinklerDistance := Config.Get("Alt", "SprinklerDistance", 1)
		this.ClaimHiveEnabled := Config.Get("Alt", "ClaimHive", 1)
	}

	Toggle() {
		this.IsRunning ^= 1
		this.IsActive := this.IsRunning && Config.Get("Main", "AltMacroEnabled", 0)
		if (this.IsActive) {
			this.Fancy.Show("Alt Macro: ON")
			ActivateRoblox()
			SetTimer(() => this.Fancy.Hide(), -500)
			SetTimer(this.MainLoop.Bind(this), 1000)
		} else {
			if Config.Get("Main", "AltMacroEnabled", 0)
				this.Fancy.Show("Alt Macro: OFF")
			SetTimer(() => this.Fancy.Hide(), -500)
			SetTimer(this.MainLoop.Bind(this), 0)
			this.Cleanup()
		}
	}

	MainLoop() {
		if !this.IsRunning
			return

		local inactiveHoney := 0
		this.Settings()

		; If the Guiding Star cycle is enabled, run that flow instead of the normal Alt loop.
		;if (Config.Get("Guide", "Enabled", 0)) {
		;	this.GuideCycle()
		;	return
		;}
		if !(this.Reconnect())
			this.Reset()
		fieldName := this.DefaultField
		this.GotoField(fieldName)
		this.PlaceSprinkler()
		this.Rotation()
		this.EnableShift(1)
		sleep 500
		if (IsSet(Boost) && Boost)
			Boost.stats.BuffState["Timer"] := 1

		loop {
			if !this.Shiftlock
				MouseMove windowX + (windowWidth // 2), windowY + (windowHeight // 2)
			if this.UseTool
				click "down"
			if !this.IsRunning {
				click "up"
				break
			}

			this.Gather(this.Pattern, fieldName, A_Index)

			while ((GetKeyState("F14") && (A_Index <= 3600)) || (A_Index = 1)) {
				if !this.IsRunning || this.IsDead() = true || this.Reconnect() {
					click "up"
					break 2
				}

				if (Mod(A_Index, 10) = 0) {
					if (!this.ActiveHoney()) {
						if (++inactiveHoney >= 5) {
							click "up"
							break 2
						}
					} else
						inactiveHoney := 0
				}
				sleep 50
			}
			click "up"

			if (this.FieldDriftComp)
				FieldDriftCompensation()
		}
		this.Cleanup()
		sleep 500
	}

	PlaceSprinkler() {
		if (this.SprinklerLocation = "Center") {
			send "{" SC_1 "}"
			sleep 500
			return
		}
		fieldDims := State.FieldSize.Has(this.DefaultField) ? State.FieldSize[this.DefaultField] : {width: 30, height: 20}
		scale := this.SprinklerDistance / 10
		loc := this.SprinklerLocation
		moveX := 0
		moveY := 0
		if InStr(loc, "Upper")
			moveY := (fieldDims.height / 2) * scale
		else if InStr(loc, "Lower")
			moveY := -(fieldDims.height / 2) * scale
		if InStr(loc, "Left")
			moveX := -(fieldDims.width / 2) * scale
		else if InStr(loc, "Right")
			moveX := (fieldDims.width / 2) * scale
		
		if (moveY != 0) {
			key := (moveY > 0) ? FwdKey : BackKey
			RunPath(walk(Abs(moveY), key))
			KeyWait "F14", "D T5 L"
			KeyWait "F14", "T15 L"
			EndPath()
		}
		if (moveX != 0) {
			key := (moveX > 0) ? RightKey : LeftKey
			RunPath(walk(Abs(moveX), key))
			KeyWait "F14", "D T5 L"
			KeyWait "F14", "T15 L"
			EndPath()
		}
		sleep 100
		send "{" SC_1 "}"
		sleep 500
	}

	Rotation() {
		amt := this.RotationAmount
		if (amt > 0 && amt <= 4) {
			key := (this.RotationDirection = "Left") ? RotLeft : RotRight
			send "{" key " " amt "}"
			sleep 300
		}
	}

	EnableShift(state := 0) {
		if (!this.ShiftLock || !GetRobloxClientPos())
			return
		ActivateRoblox()
		pBMScreen := Gdip_BitmapFromScreen(windowX + 5 "|" windowY + windowHeight - 54 "|50|50")
		if (Gdip_ImageSearch(pBMScreen, bitmaps["shiftlock"], , , , , , 2) != state)
			send "{" SC_LShift "}"
		Gdip_DisposeImage(pBMScreen)
		sleep 50
	}

	Reconnect() {
		reconnect := 0

		; check if roblox is open
		if !(GetRobloxClientPos())
			reconnect := 1
		pBMScreen := Gdip_BitmapFromScreen(windowX + (windowWidth // 2) "|" windowY + windowHeight // 2 "|200|80")
		if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"],,,,,,2) = 1)
			reconnect := 1
		Gdip_DisposeImage(pBMScreen)

		if !reconnect
			return 0
		
		click "up"
		EndPath()
		; possibly add join user for public server ?
		link := Config.Get("Alt", "PrivServer", "")

		loop {
			idx := A_Index
			success := 0
			CloseRoblox()
			if RegExMatch(link, "i)(?<=privateServerLinkCode=)(.{32})", &code) {
				try Run '"roblox://placeID=1537690962&linkcode=' code[0] '"'
			} else if RegExMatch(link, "i)(?<=share\?code=)(.{32})(?=&type=Server)", &code) {
				try Run '"roblox://navigation/share_links?code=' code[0] '&type=Server"'
			} else {
				try Run '"roblox://placeID=1537690962"'
			}

			loop 240 {
				if GetRobloxHWND() {
					ActivateRoblox()
					break
				}
				if (A_Index = 240) {
					break 2
				}
				sleep 1000
			}

			loop 180 {
				ActivateRoblox()
				if !GetRobloxClientPos() {
					sleep 1000
					continue
				}
				pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY + 30 "|" windowWidth "|" windowHeight - 30)
				if (Gdip_ImageSearch(pBMScreen, bitmaps["loading"], , , , , 150, 4) = 1) {
					Gdip_DisposeImage(pBMScreen)
					break
				}
				if (Gdip_ImageSearch(pBMScreen, bitmaps["science"], , , , , 150, 2) = 1) {
					Gdip_DisposeImage(pBMScreen)
					success := 1
					break 2
				}
				if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) = 1) {
					Gdip_DisposeImage(pBMScreen)
					continue 2
				}
				Gdip_DisposeImage(pBMScreen)
				if (A_Index = 180) {
					break 2
				}
				sleep 1000
			}

			loop 180 {
				ActivateRoblox()
				if !GetRobloxClientPos() {
					continue 2
				}
				pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY + 30 "|" windowWidth "|" windowHeight - 30)
				if ((Gdip_ImageSearch(pBMScreen, bitmaps["loading"], , , , , 150, 4) = 0) || (Gdip_ImageSearch(pBMScreen, bitmaps["science"], , , , , 150, 2) = 1)) {
					Gdip_DisposeImage(pBMScreen)
					success := 1
					break 2
				}
				if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) = 1) {
					Gdip_DisposeImage(pBMScreen)
					continue 2
				}
				Gdip_DisposeImage(pBMScreen)
				if (A_Index = 180) {
					break 2
				}
				sleep 1000
			}
		}

		if !success
			return 0
		
		ActivateRoblox()
		GetRobloxClientPos()
		MouseMove windowX + (windowWidth // 2), windowY + (windowHeight // 2)
		sleep 500

		if (this.ClaimHiveEnabled) {
				if this.ClaimHive() {
					return 1
				} else {
					return 0
				}
		} else {
			this.DetectSpawn()
				return 1
		}
	}

	Gather(patternName, field, index) {
		if !this.IsRunning
			return
		if !patterns.Has(patternName) {
			this.Fancy.Show("Pattern '" patternName "' does not exist!")
			return
		}

		DetectHiddenWindows true
		pathRunning := WinExist("ahk_class AutoHotkey ahk_pid " State.CurrentWalk.pid)
		if ((index = 1) || !pathRunning) {
			RunPath(patterns[patternName], "pattern", PatternVars(field))
		} else {
			Send "{F13}"
		}

		DetectHiddenWindows false
		if (KeyWait("F14", "D T5 L") = 0)
			EndPath()
	}

	GotoField(fieldName) {
		if !this.IsRunning
			return
		Send "{" LeftKey " up}{" RightKey " up}{" FwdKey " up}{" BackKey " up}{" SC_Space " up}{" SC_E " up}"
		field := StrReplace(fieldName, " ")
		if !paths["gtf"].Has(field) {
			MsgBox "Path not found: gtf-" field ".ahk"
			return
		}

		RunPath(paths["gtf"][field], , PathVars())
		KeyWait "F14", "D T5 L"
		KeyWait "F14", "T120 L"
		EndPath()
		sleep 100
	}

	Cleanup() {
		Critical
		EndPath()
		Click "up"
		Send "{" LeftKey " up}{" RightKey " up}{" FwdKey " up}{" BackKey " up}{" SC_Space " up}{F14 up}{" SC_E " up}"
	}

	ClaimHive(ignoreCam := 0) {
		State.offsetY := GetYOffset()
		GetImg() {
			pBMScreen := Gdip_BitmapFromScreen(windowX + (windowWidth // 2) - 200 "|" windowY + State.offsetY "|400|150")
			while ((A_Index <= 20) && (Gdip_ImageSearch(pBMScreen, bitmaps["FriendJoin"][1], , , , , , 6) = 1 || Gdip_ImageSearch(pBMScreen, bitmaps["FriendJoin"][2], , , , , , 6) = 1)) {
				Gdip_DisposeImage(pBMScreen)
				MouseMove windowX + (windowWidth // 2) - 3, windowY + 24
				click
				MouseMove windowX + 350, windowY + State.offsetY + 100
				sleep 500
				pBMScreen := Gdip_BitmapFromScreen(windowX + (windowWidth // 2) - 200 "|" windowY + State.offsetY "|400|125")
			}
			return pBMScreen
		}

		ActivateRoblox()
		GetRobloxClientPos()
		MouseMove windowX + 350, windowY + State.offsetY + 100
		if !ignoreCam
			this.DetectSpawn()
		
		movement := this.spawnMoveTo(this.slotMove[this.HiveSlot])
		RunPath(movement)
		KeyWait "F14", "D T5 L"
		KeyWait "F14", "T120 L"
		EndPath()
		sleep 300

		pBMScreen := GetImg()
		if (Gdip_ImageSearch(pBMScreen, bitmaps["claimhive"],,,,,,2,,6) = 1) {
			Gdip_DisposeImage(pBMScreen)
			send "{" SC_E " down}"
			sleep 100
			send "{" SC_E " up}"
			HiveConfirmed := 1
			return 1
		} else if this.atHive() {
			HiveConfirmed := 1
			return 1
		}
		Gdip_DisposeImage(pBMScreen)

		Sleep 500
		GetRobloxClientPos()
		send "{" ZoomOut " 8}"
		movement :=
		(
			'Send "{' RightKey ' down}"
			move(4)
			Send "{' FwdKey ' down}"
			move(20)
			Send "{' RightKey ' up}{' FwdKey ' up}"'
		)
		RunPath(movement)
		KeyWait "F14", "D T5 L"
		KeyWait "F14", "T120 L"
		EndPath()

		slots := Map()
		move := walk(9.2, LeftKey)
		foundHive := false

		Loop this.HiveSlot {
			if (A_Index > 1) {
				RunPath(move)
				KeyWait "F14", "D T5 L"
				KeyWait "F14", "T120 L"
				EndPath()
			}
			sleep 300
			pBMScreen := GetImg()
			if (Gdip_ImageSearch(pBMScreen, bitmaps["claimhive"],,,,,,2,,6) = 1)
				slots[A_Index] := 1
			Gdip_DisposeImage(pBMScreen)
			if (slots.Has(this.HiveSlot) && (slots[this.HiveSlot] = 1)) {
				foundHive := true
				break
			} else {
				if ((slot := ObjMinIndex(slots)) > 0) {
					movement := walk((this.HiveSlot - slot) * 9.2, RightKey)
					RunPath(movement)
					KeyWait "F14", "D T5 L"
					KeyWait "F14", "T120 L"
					EndPath()

					sleep 300
					pBMScreen := GetImg()
					if (Gdip_ImageSearch(pBMScreen, bitmaps["claimhive"],,,,,,2,,6) = 1) {
						this.HiveSlot := slot
						foundHive := true
						break
					}
					Gdip_DisposeImage(pBMScreen)
				} else {
					loop (6 - this.HiveSlot) {
						RunPath(move)
						KeyWait "F14", "D T5 L"
						KeyWait "F14", "T120 L"
						EndPath()

						sleep 300
						pBMScreen := GetImg()
						if (Gdip_ImageSearch(pBMScreen, bitmaps["claimhive"],,,,,,2,,6) = 1) {
							this.HiveSlot := this.HiveSlot + A_Index
							foundHive := true
							break 2
						}
						Gdip_DisposeImage(pBMScreen)
					}
				}
			}
			if (A_Index = 5)
				return 0
		}
		if !foundHive
			return 0

		send "{" SC_E " down}"
		sleep 100
		send "{" SC_E " up}"
		HiveConfirmed := 1
		return 1
	}

	spawnMoveTo(moves) {
		script := ""
		for k in moves {
			dirs := (Type(k.dir) = "Array") ? k.dir : [k.dir]
			for dir in dirs
				script .= 'Send "{' %dir "Key"% ' down}"`n'
			script .= "move(" k.dist ")" "`n"
			for dir in dirs
				script .= 'Send "{' %dir "Key"% ' up}"`n'
		}
		return script
	}

	Reset() {
		static HiveDown := false
		static lastReset := 0
		gracePeriod := 7000

		if (IsSet(Boost) && Boost)
			Boost.stats.BuffState["Timer"] := 0

		this.EnableShift(0)
		Loop 5 {
			ActivateRoblox()
			GetRobloxClientPos()
			PrevKeyDelay := A_KeyDelay
			SetKeyDelay 300
			send "{" SC_Esc "}{" SC_R "}{" SC_Enter "}"

			n := 0
			while ((n < 2) && (A_Index <= 50)) {
				sleep 200
				pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY "|" windowWidth "|50")
				n += ((Gdip_ImageSearch(pBMScreen, bitmaps["emptyhealth"], , , , , , 10) || this.HealthBar()) = (n = 0))
				Gdip_DisposeImage(pBMScreen)
			}
			sleep 750
			SetKeyDelay PrevKeyDelay

			if (!this.ClaimHiveEnabled) {
				if this.DetectSpawn() {
					lastReset := A_TickCount
					return
				}
			} else {
				grace := (A_TickCount - lastReset) < gracePeriod
				if ((grace || !this.atHive()) && this.DetectSpawn()) {
					sleep 500
					if this.ClaimHive(1) {
						lastReset := A_TickCount
						return
					}
				}
				if (HiveDown)
					sendinput "{" RotDown "}"
				region := windowX "|" windowY + 3 * windowHeight // 4 "|" windowWidth "|" windowHeight // 4
				sconf := windowWidth ** 2 // 3200

				loop 4 {
					sleep 250
					pBMScreen := Gdip_BitmapFromScreen(region), s := 0
					for i, k in bitmaps["hive"] {
						s := Max(s, Gdip_ImageSearch(pBMScreen, k, , , , , , 5, , , sconf))
						if (s >= sconf) {
							Gdip_DisposeImage(pBMScreen)
							HiveConfirmed := 1
							sendinput "{" RotRight " 4}" (HiveDown ? ("{" RotUp "}") : "")
							Send "{" ZoomOut " 5}"
							return
						}
					}
					Gdip_DisposeImage(pBMScreen)
					sendinput "{" RotRight " 4}" ((A_Index = 2) ? ("{" ((HiveDown := !HiveDown) ? RotDown : RotUp) "}") : "")
				}
			}
		}

		CloseRoblox()
		while !(this.Reconnect()) {
			sleep 1000
			CloseRoblox()
		}
		return
	}

	HealthBar() {
		local detection := 0

		static isDead(c) => ((((c) & 0x00FF0000 >= 0x004D0000) && ((c) & 0x00FF0000 <= 0x00830000)) ; 4D4D4D-blackBG|838383-whiteBG
			&& (((c) & 0x0000FF00 >= 0x00004D00) && ((c) & 0x0000FF00 <= 0x00008300))
			&& (((c) & 0x000000FF >= 0x0000004D) && ((c) & 0x000000FF <= 0x00000083)))
		try {
			GetRobloxClientPos(hwnd := GetRobloxHWND())
			pBMScreen := Gdip_BitmapFromScreen(windowX + windowWidth - 100 "|" windowY + State.offsetY "|50|24")

			p := Gdip_GetPixel(pBMScreen, 25, 12)
			if isDead(p)
				detection := 1
		} catch
			return 0
		finally
			Gdip_DisposeImage(pBMScreen)
		return detection
	}

	atHive() {
		static fail := 0
		ActivateRoblox()
		GetRobloxClientPos()
		pBMScreen := Gdip_BitmapFromScreen(windowX + windowWidth // 2 - 200 "|" windowY + State.offsetY + 20 "|400|100")
		out := Gdip_ImageSearch(pBMScreen, bitmaps["honey"], , , , , , 5) = 1 ||  Gdip_ImageSearch(pBMScreen, bitmaps["collect"], , , , , , 5) = 1
		Gdip_DisposeImage(pBMScreen)
		fail := out = 1 ? 0 : fail + 1
		if fail > 3 {
			fail := 0
			return 1
		}
		return out
	}

	DetectSpawn() {
		ActivateRoblox()
		GetRobloxClientPos()
		loop 5
			send("{" ZoomIn "}"), sleep(50)
		send("{" RotDown " 11}"), sleep(100), send("{" RotUp " 5}")
		region := windowX "|" windowY "|" windowWidth "|" windowHeight // 4
		sconf := windowWidth ** 2 // 3200
		spawnConfirmed := 0
		loop 4 {
			sleep 250
			pBMScreen := Gdip_BitmapFromScreen(region), s := 0
			for i, k in bitmaps["spawn"] {
				s := Max(s, Gdip_ImageSearch(pBMScreen, k, , , , , , 13, , , sconf))
				if (s >= sconf) {
					Gdip_DisposeImage(pBMScreen)
					spawnConfirmed := 1
					Send "{" RotUp " 2}"
					loop 5
						send("{" ZoomOut "}"), sleep(50)
					break 2
				}
			}
			Gdip_DisposeImage(pBMScreen)
			sendinput "{" RotRight " 4}"
		}
		return spawnConfirmed
	}

	ActiveHoney() {
		static a := unset
		if !IsSet(a)
			a := Gdip_CreateBitmap(1, 1), pGraphics := Gdip_GraphicsFromImage(a), Gdip_GraphicsClear(pGraphics, 0xFFFFE280), Gdip_DeleteGraphics(pGraphics)

		if !GetRobloxClientPos()
			return false

		if this.IgnoreInactiveHoney
			return true

		pBMScreen := Gdip_BitmapFromScreen(windowX + windowWidth // 2 - 90 "|" windowY + State.offsetY "|70|34")
		if (Gdip_ImageSearch(pBMScreen, a, , , , , , 20) > 0) {
			Gdip_DisposeImage(pBMScreen)
			return true
		}

		Gdip_DisposeImage(pBMScreen)
		return false
	}

	isDead() {
		static LastDeath := 0
		if ((nowUnix() - LastDeath) < 5)
			return true

		pBMScreen := Gdip_BitmapFromScreen(windowX + windowWidth // 2 "|" windowY + windowHeight // 2 "|" windowWidth // 2 "|" windowHeight // 2)
		if (Gdip_ImageSearch(pBMScreen, bitmaps["died"], , , , , , 50) = 1) {
			Gdip_DisposeImage(pBMScreen)
			LastDeath := nowUnix()
			return true
		}
		Gdip_DisposeImage(pBMScreen)
		return false
	}


	AfterJoinCommon() {
		try ActivateRoblox()
		try GetRobloxClientPos()
		if (this.ClaimHiveEnabled)
			try this.ClaimHive()
		try this.Rotation()
	}

	GatherForSeconds(fieldName, seconds) {
		start := A_TickCount
		local inactiveHoney := 0
		while (this.IsRunning && ((A_TickCount - start) < (seconds * 1000))) {
			if !this.Shiftlock
				MouseMove windowX + (windowWidth // 2), windowY + (windowHeight // 2)
			if this.UseTool
				Click "down"
			this.Gather(this.Pattern, fieldName, 1)

			if (this.IsDead() = true || this.Reconnect()) {
				Click "up"
				break
			}
			if (Mod((A_TickCount - start) // 1000, 10) = 0) {
				if (!this.ActiveHoney()) {
					if (++inactiveHoney >= 5) {
						Click "up"
						break
					}
				} else
					inactiveHoney := 0
			}
			sleep 50
		}
		Click "up"
	}

	JoinPublicServer() {
		try CloseRoblox()
		try Run '"roblox://placeID=1537690962"'
		return this.WaitForRobloxLoaded(420)
	}

	JoinPrivateServer(link) {
		link := Trim(link)

		linkCode := ""
		if RegExMatch(link, "i)(?:privateServerLinkCode|linkCode|joinCode)=([^&]+)", &m) {
			linkCode := m[1]
		}

		try CloseRoblox()

		if (linkCode != "") {
			try Run('roblox://placeID=1537690962&linkCode=' linkCode)
		} else {
			try Run(link)
		}

		return this.WaitForRobloxLoaded(420)
	}

	WaitForRobloxLoaded(timeoutSeconds := 420) {
		Loop timeoutSeconds {
			if (GetRobloxHWND()) {
				ActivateRoblox()
				break
			}
			if !this.IsRunning
				return false
			sleep 1000
		}
		if !GetRobloxHWND()
			return false

		Loop 240 { ; ignore this for now, used for testing gather
			ActivateRoblox()
			if !GetRobloxClientPos() {
				sleep 500
				continue
			}
			pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY + 30 "|" windowWidth "|" windowHeight - 30)
			if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) = 1) {
				Gdip_DisposeImage(pBMScreen)
				return false
			}
			if ((Gdip_ImageSearch(pBMScreen, bitmaps["loading"], , , , , 150, 4) = 0)
				|| (Gdip_ImageSearch(pBMScreen, bitmaps["science"], , , , , 150, 2) = 1)) {
				Gdip_DisposeImage(pBMScreen)
				return true
			}
			Gdip_DisposeImage(pBMScreen)
			if !this.IsRunning
				return false
			sleep 1000
		}
		return false
	}

	WaitForGuidingStarAnnouncement(timeoutSeconds := 600) {
		start := A_TickCount
		while (this.IsRunning && ((A_TickCount - start) < (timeoutSeconds * 1000))) {
			try ActivateRoblox()
			try GetRobloxClientPos()
			text := this.OcrTopAnnouncement()
			if (text != "" && InStr(StrLower(text), "guiding") && InStr(StrLower(text), "star"))
				return text
			sleep 1000
		}
		return ""
	}

	OcrTopAnnouncement() {
		hwnd := GetRobloxHWND()
		if !hwnd
			return ""
		GetRobloxClientPos(hwnd)
		offsetY := GetYOffset(hwnd)
		if (windowWidth < 600 || windowHeight < 500)
			return ""

		x := windowX + (windowWidth // 2) - 500
		y := windowY + offsetY + 40
		w := 1000
		h := 140
		pBM := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
		hBM := Gdip_CreateHBITMAPFromBitmap(pBM)
		Gdip_DisposeImage(pBM)
		pStream := HBitmapToRandomAccessStream(hBM)
		DllCall("DeleteObject", "Ptr", hBM)
		try out := ocr(pStream)
		catch
			out := ""
		return Trim(out)
	}

	GuideCycle() {

		target := this.NormalizeGuideField(Config.Get("Guide", "Field", "pepper"))
		privLink := Trim(Config.Get("Guide", "PrivLink", ""))

		; use the user's configured alt gather field/pattern
		waitField := this.DefaultField
		if (waitField = "")
			waitField := "dandelion"

		if (privLink = "")
			return

		while (this.IsRunning && Config.Get("Guide", "Enabled", 0)) {
			if !this.JoinPublicServer()
				continue

			this.AfterJoinCommon()

			this.GotoField(waitField)
			this.PlaceSprinkler()
			this.EnableShift(1)

			this.GatherForSeconds(waitField, 240)

			if !this.IsRunning
				break

			if !this.JoinPrivateServer(privLink)
				continue

			this.AfterJoinCommon()

			this.GotoField(waitField)
			this.PlaceSprinkler()
			this.EnableShift(1)

			start := A_TickCount
			foundField := ""

			while (this.IsRunning) {

				this.Gather(this.Pattern, waitField, 1)

				if this.GuidingDetected() {
					foundField := this.DetectGuideField()
					break
				}

				if ((A_TickCount - start) > 600000)
					break
			}

			if (!this.IsRunning)
				break

			if (foundField = target) {

				gotoKey := this.GuideFieldKeyToGoto(foundField)

				if (gotoKey != "") {

					this.GotoField(gotoKey)
					this.PlaceSprinkler()
					this.EnableShift(1)

					this.GatherForSeconds(gotoKey, 600)
				}
			}
		}
	}

	GuidingDetected() {

		if !GetRobloxClientPos()
			return false

		pBM := Gdip_BitmapFromScreen(
			windowX + (windowWidth // 2 - 450) "|"
			windowY + 40 "|900|160"
		)

		found := (Gdip_ImageSearch(pBM, bitmaps["guiding"], , , , , , 20) > 0)

		Gdip_DisposeImage(pBM)

		return found
	}

	DetectGuideField() {

		if !GetRobloxClientPos()
			return ""

		pBM := Gdip_BitmapFromScreen(
			windowX + (windowWidth // 2 - 450) "|"
			windowY + 40 "|900|160"
		)

		if (Gdip_ImageSearch(pBM, bitmaps["guide_pepper"], , , , , , 20) > 0)
			field := "pepper"
		else if (Gdip_ImageSearch(pBM, bitmaps["guide_spider"], , , , , , 20) > 0)
			field := "spider"
		else if (Gdip_ImageSearch(pBM, bitmaps["guide_rose"], , , , , , 20) > 0)
			field := "rose"
		else if (Gdip_ImageSearch(pBM, bitmaps["guide_pinetree"], , , , , , 20) > 0)
			field := "pinetree"
		else if (Gdip_ImageSearch(pBM, bitmaps["guide_bamboo"], , , , , , 20) > 0)
			field := "bamboo"
		else if (Gdip_ImageSearch(pBM, bitmaps["guide_bff"], , , , , , 20) > 0)
			field := "bff"
		else
			field := ""

		Gdip_DisposeImage(pBM)

		return field
	}

	NormalizeGuideField(fieldVal) {
		v := StrLower(Trim(fieldVal))
		v := StrReplace(v, " ", "")
		if (v = "pinetree" || v = "pinetreeforest" || v = "pinetree")
			return "pinetree"
		if (v = "blueflower" || v = "bff")
			return "bff"
		if (v = "pepper" || v = "spider" || v = "rose" || v = "bamboo")
			return v
		return "pepper"
	}

	GuideFieldKeyToGoto(key) {
		switch key {
			case "pepper": return "pepper"
			case "spider": return "spider"
			case "rose": return "rose"
			case "pinetree": return "pinetree"
			case "bamboo": return "bamboo"
			case "bff": return "blueflower"
			default: return "pepper"
		}
	}
}
