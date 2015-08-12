using web::WebRes
using web::WebClient
using concurrent::AtomicInt
using concurrent::ActorPool
using inet::TcpSocket
using afConcurrent

internal class WebSocketFan : WebSocket {
	static const private AtomicInt	nextId := AtomicInt(1) 
				private InStream?	reqIn
				private OutStream?	resOut
				private Bool 		connected
						Str[]?		allowedOrigins
						Bool		isClient

	override Uri 			id
	override ReadyState 	readyState
	override Int 			bufferedAmount

	override Uri url {
		get {
			if (!connected)	throw WebSocketErr(WsErrMsgs.wsNotConnected)
			return &url
		}
	}

	new make(Str[]? allowedOrigins) {
		if (Env.cur.runtime == "js")
			throw Err(WsErrMsgs.ctorServerOnly)
		this.id		 		= ("afWebSocket:" + nextId.getAndIncrement.toStr.padl(4, '0')).toUri
		this.url			= ``
		this.readyState		= ReadyState.connecting
		this.bufferedAmount	= 0
		this.allowedOrigins	= allowedOrigins
	}
	
	override This open(Uri url, Str[]? protocols := null) {
		if (url.scheme != "ws" && url.scheme != "wss")
			throw ArgErr(WsErrMsgs.wrongWsScheme(url))
		this.url		= url

		httpUri := ("http" + url.toStr[2..-1]).toUri
		key := Buf.random(16).toBase64
		c := WebClient(httpUri)

		// TODO: move to WsProtocol.handshake and give better error messages
		c.reqMethod								= "GET"
		c.reqHeaders["Upgrade"]					= "websocket"
		c.reqHeaders["Connection"]				= "Upgrade"
		c.reqHeaders["Sec-WebSocket-Key"]		= key
		c.reqHeaders["Sec-WebSocket-Version"]	= 13.toStr
		if (protocols != null)
			c.reqHeaders["Sec-WebSocket-Protocol"]	= protocols.join(", ")
		c.writeReq
		
		c.readRes
		if (c.resCode != 101)									throw IOErr("Bad HTTP response $c.resCode $c.resPhrase")
		if (c.resHeaders["Upgrade"]    != "websocket")			throw IOErr("Invalid Upgrade header")
		if (c.resHeaders["Connection"] != "Upgrade")			throw IOErr("Invalid Connection header")
		digest		:= c.resHeaders["Sec-WebSocket-Accept"] ?:	throw IOErr("Missing Sec-WebSocket-Accept header")
		secDigest	:= Buf().print(key).print("258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toDigest("SHA-1").toBase64
		if (secDigest != digest) 								throw IOErr("Mismatch Sec-WebSocket-Accept")
		
		// TODO: pester Brian to make socket field public and @NoDoc'ed
		socket := (TcpSocket) WebClient#.field("socket").get(c)
		resOut = socket.out
		
		this.readyState = ReadyState.open
		connected 		= true

		WsProtocol().process(this)
		return this
	}
	
	override Void sendText(Str data) {
		writeFrame(Frame(data))
	}
	
	override Void close(Int? code := 1000, Str? reason := null) {
		// when the client pongs the close frame back, we'll close the connection
		readyState = ReadyState.closing
		writeFrame(Frame(code, reason))
	}
	
	This service(Uri url, InStream reqIn, OutStream resOut) {
		this.url 		= url
		this.reqIn		= reqIn
		this.resOut		= resOut
		this.readyState = ReadyState.open
		connected 		= true
		return this
	}

	Frame? readFrame() {
		Frame.readFrom(reqIn)
	}

	Void writeFrame(Frame frame) {
		bufferedAmount += frame.payload.size
		
		if (readyState != ReadyState.open && readyState != ReadyState.closing)
			return
		
		if (isClient)
			frame.fromClient.writeTo(resOut)
		else
			frame.writeTo(resOut)
		
		bufferedAmount -= frame.payload.size
	}

	@NoDoc
	override Str toStr() {
		"$id - $url"
	}
}

@Js
internal class WebSocketJs : WebSocket {
	private Bool connected
	override Uri id
	override Uri url {
		get {
			if (!connected)	throw WebSocketErr(WsErrMsgs.wsNotConnected)
			return &url
		}
	}

	new make() {
		this.id		= `afWebSocket:null`
		this.url	= ``
	}
	
	override This open(Uri url, Str[]? protocols := null) { 
		if (url.scheme != "ws" && url.scheme != "wss")
			throw ArgErr(WsErrMsgs.wrongWsScheme(url))
		this.url = url
		connect(url, protocols)
		connected = true
		return this
   }

	native 			Void		connect(Uri url, Str[]? protocols)
	native override ReadyState	readyState()
	native override Int 		bufferedAmount()
	native override Void		sendText(Str data)	
	native override Void		close(Int? code := 1000, Str? reason := null)
}
