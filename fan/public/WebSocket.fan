using web::WebReq
using web::WebRes

** The main 'WebSocket' class as defined by the [W3C WebSocket API]`http://www.w3.org/TR/websockets/`. 
** 
** Sample client usage:
** -------------------
** pre>
** syntax: fantom 
** webSock := WebSocket()
** webSock.onMessage |MsgEvent e| { ... }
** webSock.open(`ws:localhost:8069`)
** webSock.read
** <pre
** 
** Sample BedSheet server usage:
** ----------------------------
** 
** pre>
** syntax: fantom
** WebSocket serviceWs() { 
**     webSock := WebSocket()
**     webSock.onMessage |MsgEvent e| { ... }
**     return webSock
** }
** <pre
** 
** Note that all returned 'WebSocket' instances are available from the 'WebSockets' service for future use.
** 
** Sample WebMod server usage.  
** --------------------------
** 
** pre>
** syntax: fantom
** Void serviceWs() { 
**     webSock := WebSocket()
**     webSock.onMessage |MsgEvent e| { ... }
**     webSock.upgrade(req, res)
**     webSock.read
** }
** <pre
** 
@Js
abstract class WebSocket {
	
	** A unique ID for this 'WebSocket' instance. Use to retrieve instances from 'WebSockets'.
	abstract Uri id()

	** The URL this WebSocket is connected to. Only available after calling 'open()' or 'upgrade()'.
	abstract Uri url()
	
	** Returns the state of the connection.
	abstract ReadyState readyState()

	** The number of bytes that have been queued using 'sendXXXX()' but have not yet been 
	** transmitted to the network.
	** 
	** This amount does not include framing overhead incurred by the protocol.
	**  
	** If the connection is closed, this attribute's value will only increase with each call to the 
	** 'sendXXXX()' method (the number does not reset to zero once the connection closes).
	abstract Int bufferedAmount()

	** A list of regex globs that are matched against incoming requests. 
	** Only used by 'upgrade()' and is ignored by client WebSocket instances.
	** 
	** A 'null' value indicated that *all* origins are accepted. (Unsafe!)  
	** 
	**   syntax: fantom
	**   webSock := WebSocket()
	**   webSock.allowedOrigins = ["http://localhost:8069", "http://example.*"]
	Str[]? allowedOrigins
	
	** Hook for when the WebSocket is connected. 
	** 
	**   syntax: fantom
	**   webSock := WebSocket()
	**   webSock.onOpen = |->| {
	**       echo("WebSocket open for business!")
	**   }
	|->|? 			onOpen
	
	** Hook for when a message is received.
	**  
	**   syntax: fantom
	**   webSock := WebSocket()
	**   webSock.onMessage = |MsgEvent me| {
	**       echo("WebSocket message: $me.txt")
	**   }
	|MsgEvent|? 	onMessage
	
	** Hook for when an error occurs. 
	** 
	**   syntax: fantom
	**   webSock := WebSocket()
	**   webSock.onError = |Err err| {
	**       echo("WebSocket error - $err")
	**   }
	|Err|?			onError
	
	** Hook for when an WebSocket closes. 
	** 
	**   syntax: fantom
	**   webSock := WebSocket()
	**   webSock.onClose = |CloseEvent ce| {
	**       echo("WebSocket closed")
	**   }
	|CloseEvent|?	onClose

	@NoDoc
	protected new makeDefault() { }
	
	** Creates a 'WebSocket' instance based the current runtime. (Fantom vs Javascript) 
	** 
	**   syntax: fantom
	**   webSock := WebSocket()
	static new make() {
		Env.cur.runtime == "js" ? WebSocketJs() : WebSocketFan()
	}

	** Opens a HTTP connection to the given URL and upgrades the connection to a WebSocket.
	** All URLs should have either a 'ws' or 'wss' scheme. 
	** 
	** Usage designates this 'WebSocket' instance as a client.
	** 
	** Throws 'IOErr' on handshake errors.
	abstract This open(Uri url, Str[]? protocols := null)

	** Upgrades the given HTTP connection ([WebReq]`web::WebReq` and [WebRes]`web::WebRes`) to a WebSocket connection.
	** If 'flush' is 'true' (the default) then headers are flushed to the client, committing the response. 
	** Set to 'false' to alter header / connection settings before doing a manually flush.
	**  
	** Server side usage only.
	** 
	** Throws 'IOErr' on handshake errors.
	abstract This upgrade(Obj webReq, Obj webRes, Bool flush := true)
	
	** Enters a WebSocket read / event loop that blocks the current thread until the WebSocket is closed.
	** 
	** This method does nothing when called from a Javascript runtime.
	abstract Void read()

	** Transmits text through the WebSocket connection.
	abstract Void sendText(Str data)

	** Transmits binary data through the WebSocket connection.
	abstract Void sendBinary(Buf data)
	
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
