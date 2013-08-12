
const class WebSocketErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}	
}

internal const class CloseFrameErr : Err {
	const CloseEvent closeEvent
	new make(Int code, Str? reason, Bool wasClean := true) : super("${code}: ${reason}", null) {
		this.closeEvent = CloseEvent { it.wasClean = wasClean; it.code = code; it.reason = reason }
	}	
}
