class Conditions {
	BuffState := Map(
		"Timer", 0
		, "scorch", 0
		, "gummy", 0
		, "glitter", 0.00
		, "smoothie", 0.00
		, "shower", 0
		, "popstar", 0
		, "baller", 0
	)

	topBuff := Map(
		"glitter", { key: "glitter", var: 0, time: 1, type: "boost" }
		, "scorch", { key: "scorch_buff", var: 21, time: 0, type: "buff", inv: "scorch" }
		, "smoothie", { key: "smoothie", var: 4, time: 1, type: "buff" }
		, "popstar", { key: "popstar_buff", var: 21, time: 0, type: "buff", inv: "popstar" }
		, "baller", { key: "baller", var: 0, time: 0, type: "buff" }
	)

	bottomBuff := Map(
		"gummy", { key: "gummy", var: 0, time: 0, type: "buff" }
		, "shower", { key: "shower", var: 0, time: 0, type: "buff" }
		, "scorch", { key: "scorch", var: 30, time: 0, type: "check" }
		, "popstar", { key: "popstar", var: 30, time: 0, type: "check" }
	)

	Modes := Map(
		"Timer", (idx) => this.BuffState["Timer"],
		"On Scorch", (idx) => this.BuffState["scorch"],
		"On Gummy", (idx) => this.BuffState["gummy"],
		"ReGlitter", (idx) => this.BuffState["glitter"],
		"ReSmoothie", (idx) => this.BuffState["smoothie"],
		"On Shower", (idx) => this.BuffState["shower"],
		"On Pop Star", (idx) => this.BuffState["popstar"],
		"On Baller", (idx) => this.BuffState["baller"]
	)

	Fancy := GdipTooltip()

	__New() {
		Scheduler.Add("BoostBar.SearchBuffs", this.SearchBuffs.Bind(this), 100)
		;SetTimer(this.displayState.Bind(this), 100)
	}

	displayState() {
		ToolTip(JSON.stringify(this.BuffState))
	}

	SearchBuffs(*) {
		if (Config.Get("Main", "AltMacroEnabled", 0))
			return

		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok || !Config.Get("Main", "BoostBarEnabled", 0)
			return

		regionTop := win.x "|" win.y + State.offsetY + 36 "|" win.w "|" 38
		regionBottom := win.x + (win.w // 2) - 257 "|" win.y + win.h - 142 "|517|36"

		pBMTop := FrameCache.Get(regionTop)
		pBMBottom := FrameCache.Get(regionBottom)

		top := this.Scan(pBMTop, this.topBuff)
		bottom := this.Scan(pBMBottom, this.bottomBuff)

		for name, data in this.topBuff {
			isActive := false
			if (top.Has(name) && top[name].found) {
				isActive := true
				if (data.HasOwnProp("inv") && data.inv != "") {
					inv := data.inv
					if (bottom.Has(inv) && bottom[inv].found) {
						isActive := false
					}
				}
			}
			if (name = "glitter" || name = "smoothie") {
				this.UpdateStreak(name, isActive, (isActive ? top[name].val : 0))
			} else {
				this.BuffState[name] := isActive ? 1 : 0
			}
		}

		for name, data in this.bottomBuff {
			if (data.type = "check")
				continue
			
			if (bottom.Has(name) && bottom[name].found) {
				this.BuffState[name] := 1
			} else {
				this.BuffState[name] := 0
			}
		}

		static last := ""
		current := JSON.stringify(this.BuffState)
		if (current != last) {
			if IsSet(Comms) {
				Comms.BroadcastBuffs(this.BuffState)
				last := current
			}
		}
	}

	Scan(pBitmap, list) {
		results := Map()
		if !pBitmap
			return results

		for name, data in list {
			found := false
			val := 0

			if (name = "glitter") {
				field := Config.Get("Alt", "DefaultField", "pepper")
				for variant in ["3", "1", "0"] {
					try {
						if (Gdip_ImageSearch(pBitmap, bitmaps["boost"][field . variant], &loc, , , , , variant = 3 ? 50 : 35) = 1) {
							x := SubStr(loc, 1, InStr(loc, ",") - 1)
							gridX := Floor(x / 38) * 38
							val := this.MeasureBoost(pBitmap, gridX)
							found := true
							break
						}
					}
				}
			} else if (Gdip_ImageSearch(pBitmap, bitmaps["buff"][data.key], &loc, , , , , data.var, , 6) = 1) {
				found := true
				if (data.time != 0) {
					x := SubStr(loc, 1, InStr(loc, ",") - 1)
					gridX := Floor(x / 38) * 38
					val := this.MeasureBuff(pBitmap, gridX)
				}
			}
			results[name] := {found: found, val: val}
		}
		return results
	}

	UpdateStreak(name, found, val) {
		static Streak := Map("glitter", 0, "smoothie", 0)
		static Thresholds := Map("glitter", 0.01, "smoothie", 0.01)

		if (found && val > 0 && val <= Thresholds[name]) {
			Streak[name] += 1
		} else {
			Streak[name] := 0
		}
		this.BuffState[name] := (Streak[name] >= 10) ? 1 : 0
	}

	MeasureBuff(pBitmap, slotX) {
		static fail := 0
		static last := 0

		scanX := slotX
		if Gdip_GetPixel(pBitmap, scanX, 37) != 0xFFFEC650 {
			if (++fail < 10)
				return last
			return 0
		}

		fail := 0
		low := 0, high := 35
		while (low < high) {
			mid := Floor((low + high) / 2)
			if Gdip_GetPixel(pBitmap, scanX, mid) = 0xFFFEC650
				high := mid
			else
				low := mid + 1
		}
		return Round((36 - low) / 36, 2)
	}

	MeasureBoost(pBitmap, slotX?) {
		static fail := 0
		static last := 0
		static isBooster(c) => ((((c) & 0x00FF0000 >= 0x00b80000) && ((c) & 0x00FF0000 <= 0x00e10000)) ; b8a43a-blackBG|e1cd63-whiteBG
			&& (((c) & 0x0000FF00 >= 0x0000a400) && ((c) & 0x0000FF00 <= 0x0000cd00))
			&& (((c) & 0x000000FF >= 0x0000003a) && ((c) & 0x000000FF <= 0x00000063)))
		scanX := slotX

		if !isBooster(Gdip_GetPixel(pBitmap, scanX, 37)) {
			if (++fail < 15)
				return last
			return 0
		}

		fail := 0
		low := 0, high := 35
		while (low < high) {
			mid := Floor((low + high) / 2)
			if isBooster(Gdip_GetPixel(pBitmap, scanX, mid))
				high := mid
			else
				low := mid + 1
		}
		return Round((36 - low) / 36, 2)
	}
}

class BoostBar {
	Gui := unset
	IsRunning := false
	IsEnabled := false
	IsActive := false

