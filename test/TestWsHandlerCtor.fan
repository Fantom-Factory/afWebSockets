
internal class TestWsHandlerCtor : WsTest {

	Void testMethodHasCorrectParams() {
		verifyWsErrMsg(WsErrMsgs.wsHandlerMethodWrongParams(#invalid, [WebSocket#])) {
			fh := WebSocketHandler( [`/wotever/`:#invalid] )
		}
	}

	Void testUriPathOnly() {
		verifyWsErrMsg(WsErrMsgs.wsHandlerUriNotPathOnly(`http://wotever.com`)) {
			fh := WebSocketHandler( [`http://wotever.com`:#valid] )
		}
	}

	Void testUriNotStartWithSlash() {
		verifyWsErrMsg(WsErrMsgs.wsHandlerUriMustStartWithSlash(`wotever/`)) {
			fh := WebSocketHandler( [`wotever/`:#valid] )
		}
	}

	Void valid(WebSocket ws) { }
	Void invalid(Int ulp) { }
}
