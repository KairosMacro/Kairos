class Audio {
    _wmp := ""
    _useNative := false
    _filePath := ""

    __New(filePath) {
        if !FileExist(filePath)
            throw Error("Sound file not found: " filePath)
        this._filePath := filePath

        try {
            this._wmp := ComObject("WMPlayer.OCX")
            this._wmp.settings.autoStart := false
            this._wmp.URL := filePath
        } catch {
            this._useNative := true
        }
    }

    Play(vol?) {
        if this._useNative {
            SoundPlay(this._filePath)
            return
        }
        if IsSet(vol)
            this.Volume := vol
        try this._wmp.controls.play()
    }

    Stop() {
        if this._useNative {
            SoundPlay("")
            return
        }
        try this._wmp.controls.stop()
    }

    Pause() {
        if this._useNative
            return
        try this._wmp.controls.pause()
    }

    Volume {
        get => this._useNative ? 100 : this._wmp.settings.volume
        set => this._useNative ? "" : this._wmp.settings.volume := value
    }

    Position {
        get => this._useNative ? 0 : this._wmp.controls.currentPosition
        set => this._useNative ? "" : this._wmp.controls.currentPosition := value
    }

    Duration => this._useNative ? 0 : this._wmp.currentMedia.Duration

    IsPlaying => (this._useNative ? false : this._wmp.playState = 3)

    __Delete() {
        this.Stop()
        if !this._useNative
            this._wmp := ""
    }
}