	SlotW := 68
	SlotH := 36
	Gap := 7
	TotalW := (68 * 7) + (7 * 6) + 4
	TotalH := 36
	BrushBack := 0
	BrushOff := 0
	BrushOn := 0
	BrushSpecial := 0
	BrushMulti := 0
	BrushTimer := 0
	BrushRunning := 0

	stats := Conditions()
	ConfigCache := { enabled: 0, showWhenActive: 1, slotActive: [], slotTimer: [], slotModes: [], slotModeStr: [] }
	SpamFn := 0

	__New() {
		this.RefreshConfig()
		this.InitBrushes()
		this.CreateUI()

		OnMessage(0x201, this.OnClick.Bind(this))
		OnMessage(0x204, this.OnRightClick.Bind(this))

		Scheduler.Add("BoostBar.FollowWindow", this.FollowWindow.Bind(this), 50)
		this.SpamFn := this.SpamLoop.Bind(this)
	}

	Cleanup() {
		Scheduler.Remove("BoostBar.FollowWindow")
		Scheduler.Remove("BoostBar.SearchBuffs")
		Scheduler.Remove("BoostBar.SpamLoop")
		this.DisposeBrushes()
		SelectObject(this.hdc, this.obm)
		DeleteObject(this.hbm)
		DeleteDC(this.hdc)
		Gdip_DeleteGraphics(this.G)
	}

	CreateUI(*) {
		this.Gui := Gui("-Caption +E0x80000 +AlwaysOnTop +ToolWindow +OwnDialogs", "Boost Bar")
		(this.ConfigCache.enabled ? this.Gui.Show("NA") : this.Gui.Hide())

		this.hbm := CreateDIBSection(this.TotalW, this.TotalH)
		this.hdc := CreateCompatibleDC()
		this.obm := SelectObject(this.hdc, this.hbm)
		this.G := Gdip_GraphicsFromHDC(this.hdc)
		Gdip_SetSmoothingMode(this.G, 4)
		this.Draw()
	}

