using web::WebUtil

internal class WebSocketCore {
	private const static Log log := Utils.getLog(WebSocketCore#)
	private static const Version httpVer11	:= Version("1.1")

	Bool handshake(WsReq req, WsRes res, Str? allowedOrigins := null) {
		if (req.httpVersion < httpVer11)
			throw WebSocketErr(WsMsgs.handshakeWrongHttpVersion(req.httpVersion))
		
		if (req.httpMethod != "GET")
			throw WebSocketErr(WsMsgs.handshakeWrongHttpMethod(req.httpMethod))
		
		if (req.headers["Host"] == null)
			throw WebSocketErr(WsMsgs.handshakeHostHeaderNotFound(req.headers))
		
		if (req.headers["Connection"] == null)
			throw WebSocketErr(WsMsgs.handshakeConnectionHeaderNotFound(req.headers))
		if (!req.headers["Connection"].lower.split(',').contains("upgrade"))
			throw WebSocketErr(WsMsgs.handshakeConnectionHeaderWrongValue(req.headers["Connection"]))
		
		if (req.headers["Upgrade"] == null)
			throw WebSocketErr(WsMsgs.handshakeUpgradeHeaderNotFound(req.headers))
		if (!req.headers["Upgrade"].equalsIgnoreCase("websocket"))
			throw WebSocketErr(WsMsgs.handshakeUpgradeHeaderWrongValue(req.headers["Upgrade"]))

		if (req.headers["Sec-WebSocket-Version"] == null)
			throw WebSocketErr(WsMsgs.handshakeWsVersionHeaderNotFound(req.headers))
		if (!req.headers["Sec-WebSocket-Version"].equalsIgnoreCase("13")) {
			log.warn(WsMsgs.handshakeWsVersionHeaderWrongValue(req.headers["Sec-WebSocket-Version"]))
			res.headers["Sec-WebSocket-Version"] = "13"
			res.setStatusCode(400)
			return false
		}

		if (req.headers["Sec-WebSocket-Key"] == null)
			throw WebSocketErr(WsMsgs.handshakeWsKeyHeaderNotFound(req.headers))

		if (allowedOrigins != null) {
			origin := req.headers["Origin"]
			if (origin == null)
				throw WebSocketErr(WsMsgs.handshakeOriginHeaderNotFound(req.headers))
			originGlobs := (Regex[]) allowedOrigins.split(',').map { Regex.glob(it) }
			if (!originGlobs.any |domain| { domain.matches(origin) }) {
				log.warn(WsMsgs.handshakeOriginIsNotAllowed(origin, allowedOrigins))
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
	
}
