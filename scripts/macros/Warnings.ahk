class Warnings {
	IsRunning := false
	IsActive := false
	AudioPlayer := unset
	LastPlayed := 0
	WarnThreshold := 25
	WarnVolume := 25

	__New() {
		soundPath := Config.Get("Warns", "SoundFile", "C:\Windows\Media\Windows Critical Stop.wav")
		if !FileExist(soundPath) {
			soundPath := "C:\Windows\Media\Windows Critical Stop.wav"
		}
		this.AudioPlayer := Audio(soundPath)
		this.Fancy := GdipTooltip()
		this.RefreshConfig()
		Scheduler.Add("Warnings.CheckLoop", this.CheckLoop.Bind(this), 150, () => this.IsActive)
	}

	Cleanup(*) {
		this.IsRunning := false
	}

	Toggle() {
		this.IsRunning ^= 1
		this.IsActive := this.IsRunning && Config.Get("Main", "WarnsEnabled", 0)

		if Config.Get("Main", "WarnsEnabled", 0)
			this.Fancy.Show("Warns: " (this.IsActive ? "ON" : "OFF"))
		SetTimer () => this.Fancy.Hide(), -500
	}

	CheckLoop(*) {
		if (State.IsPaused)
			return

		static minTime := 500
		static maxTime := 5000
		if !this.IsRunning || !WinActive("Roblox")
			return

		percent := Round(this.DetectPrecPercent(), 2)
		if (percent = 0)
			return

		secondsLeft := Round(0.6 * percent)
		threshold := this.WarnThreshold
		vol := this.WarnVolume
		if (secondsLeft <= threshold) {
			ratio := secondsLeft / threshold
			calcDelay := minTime + (ratio * (maxTime - minTime))
			delay := Min(Max(minTime, calcDelay), maxTime)
			if (A_TickCount - this.LastPlayed > delay) {
				this.LastPlayed := A_TickCount
				this.AudioPlayer.Play(vol)
			}
		}
	}

	RefreshConfig() {
		this.WarnThreshold := Config.Get("Warns", "StartWarn", 25)
		this.WarnVolume := Config.Get("Warns", "Volume", 25)
	}

	DetectPrecPercent() {
		static buffer := [], bufferSize := 6, tolerance := 5
		static colors := [
			0xff8F4EB4
			, 0xff774296
			, 0xff3E274C
			, 0xff211A24
			, 0xff201A24
			, 0xff221A26
			, 0xff55316A
			, 0xff8448A6
		]
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok
			return 0

		region := win.x "|" win.y + State.offsetY + 32 "|" win.w "|" 42
		pBMScreen := FrameCache.Get(region)
		if !pBMScreen
			return 0

		if (Gdip_ImageSearch(pBMScreen, bitmaps["buff"]["Precise"], &loc, , , , , 3, , 6) != 1) {
			buffer := []
			return 0
		}

		x := SubStr(loc, 1, InStr(loc, ",") - 1)
		y := SubStr(loc, InStr(loc, ",") + 1)
		bottomY := y
		high := y
		low := 0

		while (low < high) {
			if (A_Index > 20)
				return 0
			mid := Floor((low + high) / 2)
			if ((ObjHasValue(colors, Gdip_GetPixel(pBMScreen, x + 9, mid))))
				high := mid
			else
				low := mid + 1
		}

		raw := Round((bottomY - low) / 38 * 100, 2) + 2

		buffer.Push(raw)
		if (buffer.Length > bufferSize)
			buffer.RemoveAt(1)
		best := []
		for val1 in buffer {
			current := []
			for val2 in buffer {
				if (Abs(val1 - val2) <= tolerance)
					current.Push(val2)
			}
			if (current.Length > best.Length)
				best := current
		}
			if (best.Length = 0)
				return raw
			sum := 0
			for val in best
				sum += val
			return Round(sum / best.Length, 2)
	}
}
