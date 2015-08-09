using web::WebMod

const class WebSocketWebMod : WebMod {

	private const WebSocketCore	webSocketCore	:= WebSocketCore()
	
	** The 'handlerMethod' must take `WebSocket` as an argument.
	const Method handlerMethod
	
	new make(Method handlerMethod) {
		this.handlerMethod = handlerMethod
	}
	
	override Void onGet() {		
		try {
			ok 	:= webSocketCore.handshake(req, res)
			if (!ok) return
			
		} catch (WebSocketErr wsErr) {
			res.statusCode = 400
			return
		}
		
		// flush the headers out to the client
		resOut 	:= res.out.flush
		reqIn 	:= req.in
		
		webSocket := WebSocketServerImpl(req.uri, "", res)
		
		if (handlerMethod.isStatic)
			handlerMethod.call(webSocket)
		else {
			inst := handlerMethod.parent.make
			handlerMethod.callOn(inst, [webSocket])
		}

		// the meat of the WebSocket connection
		webSocket.readyState = ReadyState.open
		webSocketCore.process(webSocket, reqIn, resOut)
	}

	// TODO: onStop - kill / close active WebSockets with 1001
	override Void onStop() {}
}
