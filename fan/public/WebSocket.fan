
//[Constructor(in DOMString url, in optional DOMString protocols)]
//[Constructor(in DOMString url, in optional DOMString[] protocols)]

** The main 'WebSocket' class as defined by the [W3C WebSocket API]`http://www.w3.org/TR/websockets/`. 
** 
** To use, create an instance and pass to `WebSockets` to be serviced.
class WebSocket {
	
	Uri id {
		internal set		
		get {
			if (_attachment == null)
				throw WebSocketErr(WsErrMsgs.wsNotAttached)
			return &url
		}
	}

	** The URI the WebSocket is connected to.
	** Only available once connected.
	Uri url {
		internal set
		get {
			if (_attachment == null)
				throw WebSocketErr(WsErrMsgs.wsNotAttached)
			return &url
		}
	}
	
	** Returns the state of the connection.
	ReadyState readyState {
		internal set
	}

	** The number of bytes of UTF-8 text that have been queued using send() but have not yet been 
	** transmitted to the network.
	** This does not include framing overhead incurred by the protocol. 
	** If the connection is closed, this attribute's value will only increase with each call to the 
	** 'send()' method (the number does not reset to zero once the connection closes).
	Int bufferedAmount {
		internal set
	}

	** Hook for when the WebSocket is connected. 
	|->|? 			onOpen
	
	** Hook for when a message is received. 
	|MsgEvent|? 	onMessage
	
	** Hook for when an error occurs. 
	** Also called should the socket timeout
	|Err|?			onError
	
	** Hook for when an WebSocket closes. 
	|CloseEvent|?	onClose
	
	@NoDoc
	new make() {
		this.id				= ``
		this.url			= ``
		this.readyState		= ReadyState.connecting
		this.bufferedAmount	= 0
	}
	
	** Transmits data through the WebSocket connection.
	Void sendText(Str data) {
		_attachment.sendText(this, data)
	}
	
	** Closes the WebSocket connection.
	** Does nothing if the connection is already closed or closing.
	** 
	** The close code defaults to '1000 - Normal Closure' - see [RFC 6455 sec. 7.4.1]`https://tools.ietf.org/html/rfc6455#section-7.4.1` 
	** for a list of valid close codes.
	Void close(Int? code := 1000, Str? reason := null) {
		_attachment.close(this, code, reason)		
	}
	
	private WsAttachment? _attachment
	internal This _attach(WsAttachment attachment) {
		this._attachment = attachment.attach(this)
		return this
	}
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

