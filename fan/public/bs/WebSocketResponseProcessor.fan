using afIoc
using afBedSheet
using web
using concurrent

internal const class WebSocketResponseProcessor : ResponseProcessor {
	
	@Inject private const WebSockets	webSockets

	internal new make(|This| in) {
		in(this)
	}

	override Obj process(Obj response) {
		webSocket := (WebSocket) response

		webSockets.service(req, res, webSocket)

		return true
	}
	
	private WebReq req() {
		Actor.locals.containsKey("web.req") ? Actor.locals["web.req"] : throw Err("No web request active in thread")
	}
	
	private WebRes res() {
		Actor.locals.containsKey("web.res") ? Actor.locals["web.res"] : throw Err("No web request active in thread")
	}
}
