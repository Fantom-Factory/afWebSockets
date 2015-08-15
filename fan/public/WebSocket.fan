using web::WebReq
using web::WebRes

** The main 'WebSocket' class as defined by the [W3C WebSocket API]`http://www.w3.org/TR/websockets/`. 
** 
** To use, create an instance and pass to `WebSockets` to be serviced.
@Js
abstract class WebSocket {
	
	** A unique ID for this 'WebSocket' instance. Use to retrieve instances from 'WebSockets'.
	abstract Uri id()

	** The URL the WebSocket is connected to.
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

	Str[]? allowedOrigins
	
	** Hook for when the WebSocket is connected. 
	|->|? 			onOpen
	
	** Hook for when a message is received. 
	|MsgEvent|? 	onMessage
	
	** Hook for when an error occurs. 
	** Also called should the socket time out
	|Err|?			onError
	
	** Hook for when an WebSocket closes. 
	|CloseEvent|?	onClose

	@NoDoc
	protected new makeDefault() { }
	
	static new make() {
		Env.cur.runtime == "js" ? WebSocketJs() : WebSocketFan()
	}

	** Throws 'IOErr' should there be something wrong with the upgrade handskake.
	abstract This open(Uri url, Str[]? protocols := null)

	** Throws 'IOErr' should there be something wrong with the upgrade handskake.
	abstract This upgrade(Obj webReq, Obj webRes, Bool flush := true)
	
	** Closes the WebSocket connection.
	** Does nothing if the connection is already closed or closing.
	** 
	** The close code defaults to '1000 - Normal Closure' - see [RFC 6455 sec. 7.4.1]`https://tools.ietf.org/html/rfc6455#section-7.4.1` 
	** for a list of valid close codes.
	abstract Void close(Int? code := 1000, Str? reason := null)

	abstract Void read()
	
	** Transmits text through the WebSocket connection.
	abstract Void sendText(Str data)

	** Transmits binary data through the WebSocket connection.
	abstract Void sendBinary(Buf data)
	
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
