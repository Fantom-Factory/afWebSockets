using afIoc
using afBedSheet

// The afBedSheet class
const class WebSocketHandler {

			private const Uri:Method 			handlers

	@Inject private const HttpRequest 			httpRequest
	@Inject private const HttpResponse			httpResponse
	@Inject private const ReqestHandlerInvoker	handlerInvoker

			private const WebSocketCore			webSocketCore

	internal new make(Uri:Method handlers, |This|? in := null) {
		in?.call(this)
		
		// TODO register with reg shutdown and close all active ws conns with 1001 (going away)
		
		handlers.each |method, uri| {
			if (!ReflectUtils.paramTypesFitMethodSignature([WebSocket#], method))
				throw WebSocketErr(WsErrMsgs.wsHandlerMethodWrongParams(method, [WebSocket#]))
			if (!uri.isPathOnly)
				throw WebSocketErr(WsErrMsgs.wsHandlerUriNotPathOnly(uri))
			if (!uri.isPathAbs)
				throw WebSocketErr(WsErrMsgs.wsHandlerUriMustStartWithSlash(uri))
			if (!uri.isDir)
				throw WebSocketErr(WsErrMsgs.wsHandlerUriMustEndWithSlash(uri))
		}

		this.handlers 		= handlers.toImmutable
		this.webSocketCore	= WebSocketCore()
	}

	Obj service(Uri remainingUri := ``) {
		
		req	:= WsReqBsImpl(httpRequest)
		res	:= WsResBsImpl(httpResponse)
		
		try {
			ok 	:= webSocketCore.handshake(req, res)
			if (!ok) return false
			
		} catch (WebSocketErr wsErr) {
			res.setStatusCode(400)
			return false
		}
		

		httpResponse.disableGzip = true
		httpResponse.disableBuffering = true
		
		// flush the headers out to the client
		resOut 	:= res.out.flush
		reqIn 	:= req.in

		
		webSocket := WebSocketServerImpl(httpRequest.uri, "", res)
		
		// use pathStr to knockout any unwanted query str
		matchedUri := httpRequest.modRel.pathStr[0..<-remainingUri.pathStr.size].toUri
		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
		// The 'false' appends a '/' automatically - it's nicer web behaviour
	    method := handlers[matchedUri]
		
		wsHandler := RouteHandler(method, [webSocket])
		handlerInvoker.invokeHandler(wsHandler)		

		// the meat of the WebSocket connection
		webSocketCore.process(webSocket, reqIn, resOut)
		
		return true
	}
	
}



