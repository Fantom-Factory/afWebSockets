
internal class WebSocketServerImpl : WebSocket {

	private WsRes res
	
	override Uri 			url
	override Str			protocol	:= ""
	override Str			extensions	:= ""
	override ReadyState		readyState	:= ReadyState.connecting
	
	override |->|? 			onOpen
	override |MsgEvent|?	onMessage
	override |Err|?			onError
	override |CloseEvent|?	onClose


	new make(Uri url, Str protocol, WsRes res, |This|? in := null) {
		in?.call(this)
		this.url 		= url
		this.protocol 	= protocol
		this.res		= res
	}

	override Int bufferedAmount() {
		0	// TODO: bufferedAmount
	}

	override Void sendText(Str data) {
		if (readyState != ReadyState.open)
			return
		
		// TODO: add/set buffered amount
		Frame(data).writeTo(res.out)
	}
	
	override Void close(Int? code := null, Str? reason := null) { 
		// when the client pongs the close frame back, we'll close the connection
		readyState = ReadyState.closing
		Frame(code, reason).writeTo(res.out)
		
		// TODO: it'd be nice to able to set a timeout and 'interrupt' the blocked requestIn.read()
		// for now, potentially, we're open to attack from many clients holding the connection open.
	}

}
