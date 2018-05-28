using afIoc
using afBedSheet::ResponseProcessor
using web::WebReq
using web::WebRes
using concurrent

internal const class WebSocketResponseProcessor : ResponseProcessor {
	@Inject private const WebSockets webSockets

	new make(|This| in) { in(this)	}

	override Obj process(Obj webSocket) {
		try {
		webSock := (WebSocket) webSocket
		webSockets.service(webSock, req, res)
			
		} catch (Err err) {
			err.trace
		}
		return true
	}
	
	private WebReq req() {
		Actor.locals["web.req"] ?: throw Err("No web request active in thread")
	}

	private WebRes res() {
		Actor.locals["web.res"] ?: throw Err("No web request active in thread")
	}
}
