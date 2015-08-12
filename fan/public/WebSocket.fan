
** The main 'WebSocket' class as defined by the [W3C WebSocket API]`http://www.w3.org/TR/websockets/`. 
** 
** To use, create an instance and pass to `WebSockets` to be serviced.
@Js
mixin WebSocket {
	
	** A unique ID for this 'WebSocket' instance. Use to retrieve instances from the 'WebSockets' instance.
	** 
	** This field is only meaningful on the server, and is unused in Javascript.
	abstract Uri id()

	** The URI the WebSocket is connected to.
	** Only available once connected.
	abstract Uri url()
	
	** Returns the state of the connection.
	abstract ReadyState readyState()

	** The number of bytes of UTF-8 text that have been queued using send() but have not yet been 
	** transmitted to the network.
	** 
	** This amount does not include framing overhead incurred by the protocol.
	**  
	** If the connection is closed, this attribute's value will only increase with each call to the 
	** 'send()' method (the number does not reset to zero once the connection closes).
	abstract Int bufferedAmount()

	** Hook for when the WebSocket is connected. 
	abstract |->|? 			onOpen
	
	** Hook for when a message is received. 
	abstract |MsgEvent|? 	onMessage
	
	** Hook for when an error occurs. 
	** Also called should the socket timeout
	abstract |Err|?			onError
	
	** Hook for when an WebSocket closes. 
	abstract |CloseEvent|?	onClose
	
	** The ctor to use on the server.
	static new makeServer() {
		if (Env.cur.runtime == "js")
			throw Err(WsErrMsgs.ctorServerOnly)
		return WebSocketFanImpl()
	}
	
	** The ctor to use from a Javascript client.
	static new makeClient(Uri url, Str[]? protocols := null) {
		if (Env.cur.runtime != "js")
			throw Err(WsErrMsgs.ctorClientOnly)
		return WebSocketJsImpl(url, protocols)
	}

	// TODO: have sendBinary(Buf data)
	** Transmits data through the WebSocket connection.
	abstract Void sendText(Str data)
	
	** Closes the WebSocket connection.
	** Does nothing if the connection is already closed or closing.
	** 
	** The close code defaults to '1000 - Normal Closure' - see [RFC 6455 sec. 7.4.1]`https://tools.ietf.org/html/rfc6455#section-7.4.1` 
	** for a list of valid close codes.
	abstract Void close(Int? code := 1000, Str? reason := null)
}

** The state of the WebSocket connection.
@Js
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

