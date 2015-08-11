using afConcurrent
using concurrent
using web

// TODO: convert to mixin
const class WebSockets {
	
	private const WsProtocol 		wsProtocol	:= WsProtocol()
	private const SynchronizedList	webSockets 
	
	new make(ActorPool actorPool) {
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
			res.statusCode = 400
			return
		}

		webSocket._attach(WsAttachment(req.modRel, "", res.out))

		wsProtocol.process(webSocket, req.in, res.out)
	}
	
	
	Void broadcast(Str msg, Uri[]? webSocketIds := null) {
		
	}
	
	// TODO register with reg shutdown and close all active ws conns with 1001 (going away)
	Void shutdown() {
		
	}

}
