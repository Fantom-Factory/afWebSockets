using concurrent
using web::WebMod

@NoDoc
const class WebSocketWebMod : WebMod {

	private const WebSockets	webSockets	:= WebSockets(ActorPool())
	
	virtual WebSocket makeWebSocket() {
		WebSocket.make()
	}
	
	override Void onGet() {		
		webSockets.service(req, res, makeWebSocket)
	}

	override Void onStop() {
		webSockets.shutdown
	}
}
