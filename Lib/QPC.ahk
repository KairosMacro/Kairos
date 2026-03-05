QPC() {
	static _ := 0, f := (DllCall("QueryPerformanceFrequency", "int64*", &_), _ /= 1000)
	return (DllCall("QueryPerformanceCounter", "int64*", &_), _ / f)
}
