using web::WebMod

const class WebSocketWebMod : WebMod {

	private const WebSocketCore	webSocketCore	:= WebSocketCore()
	
	virtual WebSocket makeWebSocket() {
		WebSocket()
	}
	
	override Void onGet() {		
		try {
			ok 	:= webSocketCore.handshake(req, res)
			if (!ok) return
			
		} catch (WebSocketErr wsErr) {
			res.statusCode = 400
			return
		}

		webSocket := makeWebSocket
		attachment := WsAttachment(req.uri, "", res)
		webSocket._attach(attachment)

		// the meat of the WebSocket connection
		webSocketCore.process(webSocket, req.in, res.out)
	}

	// TODO: onStop - kill / close active WebSockets with 1001
	override Void onStop() {}
}
