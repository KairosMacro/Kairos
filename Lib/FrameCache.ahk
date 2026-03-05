class FrameCache {
	static cache := Map()
	static defaultTtl := 25

	static Get(region, ttlMs := unset) {
		if !IsSet(ttlMs)
			ttlMs := this.defaultTtl

		now := A_TickCount
		if this.cache.Has(region) {
			entry := this.cache[region]
			if (now - entry.ts) <= ttlMs
				return entry.bmp
			if entry.bmp
				Gdip_DisposeImage(entry.bmp)
		}

		bmp := Gdip_BitmapFromScreen(region)
		if !bmp
			return 0
		this.cache[region] := { bmp: bmp, ts: now }
		return bmp
	}

	static Clear() {
		for region, entry in this.cache {
			if entry.bmp
				Gdip_DisposeImage(entry.bmp)
		}
		this.cache := Map()
	}
}
