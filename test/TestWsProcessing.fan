
internal class TestWsProcessing : WsTest {

	WsReqTestImpl? 			wsReq
	WsResTestImpl? 			wsRes
	WebSocketServerImpl?	webSocket
	WebSocketCore?			wsCore
	Buf?					reqInBuf
	
	override Void setup() {
		reqInBuf	= Buf()
		wsReq		= WsReqTestImpl(reqInBuf.in)
		wsRes		= WsResTestImpl()
		webSocket 	= WebSocketServerImpl(``, "", wsRes)
		wsCore		= WebSocketCore()
	}
	
	Void testOnOpenCallback() {
		gotMsg := false
		webSocket.onOpen.add |->| { gotMsg = true }
		
		wsCore.process(webSocket, wsReq.in, wsRes.out)
		
		verify(gotMsg)
	}

	Void testOnMessageCallback() {
		Frame.makeFromText("Hello Peeps!") { it.maskFrame = true }.writeTo(reqInBuf.out)
		reqInBuf.flip
		gotMsg := "no message"
		webSocket.onMessage.add |MsgEvent me| { gotMsg = me.msg }
		
		wsCore.process(webSocket, wsReq.in, wsRes.out)
		
		verifyEq(gotMsg, "Hello Peeps!")
	}

	Void testOnCloseCallback() {
		gotMsg := "no message"
		webSocket.onClose.add |CloseEvent ce| { gotMsg = ce.reason }
		
		wsCore.process(webSocket, wsReq.in, wsRes.out)
		
		verifyEq(gotMsg, "Normal Closure")
	}
}
