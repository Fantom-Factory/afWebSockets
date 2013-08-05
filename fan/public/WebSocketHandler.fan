using afIoc
using afBedSheet

const class WebSocketHandler {
	
	private const Uri:Method handlers
	
	@Inject private const HttpRequest 			httpRequest
	@Inject private const HttpResponse			httpResponse
	@Inject private const ReqestHandlerInvoker	handlerInvoker
	
	// TODO: unit test
	internal new make(Uri:Method handlers, |This|? in := null) {
		in?.call(this)
		
		handlers.each |method, uri| {
			if (!ReflectUtils.paramTypesFitMethodSignature([WebSocket#], method))
				throw WebSocketErr(WsMsgs.wsHandlerMethodWrongParams(method, [WebSocket#]))
			if (!uri.isPathOnly)
				throw WebSocketErr(WsMsgs.wsHandlerUriNotPathOnly(uri))
			if (!uri.isPathAbs)
				throw WebSocketErr(WsMsgs.wsHandlerUriMustStartWithSlash(uri))
			if (!uri.isDir)
				throw WebSocketErr(WsMsgs.wsHandlerUriMustEndWithSlash(uri))
		}

		this.handlers = handlers.toImmutable		
	}

	Obj service(Uri remainingUri := ``) {
		
		req	:= WsReqBsImpl(httpRequest)
		res	:= WsResBsImpl(httpResponse)
		
		try {
			ok 	:= WebSocketCore().handshake(req, res)
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
		
		webSocket.onOpen.each |f| { f.call() }
		
		
		
		while (webSocket.readyState <= ReadyState.closing) {
			
			// die with 1002 if 
			frame 	:= Frame.readFrom(reqIn)
			
			// if not text frame - die with 1003
			
			// if not UTF-8 text - die with a 1007
			message	:= frame.payload.readAllStr
			
			msgEvt	:= MsgEvent() { it.msg = message }
			Env.cur.err.printLine("GOT MESSAGE: $message")
			webSocket.onMessage.each |f| { f.call(msgEvt) }
		}
		
		Env.cur.err.printLine("WS go bye bye now!")
//		webSocket.onClose.each |f| { f.call() }
		
		return true
	}

}


enum class CloseFrameStatusCode {
	// see http://tools.ietf.org/html/rfc6455#section-7.4
	// http://www.iana.org/assignments/websocket/websocket.xml
	close
}


