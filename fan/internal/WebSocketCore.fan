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
		try {
			webSocket.onOpen?.call()
			
			while (webSocket.readyState < ReadyState.closing) {
				
				frame 	:= Frame.readFrom(reqIn)
				
				// TODO: close proper!
				// TODO: die with a 1006 if connection is closed on us.
				if (frame == null) {
					webSocket.readyState = ReadyState.closing
					continue
				}
				
				if (!frame.maskFrame)
					throw CloseFrameErr(CloseCodes.protocolError, CloseMsgs.frameNotMasked)
				
				if (frame.type == FrameType.close) {
					webSocket.readyState = ReadyState.closing
					closeCode 	:= (frame.payload.remaining >= 2) ? frame.payload.readU2 : CloseCodes.noStatusRcvd
					closeReason	:= (closeCode == CloseCodes.noStatusRcvd) ? null : frame.payloadAsStr
					// purists will hate me for this! using Errs for flow logic!
					throw CloseFrameErr(closeCode, closeReason)
				}

				if (frame.type == FrameType.text) {
					message	:= frame.payloadAsStr	
					msgEvt	:= MsgEvent() { it.msg = message }
					webSocket.onMessage?.call(msgEvt)
					continue
				}

				throw CloseFrameErr(CloseCodes.unsupportedData, CloseMsgs.unsupportedData)
			}

		} catch (CloseFrameErr err) {
			err.trace
			webSocket.readyState = ReadyState.closing
			err.closeEvent.writeTo(resOut)
			webSocket.onClose?.call(err.closeEvent)
			webSocket.readyState = ReadyState.closed
			
		} catch (Err err) {
		// die with 1011 internalError if catch Err
			err.trace
		}		
	}
}
