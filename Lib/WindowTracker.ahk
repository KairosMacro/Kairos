class WindowTracker {
	static state := { hwnd: 0, x: 0, y: 0, w: 0, h: 0, ok: false, ts: 0 }
	static interval := 50

	static Start(intervalMs := 50) {
		this.interval := intervalMs
		this.Update()
		Scheduler.Add("WindowTracker.Update", ObjBindMethod(this, "Update"), intervalMs)
	}

	static Stop() {
		Scheduler.Remove("WindowTracker.Update")
	}

	static Get() {
		return this.state
	}

	static Update(*) {
		global windowX, windowY, windowWidth, windowHeight
		hwnd := GetRobloxHWND()
		if !hwnd {
			this.state := { hwnd: 0, x: 0, y: 0, w: 0, h: 0, ok: false, ts: A_TickCount }
			return
		}
		if !GetRobloxClientPos(hwnd) {
			this.state := { hwnd: hwnd, x: 0, y: 0, w: 0, h: 0, ok: false, ts: A_TickCount }
			return
		}
		this.state := { hwnd: hwnd, x: windowX, y: windowY, w: windowWidth, h: windowHeight, ok: true, ts: A_TickCount }
	}
}
