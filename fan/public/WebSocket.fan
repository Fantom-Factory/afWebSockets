
//[Constructor(in DOMString url, in optional DOMString protocols)]
//[Constructor(in DOMString url, in optional DOMString[] protocols)]

// TODO: make const
** The main WebSocket interface as defined by the [W3C WebSocket API]`http://www.w3.org/TR/2011/WD-websockets-20110419/`. 
mixin WebSocket {
	
	** The URI the WebSocket is connected to.
	abstract Uri 		url()
	
	// TODO: client U+0021 or greater than U+007E -> Err
	** The subprotocol selected by the server. 
	** Returns 'emptyStr' if none selected.
	abstract Str		protocol()
	
	** Returns the state of the connection.
	abstract ReadyState	readyState()
	
	** The number of bytes of UTF-8 text that have been queued using send() but have not yet been 
	** transmitted to the network.
	** This does not include framing overhead incurred by the protocol. 
	** If the connection is closed, this attribute's value will only increase with each call to the 
	** 'send()' method (the number does not reset to zero once the connection closes).
	abstract Int bufferedAmount()

	abstract |->|? 			onOpen
	abstract |MsgEvent|? 	onMessage
//	abstract |->|?			onError
	abstract |CloseEvent|?	onClose
	
	** Transmits data through the WebSocket connection.
	abstract Void send(Str data)
	
	** Closes the WebSocket connection.
	** Does nothing if the connection is already closed or closing.
	abstract Void close()
}

** The state of the WebSocket connection.
enum class ReadyState {
	** The connection has not yet been established.
	connecting, 
	
	** The WebSocket connection is established and communication is possible.
	open, 
	
	** The connection is going through the closing handshake.
	closing, 
	
	** The connection has been closed or could not be opened.
	closed;
}

const class MsgEvent {
	const Str msg
	
	new make(|This|in) { in(this) }
}

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
	
	override Str toStr() {
		(wasClean ? "Clean" : "Unclean") + " close - ${code}: ${reason}"
	}
}
