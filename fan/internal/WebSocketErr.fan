
internal const class CloseFrameErr : IOErr {
	const CloseEvent closeEvent
	new make(Int code, Str? reason, Bool wasClean := true) : super("${code}: ${reason}", null) {
		this.closeEvent = CloseEvent { it.wasClean = wasClean; it.code = code; it.reason = reason }
	}	
}
