using web::WebRes
using concurrent::AtomicInt

internal class WsAttachment {
	private Uri			url
	private OutStream	resOut
	private AtomicInt	nextId
	
	new make(Uri url, OutStream resOut) {
		this.url 	= url
		this.resOut	= resOut
		this.nextId	= AtomicInt(1)
	}

	This attach(WebSocket webSocket) {
		webSocket.id		 = ("afWebSocket:" + nextId.getAndIncrement.toStr.padl(4, '0')).toUri
		webSocket.url 		 = url
		webSocket.readyState = ReadyState.open
		return this
	}
	
	Void sendText(WebSocket webSocket, Str data) {
		frame := Frame(data)
		webSocket.bufferedAmount += frame.payload.size
		
		if (webSocket.readyState != ReadyState.open)
			return
		
		frame.writeTo(resOut)
		webSocket.bufferedAmount -= frame.payload.size
	}
	
	Void close(WebSocket webSocket, Int? code, Str? reason) {
		// when the client pongs the close frame back, we'll close the connection
		webSocket.readyState = ReadyState.closing
		Frame(code, reason).writeTo(resOut)
	}
}
