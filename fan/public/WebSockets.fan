using afConcurrent
using concurrent
using web

// TODO: convert to mixin
** (Service)
** The main service for handling 'WebSocket' connections.
const class WebSockets {
	private static const Log 		log 		:= WebSockets#.pod.log	
	private const WsProtocol 		wsProtocol	:= WsProtocol()
	private const SynchronizedList	webSockets 
	
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
		webSockets = SynchronizedList(actorPool)
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
		webSocket._attach(WsAttachment(req.modRel, res.out))

		req.socketOptions.receiveTimeout = socketReadTimeOut

		unsafeWs := Unsafe(webSocket)
		try {
			webSockets.add(unsafeWs)
			wsProtocol.process(webSocket, req.in, res.out)
		} finally {
			webSockets.remove(unsafeWs)
		}
	}
	
	
	Void broadcast(Str msg, Uri[]? webSocketIds := null) {
		webSockets.each |Unsafe unsafe| {
			webSocket := (WebSocket) unsafe.val
			webSocket.sendText(msg)
		}
	}
	
	Void shutdown() {
		webSockets.each |Unsafe unsafe| {
			webSocket := (WebSocket) unsafe.val
			webSocket.close(CloseCodes.goingAway, "Server shutting down...")
		}		
		webSockets.clear
	}
}
