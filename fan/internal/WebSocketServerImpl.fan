
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
		
		// TODO: check con state
		// TODO: add/set buffered amount
		Frame(data).writeTo(res.out)
		res.out.flush
		
	}
	
	override Void close() { 
		
		// TODO: close!
		
	}

}
