using web::WebMod

const class WebSocketWebMod : WebMod {

	private const WebSocketCore	webSocketCore	:= WebSocketCore()
	
	** The 'handlerMethod' must take `WebSocket` as an argument.
	const Method handlerMethod
	
	new make(Method handlerMethod) {
		this.handlerMethod = handlerMethod
	}
	
	override Void onGet() {
		wsReq	:= WsReqWebImpl(req)
		wsRes	:= WsResWebImpl(res)
		
		try {
			ok 	:= webSocketCore.handshake(wsReq, wsRes)
			if (!ok) return
			
		} catch (WebSocketErr wsErr) {
			wsRes.setStatusCode(400)
			return
		}
		
		// flush the headers out to the client
		resOut 	:= wsRes.out.flush
		reqIn 	:= wsReq.in
		
		webSocket := WebSocketServerImpl(req.uri, "", wsRes)
		
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
