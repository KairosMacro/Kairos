class Communicator {
	isServer := false
	isEnabled := false
	thingName := ""
	lastDweet := ""
	readTimer := ""

	__New() {
		this.UpdateSettings()
	}

	UpdateSettings() {
		if (this.readTimer) {
			SetTimer(this.readTimer, 0)
			this.readTimer := ""
		}
		this.isEnabled := Config.Get("Communicator", "CommunicationEnabled", 0)
		if (!this.isEnabled)
			return
		this.isServer := !Config.Get("Main", "AltMacroEnabled", 0)
		this.thingName := Config.Get("Communicator", "DweetName", "you might wanna change this...")
		if (this.isServer) {
			this.server := dweet(this.thingName)
		} else {
			this.client := dweet(this.thingName)
			this.readTimer := this.ReadDweet.Bind(this)
			SetTimer(this.readTimer, 1000)
		}
	}

	BroadcastBuffs(state) {
		if (!this.isEnabled || !this.isServer)
			return
		payload := Map(
			"action", "update stats",
			"data", state,
			"timestamp", nowUnix()
		)
		try this.server.SendMessage(JSON.Stringify(payload))
	}

	ReadDweet(*) {
		if (!this.isEnabled || this.isServer)
			return
		try {
			msg := this.client.ReceiveMessage()
			if (msg = "")
				return
			this.LastDweet := msg["timestamp"]
			this.ProcessMessage(msg)
		}
	}

	; message Struct: {"action": [string], "data": [any], "timestamp": [int]}
	ProcessMessage(msg) {
		if (msg["action"] = "update stats") {
			global Boost
			if (IsSet(Boost) && IsObject(Boost)) {
				newState := msg["data"]
				list := Type(newState) = "Map" ? newState : newState.OwnProps()
				for name, isActive in list {
					if (Boost.stats.BuffState.Has(name))
						Boost.stats.BuffState[name] := isActive
				}
			}
		}
	}
}
