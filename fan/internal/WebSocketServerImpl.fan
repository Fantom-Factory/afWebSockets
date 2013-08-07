
internal class WebSocketServerImpl : WebSocket {

	private WsRes res
	
	override Uri 			url
	override Str			protocol
	override ReadyState		readyState	:= ReadyState.connecting
	
	override |->|[] 		onOpen		:= [,]
	override |MsgEvent|[]	onMessage	:= [,]
//	override |->|[] 		onError		:= [,]
	override |CloseEvent|[] onClose		:= [,]


	new make(Uri url, Str protocol, WsRes res, |This|? in := null) {
		in?.call(this)
		this.url 		= url
		this.protocol 	= protocol
		this.res		= res
	}
	
	override Int bufferedAmount() {
		0	// TODO: bufferedAmount
	}
	
	override Void send(Str data) {
		
		// TODO: check con state
		// TODO: add/set buffered amount
		Frame("Whoop Whoop!").writeTo(res.out)
		res.out.flush
		
	}
	
	override Void close() { }

}
