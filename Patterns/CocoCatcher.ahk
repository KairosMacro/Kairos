#Warn All, Off

locateCoco() {
	static init := false
	static coco := ""
	static lastPos := ""
	static nWidth, nHeight, nStride, nScan, nBitmap
	if (!init) {
		coco := Gdip_CreateBitmap(7, 7)
		G := Gdip_GraphicsFromImage(coco)
		Gdip_GraphicsClear(G, 0xFF99AAB5) ; health 0xFF1FE744, coco 0xFF99AAB5, balloon 0xFFBB1A34
		Gdip_DeleteGraphics(G)

		Gdip_GetImageDimensions(coco, &nWidth, &nHeight)
		Gdip_LockBits(coco, 0, 0, nWidth, nHeight, &nStride, &nScan, &nBitmap)
		init := true
	}
	if (lastPos) {
		scanW := Round(windowWidth * 0.2)
		scanH := Round(windowHeight * 0.2)
		screenX := (windowX + lastPos.x) - (scanW // 2)
		screenY := (windowY + lastPos.y) - (scanH // 2)

		scanX := (screenX < windowX) ? windowX : screenX
		scanY := (screenY < windowY) ? windowY : screenY

		pBM := Gdip_BitmapFromScreen(scanX "|" scanY "|" scanW "|" scanH)
		Gdip_GetImageDimensions(pBM, &hWidth, &hHeight)
		Gdip_LockBits(pBM, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmap)
		sx2 := hWidth - nWidth
		sy2 := hHeight - nHeight
		if (0 = Gdip_LockedBitsSearch(hStride, hScan, hWidth, hHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2)) {
			Gdip_UnlockBits(pBM, &hBitmap)
			Gdip_DisposeImage(pBM)

			finalX := (scanX - windowX) + foundX
			finalY := (scanY - windowY) + foundY

			lastPos := {x: finalX, y: finalY}
			return {x: finalX, y: finalY}
		}
		Gdip_UnlockBits(pBM, &hBitmap)
		Gdip_DisposeImage(pBM)
	}

	pBMAll := Gdip_BitmapFromScreen(windowX "|" windowY "|" windowWidth "|" windowHeight)
	Gdip_GetImageDimensions(pBMAll, &aWidth, &aHeight)
	Gdip_LockBits(pBMAll, 0, 0, aWidth, aHeight, &aStride, &aScan, &aBitmap)
	sx2 := aWidth - nWidth
	sy2 := aHeight - nHeight
	if (0 = Gdip_LockedBitsSearch(aStride, aScan, aWidth, aHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2)) {
		Gdip_UnlockBits(pBMAll, &aBitmap)
		Gdip_DisposeImage(pBMAll)

		lastPos := {x: foundX + windowX, y: foundY + windowY}
		return {x: foundX + windowX, y: foundY + windowY}
	}
	lastPos := ""
	Gdip_UnlockBits(pBMAll, &aBitmap)
	Gdip_DisposeImage(pBMAll)
	return 0
}

gotoCoco() {
	start := A_TickCount
	GetRobloxClientPos()
	if !(pos := locateCoco()) {
		rotate()
		return
	}
	rotate(true)

	centerX := windowWidth // 2, centerY := windowHeight // 2
	deadX := windowWidth * 0.035, deadY := windowHeight * 0.035

	heldX := ""
	heldY := ""
	miss := 0

	miss := 0
	; make it walk in an angle towards the coconut instead of 45 degree/straght ?
	while (A_TickCount - start < 10000) {
		if !(pos := locateCoco()) {
			if (miss++ > 3)
				break
			continue
		}
		miss := 0
		vecX := pos.x - centerX
		vecY := pos.y - centerY
		targetX := targetY := ""
		if (Abs(vecX) > deadX)
			targetX := (vecX > 0) ? RightKey : LeftKey
		if (Abs(vecY) > deadY)
			targetY := (vecY > 0) ? BackKey : FwdKey

		if (heldX != targetX) {
			if heldX
				send "{" heldX " up}"
			if targetX
				send "{" targetX " down}"
			heldX := targetX
		}
		if (heldY != targetY) {
			if heldY
				send "{" heldY " up}"
			if targetY
				send "{" targetY " down}"
			heldY := targetY
		}
		
		if (heldX = "" && heldY = "")
			break
	}
	Send "{" FwdKey " up}{" BackKey " up}{" LeftKey " up}{" RightKey " up}"
}

rotate(reset := false) {
	static step := 0
	static count := 0
	static last := 0
	limit := 160

	if (reset) {
		last := A_TickCount + 275
		step := 0
		return
	}
	if (step >= limit)
		return
	if (A_TickCount - last < 40)
		return
	last := A_TickCount
	step++
	if (Mod(count, 4) < 2) {
		send "{" RotLeft "}"
		compensate(1)
	} else {
		send "{" RotRight "}"
		compensate(-1)
	}
	count++
}

compensate(dir) {
	static cycle := []
	if (cycle.Length = 0) {
		cycle := [
			[FwdKey],
			[FwdKey, RightKey],
			[RightKey],
			[RightKey, BackKey],
			[BackKey],
			[BackKey, LeftKey],
			[LeftKey],
			[LeftKey, FwdKey]
		]
	}

	f := GetKeyState(FwdKey)
	b := GetKeyState(BackKey)
	l := GetKeyState(LeftKey)
	r := GetKeyState(RightKey)
	idx := (f && l ? 8 : f && r ? 2 : b && l ? 6 : b && r ? 4 : f ? 1 : b ? 5 : l ? 7 : r ? 3 : 0)
	
	if idx = 0
		return
		
	newIdx := idx + dir
	if newIdx > 8
		newIdx := 1
	else if newIdx < 1
		newIdx := 8
	old := cycle[idx]
	new := cycle[newIdx]
	for k in old {
		inNew := false
		for nk in new {
			if (k = nk) {
				inNew := true
				break
			}
		}
		if (!inNew) {
			send "{"  k " up}"
		}
	}
	for k in new {
		inOld := false
		for ok in old {
			if (k = ok)
				inOld := true
				break
		}
		if (!inOld)
			send "{"  k " down}"
	}
}

spam() {
	send "{" ZoomOut "}{" RotUp "}"
}
SetTimer(spam, 1)

loop
	gotoCoco()
