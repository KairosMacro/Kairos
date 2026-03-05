global cameraOffset := 0
global targetIdx := 0
global rotStep := 0

DirMap := Map()
DirMap[FwdKey] := 1
DirMap[FwdKey . RightKey] := 2
DirMap[RightKey . FwdKey] := 2
DirMap[RightKey] := 3
DirMap[RightKey . BackKey] := 4
DirMap[BackKey . RightKey] := 4
DirMap[BackKey] := 5
DirMap[BackKey . LeftKey] := 6
DirMap[LeftKey . BackKey] := 6
DirMap[LeftKey] := 7
DirMap[LeftKey . FwdKey] := 8
DirMap[FwdKey . LeftKey] := 8

OnExit(ExitFunc)

SetTimer RotLoop, 50

dy_walk(10, FwdKey)
dy_walk(10, RightKey)
dy_walk(10, BackKey)
dy_walk(10, LeftKey)

SetTimer RotLoop, 0
comp(0)
ResetCam()

dy_walk(amount, dir1, dir2 := "") {
   key := dir1 . dir2
   if DirMap.Has(key)
      global targetIdx := DirMap[key]
   else
      global targetIdx := 1
   UpdateMovement()
   move(amount)
}

RotLoop() {
   global cameraOffset, rotStep
   if (rotStep < 3) {
      send "{" RotLeft "}"
      cameraOffset--
   } else {
      send "{" RotRight "}"
      cameraOffset++
   }
   rotStep++
   if (rotStep >= 6)
      rotStep := 0
   UpdateMovement()
}

UpdateMovement() {
   global targetIdx, cameraOffset
   if (targetIdx = 0) {
      comp(0)
      return
   }
   actualIdx := targetIdx - cameraOffset
   actualIdx := Mod(actualIdx - 1, 8)
   if (actualIdx < 0)
      actualIdx += 8
   actualIdx++
   comp(actualIdx)
}

ResetCam() {
   global cameraOffset
   while (cameraOffset != 0) {
      if (cameraOffset < 0) {
         send "{" RotRight "}"
         cameraOffset++
      } else {
         send "{" RotLeft "}"
         cameraOffset--
      }
   }
}

comp(idx) {
   static cycle := [
      [FwdKey], ; 1
      [FwdKey, RightKey], ; 2
      [RightKey], ; 3
      [RightKey, BackKey], ; 4
      [BackKey], ; 5
      [BackKey, LeftKey], ; 6
      [LeftKey], ; 7
      [LeftKey, FwdKey] ; 8
   ]
   if (idx = 0) {
      send "{" FwdKey " up}{" BackKey " up}{" LeftKey " up}{" RightKey " up}"
      return
   }
   target := cycle[idx]
   for k in [FwdKey, BackKey, LeftKey, RightKey] {
      press := false
      for tk in target
         if (k = tk)
            press := true
      if (!press && GetKeyState(k))
         send "{" k " up}"
   }
   for k in target
      if (!GetKeyState(k))
         send "{" k " down}"
}

ExitFunc(*) {
   comp(0)
   ResetCam()
}