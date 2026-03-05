class GdipTooltip {
	__New() {
		this.Gui := Gui("-Caption +E0x80000 +E0x20 +AlwaysOnTop +ToolWindow +OwnDialogs")
		this.Gui.Show("NA")
		this.hwnd := this.Gui.Hwnd

		this.MaxWidth := 600
		this.MaxHeight := 800

		this.hbm := CreateDIBSection(this.MaxWidth, this.MaxHeight)
		this.hdc := CreateCompatibleDC()
		this.obm := SelectObject(this.hdc, this.hbm)
		this.G := Gdip_GraphicsFromHDC(this.hdc)
		Gdip_SetSmoothingMode(this.G, 4)

		this.fontName := "Arial"
		this.fontSize := 15
		this.fontStyle := 0
		this.fontColor := "FFFFFFFF"

		this.imageSize := 20

		this.padX := 5
		this.padY := 5
		this.rowSpacing := 2
		this.columnSpacing := 2
	}

	Show(data, x := "", y := "", scale := 0, background := 0xCC000000) {
		if !IsObject(data)
			data := [[String(data)]]
		else if (data.Length > 0 && Type(data[1]) != "Array")
			data := [data]

		layout := []
		totalH := this.padY * 2
		maxRowW := 0
		trash := []

		for i, row in data {
			if !IsObject(row)
				row := [row]

			rowHeight := 0
			rowWidth := 0
			rowItems := []

			for k, item in row {
				obj := {}
				isImage := false
				pBM := 0

				if IsInteger(item) && item > 65535 {
					pBM := item
					isImage := true
				} else if FileExist(item) {
					pBM := Gdip_CreateBitmapFromFile(item)
					isImage := true
				}

				if (isImage) {
					obj.Type := "Image"
					obj.Ptr := pBM
					obj.w := (scale ? Gdip_GetImageWidth(pBM) : this.imageSize)
					obj.h := (scale ? Gdip_GetImageHeight(pBM) : this.imageSize)
				} else {
					obj.Type := "Text"
					obj.Text := String(item)

					rect := this.MeasureText(obj.Text)
					obj.w := rect.w
					obj.h := rect.h
				}

				if (k > 1)
					rowWidth += this.columnSpacing
				rowWidth += obj.w
				if (obj.h > rowHeight)
					rowHeight := obj.h
				rowItems.Push(obj)
			}

			layout.Push({ Items: rowItems, w: rowWidth, h: rowHeight })

			if (rowWidth > maxRowW)
				maxRowW := rowWidth
			totalH += rowHeight + this.rowSpacing
		}

		totalH -= this.rowSpacing
		finalW := maxRowW + this.padX * 2
		Gdip_GraphicsClear(this.G)

		pBrushBackground := Gdip_BrushCreateSolid(background)
		Gdip_FillRoundedRectangle(this.G, pBrushBackground, 0, 0, finalW, totalH, 5)
		Gdip_DeleteBrush(pBrushBackground)

		currentY := this.padY

		for i, rowData in layout {
			currentX := this.padX

			for item in rowData.Items {
				yOffset := (rowData.h - item.h) // 2
				drawY := currentY + yOffset

				if (item.Type = "Image") {
					Gdip_DrawImage(this.G, item.Ptr, currentX, drawY, item.w, item.h)
				} else {
					Options := "x" currentX " y" drawY " c" this.fontColor " s" this.fontSize " " this.fontStyle " NoWrap"
					Gdip_TextToGraphics(this.G, item.Text, Options, this.fontName, item.w + 10, item.h + 10)
				}
				currentX += item.w + this.columnSpacing
			}
			currentY += rowData.h + this.rowSpacing
		}

		for bm in trash
			Gdip_DisposeImage(bm)

		if (x = "" || y = "") {
			MouseGetPos(&mx, &my)
			x := mx + 15
			y := my + 15
		}

		if (x + finalW > A_ScreenWidth)
			x := A_ScreenWidth - finalW - 10
		UpdateLayeredWindow(this.hwnd, this.hdc, x, y, finalW, totalH)
	}

	MeasureText(text) {
		hFormat := Gdip_StringFormatCreate()
		hFamily := Gdip_FontFamilyCreate(this.fontName)
		hFont := Gdip_FontCreate(hFamily, this.fontSize, this.fontStyle)

		CreateRectF(&RC := "", 0, 0, 0, 0)
		Rect := Gdip_MeasureString(this.G, String(text), hFont, hFormat, &RC)

		Gdip_DeleteStringFormat(hFormat)
		Gdip_DeleteFont(hFont)
		Gdip_DeleteFontFamily(hFamily)

		RectArr := StrSplit(Rect, "|")
		return { w: Ceil(RectArr[3]), h: Ceil(RectArr[4]) }
	}

	Hide() {
		Gdip_GraphicsClear(this.G)
		UpdateLayeredWindow(this.hwnd, this.hdc, -1000, -1000, 1, 1)
	}

	__Delete() {
		SelectObject(this.hdc, this.obm)
		DeleteObject(this.hbm)
		DeleteDC(this.hdc)
		try Gdip_DeleteGraphics(this.G)
		this.Gui.Destroy()
	}
}
