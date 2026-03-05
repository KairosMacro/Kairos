move(tiles) {
    s := QPC()
    current := DetectMovespeed() + 0.45
    while ((current += DetectMovespeed()) < tiles * 4) {
        continue
    }
    return QPC() - s
}

walk(tiles, dir1, dir2?) {
    s := QPC()
    send "{" dir1 " down}" (IsSet(dir2) ? "{" dir2 " down}" : "")
    current := DetectMovespeed() + 0.45
    while ((current += DetectMovespeed()) < tiles * 4) {
        continue
    }
    send "{" dir1 " up}" (IsSet(dir2) ? "{" dir2 " up}" : "")
}

DetectMovespeed(getMovespeed?) {
    s := QPC()
    global HastyGuards, BaseMovespeed, GiftedHasty, offsetY
    GetRobloxClientPos()

    static chdc := 0, hbm := 0, obm := 0, capW := 0, capH := 30
    if (!chdc || capW != windowWidth) {
        if (chdc) {
            SelectObject(chdc, obm)
            DeleteObject(hbm)
            DeleteDC(chdc)
        }
        chdc := CreateCompatibleDC()
        hbm := CreateDIBSection(windowWidth, capH, chdc)
        obm := SelectObject(chdc, hbm)
        capW := windowWidth
    }

    hhdc := GetDC()
    BitBlt(chdc, 0, 0, windowWidth, capH, hhdc, windowX, windowY + offsetY + 48)
    ReleaseDC(hhdc)
    pBMScreen := Gdip_CreateBitmapFromHBITMAP(hbm)

    Haste := 0
    x := 0
    loop 3 {
        if (Gdip_ImageSearch(pBMScreen, bitmaps["move"]["haste"], &location, x, 14, , , , , 6) != 1) {
            break
        }
        x := SubStr(location, 1, InStr(location, ",") - 1)
        y := SubStr(location, InStr(location, ",") + 1)
        if (Gdip_ImageSearch(pBMScreen, bitmaps["move"]["Melody"], , x + 2, , x + Max(16, 2 * y - 24), y, 12) = 0) {
            Haste++
            (Haste = 1) ? (x1 := x, y1 := y) : ""
        }
        x += 2 * y - 14
    }
    CoconutHaste := (Haste = 2) * 10
    if Haste {
        loop 9 {
            if (Gdip_ImageSearch(pBMScreen, bitmaps["move"][Mod(11 - A_Index, 10)], , x1 + 2 * y1 - 44, Max(0, y1 - 18), x1 + 2 * y1 - 14, y1 - 1) = 1) {
                Haste := 1 + (A_Index = 1 || (Mod(11 - A_Index, 10) / 10))
                break
            }
            Haste := 1.1
        }
    } else {
        Haste := 1
    }

    BearMorph := 0
    for bear in ["Brown", "Black", "Mother", "Panda", "Polar", "Science", "Gummy"] {
        if (Gdip_ImageSearch(pBMScreen, bitmaps["move"][bear], , , 25, , 27, 5, , 2) = 1) {
            BearMorph := 4
            break
        }
    }

    Multiplier := (Gdip_ImageSearch(pBMScreen, bitmaps["move"]["SuperSmoothie"], , , 25, , 27, 4, , 2) = 1) ? 1.25 : Gdip_ImageSearch(pBMScreen, bitmaps["move"]["Oil"], , , 25, , 27, 4, , 2) = 1 ? 1.2 : 1
    HastePlus := (Gdip_ImageSearch(pBMScreen, bitmaps["move"]["HastePlus"], , , 25, , 27, , , 2) = 1) ? 2 : 1

    Gdip_DisposeImage(pBMScreen)
    return ((BaseMovespeed + BearMorph + CoconutHaste) * Multiplier * Haste * HastePlus * (GiftedHasty ? 1.15 : 1) * (HastyGuards ? 1.1 : 1)) * (IsSet(getMovespeed) ? 1 : (QPC() - s) / 1000)
}
