
internal class WsReqTestImpl : WsReq {
	override Version	httpVersion	:= Version("1.1")
	override Str		httpMethod	:= "GET"
	override Str:Str	headers		:= Utils.makeMap(Str#, Str#)
	private Str text
	new make(Str text := "") { 
		this.text = text
		headers["Host"] 					= "localhost:8070" 
		headers["Connection"] 				= "keep-alive, Upgrade" 
		headers["Upgrade"] 					= "WebSocket" 
		headers["Sec-WebSocket-Version"]	= "13" 
		headers["Sec-WebSocket-Key"]		= "L3vSWlgMnhQWv2FldG/QTQ==" 
	}
	override InStream in() { text.in }
}

internal class WsResTestImpl : WsRes {
	Int? statusCode
	Buf buf	:= Buf()
	override Str:Str	headers	:= [:]
	override Void setStatusCode(Int statusCode) { this.statusCode = statusCode } 	
	override OutStream out() { buf.out }
}

