
internal class TestWebSocketHandlerCtor : WsTest {

	Void testMethodHasCorrectParams() {
		verifyWsErrMsg(WsMsgs.wsHandlerMethodWrongParams(#invalid, [WebSocket#])) {
			fh := WebSocketHandler( [`/wotever/`:#invalid] )
		}
	}

	Void testUriPathOnly() {
		verifyWsErrMsg(WsMsgs.wsHandlerUriNotPathOnly(`http://wotever.com`)) {
			fh := WebSocketHandler( [`http://wotever.com`:#valid] )
		}
	}

	Void testUriNotStartWithSlash() {
		verifyWsErrMsg(WsMsgs.wsHandlerUriMustStartWithSlash(`wotever/`)) {
			fh := WebSocketHandler( [`wotever/`:#valid] )
		}
	}

	Void testUriNotEndWithSlash() {
		verifyWsErrMsg(WsMsgs.wsHandlerUriMustEndWithSlash(`/wotever`)) {
			fh := WebSocketHandler( [`/wotever`:#valid] )
		}
	}
	
	Void valid(WebSocket ws) { }
	Void invalid(Int ulp) { }
}
