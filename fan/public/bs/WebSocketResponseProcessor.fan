using afIoc
using afBedSheet
using web

internal const class WebSocketResponseProcessor : ResponseProcessor {
	
	@Inject private const HttpResponse	httpResponse
	@Inject private const WebSocketCore	webSocketCore
	@Inject private const Registry		registry

	internal new make(|This| in) {
		in(this)
	}

	override Obj process(Obj response) {
		webSocket := (WebSocket) response

		req	:= (WebReq) registry.serviceById(WebReq#.qname)
		res	:= (WebRes) registry.serviceById(WebRes#.qname)
		
		try {
			ok 	:= webSocketCore.handshake(req, res)
			if (!ok) return true
			
		} catch (WebSocketErr wsErr) {
			res.statusCode = 400
			return true
		}

		httpResponse.disableGzip 		= true
		httpResponse.disableBuffering	= true
		
		// flush the headers out to the client
		resOut 	:= res.out.flush
		reqIn 	:= req.in

		// the meat of the WebSocket connection
		
//		webSocket := WebSocketServerImpl(httpRequest.url, "", res)
//
//		webSocket.readyState = ReadyState.open
//		webSocketCore.process(webSocket, reqIn, resOut)

		return true
	}
}
