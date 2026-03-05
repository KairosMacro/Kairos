class Audio {
    _wmp := ""

    __New(filePath) {
        if !FileExist(filePath)
            throw Error("Sound file not found: " filePath)
        this._wmp := ComObject("WMPlayer.OCX")
        this._wmp.settings.autoStart := false
        this._wmp.URL := filePath
    }

    Play(vol?) {
        if IsSet(vol)
            this.Volume := vol
        try this._wmp.controls.play()
    }

    Stop() {
        try this._wmp.controls.stop()
    }

    Pause() {
        try this._wmp.controls.pause()
    }

    Volume {
        get => this._wmp.settings.volume
        set => this._wmp.settings.volume := value
    }

    Position {
        get => this._wmp.controls.currentPosition
        set => this._wmp.controls.currentPosition := value
    }

    Duration => this._wmp.currentMedia.Duration

    IsPlaying => (this._wmp.playState = 3)

    __Delete() {
        this.Stop()
        this._wmp := ""
    }
}
