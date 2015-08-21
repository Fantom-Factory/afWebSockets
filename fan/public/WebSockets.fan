using afConcurrent
using concurrent
using web::WebReq
using web::WebRes

** (Service)
** The main service for handling 'WebSocket' connections.
** 
** If creating a BedApp
const mixin WebSockets {
	
	** The maximum amount of time a websocket blocks for while waiting for a message from the client.
	** After this time the socket times out and the WebSocket closes.
	** 
	** Set to 'null' for an infinite timeout - but a word of caution, this then leaves you vulnerable to DOS attacks.
	**  
	** This field may be set at any time, but only affects WebSockets connected *after* the change.
	** 
	** Defaults to '5min'.
	abstract Duration? socketReadTimeOut

	** Hook to allow negotiation of websocket protocols and extensions.
	** Called after the socket upgrade has been verified but before any response is flushed to the client.
	** 
	** This field may be set at any time.
	abstract |WebReq, WebRes, WebSocket|? onUpgrade
	
	** Creates a 'WebSockets' instance. 
	static new make(ActorPool actorPool, |This|? f := null) {
		WebSocketsImpl(actorPool, f)
	}
	
	** Services the given 'WebSocket'. 
	** The active HTTP request is upgraded to a WebSocket connection.
	** This call then enters a read loop and blocks until the WebSocket is closed.
	abstract Void service(WebSocket webSocket, WebReq req, WebRes res)

	** Returns the 'WebSocket' associated with the given ID.
	** Note that closed WebSockets no longer exist.
	** 
	** If a WebSocket could not be found then either 'null' is returned or an 'ArgErr' is thrown dependant on the value of 'checked'.
	abstract WebSocket? get(Uri webSocketId, Bool checked := true)
	
	** Broadcasts the given message to all open WebSockets, or to just the WebSockets associated with the given IDs.
	** This is a safe operation, as in if a WebSocket for a given ID could not be found, it is silently ignored. 
	abstract Void broadcast(Str msg, Uri[]? webSocketIds := null)
	
	** Closes all open WebSockets.
	abstract Void shutdown()
}

internal const class WebSocketsImpl : WebSockets {
	private static const Log 		log 			:= WebSockets#.pod.log	
	private const WsProtocol 		wsProtocol		:= WsProtocol()
	private const AtomicRef			readTimeOutRef	:= AtomicRef(5min)
	private const AtomicRef			onUpgradeRef	:= AtomicRef()
	private const SynchronizedMap	webSockets 
	
	override Duration? socketReadTimeOut {
		get { readTimeOutRef.val 		}
		set { readTimeOutRef.val = it	}
	}

	override |WebReq, WebRes, WebSocket|? onUpgrade {
		get { onUpgradeRef.val 		}
		set { onUpgradeRef.val = it	}		
	}
	
	new make(ActorPool actorPool, |WebSockets|? f := null) {
		webSockets = SynchronizedMap(actorPool) {
			it.keyType = Uri#
			it.valType = Unsafe#
		}
		f?.call(this)
	}
	
	override Void service(WebSocket webSocket, WebReq req, WebRes res) {

		// the socket may have been manually upgraded before being passed to us
		if (webSocket.readyState == ReadyState.connecting) {
			try {
				webSocket.upgrade(req, res, false)
				
			} catch (IOErr wsErr) {
				log.warn(wsErr.msg)
				if (res.statusCode == 200)
					res.statusCode = 400
				return
			}

			// allow others to mess with the connection
			// they may want to add protocols and extensions
			req.socketOptions.receiveTimeout = socketReadTimeOut
			onUpgrade?.call(req, res, webSocket)
	
			// connection established
			res.out.flush			
		}

		unsafeWs := Unsafe(webSocket)
		try {
			webSockets[webSocket.id] = unsafeWs
			webSocket.read
		} finally {
			webSockets.remove(unsafeWs)
		}
	}
	
	override WebSocket? get(Uri webSocketId, Bool checked := true) {
		unsafe := (Unsafe?) webSockets[webSocketId]
		return unsafe?.val ?: (checked ? throw ArgErr("Could not find WebSocket with id '${webSocketId}'") : null)
	}
	
	override Void broadcast(Str msg, Uri[]? webSocketIds := null) {
		sockets := webSocketIds?.map { webSockets[it] } ?: webSockets.vals 
		sockets.each |Unsafe? unsafe| {
			webSocket := (WebSocket?) unsafe?.val
			webSocket?.sendText(msg)
		}
	}
	
	override Void shutdown() {
		webSockets.vals.each |Unsafe unsafe| {
			webSocket := (WebSocket) unsafe.val
			webSocket.close(CloseCodes.goingAway, "Server shutting down...")
		}		
		webSockets.clear
	}
}
