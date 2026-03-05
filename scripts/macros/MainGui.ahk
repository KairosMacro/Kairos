class MainGui {
	Selectors := Map()
	Gui := unset
	FeatureList := ["Warns", "Boost Bar", "Alt Macro", "Key Alignment", "Passive Scanner", "Magnifier"]
	FwdDown := false
	BackDown := false
	LeftDown := false
	RightDown := false
	__New() {
		this.Gui := Gui((Config.Get("Main", "AlwaysOnTop", 0) ? "+AlwaysOnTop " : "") " +Border +OwnDialogs", "Kairos")
		this.Gui.Show("x" Config.Get("Main", "GuiX", A_ScreenWidth // 2 - 200) " y" Config.Get("Main", "GuiY", A_ScreenHeight // 2 - 100) " w400 h220")
		this.FeatureRefreshers := Map(
			"BoostBarEnabled", () => (IsSet(Boost) && Boost) ? Boost.RefreshConfig() : 0,
			"WarnsEnabled", () => (IsSet(Warns) && Warns) ? Warns.RefreshConfig() : 0,
			"PassiveScannerEnabled", () => (IsSet(Scorch) && Scorch) ? Scorch.RefreshConfig() : 0
		)

		; General UI
		this.Gui.OnEvent("Close", (*) => ExitApp())
		this.Gui.SetFont("s8 cDefault Norm")
		(GuiCtrl := this.Gui.Add("Text", "x400 y205 w90 -Wrap +BackgroundTrans", "v" version)), GuiCtrl.Move(396 - (TextWidth := this.TextExtend("v" version, GuiCtrl)))
		this.Gui.Add("Button", "x5 y198 w65 h20 -Wrap vStartButton", "Start (" Config.Get("Main", "StartHotkey", "F1") ")").OnEvent("Click", this.start.Bind(this))
		this.Gui.Add("Button", "x75 y198 w65 h20 -Wrap vPauseButton", "Pause (" Config.Get("Main", "PauseHotkey", "F2") ")").OnEvent("Click", this.pause.Bind(this))
		this.Gui.Add("Button", "x145 y198 w65 h20 -Wrap vStopButton", "Stop (" Config.Get("Main", "StopHotkey", "F3") ")").OnEvent("Click", this.stop.Bind(this))

		TabArr := ["Main", "Alt", "Scanner", "Warnings", "Boost Bar", "Communicator", "Key Alignment"]
		(TabCtrl := this.Gui.Add("Tab", "x0 y-1 w440 h240 -Wrap " (Config.Get("Main", "DarkMode", 1) ? "cFFFFFF" : "C000000"), TabArr)).OnEvent("Change", (*) => TabCtrl.Focus())
		SendMessage 0x1331, 0, 20, , TabCtrl
		; --- Main Tab ---
		TabCtrl.UseTab("Main")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y20 w110 h145 -Wrap", "")
		this.Gui.Add("Text", "x20 y22 w85 h20 -Wrap", "Main Features")
		this.Gui.SetFont("s8 cDefault Norm")
		for i in this.FeatureList {
			name := StrReplace(i, " ", "") "Enabled"
			isEnabled := Config.Get("Main", name, 0)
			(GuiCtrl := this.Gui.Add("CheckBox", "x15 y" 40 + (20 * (A_Index - 1)) " w20 h20 -Wrap v" name " Checked" isEnabled, "")).Section := "Main", GuiCtrl.OnEvent("Click", this.ToggleFeature.Bind(this))
			this.Gui.Add("Text", "x35 y" 43 + (20 * (A_Index - 1)) " w80 h20 -Wrap", i)
		}
		; --- Warnings Tab ---
		TabCtrl.UseTab("Warnings")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y20 w180 h140 -Wrap", "")
		this.Gui.Add("Text", "x20 y22 w103 h20 -Wrap", "Precision Settings")

		this.Gui.Add("Text", "x15 y45", "Threshold:")
		this.Gui.Add("Edit", "x76 y42 w50 Number vWarns_StartWarn", Config.Get("Warns", "StartWarn", 25)).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("UpDown", "Range0-60", Config.Get("Warns", "StartWarn", 25))
		this.Gui.Add("Text", "x+5 yp+3", "Seconds")

		this.Gui.Add("Text", "x15 y70", "Volume:")
		this.Gui.Add("Edit", "x61 y68 w50 Number vWarns_Volume", Config.Get("Warns", "Volume", 25)).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("UpDown", "Range0-100", Config.Get("Warns", "Volume", 25))
		this.Gui.Add("Text", "x+5 yp+3", "%")

		this.Gui.Add("Text", "x15 y95", "Sound:")
		this.Gui.Add("Button", "x+5 y92 w60 h20", "Browse").OnEvent("Click", this.SelectSound.Bind(this))
		this.Gui.Add("Button", "xp+60 yp w60 h20 vWarns_ResetSoundFile", "Test").OnEvent("Click", this.TestAudio.Bind(this))
		this.Gui.Add("Edit", "x15 y120 w170 h20 ReadOnly vWarns_SoundFile", Config.Get("Warns", "SoundFile", "C:\Windows\Media\Windows Critical Stop.wav"))

		; --- Boost Bar Tab ---
		TabCtrl.UseTab("Boost Bar")
		this.Gui.Add("Text", "x20 y25 w40", "Active")
		this.Gui.Add("Text", "x75 y25 w60", "Timer(s)")
		this.Gui.Add("Text", "x130 y25 w80", "Mode(s)")

		loop 7 {
			yPos := 45 + ((A_Index - 1) * 20)
			i := A_Index

			this.Gui.Add("Text", "x10 y" yPos " w36 h20 -Wrap", "Slot " i ":")
			this.Gui.Add("CheckBox", "x50 y" yPos - 2 " w20 h20 vBoostBar_SlotActive" i " Checked" Config.Get("BoostBar", "SlotActive" i, 0)).OnEvent("Click", this.SaveConfig.Bind(this))
			this.Gui.Add("Edit", "x75 y" yPos - 3 " w50 h20 Number vBoostBar_SlotTimer" i, Config.Get("BoostBar", "SlotTimer" i, 100)).OnEvent("Change", this.SaveConfig.Bind(this))

			currentModes := Config.Get("BoostBar", "SlotMode" i, "Timer")
			display := currentModes = "" ? "None" : (StrSplit(currentModes, "|").Length > 1 ? "Multiple" : currentModes)

			btn := this.Gui.Add("Button", "x130 y" yPos - 3 " w70 h21 vBoostBar_Config" i, display)
			btn.OnEvent("Click", this.OpenModeSelector.Bind(this, i, btn))
		}

		this.Gui.Add("Text", "x290 y25", "Show when active")
		this.Gui.Add("CheckBox", "x270 y22 w20 h20 vBoostBar_ShowWhenActive Checked" Config.Get("BoostBar", "ShowWhenActive", 1)).OnEvent("Click", this.SaveConfig.Bind(this))

		; --- Alt Tab ---
		TabCtrl.UseTab("Alt")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y20 w185 h170")
		this.Gui.Add("Text", "x20 y22", "Alt Settings")
		this.Gui.SetFont("s8 cDefault Norm")
		this.Gui.SetFont("s8 w400")

		this.Gui.Add("Text", "x20 y45", "MoveSpeed:")
		this.Gui.Add("Edit", "x95 y42 w60 h20 vAlt_Movespeed", Config.Get("Alt", "Movespeed", 29)).OnEvent("Change", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x20 y70", "Hive Slot:")
		this.Gui.Add("Edit", "x95 y68 w60 h20 vAlt_HiveSlot", Config.Get("Alt", "HiveSlot", 1)).OnEvent("Change", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x20 y95", "Alt Number:")
		this.Gui.Add("Edit", "x95 y92 w40 h20 Number vAlt_AltNumber", Config.Get("Alt", "AltNumber", 1)).OnEvent("Change", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x40 y120", "Shift Lock")
		this.Gui.Add("CheckBox", "x20 y117 w20 h20 vAlt_ShiftLock Checked" Config.Get("Alt", "ShiftLock", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x120 y120", "Drift Comp")
		this.Gui.Add("CheckBox", "x100 y117 w20 h20 vAlt_FieldDriftComp Checked" Config.Get("Alt", "FieldDriftComp", 1)).OnEvent("Click", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x40 y143", "Claim Hive")
		this.Gui.Add("CheckBox", "x20 y140 w20 h20 vAlt_ClaimHive Checked" Config.Get("Alt", "ClaimHive", 1)).OnEvent("Click", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x20 y165", "Priv Server:")
		this.Gui.Add("Edit", "x80 y163 w110 h20 vAlt_PrivServer", Config.Get("Alt", "PrivServer", "")).OnEvent("Change", this.SaveConfig.Bind(this))



		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x205 y20 w185 h170")
		this.Gui.Add("Text", "x215 y22", "Field Settings")

		this.Gui.SetFont("s8 w400")
		this.Gui.Add("Button", "x300 y22 w40 h16", "Copy").OnEvent("Click", this.CopyFieldSettings.Bind(this))
		this.Gui.Add("Button", "x345 y22 w40 h16", "Paste").OnEvent("Click", this.PasteFieldSettings.Bind(this))

		this.Gui.SetFont("s8 cDefault Norm")

		this.Gui.Add("Text", "x215 y45", "Field:")
		fieldArr := ["sunflower", "dandelion", "mushroom", "blueflower", "clover", "strawberry", "spider", "bamboo", "pineapple", "stump", "cactus", "pumpkin", "pinetree", "rose", "mountaintop", "pepper", "coconut"]
		(GuiCtrl := this.Gui.Add("DropDownList", "x255 y42 w100 vAlt_DefaultField Choose" ObjIndexOf(fieldArr, Config.Get("Alt", "DefaultField", "pepper")), fieldArr)).OnEvent("Change", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x215 y70", "Pattern:")
		this.Gui.Add("DropDownList", "x270 y68 w110 vAlt_Pattern Choose" ObjIndexOf(patternList, Config.Get("Alt", "Pattern", "GeneralBooster")), patternList).OnEvent("Change", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x215 y95", "Size:")
		this.Gui.Add("Edit", "x240 y92 w40 h20 Number vAlt_PatternSize", Config.Get("Alt", "PatternSize"))
		this.Gui.Add("UpDown", "Range1-10", Config.Get("Alt", "PatternSize"))

		this.Gui.Add("Text", "x285 y95", "Width:")
		this.Gui.Add("Edit", "x320 y92 w40 h20 Number vAlt_PatternWidth", Config.Get("Alt", "PatternWidth"))
		this.Gui.Add("UpDown", "Range1-10", Config.Get("Alt", "PatternWidth"))

		this.Gui.Add("Text", "x215 y123", "Sprinkler:")
		sprinklerArr := ["Center", "Upper Left", "Left", "Lower Left", "Lower", "Lower Right", "Right", "Upper Right", "Upper"]
		this.Gui.Add("DropDownList", "x265 y120 w80 vAlt_SprinklerLocation Choose" ObjIndexOf(sprinklerArr, Config.Get("Alt", "SprinklerLocation", "Center")), sprinklerArr).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("Edit", "x350 y120 w30 h20 Number vAlt_SprinklerDistance", Config.Get("Alt", "SprinklerDistance", 1)).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("UpDown", "Range0-10", Config.Get("Alt", "SprinklerDistance", 1))

		this.Gui.Add("Text", "x215 y150", "Rotation:")
		this.Gui.Add("Edit", "x260 y148 w40 h20 Number vAlt_RotationAmount", Config.Get("Alt", "RotationAmount", 0)).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("UpDown", "Range0-8", Config.Get("Alt", "RotationAmount", 0))
		this.Gui.Add("DropDownList", "x320 y148 w60 vAlt_RotationDirection Choose" ObjIndexOf(["Right", "Left"], Config.Get("Alt", "RotationDirection", "Right")), ["Right", "Left"]).OnEvent("Change", this.SaveConfig.Bind(this))

		; --- Communicator Tab ---
		TabCtrl.UseTab("Communicator")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y20 w380 h150")
		this.Gui.Add("Text", "x20 y21", "Connection Settings")
		this.Gui.SetFont("s8 cDefault Norm")

		this.Gui.Add("Text", "x45 y40", "Enable Communication")
		this.Gui.Add("CheckBox", "x25 y37 w20 h20 vCommunicator_CommunicationEnabled Checked" Config.Get("Communicator", "CommunicationEnabled", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x25 y60 w350 h30", "Both the Main and Alt must have the EXACT same 'Channel' name for this to work.")
		this.Gui.Add("Text", "x25 y93", "Channel Name:")
		(GuiCtrl := this.Gui.Add("Edit", "x110 y90 w180 h20 vCommunicator_DweetName", Config.Get("Communicator", "DweetName", "you might wanna change this..."))).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("Button", "x300 y90 w80 h20", "Generate").OnEvent("Click", this.GenerateUser.Bind(this))
		this.Gui.Add("Text", "x25 y130 w80", "Status:")
		role := Config.Get("Main", "AltMacroEnabled", 0) ? "Client" : "Server"
		this.Gui.Add("Text", "x60 y130 w200 vCommsStatus", role)

		; --- Scanner Tab ---
		TabCtrl.UseTab("Scanner")
		this.GUi.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y20 w130 h120")
		this.Gui.Add("Text", "x20 y22", "Scanner Settings")
		this.Gui.SetFont("s8 cDefault Norm")

		passives := Config.Get("PassiveScanner", "Passives", "Scorch")
		has := (str) => InStr("|" passives "|", "|" str "|")


		this.Gui.Add("CheckBox", "x25 y42 w20 h20 vPassiveScanner_Scorch Checked" has("scorch")).OnEvent("Click", this.UpdatePassives.Bind(this))
		this.Gui.Add("Text", "x45 y45", "Scorch")

		this.Gui.Add("CheckBox", "x25 y62 w20 h20 vPassiveScanner_PopStar Checked" has("popstar")).OnEvent("Click", this.UpdatePassives.Bind(this))
		this.Gui.Add("Text", "x45 y65", "Pop Star")

		this.Gui.Add("CheckBox", "x25 y82 w20 h20 vPassiveScanner_XFlame Checked" has("x-flame")).OnEvent("Click", this.UpdatePassives.Bind(this))
		this.Gui.Add("Text", "x45 y85", "X-Flame")
		; --- Key Alignment Tab ---
		TabCtrl.UseTab("Key Alignment")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y20 w380 h150")
		this.Gui.Add("Text", "x20 y21", "Key Alignment Settings")
		this.Gui.SetFont("s8 cDefault Norm")

		this.Gui.Add("Text", "x25 y45", "Alignment Key:")
		this.Gui.Add("Edit", "x100 y45 w100 vKeyAlignment_AlignmentKey", Config.Get("KeyAlignment", "AlignmentKey", "e")).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("Text", "x25 y75", "Rebind Hotkey:")
		this.Gui.Add("Edit", "x100 y75 w100 vKeyAlignment_RebindHotkey", Config.Get("KeyAlignment", "RebindHotkey", "^+k")).OnEvent("Change", this.SaveConfig.Bind(this))

		; --- Dark Mode ---
		SetWindowTheme(this.Gui, Config.Get("Main", "DarkMode", 1))
		SetWindowAttribute(this.Gui, Config.Get("Main", "DarkMode", 1))
		this.RegisterHotkeys()
	}

	GenerateUser(GuiCtrl, *) {
		name := "K" Random(10000000, 99999999) "X" Random(10000000, 99999999)
		this.Gui["Communicator_DweetName"].Value := name
		Config.Set("Communicator", "DweetName", name)
		Config.WriteIni()
		if IsSet(Comms)
			Comms.UpdateSettings()
	}

	OpenModeSelector(index, GuiCtrl*) {
		static ModeGui := ""
		GuiClose(*) {
			if (IsSet(ModeGui) && IsObject(ModeGui))
				try ModeGui.Destroy(), ModeGui := ""
		}
		GuiClose()
		currentConfig := Config.Get("BoostBar", "SlotMode" index, "Timer")

		ModeGui := Gui("+Owner" this.Gui.Hwnd " +AlwaysOnTop +Border +ToolWindow", "Slot " index)
		ModeGui.SetFont("s8 cDefault Norm", "Tahoma")
		ModeGui.OnEvent("Close", (*) => GuiClose)

		UpdateConfig(*) {
			savedList := []
			for mode, ctrl in CheckBoxes {
				if (ctrl.Value)
					savedList.Push(mode)
			}

			saveString := ""
			for item in savedList
				saveString .= (A_Index > 1 ? "|" : "") item
			Config.Set("BoostBar", "SlotMode" index, saveString)
			Config.WriteIni()

			count := savedList.Length
			this.Gui["BoostBar_Config" index].Text := (count = 0) ? "None" : (count > 1 ? "Multiple" : saveString)

			if IsSet(Boost) && Boost
				Boost.Draw()
		}

		CheckBoxes := Map()
		ModeList := []
		for i in ["Timer", "ReGlitter", "On Scorch", "ReSmoothie", "On Pop Star", "On Baller", "On Shower", "On Gummy"]
			ModeList.Push(i)

		Columns := 2
		Margin := 10

		for index, modeName in ModeList {
			i := A_Index - 1
			col := Mod(i, Columns)
			row := Floor(i / Columns)
			isChecked := InStr("|" currentConfig "|", "|" modeName "|")
			x := Margin + (col * 100)
			y := Margin + (row * 25)
			cb := ModeGui.Add("CheckBox", "x" x " y" y " w20 h20 Checked" isChecked)
			cb.OnEvent("Click", UpdateConfig.Bind(this))
			ModeGui.Add("Text", "x" x + 20 " y" y + 3 " w100 h20 c" (Config.Get("Main", "DarkMode", 1) ? "White" : "Black"), modeName)
			CheckBoxes[modeName] := cb
		}
		TotalRows := Ceil(ModeList.Length / Columns)
		MinWidth := (Margin * 2) + (Columns * 100)
		MinHeight := (Margin * 2) + (TotalRows * 25)
		ModeGui.Show("w" MinWidth " h" MinHeight)
		SetWindowTheme(ModeGui, Config.Get("Main", "DarkMode", 1))
		SetWindowAttribute(ModeGui, Config.Get("Main", "DarkMode", 1))
	}

	UpdatePassives(GuiCtrl, *) {
		current := Config.Get("PassiveScanner", "Passives", "Scorch")
		list := StrSplit(current, "|")

		name := StrLower(StrReplace(GuiCtrl.Name, "PassiveScanner_", ""))
		if (name = "xflame")
			name := "x-flame"
		
		newList := []
		found := false
		for item in list {
			if (item = name)
				found := true
			else if (item != "")
				newList.Push(item)
		}

		if (GuiCtrl.Value)
			newList.Push(name)
		saveStr := ""
		for item in newList
			saveStr .= (A_Index > 1 ? "|" : "") item
		Config.Set("PassiveScanner", "Passives", saveStr)
		Config.WriteIni()
		this.RefreshFeature("PassiveScannerEnabled")
	}

	CopyFieldSettings(*) {
		settings := Config.Get("Alt", "DefaultField") "|" Config.Get("Alt", "Pattern") "|" Config.Get("Alt", "PatternSize") "|" Config.Get("Alt", "PatternWidth") "|" Config.Get("Alt", "SprinklerLocation") "|" Config.Get("Alt", "SprinklerDistance") "|" Config.Get("Alt", "RotationAmount") "|" Config.Get("Alt", "RotationDirection")
		A_Clipboard := settings
		ToolTip("Settings copied to clipboard")
		SetTimer(ToolTip, -500)
	}

	PasteFieldSettings(*) {
		try {
			data := StrSplit(A_Clipboard, "|")
			if (data.Length != 8) {
				ToolTip("Invalid settings.")
				SetTimer(ToolTip, -500)
				return
			}

			Config.Set("Alt", "DefaultField", data[1])
			Config.Set("Alt", "Pattern", data[2])
			Config.Set("Alt", "PatternSize", data[3])
			Config.Set("Alt", "PatternWidth", data[4])
			Config.Set("Alt", "SprinklerLocation", data[5])
			Config.Set("Alt", "SprinklerDistance", data[6])
			Config.Set("Alt", "RotationAmount", data[7])
			Config.Set("Alt", "RotationDirection", data[8])
			Config.WriteIni()

			this.Gui["Alt_DefaultField"].Text := data[1]
			this.Gui["Alt_Pattern"].Text := data[2]
			this.Gui["Alt_PatternSize"].Value := data[3]
			this.Gui["Alt_PatternWidth"].Value := data[4]
			this.Gui["Alt_SprinklerLocation"].Text := data[5]
			this.Gui["Alt_SprinklerDistance"].Value := data[6]
			this.Gui["Alt_RotationAmount"].Value := data[7]
			this.Gui["Alt_RotationDirection"].Text := data[8]
			ToolTip("Settings pasted from clipboard")
			SetTimer(ToolTip, -500)
		} catch {
			ToolTip("Error pasting settings.")
			SetTimer(ToolTip, -500)
		}
	}

	TestAudio(GuiCtrl, *) {
		soundPath := Config.Get("Warns", "SoundFile", "C:\Windows\Media\Windows Critical Stop.wav")
		if !FileExist(soundPath) {
			soundPath := "C:\Windows\Media\Windows Critical Stop.wav"
		}
		this.AudioPlayer := unset
		this.AudioPlayer := Audio(soundPath)
		vol := Config.Get("Warns", "Volume", 25)
		this.AudioPlayer.Play(vol)
	}

	ToggleFeature(GuiCtrl, *) {
		isChecked := GuiCtrl.Value
		FeatureName := GuiCtrl.Name
		Config.Set("Main", FeatureName, isChecked)
		Config.WriteIni()

		if (FeatureName = "AltMacroEnabled") {
			role := isChecked ? "Client" : "Server"
			try this.Gui["CommsStatus"].Text := role
			if IsSet(Comms)
				Comms.UpdateSettings()
		}
		this.RefreshFeature(FeatureName)
	}

	SaveConfig(GuiCtrl, *) {
		Split := StrSplit(GuiCtrl.Name, "_")
		if (Split.Length != 2)
			return
		Section := Split[1]
		Key := Split[2]

		val := (GuiCtrl.Type = "DDL") ? GuiCtrl.Text : GuiCtrl.Value
		Config.Set(Section, Key, val)
		Config.WriteIni()

		if (Section = "BoostBar")
			this.RefreshFeature("BoostBarEnabled")
		else if (Section = "Warns")
			this.RefreshFeature("WarnsEnabled")
		else if (Section = "PassiveScanner")
			this.RefreshFeature("PassiveScannerEnabled")
		else if (Section = "Main" && (Key = "BoostBarEnabled" || Key = "WarnsEnabled" || Key = "PassiveScannerEnabled"))
			this.RefreshFeature(Key)
		else if (Section = "Communicator")
			if IsSet(Comms)
				Comms.UpdateSettings()

		if (Key = "DarkMode") {
			SetWindowTheme(this.Gui, GuiCtrl.Value)
			SetWindowAttribute(this.Gui, GuiCtrl.Value)
		}

		if (Key ~= "SlotTimer") {
			if IsSet(Boost) && Boost
				Boost.Draw()
		}
	}

	RefreshFeature(FeatureName) {
		if (this.FeatureRefreshers.Has(FeatureName))
			this.FeatureRefreshers[FeatureName]()
	}

	SelectSound(GuiCtrl, *) {
		SelectedFile := FileSelect(1, , "Select Sound File", "Audio (*.wav; *.mp3)")
		if SelectedFile {
			this.Gui["Warns_SoundFile"].Value := SelectedFile
			Config.Set("Warns", "SoundFile", SelectedFile)
			Config.WriteIni()
		}
	}

	TextExtend(text, textCtrl) {
		hDC := DllCall("GetDC", "Ptr", textCtrl.Hwnd, "Ptr")
		hFold := DllCall("SelectObject", "Ptr", hDC, "Ptr", SendMessage(0x31, , , textCtrl), "Ptr")
		nSize := Buffer(8)
		DllCall("GetTextExtentPoint32", "Ptr", hDC, "Str", text, "Int", StrLen(text), "Ptr", nSize)
		DllCall("SelectObject", "Ptr", hDC, "Ptr", hFold)
		DllCall("ReleaseDC", "Ptr", textCtrl.Hwnd, "Ptr", hDC)
		return NumGet(nSize, 0, "UInt")
	}

	start(*) {
		static ran := 0
		if ran
			return
		ran++
		State.offsetY := GetYOffset(, &fail)
		try {
		if fail
			msgbox "Failed to get y-Offset, this either means`n1. Your font is NOT the default size (e.g. font scale or broken roblox updates)`n2. Your font is wrong (e.g. custom font w/bloxstrap)`n3. the 'Pollen' text at the top is being covered`n4. Graphical issues`n5. I made a mistake...`n6. You don't have roblox open.", "Kairos", 16
		}
		Scorch.Toggle()
		Warns.Toggle()
		Boost.Toggle()
		Alt.Toggle()
		Aligner.Toggle()
		Mag.Toggle()
		this.Gui.Show("Hide")
	}

	pause(*) {
		State.IsPaused ^= 1

		if (State.IsPaused) {
			this.Gui.Show("")
			this.Gui.Title := "Kairos (Paused)"
			this.Gui["PauseButton"].Text := "Resume (" Config.Get("Main", "PauseHotkey", "F2") ")"

			if IsSet(Scorch) && Scorch.Fancy
				Scorch.Fancy.Hide()
			if IsSet(Warns) && Warns.Fancy
				Warns.Fancy.Hide()
			if IsSet(Boost) && Boost {
				Boost.Draw()
				Boost.FollowWindow()
			}
			if IsSet(Aligner) && Aligner
				Aligner.Draw()
			if IsSet(Mag) && Mag.Gui
				Mag.Gui.Hide()

			DetectHiddenWindows true
			if WinExist("ahk_class AutoHotkey ahk_pid " State.CurrentWalk.pid)
				send "{F16}"
			DetectHiddenWindows false
		} else {
			this.Gui.Hide()
			this.Gui.Title := "Kairos"
			this.Gui["PauseButton"].Text := "Pause (" Config.Get("Main", "PauseHotkey", "F2") ")"

			if IsSet(Boost) && Boost
				Boost.Draw()
			if IsSet(Aligner) && Aligner
				Aligner.Draw()

			DetectHiddenWindows true
			if WinExist("ahk_class AutoHotkey ahk_pid " State.CurrentWalk.pid)
				send "{F14}"
			DetectHiddenWindows false

		}
		Pause -1
	}

	stop(*) {
		Reload
	}

	RegisterHotkeys() {
		try {
			Hotkey(Config.Get("Main", "StartHotkey", "F1"), (*) => this.start())
			Hotkey(Config.Get("Main", "PauseHotkey", "F2"), (*) => this.pause())
			Hotkey(Config.Get("Main", "StopHotkey", "F3"), (*) => this.stop())
		}
	}
}
