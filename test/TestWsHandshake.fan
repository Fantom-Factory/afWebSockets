using web

** http://tools.ietf.org/html/rfc6455#section-4.2
internal class TestWsHandshake : WsTest {

	WsReqTestImpl?	req
	WsResTestImpl?	res
	WsProtocol?		core

	override Void setup() {
		req = WsReqTestImpl()
		res = WsResTestImpl()
		core= WsProtocol()
	}
	
	Void testHandshakeMustBeHttpVersion11() {
		verifyWsErrMsg(WsErrMsgs.handshakeWrongHttpVersion(Version("1.0"))) {
			req.version = Version("1.0")
			core.shakeHandsWithClient(req, res, null)
		}

		// future proof
		req.version = Version("1.2")
		core.shakeHandsWithClient(req, res, null)

		// future proof
		req.version = Version("2.0")
		core.shakeHandsWithClient(req, res, null)
	}

	Void testHandshakeMustBeHttpGet() {
		verifyWsErrMsg(WsErrMsgs.handshakeWrongHttpMethod("POST")) {
			req.method = "POST"
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainHost() {
		req.headers.remove("Host")
		verifyWsErrMsg(WsErrMsgs.handshakeHeaderNotFound("Host", req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainConnection() {
		req.headers.remove("Connection")
		verifyWsErrMsg(WsErrMsgs.handshakeHeaderNotFound("Connection", req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}

		req.headers["Connection"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeWrongHeaderValue("Connection", "Upgrade", "wotever")) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainUpgrade() {
		req.headers.remove("Upgrade")
		verifyWsErrMsg(WsErrMsgs.handshakeHeaderNotFound("Upgrade", req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}

		req.headers["Upgrade"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeWrongHeaderValue("Upgrade", "websocket", "wotever")) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainWsVersion() {
		req.headers.remove("Sec-WebSocket-Version")
		verifyWsErrMsg(WsErrMsgs.handshakeHeaderNotFound("Sec-WebSocket-Version", req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}

		req.headers["Sec-WebSocket-Version"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeWrongHeaderValue("Sec-WebSocket-Version", "13", "wotever")) {
			core.shakeHandsWithClient(req, res, null)
		}
		verifyEq(res.headers["Sec-WebSocket-Version"], "13")
	}

	Void testHandshakeReqHeaderContainsWsKey() {
		req.headers.remove("Sec-WebSocket-Key")
		verifyWsErrMsg(WsErrMsgs.handshakeHeaderNotFound("Sec-WebSocket-Key", req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeMatchesAllowedOrigins() {
		verifyWsErrMsg(WsErrMsgs.handshakeHeaderNotFound("Origin", req.headers)) {
			core.shakeHandsWithClient(req, res, ["*"])
		}
		
		req.headers["Origin"] = "alienfactory.co.uk"
		verifyWsErrMsg(WsErrMsgs.handshakeOriginIsNotAllowed("alienfactory.co.uk", ["alienfactory.com"])) {
			core.shakeHandsWithClient(req, res, ["alienfactory.com"])
		}
		verifyEq(res.statusCode, 403)
	}

	Void testHandshakeSuccess() {
		core.shakeHandsWithClient(req, res, null)

		verifyEq(res.statusCode, 101)
		verifyEq(res.headers["Upgrade"], 				"websocket")
		verifyEq(res.headers["Connection"], 			"Upgrade")
		verifyEq(res.headers["Sec-WebSocket-Accept"], 	"2/qvz8Hucx3K4CxvMRjwgD42aoE=")
	}
}
