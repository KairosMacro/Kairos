class Scheduler {
	static tasks := Map()
	static timerFn := 0
	static interval := 0
	static running := false

	static Start(intervalMs := unset) {
		if IsSet(intervalMs)
			this.interval := intervalMs
		else if (this.interval = 0)
			this.interval := this.ComputeMinInterval(10)

		if !this.timerFn
			this.timerFn := ObjBindMethod(this, "Tick")
		SetTimer(this.timerFn, this.interval)
		this.running := true
	}

	static Stop() {
		if this.timerFn
			SetTimer(this.timerFn, 0)
		this.running := false
	}

	static Add(name, fn, intervalMs, enabledFn := 0) {
		if !(intervalMs > 0)
			intervalMs := 10

		if this.tasks.Has(name) {
			task := this.tasks[name]
			task.fn := fn
			task.interval := intervalMs
			task.enabled := enabledFn
		} else {
			this.tasks[name] := { fn: fn, interval: intervalMs, enabled: enabledFn, last: 0 }
		}

		this.UpdateBaseInterval()
	}

	static Remove(name) {
		if this.tasks.Has(name)
			this.tasks.Delete(name)
		this.UpdateBaseInterval()
	}

	static ComputeMinInterval(fallback := 10) {
		min := 0
		for name, task in this.tasks {
			if (min = 0 || task.interval < min)
				min := task.interval
		}
		return (min = 0 ? fallback : min)
	}

	static UpdateBaseInterval() {
		min := this.ComputeMinInterval(this.interval ? this.interval : 10)
		if (min != this.interval) {
			this.interval := min
			if this.timerFn && this.running
				SetTimer(this.timerFn, this.interval)
		}
	}

	static Tick(*) {
		now := A_TickCount
		for name, task in this.tasks {
			if (now - task.last < task.interval)
				continue
			if (task.enabled && !task.enabled.Call())
				continue
			task.last := now
			try task.fn()
		}
	}
}
