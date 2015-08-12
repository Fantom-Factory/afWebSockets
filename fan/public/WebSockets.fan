using afConcurrent
using concurrent
using web::WebReq
using web::WebRes

// TODO: convert to mixin
** (Service)
** The main service for handling 'WebSocket' connections.
const class WebSockets {
	private static const Log 		log 		:= WebSockets#.pod.log	
	private const WsProtocol 		wsProtocol	:= WsProtocol()
	private const SynchronizedMap	webSockets 
	
			** The maximum amount of time a websocket blocks for while waiting for a message from the client.
			** After this time the socket times out and the WebSocket closes.
			** 
			** Set to 'null' for an infinite timeout - but a word of caution, this then leaves you vulnerable to DOS attacks.
			**  
			** Set via the it-block ctor param.
			const Duration? socketReadTimeOut	:= 5min
	
			** Hook to allow negotiation of websocket protocols and extensions.
			** Called after the socket upgrade has been verified but before any response is flushed to the client.
			** 
			** Set via the it-block ctor param.
			const |WebReq, WebRes, WebSocket|? onUpgrade
	
	** Creates a 'WebSockets' instance. 
	new make(ActorPool actorPool, |This|? f := null) {
		f?.call(this)
		webSockets = SynchronizedMap(actorPool) {
			it.keyType = Uri#
			it.valType = Unsafe#
		}
	}
	
	** Services the given 'WebSocket'. 
	** The active HTTP request is upgraded to a WebSocket connection.
	** This call then enters a read loop and blocks until the WebSocket is closed.
	Void service(WebReq req, WebRes res, WebSocket webSocket) {
		try {
			ok 	:= wsProtocol.handshake(req, res)
			if (!ok) return
			
		} catch (WebSocketErr wsErr) {
			log.warn(wsErr.msg)
			res.statusCode = 400
			return
		}

		// allow others to mess with the connection
		// they may want to add protocols and extensions
		onUpgrade?.call(req, res, webSocket)

		// connection established
		res.out.flush
		((WebSocketFanImpl) webSocket).connect(req.modRel, res.out)

		req.socketOptions.receiveTimeout = socketReadTimeOut

		unsafeWs := Unsafe(webSocket)
		try {
			webSockets[webSocket.id] = unsafeWs
			wsProtocol.process(webSocket, req.in, res.out)
		} finally {
			webSockets.remove(unsafeWs)
		}
	}
	
	** Returns the 'WebSocket' associated with the given ID.
	** Note that closed WebSockets no longer exist.
	** 
	** If a WebSocket could not be found then either 'null' is returned or an 'ArgErr' is thrown dependant on the value of 'checked'.
	WebSocket? get(Uri webSocketId, Bool checked := true) {
		unsafe := (Unsafe?) webSockets[webSocketId]
		return unsafe?.val ?: (checked ? throw ArgErr("Could not find WebSocket with id '${webSocketId}'") : null)
	}
	
	** Broadcasts the given message to all open WebSockets, or to just the WebSockets associated with the given IDs.
	** This is a safe operation, as in if a WebSocket for a given ID could not be found, it is silently ignored. 
	Void broadcast(Str msg, Uri[]? webSocketIds := null) {
		sockets := webSocketIds?.map { webSockets[it] } ?: webSockets.vals 
		sockets.each |Unsafe? unsafe| {
			webSocket := (WebSocket?) unsafe?.val
			webSocket?.sendText(msg)
		}
	}
	
	** Closes all open WebSockets.
	Void shutdown() {
		webSockets.vals.each |Unsafe unsafe| {
			webSocket := (WebSocket) unsafe.val
			webSocket.close(CloseCodes.goingAway, "Server shutting down...")
		}		
		webSockets.clear
	}
}
