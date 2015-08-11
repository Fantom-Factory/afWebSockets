
//[Constructor(in DOMString url, in optional DOMString protocols)]
//[Constructor(in DOMString url, in optional DOMString[] protocols)]

** The main WebSocket interface as defined by the [W3C WebSocket API]`http://www.w3.org/TR/websockets/`. 
class WebSocket {
	
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
	
	// TODO: client U+0021 or greater than U+007E -> Err
	** The subprotocol selected by the server. 
	** Only available once connected.
	** Returns 'emptyStr' if none selected.
	Str protocol {
		internal set
		get {
			if (_attachment == null)
				throw WebSocketErr(WsErrMsgs.wsNotAttached)
			return &protocol
		}
	}

	** The extensions selected by the server.
	** Only available once connected.
	** Returns 'emptyStr'.
	Str extensions {
		internal set
		get {
			if (_attachment == null)
				throw WebSocketErr(WsErrMsgs.wsNotAttached)
			return &extensions
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
		this.url			= ``
		this.protocol		= ""
		this.extensions		= ""
		this.readyState		= ReadyState.connecting
		this.bufferedAmount	= 0
	}
	
	** Transmits data through the WebSocket connection.
	Void sendText(Str data) {
		_attachment.sendText(this, data)
	}
	
	** Closes the WebSocket connection.
	** Does nothing if the connection is already closed or closing.
	Void close(Int? code := null, Str? reason := null) {
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

