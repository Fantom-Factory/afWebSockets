using web::WebUtil

internal const class WebSocketCore {
	private const static Log log := Utils.getLog(WebSocketCore#)
	private static const Version httpVer11	:= Version("1.1")

	Bool handshake(WsReq req, WsRes res, Str? allowedOrigins := null) {
		if (req.httpVersion < httpVer11)
			throw WebSocketErr(WsErrMsgs.handshakeWrongHttpVersion(req.httpVersion))
		
		if (req.httpMethod != "GET")
			throw WebSocketErr(WsErrMsgs.handshakeWrongHttpMethod(req.httpMethod))
		
		if (req.headers["Host"] == null)
			throw WebSocketErr(WsErrMsgs.handshakeHostHeaderNotFound(req.headers))
		
		if (req.headers["Connection"] == null)
			throw WebSocketErr(WsErrMsgs.handshakeConnectionHeaderNotFound(req.headers))
		if (!req.headers["Connection"].lower.split(',').contains("upgrade"))
			throw WebSocketErr(WsErrMsgs.handshakeConnectionHeaderWrongValue(req.headers["Connection"]))
		
		if (req.headers["Upgrade"] == null)
			throw WebSocketErr(WsErrMsgs.handshakeUpgradeHeaderNotFound(req.headers))
		if (!req.headers["Upgrade"].equalsIgnoreCase("websocket"))
			throw WebSocketErr(WsErrMsgs.handshakeUpgradeHeaderWrongValue(req.headers["Upgrade"]))

		if (req.headers["Sec-WebSocket-Version"] == null)
			throw WebSocketErr(WsErrMsgs.handshakeWsVersionHeaderNotFound(req.headers))
		if (!req.headers["Sec-WebSocket-Version"].equalsIgnoreCase("13")) {
			log.warn(WsLogMsgs.handshakeWsVersionHeaderWrongValue(req.headers["Sec-WebSocket-Version"]))
			res.headers["Sec-WebSocket-Version"] = "13"
			res.setStatusCode(400)
			return false
		}

		if (req.headers["Sec-WebSocket-Key"] == null)
			throw WebSocketErr(WsErrMsgs.handshakeWsKeyHeaderNotFound(req.headers))

		if (allowedOrigins != null) {
			origin := req.headers["Origin"]
			if (origin == null)
				throw WebSocketErr(WsErrMsgs.handshakeOriginHeaderNotFound(req.headers))
			originGlobs := (Regex[]) allowedOrigins.split(',').map { Regex.glob(it) }
			if (!originGlobs.any |domain| { domain.matches(origin) }) {
				log.warn(WsLogMsgs.handshakeOriginIsNotAllowed(origin, allowedOrigins))
				res.setStatusCode(403)
				return false
			}
		}

		reqKey := req.headers["Sec-WebSocket-Key"] + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
		resKey := Buf().print(reqKey).toDigest("SHA-1").toBase64
		
		res.headers["Upgrade"] 				= "websocket"
		res.headers["Connection"] 			= "Upgrade"
		res.headers["Sec-WebSocket-Accept"]	= resKey		
		res.setStatusCode(101)
		
		return true
	}
	
	internal Void process(WebSocketServerImpl webSocket, InStream reqIn, OutStream resOut) {

		Int? closeCode
		Str? closeReason
		Bool closeFrameSent

		webSocket.onOpen.each |f| { f.call() }
		
		while (webSocket.readyState < ReadyState.closing) {
			
			// TODO: move close info into Frame - and have it raise a CloseErr
			frame 	:= Frame.readFrom(reqIn)
			
			// TODO: close proper!
			if (frame == null) {
				webSocket.readyState = ReadyState.closing
				continue
			}
			
			// sec5.1 - The server MUST close the connection upon receiving a frame that is not 
			// masked. In this case, a server MAY send a Close frame with a status code of 1002 
			// (protocol error)
			if (!frame.maskFrame) {
				webSocket.readyState = ReadyState.closing
				closeCode 	= CloseFrameStatusCodes.protocolError
				closeReason	= "Frame not masked"
				Frame.makeCloseFrame(closeCode, closeReason).writeTo(resOut)
				closeFrameSent = true
				continue
			}
			
			if (frame.type == FrameType.close) {
				webSocket.readyState = ReadyState.closing
				closeCode 	= (frame.payload.remaining >= 2) ? frame.payload.readU2 : CloseFrameStatusCodes.noStatusRcvd
				try {
					closeReason	= (frame.payload.remaining >  0) ? frame.payload.readAllStr : null
				} catch (IOErr ioe) {
					closeCode 	= CloseFrameStatusCodes.invalidFramePayloadData
					closeReason	= "Close frame contained invalid UTF data"
				}
				Frame.makeCloseFrame(closeCode, closeReason).writeTo(resOut)
				closeFrameSent = true
				continue
			}
			
			if (frame.type == FrameType.text) {
				// if not UTF-8 text - die with a 1007
				message	:= frame.payload.readAllStr

				msgEvt	:= MsgEvent() { it.msg = message }
				Env.cur.err.printLine("GOT MESSAGE: $message")
				webSocket.onMessage.each |f| { f.call(msgEvt) }
				continue
			}

			// if frame unknown - fail connection with 1003
			webSocket.readyState = ReadyState.closing
			closeCode 	= CloseFrameStatusCodes.unsupportedData
			closeReason	= CloseFrameStatusCodes#unsupportedData.name.toDisplayName
			Frame.makeCloseFrame(closeCode, closeReason).writeTo(resOut)
			closeFrameSent = true

		}
		
		// die with a 1006 if connection is closed on us.
		
		Env.cur.err.printLine("WS go bye bye now!")
		webSocket.readyState = ReadyState.closed
//		closeEvent := CloseEvent() { it.wasClean = true; it.code = closeCode; it.reason = closeReason }
		closeEvent := CloseEvent() { it.wasClean = true; it.code = CloseFrameStatusCodes.normalClosure; it.reason = "Normal Closure" }
		webSocket.onClose.each |f| { f.call(closeEvent) }
		
	}
}
