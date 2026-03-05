class Config {
    static path := A_WorkingDir "\settings\config.ini"
    static Data := Map()

    static Default := Map(
        "Main", Map(
            "StartHotkey", "F1"
            , "PauseHotkey", "F2"
            , "StopHotkey", "F3"
            , "WarnsEnabled", 0
            , "BoostBarEnabled", 0
            , "AltMacroEnabled", 0
            , "PassiveScannerEnabled", 0
            , "KeyAlignmentEnabled", 0
            , "MagnifierEnabled", 0
            , "AlwaysOnTop", 0
            , "HideOnRun", 0
            , "GuiX", A_ScreenWidth // 2 - 200
            , "GuiY", A_ScreenHeight // 2 - 100
            , "DarkMode", 1
        )
        , "Alt", Map(
            "Movespeed", 29
            , "HiveSlot", 1
            , "FieldDriftComp", 1
            , "AltNumber", 1
            , "DefaultField", "pepper"
            , "Pattern", "GeneralBooster"
            , "PatternSize", 1
            , "PatternWidth", 1
            , "RotationAmount", 0
            , "RotationDirection", "Right"
            , "ShiftLock", 0
            , "SprinklerLocation", "Center"
            , "SprinklerDistance", 1
            , "PrivServer", ""
            , "ClaimHive", 1
        )
        , "BoostBar", Map(
            "SlotActive1", 0, "SlotTimer1", 100, "SlotMode1", "Timer"
            , "SlotActive2", 0, "SlotTimer2", 100, "SlotMode2", "Timer"
            , "SlotActive3", 0, "SlotTimer3", 100, "SlotMode3", "Timer"
            , "SlotActive4", 0, "SlotTimer4", 100, "SlotMode4", "Timer"
            , "SlotActive5", 0, "SlotTimer5", 100, "SlotMode5", "Timer"
            , "SlotActive6", 0, "SlotTimer6", 100, "SlotMode6", "Timer"
            , "SlotActive7", 0, "SlotTimer7", 100, "SlotMode7", "Timer"
            , "ShowWhenActive", 1
        )
        , "Warns", Map(
            "StartWarn", 25
            , "Volume", 25
            , "SoundFile", "C:\Windows\Media\Windows Critical Stop.wav"
        )
        , "PassiveScanner", Map(
            "Passives", "Scorch"
        )
        , "KeyAlignment", Map(
            "AlignmentKey", "e"
            , "RebindHotkey", "^+k"
        )
        , "Communicator", Map(
            "CommunicationEnabled", 0
            , "DweetName", "K" Random(10000000, 99999999) "X" Random(10000000, 99999999)
        )
    )

    static Load() {
        for section, keys in this.Default {
            if !this.Data.Has(section)
                this.Data[section] := Map()
            for key, val in keys {
                this.Data[section][key] := val
            }
        }
        if FileExist(this.path) {
            this.ReadIni()
        }
        this.WriteIni()
    }

    static ReadIni() {
        try {
            iniFile := FileOpen(this.path, "r")
            str := iniFile.Read()
            iniFile.Close()
        } catch
            return

        currentSection := ""

        Loop Parse, str, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line = "" || SubStr(line, 1, 1) = ";")
                continue

            if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                currentSection := SubStr(line, 2, -1)
                if !this.Data.Has(currentSection)
                    this.Data[currentSection] := Map()
                continue
            }

            if (p := InStr(line, "=")) && (currentSection != "") {
                key := Trim(SubStr(line, 1, p - 1))
                val := Trim(SubStr(line, p + 1))
                if IsInteger(val)
                    val := Integer(val)
                if IsFloat(val)
                    val := Round(Float(val), 2)
                this.Data[currentSection][key] := val
            }
        }
    }

    static WriteIni() {
        if !DirExist("settings")
            DirCreate "settings"

        iniStr := ""
        for section, keys in this.Default {
            iniStr .= "[" section "]`r`n"
            for key, val in keys {
                currentVal := (this.Data.Has(section) && this.Data[section].Has(key)) ? this.Data[section][key] : val
                if IsFloat(currentVal)
                    currentVal := Round(currentVal, 2)
                iniStr .= key "=" currentVal "`r`n"
            }
            iniStr .= "`r`n"
        }
        f := FileOpen(this.path, "w", "UTF-8")
        f.Write(iniStr)
        f.Close()
    }

    static Set(section, key, val) => (this.Data.Has(section) ? this.Data[section][key] := val : this.Data[section] := Map(key, val))
    static Get(section, key, defaultVal := "") => (this.Data.Has(section) && this.Data[section].Has(key)) ? this.Data[section][key] : defaultVal
}
