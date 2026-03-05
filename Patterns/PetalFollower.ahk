#Warn All, Off

locatePetal() {
	static init := false
	static coco := ""
	static lastPos := ""
	static nWidth, nHeight, nStride, nScan, nBitmap
	if (!init) {
		coco := Gdip_CreateBitmap(5, 5)
		G := Gdip_GraphicsFromImage(coco)
		Gdip_GraphicsClear(G, 0xFFCC9C5C)
		Gdip_DeleteGraphics(G)

		Gdip_GetImageDimensions(coco, &nWidth, &nHeight)
		Gdip_LockBits(coco, 0, 0, nWidth, nHeight, &nStride, &nScan, &nBitmap)
		init := true
	}
	if (lastPos) {
		scanW := Round(windowWidth * 0.1)
		scanH := Round(windowHeight * 0.1)
		screenX := (windowX + lastPos.x) - (scanW // 2)
		screenY := (windowY + lastPos.y) - (scanH // 2)

		scanX := (screenX < windowX) ? windowX : screenX
		scanY := (screenY < windowY) ? windowY : screenY

		pBM := Gdip_BitmapFromScreen(scanX "|" scanY "|" scanW "|" scanH)
		Gdip_GetImageDimensions(pBM, &hWidth, &hHeight)
		Gdip_LockBits(pBM, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmap)
		sx2 := hWidth - nWidth
		sy2 := hHeight - nHeight
		if (0 = Gdip_LockedBitsSearch(hStride, hScan, hWidth, hHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2, 16)) {
			Gdip_UnlockBits(pBM, &hBitmap)
			Gdip_DisposeImage(pBM)

			finalX := (scanX - windowX) + foundX
			finalY := (scanY - windowY) + foundY

			lastPos := {x: finalX, y: finalY}
			tooltip "hi", finalX + windowX + 5, finalY + windowY + 5
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
	if (0 = Gdip_LockedBitsSearch(aStride, aScan, aWidth, aHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2, 16)) {
		Gdip_UnlockBits(pBMAll, &aBitmap)
		Gdip_DisposeImage(pBMAll)

		lastPos := {x: foundX + windowX, y: foundY + windowY}
		tooltip "hi", foundX + windowX + 5, foundY + windowY + 5
		return {x: foundX + windowX, y: foundY + windowY}
	}
	lastPos := ""
	Gdip_UnlockBits(pBMAll, &aBitmap)
	Gdip_DisposeImage(pBMAll)
	return 0
}

gotoPetal() {
	start := A_TickCount
   pwm := 50
	GetRobloxClientPos()
	if !(pos := locatePetal()) {
		return
	}

	centerX := windowWidth // 2, centerY := windowHeight // 2
	deadX := windowWidth * 0.035, deadY := windowHeight * 0.035

	heldKeys := Map(FwdKey, 0, BackKey, 0, LeftKey, 0, RightKey, 0)
	miss := 0

	while (A_TickCount - start < 10000) {
		if !(pos := locatePetal()) {
			if (miss++ > 3)
				break
			continue
		}
		miss := 0

		vecX := pos.x - centerX
		vecY := pos.y - centerY

      if (Abs(vecX) < deadX && Abs(vecY) < deadY)
         break
      
      maxDist := Max(Abs(vecX), Abs(vecY))
      dutyX := Abs(vecX) / maxDist
      dutyY := Abs(vecY) / maxDist

      targetX := (vecX > 0) ? RightKey : LeftKey
      targetY := (vecY > 0) ? BackKey : FwdKey

      cycle := Mod(A_TickCOunt, pwm)

      shouldHoldX := (cycle < (pwm * dutyX)) && (Abs(vecX) > deadX)
      shouldHoldY := (cycle < (pwm * dutyY)) && (Abs(vecY) > deadY)

      for key, state in [[targetX, shouldHoldX], [targetY, shouldHoldY]] {
         if (state[2] && !heldKeys[state[1]]) {
            send "{" state[1] " down}"
            heldKeys[state[1]] := true
         } else if (!state[2] && heldKeys[state[1]]) {
            send "{" state[1] " up}"
            heldKeys[state[1]] := false
         }
      }

      for k, v in heldKeys {
         if (v && k != targetX && k != targetY) {
            send "{" k " up}"
            heldKeys[k] := false
         }
      }
	}
	Send "{" FwdKey " up}{" BackKey " up}{" LeftKey " up}{" RightKey " up}"
}

loop
	gotoPetal()
