using web

internal class TestWsServerImpl : WsTest {

	WsReqTestImpl?			wsReq
	WsResTestImpl? 			wsRes
	WebSocketFanImpl?		webSocket
	Buf?					resOutBuf
	
	override Void setup() {
		wsReq		= WsReqTestImpl()
		wsRes		= WsResTestImpl()
		webSocket 	= WebSocketFanImpl().connect(``, wsRes.out)
		resOutBuf	= wsRes.buf
	}

	Void testSendWhenOpen() {
		webSocket.readyState = ReadyState.open
		
		webSocket.sendText("Hello!")
		frame := Frame.readFrom(resOutBuf.flip.in)
		
		verifyEq(webSocket.bufferedAmount, 0)
		verifyEq(frame.payloadAsStr, "Hello!")
	}

	Void testSendWhenClosing() {
		webSocket.readyState = ReadyState.closing
		
		webSocket.sendText("Hello!")
		frame := Frame.readFrom(resOutBuf.flip.in)
		
		verifyEq(webSocket.bufferedAmount, 6)
		verifyEq(resOutBuf.size, 0)
		verifyNull(frame)
	}

	Void testSendWhenClosed() {
		webSocket.readyState = ReadyState.closed
		
		webSocket.sendText("Hello!")
		frame := Frame.readFrom(resOutBuf.flip.in)
		
		verifyEq(webSocket.bufferedAmount, 6)
		verifyEq(resOutBuf.size, 0)
		verifyNull(frame)
	}

}
