nowUnix() => DateDiff(A_NowUTC, "19700101000000", "Seconds")
GetUnixFactor() => Floor(nowUnix() // 10)

Padding := 4

TravelWidth := FieldWidth - (Padding * 2)
TravelHeight := FieldHeight - (Padding * 2)

AlignWidth := (FieldWidth / 2) - Padding
AlignHeight := (FieldHeight / 2) - Padding

CurrentPhase := 0
AltOffset := (altNumber = 1) ? 0 : 2

if (index = 1) {
	StartBlock := GetUnixFactor()
	CurrentPhase := Mod(StartBlock + 1 + AltOffset, 5)

	Switch CurrentPhase {
		Case 0: ; Center
			sleep 50
		Case 1: ; Top Left
			walk(AlignHeight, FwdKey)
			walk(AlignWidth, LeftKey)
			Rotate(3)
		Case 2: ; Top Right
			walk(AlignHeight, FwdKey)
			walk(AlignWidth, RightKey)
			Rotate(-3)
		Case 3: ; Bottom Right
			walk(AlignHeight, BackKey)
			walk(AlignWidth, RightKey)
			Rotate(-1)
		Case 4: ; Bottom Left
			walk(AlignHeight, BackKey)
			walk(AlignWidth, LeftKey)
			Rotate(1)
	}
	send "{" RotUp " 8}"
	loop 5
		send "{" ZoomIn "}"
	Sleep 100
}

loop {
	Pattern(CurrentPhase)
	Switch CurrentPhase {
		Case 0: ; Center -> Top Left
			walk(AlignWidth, LeftKey)
			walk(AlignHeight, FwdKey)
			Rotate(3)
		Case 1: ; Top Left -> Top Right
			Rotate(1)
			walk(TravelWidth, LeftKey)
			if field = "pepper"
				walk(10, BackKey), walk(7, FwdKey)
			Rotate(1)
		Case 2: ; Top Right -> Bottom Right
			Rotate(1)
			if field = "pepper"
				walk(12, BackKey), walk(10, FwdKey)
			walk(TravelHeight, LeftKey)
			Rotate(1)
		Case 3: ; Bottom Right -> Bottom Left
			Rotate(1)
			walk(TravelWidth, LeftKey)
			Rotate(1)
		Case 4: ; Bottom Left -> Center
			Rotate(-1)
			walk(AlignWidth, RightKey)
			walk(AlignHeight, FwdKey)
	}
	PreviousPhase := CurrentPhase
	CurrentPhase := Mod(CurrentPhase + 1, 5)
	if (PreviousPhase = 4 && CurrentPhase = 0)
		break
}
sleep 100
Pattern(location) {
	if (location = 0) {
		EnableShift(false)
		walk(3, FwdKey)
		walk(3, RightKey)
		walk(3, BackKey)
		walk(6, LeftKey)

		walk(3, FwdKey)
		walk(3, RightKey)
		walk(6, BackKey)
		walk(3, LeftKey)

		walk(3, FwdKey)
		walk(6, RightKey)
		walk(3, BackKey)
		walk(3, LeftKey)

		walk(3, FwdKey)
		return
	}

	EnableShift(true)
	loop 1 {
		walk(5, FwdKey)
		walk(1, RightKey)
		walk(5, BackKey)
		walk(1, RightKey)
	}
	loop 2 {
		walk(5, FwdKey)
		walk(1, LeftKey)
		walk(5, BackKey)
		walk(1, LeftKey)
	}
	loop 1 {
		walk(5, FwdKey)
		walk(1, RightKey)
		walk(5, BackKey)
		walk(1, RightKey)
	}
}

Rotate(Count) {
	if (Count = 0)
		return

	Key := (Count > 0) ? RotRight : RotLeft
	Loops := Abs(Count)
	Loop Loops {
		send "{" Key " down}"
		sleep 50
		send "{" Key " up}"
		sleep 50
	}
}

EnableShift(status) {
	static isEnabled := false
	if (status && !isEnabled) {
		send "{" SC_LShift "}"
		isEnabled := true
	} else if (!status && isEnabled) {
		send "{" SC_LShift "}"
		isEnabled := false
	}
}
