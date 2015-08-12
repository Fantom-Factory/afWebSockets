using web::WebRes
using concurrent::AtomicInt

internal class WebSocketFanImpl : WebSocket {
				 private Bool 		connected
				 private OutStream?	resOut
	static const private AtomicInt	nextId := AtomicInt(1) 

	override Uri id {
		get {
			if (!connected)	throw WebSocketErr(WsErrMsgs.wsNotAttached)
			return &id
		}
	}

	override Uri url {
		get {
			if (!connected)	throw WebSocketErr(WsErrMsgs.wsNotAttached)
			return &url
		}
	}
	
	override ReadyState 	readyState
	override Int 			bufferedAmount
	override |->|? 			onOpen
	override |MsgEvent|? 	onMessage
	override |Err|?			onError
	override |CloseEvent|?	onClose
	
	new make() {
		if (Env.cur.runtime == "js")
			throw Err(WsErrMsgs.ctorServerOnly)
		this.id				= ``
		this.url			= ``
		this.readyState		= ReadyState.connecting
		this.bufferedAmount	= 0
	}
	
	override Void sendText(Str data) {
		frame := Frame(data)
		bufferedAmount += frame.payload.size
		
		if (readyState != ReadyState.open)
			return
		
		frame.writeTo(resOut)
		bufferedAmount -= frame.payload.size
	}
	
	override Void close(Int? code := 1000, Str? reason := null) {
		// when the client pongs the close frame back, we'll close the connection
		readyState = ReadyState.closing
		Frame(code, reason).writeTo(resOut)
	}
	
	This connect(Uri url, OutStream resOut) {
		this.url 		= url
		this.resOut		= resOut
		this.id		 	= ("afWebSocket:" + nextId.getAndIncrement.toStr.padl(4, '0')).toUri
		this.readyState = ReadyState.open
		connected = true
		return this
	}
	
	@NoDoc
	override Str toStr() {
		"$id - $url"
	}
}

@Js
internal class WebSocketJsImpl : WebSocket {
	override Uri id
	override Uri url
	override |->|? 			onOpen
	override |MsgEvent|? 	onMessage
	override |Err|?			onError
	override |CloseEvent|?	onClose
	
	native override ReadyState	readyState()
	native override Int 		bufferedAmount()

	new make(Uri url, Str[]? protocols) {
		if (url.scheme != "ws" && url.scheme != "wss")
			throw ArgErr(WsErrMsgs.wrongWsScheme(url))

		echo("JS IMPL")
		this.id				= `afWebSocket:null`
		this.url			= url
		connect(url, protocols)
		
		echo("my sisddsd $id")
		echo("buggered: $bufferedAmount")
		echo("readys: $readyState")
	}
	
	native 			Void connect(Uri url, Str[]? protocols)
	native override Void sendText(Str data)	
	native override Void close(Int? code := 1000, Str? reason := null)
}
