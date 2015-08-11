using web::WebReq
using web::WebRes

internal const class WsProtocol {
	private static const Log 		log 		:= WsProtocol#.pod.log
	private static const Version	httpVer11	:= Version("1.1")

	Bool handshake(WebReq req, WebRes res, Str? allowedOrigins := null) {
		if (req.version < httpVer11)
			throw WebSocketErr(WsErrMsgs.handshakeWrongHttpVersion(req.version))
		
		if (req.method != "GET")
			throw WebSocketErr(WsErrMsgs.handshakeWrongHttpMethod(req.method))
		
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
			res.statusCode = 400
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
				res.statusCode = 403
				return false
			}
		}

		reqKey := req.headers["Sec-WebSocket-Key"] + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
		resKey := Buf().print(reqKey).toDigest("SHA-1").toBase64
		
		res.headers["Upgrade"] 				= "websocket"
		res.headers["Connection"] 			= "Upgrade"
		res.headers["Sec-WebSocket-Accept"]	= resKey		
		res.statusCode = 101
		
		// connection established
		res.out.flush
		req.socketOptions.receiveTimeout = 5min
		
		return true
	}
	
	Void process(WebSocket webSocket, InStream reqIn, OutStream resOut) {
		try {
			webSocket.onOpen?.call()
			
			while (webSocket.readyState < ReadyState.closing) {
				
				frame 	:= Frame.readFrom(reqIn)
				
				if (frame == null) 
					throw CloseFrameErr(CloseCodes.abnormalClosure, CloseMsgs.abnormalClosure, false)
				
				if (!frame.maskFrame)
					throw CloseFrameErr(CloseCodes.protocolError, CloseMsgs.frameNotMasked)
				
				if (frame.type == FrameType.ping) {
					Frame.makePongFrame.writeTo(resOut)
					continue
				}

				if (frame.type == FrameType.pong) {
					continue
				}

				if (frame.type == FrameType.text) {
					message	:= frame.payloadAsStr	
					msgEvt	:= MsgEvent() { it.msg = message }
					webSocket.onMessage?.call(msgEvt)
					continue
				}

				if (frame.type == FrameType.close) {
					webSocket.readyState = ReadyState.closing
					closeCode 	:= (frame.payload.remaining >= 2) ? frame.payload.readU2 : CloseCodes.noStatusRcvd
					closeReason	:= (closeCode == CloseCodes.noStatusRcvd) ? null : frame.payloadAsStr
					// purists will hate me for this! Using Errs for flow logic!
					throw CloseFrameErr(closeCode, closeReason)
				}

				throw CloseFrameErr(CloseCodes.unsupportedData, CloseMsgs.unsupportedFrame(frame.type))
			}

		} catch (CloseFrameErr err) {
			webSocket.readyState = ReadyState.closing
			if (err.closeEvent.wasClean)
				err.closeEvent.writeTo(resOut)
			webSocket.onClose?.call(err.closeEvent)
			
		} catch (Err err) {
			webSocket.readyState = ReadyState.closing
			
			try {
				webSocket.onError?.call(err)
			} catch (Err eek) {
				log.warn("Err in onError() handler", eek)
			}
			
			closeEvent := CloseEvent { it.wasClean = true; it.code = CloseCodes.internalError; it.reason = CloseMsgs.internalError(err) }
			closeEvent.writeTo(resOut)
			webSocket.onClose?.call(closeEvent)
		}
		
		webSocket.readyState = ReadyState.closed
	}
}