	Draw(*) {
		this.RefreshConfig()
		cache := this.ConfigCache
		Gdip_GraphicsClear(this.G)

		Gdip_FillRoundedRectangle(this.G, this.BrushBack, 0, 0, this.TotalW, this.TotalH, 5)

		loop 7 {
			idx := A_Index
			isSlotActive := cache.slotActive[idx]
			modeStr := cache.slotModeStr[idx]
			activeModes := cache.slotModes[idx]
			timerVal := cache.slotTimer[idx]

			x := 2 + (idx - 1) * (this.SlotW + this.Gap)
			y := 2

			if !(isSlotActive) {
				btnColor := this.BrushOff
				displayText := "Off"
			} else {
				if (activeModes.Length > 1) {
					btnColor := this.BrushMulti
					displayText := "Multi"
				} else if (activeModes.Length = 1 && activeModes[1] != "") {
					displayText := activeModes[1]
					btnColor := (activeModes[1] = "Timer") ? this.BrushOn : this.BrushSpecial
				} else {
					btnColor := this.BrushOff
					displayText := "None"
				}
			}

			Gdip_FillRoundedRectangle(this.G, btnColor, x, y, this.SlotW, 16, 3)

			Options := "x" x " y" y + 1 " w" this.SlotW " h16 Center vCenter cFFFFFFFF s9 Bold"
			Gdip_TextToGraphics(this.G, displayText, Options, "Segoe UI")

			Gdip_FillRoundedRectangle(this.G, this.BrushTimer, x, y + 18, this.SlotW, 14, 3)
			Options := "x" x " y" y + 18 " w" this.SlotW " h14 Center vCenter cFFFFFFFF s10"
			Gdip_TextToGraphics(this.G, String(timerVal), Options, "Segoe UI")
		}

		if (this.IsRunning && !State.IsPaused) {
			Gdip_FillRectangle(this.G, this.BrushRunning, 0, this.TotalH - 2, this.TotalW, 2)
		}

		UpdateLayeredWindow(this.Gui.Hwnd, this.hdc, , , this.TotalW, this.TotalH)
	}

	OnClick(wParam, lParam, msg, hwnd) {
		if (hwnd != this.Gui.hwnd)
			return

		x := lParam & 0xFFFF
		y := lParam >> 16
		this.HandleClick(x, y, "Left")
	}

	OnRightClick(wParam, lParam, msg, hwnd) {
		if (hwnd != this.Gui.hwnd)
			return

		x := lParam & 0xFFFF
		y := lParam >> 16
		this.HandleClick(x, y, "Right")
	}

	HandleClick(x, y, clickType) {
		loop 7 {
			slotX := 2 + (A_Index - 1) * (this.SlotW + this.Gap)
			if (x >= slotX && x <= slotX + this.SlotW) {
				if (y <= 18) {
					if (clickType = "Right") {
						this.OpenModeMenu(A_Index)
					} else {
						try WinActivate("ahk_id " WinExist("Roblox ahk_exe RobloxPlayerBeta.exe"))
						(GetKeyState("w")) ? (send("{w up}"), send("{w down}")) : ""
						(GetKeyState("s")) ? (send("{s up}"), send("{s down}")) : ""
						(GetKeyState("d")) ? (send("{d up}"), send("{d down}")) : ""
						(GetKeyState("a")) ? (send("{a up}"), send("{a down}")) : ""
						this.ToggleSlot(A_Index)
					}
				} else if (y > 18 && y < 34) {
					this.OpenEdit(A_Index, slotX, 20)
				}
				return
			}
		}
	}

	OpenModeMenu(idx) {
		m := Menu()
		currentStr := Config.Get("BoostBar", "SlotMode" idx, "Timer")
		currentList := StrSplit(currentStr, "|")

		HasMode := (name) => InStr("|" currentStr "|", "|" name "|")

		for modeName, func in this.stats.Modes {
			m.Add(modeName, ObjBindMethod(this, "ToggleMode", idx, modeName))
			if HasMode(modeName)
				m.Check(modeName)
		}
		m.Show()
	}

	ToggleMode(idx, modeName, *) {
		currentStr := Config.Get("BoostBar", "SlotMode" idx, "Timer")
		currentList := StrSplit(currentStr, "|")

		newList := []
		found := false

		for item in currentList {
			if (item = modeName) {
				found := true
			} else if (item != "")
				newList.Push(item)
		}
		if !(found)
			newList.Push(modeName)

		newStr := ""
		for item in newList
			newStr .= (A_Index > 1 ? "|" : "") item

		Config.Set("BoostBar", "SlotMode" idx, newStr)
		Config.WriteIni()
		this.RefreshConfig()
		this.Draw()
	}

	ToggleSlot(idx) {
		curr := Config.Get("BoostBar", "SlotActive" idx, 0)
		Config.Set("BoostBar", "SlotActive" idx, !curr)
		Config.WriteIni()
		this.RefreshConfig()
		this.Draw()
	}

