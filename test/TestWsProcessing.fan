using web::WebReq
using web::WebRes

internal class TestWsProcessing : WsTest {

	WsReqTestImpl? 	wsReq
	WsResTestImpl?	wsRes
	WebSocket?		webSocket
	WsProtocol?		wsCore
	Buf?			reqInBuf
	MsgEvent? 		msgEvent
	CloseEvent? 	closeEvent
	Bool? 			openEvent
	Err? 			errEvent
	
	override Void setup() {
		wsReq		= WsReqTestImpl()
		wsRes		= WsResTestImpl()
		webSocket 	= WebSocketFan().ready(``, wsReq.in, wsRes.out)
		wsCore		= WsProtocol()
		reqInBuf	= wsReq.buf
		webSocket.onOpen	= |->|				{ openEvent  = true }
		webSocket.onMessage = |MsgEvent me|		{ msgEvent   = me   }
		webSocket.onClose	= |CloseEvent ce|	{ closeEvent = ce   }
		webSocket.onError	= |Err err|			{ errEvent   = err  }
	}

	Void testOnOpenCallback() {
		wsCore.process(webSocket)		
		verify(openEvent)
	}

	Void testOnMessageCallback() {
		Frame.makeTextFrame("Hello Peeps!").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip
		
		wsCore.process(webSocket)		
		verifyEq(msgEvent.txt, "Hello Peeps!")
	}

	Void testOnCloseCallback() {
		Frame.makeCloseFrame(CloseCodes.normalClosure, CloseMsgs.normalClosure).fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip
		
		wsCore.process(webSocket)
		verifyEq(closeEvent.code, 	CloseCodes.normalClosure)
		verifyEq(closeEvent.reason, CloseMsgs.normalClosure)
	}

	Void testOnErrorCallback() {
		webSocket.onMessage = |MsgEvent me| { throw Err("Boobies") }
		Frame.makeTextFrame("Hello!").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)

		verifyEq(closeEvent.code, 	CloseCodes.internalError)
		verifyEq(closeEvent.reason, CloseMsgs.internalError(Err("Boobies")))
	}

	Void testNonMaksedFrameClosesConnection() {
		Frame.makeCloseFrame(69, "Emma").writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		verifyNull(msgEvent)
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.protocolError)
		verifyEq(closeEvent.reason, 	CloseMsgs.frameNotMasked)
	}

	Void testBinaryFrameClosesConnection() {
		Frame.makeTextFrame("wotever") { it.type = FrameType.binary }.fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		verifyNull(msgEvent)
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.unsupportedData)
		verifyEq(closeEvent.reason, 	CloseMsgs.unsupportedFrame(FrameType.binary))
	}

	Void testClientCloseCodeIsPingedBack() {
		Frame.makeCloseFrame(69, "Emma").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		frame := Frame.readFrom(wsRes.buf.flip.in)
		closeCode 	:= frame.payload.readU2
		closeReason	:= frame.payloadAsStr
		
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		69)
		verifyEq(closeEvent.reason, 	"Emma")
		verifyEq(closeCode, 			69)
		verifyEq(closeReason, 			"Emma")		
	}

	Void testClientSocketReqInDisconnect() {
		wsCore.process(webSocket)
		frame := Frame.readFrom(wsRes.buf.flip.in)
		
		verifyEq(closeEvent.wasClean, 	false)
		verifyEq(closeEvent.code, 		CloseCodes.abnormalClosure)
		verifyEq(closeEvent.reason, 	CloseMsgs.abnormalClosure)
		verifyNull(frame)
	}
	
	Void testCloseReasonIsOptional() {
		Frame.makeCloseFrame(69, null).fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		69)
		verifyEq(closeEvent.reason, 	null)
	}	

	Void testCloseStatusIsOptional() {
		Frame.makeCloseFrame(null, "Emma").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.noStatusRcvd)
		verifyEq(closeEvent.reason, 	null)
	}

	Void testErrCloseFrameSentToClient() {
		webSocket.onMessage = |MsgEvent me| { throw Err("Boobies") }
		Frame.makeTextFrame("Hello!").fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		frame := Frame.readFrom(wsRes.buf.flip.in)
		
		verifyEq(frame.payload.readU2, 	CloseCodes.internalError)
		verifyEq(frame.payloadAsStr, 	CloseMsgs.internalError(Err("Boobies")))
	}	

	Void testPongFrameDoesNothing() {
		Frame.makePongFrame().fromClient.writeTo(reqInBuf.out)
		Frame.makeCloseFrame(CloseCodes.normalClosure, CloseMsgs.normalClosure).fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		
		verifyNull(msgEvent)
		verifyNull(errEvent)
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.normalClosure)
	}	

	Void testPingFrameSendsPongFrame() {
		Frame.makePingFrame().fromClient.writeTo(reqInBuf.out)
		Frame.makeCloseFrame(CloseCodes.normalClosure, CloseMsgs.normalClosure).fromClient.writeTo(reqInBuf.out)
		reqInBuf.flip

		wsCore.process(webSocket)
		frame := Frame.readFrom(wsRes.buf.flip.in)
		
		verifyNull(msgEvent)
		verifyNull(errEvent)
		verifyEq(closeEvent.wasClean, 	true)
		verifyEq(closeEvent.code, 		CloseCodes.normalClosure)
		verifyEq(frame.type, 			FrameType.pong)
	}	
}
