class MagnifyingGlass {
	IsRunning := false
	ZoomFactor := 1.3
	FPS := 30

	width := 594
	height := 36

	targetOffset := -300
	offsetX := -260
	offsetY := -230

	hDC_Screen := 0
	hDC_Gui := 0
	src := { x: 0, y: 0, w: 0, h: 0 }

	__New() {
		this.Gui := Gui("-Caption +E0x20 +AlwaysOnTop +ToolWindow +OwnDialogs ", "Magnifying Glass")
		this.Gui.BackColor := "Black"
		this.UpdateFn := this.Update.Bind(this)
		Scheduler.Add("MagnifyingGlass.FollowWindow", this.FollowWindow.Bind(this), 50)
	}

	Toggle() {
		if (Config.Get("Main", "MagnifierEnabled", 0) && !this.IsRunning) {
			this.Start()
		} else if this.IsRunning {
			this.Stop()
		}
	}

	Start() {
		if this.IsRunning
			return
		this.IsRunning := true

		this.Gui.Show("NA")

		this.hDC_Screen := DllCall("GetDC", "Ptr", 0, "Ptr")
		this.hDC_Gui := DllCall("GetDC", "Ptr", this.Gui.hwnd, "Ptr")

		DllCall("SetStretchBltMode", "Ptr", this.hDC_Gui, "Int", 4)
		Scheduler.Add("MagnifyingGlass.Update", this.UpdateFn, 1000 // this.FPS)
	}

	Stop() {
		if !this.IsRunning
			return

		this.IsRunning := false

		Scheduler.Remove("MagnifyingGlass.Update")

		if this.hDC_Screen
			DllCall("ReleaseDC", "Ptr", 0, "Ptr", this.hDC_Screen)
		if this.hDC_Gui
			DllCall("ReleaseDC", "Ptr", this.Gui.hwnd, "Ptr", this.hDC_Gui)

		this.hDC_Screen := 0
		this.hDC_Gui := 0
		this.Gui.Hide()
	}

	FollowWindow(*) {
		try {
			win := WindowTracker.Get()
			if IsObject(win) && win.ok {
				wx := win.x, wy := win.y, ww := win.w, wh := win.h
				this.src.x := wx + (ww // 2) + this.targetOffset
				this.src.y := wy + State.offsetY
				this.src.w := this.width
				this.src.h := this.height

				guiW := Floor(this.width * this.ZoomFactor)
				guiH := Floor(this.height * this.ZoomFactor)
				targetX := (wx + (ww // 2) - (guiW // 2))
				targetY := wy + wh + this.offsetY + (Config.Get("Main", "BoostBarEnabled", 0) && Config.Get("BoostBar", "ShowWhenActive", 0) ? 0 : 40)
				if (this.IsRunning && !State.IsPaused && Config.Get("Main", "MagnifierEnabled", 0))
					this.Gui.Show("NA x" targetX " y" targetY " w" guiW " h" guiH)
				else
					this.Gui.Hide()
			} else
				this.Gui.Hide()
		}
	}

	Update(*) {
		if (!this.hDC_Gui || !this.hDC_Screen)
			return

		DllCall("gdi32\StretchBlt"
			, "Ptr", this.hDC_Gui
			, "Int", 0, "Int", 0
			, "Int", this.src.w * this.ZoomFactor
			, "Int", this.src.h * this.ZoomFactor
			, "Ptr", this.hDC_Screen
			, "Int", this.src.x, "Int", this.src.y
			, "Int", this.src.w, "Int", this.src.h
			, "UInt", 0x00CC0020)
	}
}
