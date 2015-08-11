
** Sent on a `WebSocket` message event.
const class MsgEvent {
	const Str msg
	
	internal new make(|This|in) { in(this) }
}

** Sent on a `WebSocket` close event.
const class CloseEvent {
	
	** Returns 'true' if the connection was closed cleanly.
	const Bool wasClean

	** The WebSocket connection close code provided by the server.
	** Returns 'null' if the connection was not closed cleanly.
	const Int? code

	** The WebSocket connection close reason provided by the server.
	** Returns 'null' if the connection was not closed cleanly.
	const Str? reason

	internal new make(|This|in) { in(this) }
	
	internal Void writeTo(OutStream resOut) {
		Frame.makeCloseFrame(code, reason).writeTo(resOut)
	}
	
	@NoDoc
	override Str toStr() {
		(wasClean ? "Clean" : "Unclean") + " close - ${code}: ${reason}"
	}
}
