
internal class TestWsProcessing : WsTest {

	WsReqTestImpl? 			wsReq
	WsResTestImpl? 			wsRes
	WebSocketServerImpl?	webSocket
	WebSocketCore?			wsCore
	Buf?					reqInBuf
	MsgEvent? 				msgEvent
	CloseEvent? 			closeEvent
	Bool? 					openEvent
	
	override Void setup() {
		reqInBuf	= Buf()
		wsReq		= WsReqTestImpl(reqInBuf.in)
		wsRes		= WsResTestImpl()
		webSocket 	= WebSocketServerImpl(``, "", wsRes)
		wsCore		= WebSocketCore()
		webSocket.onOpen = |->| { openEvent = true }
		webSocket.onMessage = |MsgEvent me| { msgEvent = me }
		webSocket.onClose = |CloseEvent ce| { closeEvent = ce }
	}
	
	Void testOnOpenCallback() {
		wsCore.process(webSocket, wsReq.in, wsRes.out)		
		verify(openEvent)
	}

	Void testOnMessageCallback() {
		Frame.makeTextFrame("Hello Peeps!").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip
		
		wsCore.process(webSocket, wsReq.in, wsRes.out)		
		verifyEq(msgEvent.msg, "Hello Peeps!")
	}

	Void testOnCloseCallbackNormal() {
		Frame.makeCloseFrame(CloseCodes.normalClosure, CloseMsgs.normalClosure).fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip
		
		wsCore.process(webSocket, wsReq.in, wsRes.out)
		verifyEq(closeEvent.code, 	CloseCodes.normalClosure)
		verifyEq(closeEvent.reason, CloseMsgs.normalClosure)
	}

	Void testNonMaksedFrameClosesConnection() {
		Frame.makeCloseFrame(69, "Emma").writeTo(reqInBuf.out)

		wsCore.process(webSocket, wsReq.in, wsRes.out)
		verifyNull(msgEvent)
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.protocolError)
		verifyEq(closeEvent.reason, 	CloseMsgs.frameNotMasked)
	}

	Void testBinaryFrameClosesConnection() {
		Frame.makeTextFrame("wotever") { it.type = FrameType.binary }.fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket, wsReq.in, wsRes.out)
		verifyNull(msgEvent)
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.unsupportedData)
		verifyEq(closeEvent.reason, 	CloseMsgs.unsupportedData)
	}

	Void testClientCloseCodeIsPingedBack() {
		Frame.makeCloseFrame(69, "Emma").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket, wsReq.in, wsRes.out)
		frame := Frame.readFrom(wsRes.buf.flip.in)
		closeCode 	:= frame.payload.readU2
		closeReason	:= frame.payloadAsStr
		
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		69)
		verifyEq(closeEvent.reason, 	"Emma")
		verifyEq(closeCode, 			69)
		verifyEq(closeReason, 			"Emma")		
	}
}
