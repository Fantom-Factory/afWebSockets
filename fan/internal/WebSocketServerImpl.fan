
internal class WebSocketServerImpl : WebSocket {

	private WsRes res
	
	override Uri 			url
	override Str			protocol
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
	
	override ReadyState	readyState() {
		ReadyState.connecting
	}
	
	override Int bufferedAmount() {
		0
	}
	
	override Void send(Str data) {
		
		// TODO: check con state
		// TODO: add/set buffered amount
		Frame("Whoop Whoop!").in.pipe(res.out)
		res.out.flush
		
	}
	
	override Void close() { }

}
