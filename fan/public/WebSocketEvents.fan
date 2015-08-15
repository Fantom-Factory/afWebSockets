
** Sent on a `WebSocket` message event.
@Js
class MsgEvent {
	Str? txt
	Buf? buf
	
	internal new make(|This|in) { in(this) }
	
	@NoDoc
	override Str toStr() {
		txt == null ? "Binary - $buf" : "Text - $txt"
	}
}

** Sent on a `WebSocket` close event.
@Js
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
	
	internal Void writeFrame(WebSocket webSocket) {
		webSock := (WebSocketFan) webSocket
		webSock.readyState = ReadyState.closing
		frame := Frame.makeCloseFrame(code, reason)
		try webSock.writeFrame(frame)
		catch { /* meh */ }
	}
	
	@NoDoc
	override Str toStr() {
		(wasClean ? "Clean" : "Unclean") + " close - ${code}: ${reason}"
	}
}
