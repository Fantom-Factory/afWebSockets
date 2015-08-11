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
			core.handshake(req, res)
		}

		// future proof
		req.version = Version("1.2")
		core.handshake(req, res)

		// future proof
		req.version = Version("2.0")
		core.handshake(req, res)
	}

	Void testHandshakeMustBeHttpGet() {
		verifyWsErrMsg(WsErrMsgs.handshakeWrongHttpMethod("POST")) {
			req.method = "POST"
			core.handshake(req, res)
		}
	}

	Void testHandshakeReqHeaderMustContainHost() {
		req.headers.remove("Host")
		verifyWsErrMsg(WsErrMsgs.handshakeHostHeaderNotFound(req.headers)) {
			core.handshake(req, res)
		}
	}

	Void testHandshakeReqHeaderMustContainConnection() {
		req.headers.remove("Connection")
		verifyWsErrMsg(WsErrMsgs.handshakeConnectionHeaderNotFound(req.headers)) {
			core.handshake(req, res)
		}

		req.headers["Connection"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeConnectionHeaderWrongValue("wotever")) {
			core.handshake(req, res)
		}
	}

	Void testHandshakeReqHeaderMustContainUpgrade() {
		req.headers.remove("Upgrade")
		verifyWsErrMsg(WsErrMsgs.handshakeUpgradeHeaderNotFound(req.headers)) {
			core.handshake(req, res)
		}

		req.headers["Upgrade"] = "wotever"
		verifyWsErrMsg(WsErrMsgs.handshakeUpgradeHeaderWrongValue("wotever")) {
			core.handshake(req, res)
		}
	}

	Void testHandshakeReqHeaderMustContainWsVersion() {
		req.headers.remove("Sec-WebSocket-Version")
		verifyWsErrMsg(WsErrMsgs.handshakeWsVersionHeaderNotFound(req.headers)) {
			core.handshake(req, res)
		}

		req.headers["Sec-WebSocket-Version"] = "wotever"
		ok := core.handshake(req, res)
		verifyFalse(ok)
		verifyEq(res.statusCode, 400)
		verifyEq(res.headers["Sec-WebSocket-Version"], "13")
	}

	Void testHandshakeReqHeaderContainsWsKey() {
		req.headers.remove("Sec-WebSocket-Key")
		verifyWsErrMsg(WsErrMsgs.handshakeWsKeyHeaderNotFound(req.headers)) {
			core.handshake(req, res)
		}
	}

	Void testHandshakeMatchesAllowedOrigins() {
		verifyWsErrMsg(WsErrMsgs.handshakeOriginHeaderNotFound(req.headers)) {
			core.handshake(req, res, "*")
		}
		
		req.headers["Origin"] = "alienfactory.co.uk"
		ok := core.handshake(req, res, "alienfactory.com")
		verifyFalse(ok)
		verifyEq(res.statusCode, 403)
	}

	Void testHandshakeSuccess() {
		core.handshake(req, res)

		verifyEq(res.statusCode, 101)
		verifyEq(res.headers["Upgrade"], 				"websocket")
		verifyEq(res.headers["Connection"], 			"Upgrade")
		verifyEq(res.headers["Sec-WebSocket-Accept"], 	"2/qvz8Hucx3K4CxvMRjwgD42aoE=")
	}
}
