using web::WebReq
using web::WebRes
using web::WebClient
using concurrent::AtomicInt
using concurrent::ActorPool
using inet::TcpSocket
using afConcurrent

internal class WebSocketFan : WebSocket {
	static const private AtomicInt	nextId		:= AtomicInt(1) 
	static const private WsProtocol	wsProtocol	:= WsProtocol()
				private InStream?	reqIn
				private OutStream?	resOut
				private Bool 		connected
						Bool		isClient

	override Uri 			id
	override ReadyState 	readyState
	override Int 			bufferedAmount

	override Uri url {
		get {
			if (!connected)	throw IOErr(WsErrMsgs.wsNotConnected)
			return &url
		}
	}

	new make() {
		this.id		 		= ("afWebSocket:" + nextId.getAndIncrement.toStr.padl(4, '0')).toUri
		this.url			= ``
		this.readyState		= ReadyState.connecting
		this.bufferedAmount	= 0
	}
	
	override This open(Uri url, Str[]? protocols := null) {
		if (url.scheme != "ws" && url.scheme != "wss")
			throw ArgErr(WsErrMsgs.wrongWsScheme(url))

		httpUri := ("http" + url.toStr[2..-1]).toUri
		c := WebClient(httpUri)

		wsProtocol.shakeHandsWithServer(c, protocols)
		
		// TODO: pester Brian to make socket field public and @NoDoc'ed
		socket := (TcpSocket) WebClient#.field("socket").get(c)

		isClient = true
		return ready(url, socket.in, socket.out)
	}
	
	override This upgrade(Obj webReq, Obj webRes, Bool flush := true) {
		req := (WebReq) webReq
		res := (WebRes) webRes
		wsProtocol.shakeHandsWithClient(req, res, allowedOrigins)
		return ready(req.modRel, req.in, res.out)
	}

	override Void close(Int? code := 1000, Str? reason := null) {
		// when the client pongs the close frame back, we'll close the connection
		CloseEvent { it.code = code; it.reason = reason }.writeFrame(this)
	}

	override Void read() {
		wsProtocol.process(this)
	}
	
	override Void sendText(Str data) {
		if (readyState == ReadyState.connecting)
			throw Err("WebSocket has not been opened / upgraded")
		writeFrame(Frame(data))
	}

	override Void sendBinary(Buf data) {
		if (readyState == ReadyState.connecting)
			throw Err("WebSocket has not been opened / upgraded")
		writeFrame(Frame(data))
	}
	
	Frame? readFrame() {
		Frame.readFrom(reqIn)
	}

	Void writeFrame(Frame frame) {
		bufferedAmount += frame.payload.size
		
		if (readyState != ReadyState.open && readyState != ReadyState.closing)
			return
		
		frame.fromClient(isClient).writeTo(resOut)
		
		bufferedAmount -= frame.payload.size
	}
	
	This ready(Uri url, InStream reqIn, OutStream resOut) {
		this.url 		= url
		this.reqIn		= reqIn
		this.resOut		= resOut
		this.readyState = ReadyState.open
		connected 		= true
		return this
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
			if (!connected)	throw IOErr(WsErrMsgs.wsNotConnected)
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
	
		   // FIXME: JS -Send Binary
		   override Void 		sendBinary(Buf data) { throw UnsupportedErr("TODO: Support binary messages in JS") }
		   override This 		upgrade(Obj req, Obj res, Bool flush := true) { throw UnsupportedErr("Only server side WebSockets may be upgraded") }
		   override Void		read()		{ }
	native 			Void		connect(Uri url, Str[]? protocols)
	native override ReadyState	readyState()
	native override Int 		bufferedAmount()
	native override Void		sendText(Str data)	
	native override Void		close(Int? code := 1000, Str? reason := null)
}
