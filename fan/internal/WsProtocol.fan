using web::WebReq
using web::WebRes
using web::WebClient

internal const class WsProtocol {
	private static const Log 		log 		:= WsProtocol#.pod.log
	private static const Version	httpVer11	:= Version("1.1")

	Bool shakeHandsWithClient(WebReq req, WebRes res, Str[]? allowedOrigins) {
		if (req.version < httpVer11)
			throw IOErr(WsErrMsgs.handshakeWrongHttpVersion(req.version))
		
		if (req.method != "GET")
			throw IOErr(WsErrMsgs.handshakeWrongHttpMethod(req.method))
		
		"Host Connection Upgrade Sec-WebSocket-Version Sec-WebSocket-Key".split.each {
			if (!req.headers.containsKey(it))
				throw IOErr(WsErrMsgs.handshakeHeaderNotFound(it, req.headers))
		}
		
		if (!req.headers["Connection"].lower.split(',').contains("upgrade"))
			throw IOErr(WsErrMsgs.handshakeWrongHeaderValue("Connection", "Upgrade", req.headers["Connection"]))

		if (!req.headers["Upgrade"].equalsIgnoreCase("websocket"))
			throw IOErr(WsErrMsgs.handshakeWrongHeaderValue("Upgrade", "websocket", req.headers["Upgrade"]))

		if (!req.headers["Sec-WebSocket-Version"].equalsIgnoreCase("13")) {
			res.headers["Sec-WebSocket-Version"] = "13"
			throw IOErr(WsErrMsgs.handshakeWrongHeaderValue("Sec-WebSocket-Version", "13", req.headers["Sec-WebSocket-Version"]))
		}

		if (allowedOrigins != null) {
			origin 		:= req.headers["Origin"] ?: throw IOErr(WsErrMsgs.handshakeHeaderNotFound("Origin", req.headers))
			originGlobs	:= (Regex[]) allowedOrigins.map { Regex.glob(it) }
			if (origin == null || !originGlobs.any |domain| { domain.matches(origin) }) {
				res.statusCode = 403
				throw IOErr(WsErrMsgs.handshakeOriginIsNotAllowed(origin, allowedOrigins))
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
		
		if (c.resCode != 101)
			throw IOErr(WsErrMsgs.handshakeBadResponseCode(c.resCode, c.resPhrase))

		"Connection Upgrade Sec-WebSocket-Accept".split.each {
			if (!c.resHeaders.containsKey(it))
				throw IOErr(WsErrMsgs.handshakeHeaderNotFound(it, c.resHeaders))
		}
		
		if (!c.resHeaders["Connection"].lower.split(',').contains("upgrade"))
			throw IOErr(WsErrMsgs.handshakeWrongHeaderValue("Connection", "Upgrade", c.resHeaders["Connection"]))

		if (!c.resHeaders["Upgrade"].equalsIgnoreCase("websocket"))
			throw IOErr(WsErrMsgs.handshakeWrongHeaderValue("Upgrade", "websocket", c.resHeaders["Upgrade"]))

		digest		:= c.resHeaders["Sec-WebSocket-Accept"]
		secDigest	:= Buf().print(key).print("258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toDigest("SHA-1").toBase64
		if (secDigest != digest)
			throw IOErr(WsErrMsgs.handshakeBadAcceptCode)
	}
	
	Void process(WebSocketFan webSocket) {
		exitErr := (Err?) null
		try {
			webSocket.onOpen?.call()

			while (exitErr == null && webSocket.readyState < ReadyState.closing) {
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
					msgEvt	:= MsgEvent() { it.txt = frame.payloadAsStr }
					webSocket.onMessage?.call(msgEvt)
					continue
				}

				if (frame.type == FrameType.binary) {
					msgEvt	:= MsgEvent() { it.buf = frame.payloadAsBuf }
					webSocket.onMessage?.call(msgEvt)
					continue
				}

				if (frame.type == FrameType.close) {
					webSocket.readyState = ReadyState.closing
					closeCode 	:= (frame.payload.remaining >= 2) ? frame.payload.readU2 : CloseCodes.noStatusRcvd
					closeReason	:= (closeCode == CloseCodes.noStatusRcvd) ? null : frame.payloadAsStr.trimToNull
					exitErr 	= CloseFrameErr(closeCode, closeReason)
					continue
				}

				exitErr = CloseFrameErr(CloseCodes.unsupportedData, CloseMsgs.unsupportedFrame(frame.type))
			}

		} catch (Err err) {
			exitErr = err
		}
		
		closeEvent := exitErr is CloseFrameErr 
			? ((CloseFrameErr) exitErr).closeEvent 
			: CloseEvent { it.wasClean = true; it.code = CloseCodes.internalError; it.reason = CloseMsgs.internalError(exitErr) }
		
		if (closeEvent.wasClean)
			closeEvent.writeFrame(webSocket)

		try webSocket.onClose?.call(closeEvent)
		catch (Err eek)
			log.warn("Err in onClose() handler", eek)

		if (exitErr isnot CloseFrameErr)
			// don't bother calling onError for read-timeouts or if the socket closed behind our back
			if (exitErr isnot IOErr) 
				try webSocket.onError?.call(exitErr)
				catch (Err eek)
					log.warn("Err in onError() handler", eek)
		
		webSocket.readyState = ReadyState.closed
	}
}
