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
		verifyWsErrMsg(WsErrMsgs.handshakeHostHeaderNotFound(req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainConnection() {
		req.headers.remove("Connection")
		verifyWsErrMsg(WsErrMsgs.handshakeConnectionHeaderNotFound(req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}

		req.headers["Connection"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeConnectionHeaderWrongValue("wotever")) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainUpgrade() {
		req.headers.remove("Upgrade")
		verifyWsErrMsg(WsErrMsgs.handshakeUpgradeHeaderNotFound(req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}

		req.headers["Upgrade"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeUpgradeHeaderWrongValue("wotever")) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeReqHeaderMustContainWsVersion() {
		req.headers.remove("Sec-WebSocket-Version")
		verifyWsErrMsg(WsErrMsgs.handshakeWsVersionHeaderNotFound(req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}

		req.headers["Sec-WebSocket-Version"] = "wotever"
		ok := core.shakeHandsWithClient(req, res, null)
		verifyFalse(ok)
		verifyEq(res.statusCode, 400)
		verifyEq(res.headers["Sec-WebSocket-Version"], "13")
	}

	Void testHandshakeReqHeaderContainsWsKey() {
		req.headers.remove("Sec-WebSocket-Key")
		verifyWsErrMsg(WsErrMsgs.handshakeWsKeyHeaderNotFound(req.headers)) {
			core.shakeHandsWithClient(req, res, null)
		}
	}

	Void testHandshakeMatchesAllowedOrigins() {
		verifyWsErrMsg(WsErrMsgs.handshakeOriginHeaderNotFound(req.headers)) {
			core.shakeHandsWithClient(req, res, ["*"])
		}
		
		req.headers["Origin"] = "alienfactory.co.uk"
		ok := core.shakeHandsWithClient(req, res, ["alienfactory.com"])
		verifyFalse(ok)
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
