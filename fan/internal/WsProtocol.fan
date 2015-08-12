using web::WebReq
using web::WebRes
using web::WebClient

internal const class WsProtocol {
	private static const Log 		log 		:= WsProtocol#.pod.log
	private static const Version	httpVer11	:= Version("1.1")

	Bool shakeHandsWithClient(WebReq req, WebRes res, Str[]? allowedOrigins) {
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
			originGlobs := (Regex[]) allowedOrigins.map { Regex.glob(it) }
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
		
		return true
	}
	
	Void shakeHandsWithServer(WebClient c, Str[]? protocols) {
		
		// TODO: give better handshake messages
		key := Buf.random(16).toBase64
		c.reqMethod								= "GET"
		c.reqHeaders["Upgrade"]					= "websocket"
		c.reqHeaders["Connection"]				= "Upgrade"
		c.reqHeaders["Sec-WebSocket-Key"]		= key
		c.reqHeaders["Sec-WebSocket-Version"]	= 13.toStr
		if (protocols != null)
			c.reqHeaders["Sec-WebSocket-Protocol"]	= protocols.join(", ")
		c.writeReq
		
		c.readRes
		if (c.resCode != 101)									throw IOErr("Bad HTTP response $c.resCode $c.resPhrase")
		if (c.resHeaders["Upgrade"]    != "websocket")			throw IOErr("Invalid Upgrade header")
		if (c.resHeaders["Connection"] != "Upgrade")			throw IOErr("Invalid Connection header")
		digest		:= c.resHeaders["Sec-WebSocket-Accept"] ?:	throw IOErr("Missing Sec-WebSocket-Accept header")
		secDigest	:= Buf().print(key).print("258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toDigest("SHA-1").toBase64
		if (secDigest != digest) 								throw IOErr("Mismatch Sec-WebSocket-Accept")
	}
	
	Void process(WebSocketFan webSocket) {
		try {
			webSocket.onOpen?.call()
			
			while (webSocket.readyState < ReadyState.closing) {
				
				frame 	:= webSocket.readFrame
				
				if (frame == null) 
					throw CloseFrameErr(CloseCodes.abnormalClosure, CloseMsgs.abnormalClosure, false)
				
				if (frame.maskFrame == webSocket.isClient)
					throw CloseFrameErr(CloseCodes.protocolError, CloseMsgs.frameNotMasked)
				
				if (frame.type == FrameType.ping) {
					webSocket.writeFrame(Frame.makePongFrame)
					continue
				}

				if (frame.type == FrameType.pong) {
					continue
				}

				if (frame.type == FrameType.text) {
					message	:= frame.payloadAsStr ?: ""
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
				webSocket.writeFrame(err.closeEvent.toFrame)

			try webSocket.onClose?.call(err.closeEvent)
			catch (Err eek)
				log.warn("Err in onClose() handler", eek)
			
		} catch (Err err) {
			webSocket.readyState = ReadyState.closing
			
			try webSocket.onError?.call(err)
			catch (Err eek)
				log.warn("Err in onError() handler", eek)
			
			closeEvent := CloseEvent { it.wasClean = true; it.code = CloseCodes.internalError; it.reason = CloseMsgs.internalError(err) }
			try webSocket.writeFrame(closeEvent.toFrame)
			catch { /* meh */ }

			try webSocket.onClose?.call(closeEvent)
			catch (Err eek)
				log.warn("Err in onClose() handler", eek)
		}
		
		webSocket.readyState = ReadyState.closed
	}
}