	OpenEdit(idx, x, y) {
		tempGui := Gui("-Caption +Owner" this.Gui.hwnd)
		tempGui.SetFont("s10", "Segoe UI")
		WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " this.Gui.hwnd)
		screenX := wx + x
		screenY := wy + y
		currentVal := Config.Get("BoostBar", "SlotTimer" idx, 0)

		ed := tempGui.Add("Edit", "w" this.SlotW " h18 Center Number", currentVal)

		SubmitEdit(*) {
			Config.Set("BoostBar", "SlotTimer" idx, ed.Value)
			Config.WriteIni()
			this.RefreshConfig()
			tempGui.Destroy()
			this.Draw()
		}

		ed.OnEvent("LoseFocus", SubmitEdit)
		tempGui.OnEvent("Escape", (*) => tempGui.Destroy())
		HotIfWinActive("ahk_id " tempGui.hwnd)
		Hotkey("Enter", SubmitEdit, "On")

		tempGui.Show("x" screenX " y" screenY " NoActivate")
		ed.Focus()
		Send("^a")
	}

	FollowWindow(*) {
		try {
			win := WindowTracker.Get()
			if IsObject(win) && win.ok {
				wx := win.x, wy := win.y, ww := win.w, wh := win.h
				targetX := wx + (ww // 2) - 261
				targetY := wy + wh - 182
				show := this.ConfigCache.enabled && ((!this.IsRunning || State.IsPaused) || this.ConfigCache.showWhenActive)
				(show ? this.Gui.Show("NA x" targetX " y" targetY " w" this.TotalW " h" this.TotalH) : this.Gui.Hide())
			} else {
				this.Gui.Hide()
			}
		}
	}

	Toggle(*) {
		this.RefreshConfig()
		this.IsRunning ^= 1
		this.IsEnabled := this.ConfigCache.enabled
		this.IsActive := this.IsRunning && this.IsEnabled
		this.stats.BuffState["Timer"] := this.IsActive ? 1 : 0
		this.Draw()
		if (this.IsEnabled) {
			if (this.IsActive && !this.ConfigCache.showWhenActive) {
				this.Gui.Hide()
			} else {
				this.Gui.Show("NA")
				this.Draw()
			}
		} else
			this.Gui.Hide()
		if (this.IsActive)
			Scheduler.Add("BoostBar.SpamLoop", this.SpamFn, 5)
		else
			Scheduler.Remove("BoostBar.SpamLoop")
	}

	SpamLoop(*) {
		if (State.IsPaused)
			return
		cache := this.ConfigCache
		if !cache.enabled || !this.IsRunning
			return

		static lastFire := Map()

		loop 7 {
			idx := A_Index
			if cache.slotActive[idx] {
				delay := cache.slotTimer[idx]
				now := A_TickCount

				if !lastFire.Has(idx) || (now - lastFire[idx] >= delay) {
					activeModes := cache.slotModes[idx]

					shouldFire := (activeModes.Length > 0)
					for name in activeModes {
						if (name != "" && this.stats.Modes.Has(name)) {
							if (!this.stats.Modes[name](idx)) {
								shouldFire := false
								break
							}
						}
					}
					if (shouldFire) {
						Send idx
						lastFire[idx] := now
					}
				}
			} else {
				if lastFire.Has(idx)
					lastFire.Delete(idx)
			}
		}
	}

	RefreshConfig() {
		cache := this.ConfigCache
		cache.enabled := Config.Get("Main", "BoostBarEnabled", 0)
		cache.showWhenActive := Config.Get("BoostBar", "ShowWhenActive", 1)
		cache.slotActive := []
		cache.slotTimer := []
		cache.slotModes := []
		cache.slotModeStr := []

		loop 7 {
			idx := A_Index
			cache.slotActive.Push(Config.Get("BoostBar", "SlotActive" idx, 0))
			cache.slotTimer.Push(Config.Get("BoostBar", "SlotTimer" idx, 100))
			modeStr := Config.Get("BoostBar", "SlotMode" idx, "Timer")
			cache.slotModeStr.Push(modeStr)
			cache.slotModes.Push(modeStr = "" ? [] : StrSplit(modeStr, "|"))
		}
	}

	InitBrushes() {
		if this.BrushBack
			return
		this.BrushBack := Gdip_BrushCreateSolid(0xCC111111)
		this.BrushOff := Gdip_BrushCreateSolid(0xFF333333)
		this.BrushOn := Gdip_BrushCreateSolid(0xFF4cAF50)
		this.BrushSpecial := Gdip_BrushCreateSolid(0xFF3480EB)
		this.BrushMulti := Gdip_BrushCreateSolid(0xFF9C27B0)
		this.BrushTimer := Gdip_BrushCreateSolid(0xFF222222)
		this.BrushRunning := Gdip_BrushCreateSolid(0xFFFF0000)
	}

	DisposeBrushes() {
		for _, handle in [this.BrushBack, this.BrushOff, this.BrushOn, this.BrushSpecial, this.BrushMulti, this.BrushTimer, this.BrushRunning] {
			if handle
				Gdip_DeleteBrush(handle)
		}
		this.BrushBack := this.BrushOff := this.BrushOn := this.BrushSpecial := this.BrushMulti := this.BrushTimer := this.BrushRunning := 0
	}
}
