using afIoc
using afBedSheet

** A request handler for [afBedSheet]`http://repo.status302.com/doc/afBedSheet/#overview`
const class WebSocketHandler {

			private const Uri:Method 			handlers

	@Inject private const HttpRequest 			httpRequest
	@Inject private const HttpResponse			httpResponse
	@Inject private const ResponseProcessors	responseProcessor

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
//			if (!uri.isDir)
//				throw WebSocketErr(WsErrMsgs.wsHandlerUriMustEndWithSlash(uri))
		}

		this.handlers 		= handlers.toImmutable
		this.webSocketCore	= WebSocketCore()
		
		// TODO: onRegShutdown - kill / close active WebSockets with 1001
	}

	Obj service() {
		
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
		matchedUri := httpRequest.modRel.pathStr
		Env.cur.err.printLine("URI=${matchedUri}")
	    method := handlers[matchedUri.toUri]
		Env.cur.err.printLine("meth=${method}")
		
		// FIXME: die nicely if no route found
//		// throw Err if user mapped the Route but forgot to contribute a matching dir to this handler 
//		if (!dirMappings.containsKey(matchedUri)) {
//			msg := """<p><b>The path '${matchedUri}' is unknown. </b></p>
//			          <p><b>Add the following to your AppModule: </b></p>
//			          <code>@Contribute { serviceType=FileHandler# }
//			          static Void contributeFileMapping(MappedConfig conf) {
//			
//			            conf[`${matchedUri}`] = `/path/to/files/`.toFile
//			
//			          }</code>
//			          """
//			throw HttpStatusErr(501, msg)
//		}		
		
		wsHandler := MethodCall(method, [webSocket])
		responseProcessor.processResponse(wsHandler)

		// the meat of the WebSocket connection
		webSocket.readyState = ReadyState.open
		webSocketCore.process(webSocket, reqIn, resOut)
		
		return true
	}
	
}



