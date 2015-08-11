using web::WebRes

internal class WsAttachment {

	private Uri		url
	private Str		protocol
	private WebRes	res
	
	new make(Uri url, Str protocol, WebRes res) {
		this.url 		= url
		this.protocol 	= protocol
		this.res		= res
	}

	This attach(WebSocket webSocket) {
		webSocket.url 		 = url
		webSocket.protocol	 = protocol
		webSocket.readyState = ReadyState.open
		return this
	}
	
	Void sendText(WebSocket webSocket, Str data) {
		frame := Frame(data)
		webSocket.bufferedAmount += frame.payload.size
		
		if (webSocket.readyState != ReadyState.open)
			return
		
		frame.writeTo(res.out)
		webSocket.bufferedAmount -= frame.payload.size
	}
	
	Void close(WebSocket webSocket, Int? code, Str? reason) {
		// when the client pongs the close frame back, we'll close the connection
		webSocket.readyState = ReadyState.closing
		Frame(code, reason).writeTo(res.out)
		
		// TODO: it'd be nice to able to set a timeout and 'interrupt' the blocked requestIn.read()
		// for now, potentially, we're open to attack from many clients holding the connection open.
	}
}
