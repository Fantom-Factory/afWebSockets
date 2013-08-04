
abstract internal class WsTest : Test {
	
	Void verifyWsErrMsg(Str errMsg, |Obj| func) {
		verifyErrAndMsg(WebSocketErr#, errMsg, func)
	}

	protected Void verifyErrAndMsg(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			msg := e.msg
			if (msg.trim != errMsg.trim)
				verifyEq(errMsg, msg)	// this gives the Str comparator in eclipse
			return
		}
		throw Err("$errType not thrown")
	}
	
}
