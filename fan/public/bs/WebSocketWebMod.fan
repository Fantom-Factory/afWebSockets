using concurrent
using web::WebMod

@NoDoc
const class WebSocketWebMod : WebMod {

	private const WebSockets	webSockets	:= WebSockets(ActorPool())
	
	virtual WebSocket makeWebSocket() {
		WebSocket.make()
	}
	
	override Void onGet() {		
		webSockets.service(makeWebSocket, req, res)
	}

	override Void onStop() {
		webSockets.shutdown
	}
}
