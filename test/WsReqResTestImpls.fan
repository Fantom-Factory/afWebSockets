using web
using inet

internal class WsReqTestImpl : WebReq {
			 Buf			buf			:= Buf()
	override Str 			method		:= "GET"
	override Version 		version		:= Version("1.1")
	override IpAddr 		remoteAddr	() { (Obj) -1 }
	override Int 			remotePort	:= -1
	override Uri 			uri			:= ``
	override WebMod 		mod			:= DefaultWebMod()
	override Str:Str 		headers		:= Str:Str[:]
	override WebSession		session		() { (Obj) -1 }
	override InStream		in			:= buf.in
	override SocketOptions	socketOptions() { TcpSocket().options }
	override TcpSocket 		socket()	{ TcpSocket() } 
	
	new make() { 
		headers["Host"] 					= "localhost:8070" 
		headers["Connection"] 				= "keep-alive, Upgrade" 
		headers["Upgrade"] 					= "WebSocket" 
		headers["Sec-WebSocket-Version"]	= "13" 
		headers["Sec-WebSocket-Key"]		= "L3vSWlgMnhQWv2FldG/QTQ==" 
	}
}

internal class WsResTestImpl : WebRes {
			 Buf			buf			:= Buf()
	override Int 			statusCode	:= 200
	override Str:Str 		headers		:= Str:Str[:]
	override Cookie[] 		cookies		:= Cookie[,]
	override Bool 			isCommitted	:= false
	override WebOutStream	out			:= WebOutStream(buf.out)
	override Bool 			isDone		:= false
		
	override TcpSocket upgrade(Int statusCode := 101) { this.statusCode = statusCode; return TcpSocket() }
	override Void redirect(Uri uri, Int statusCode := 303) { }
	override Void sendErr(Int statusCode, Str? msg := null) { }
	override Void done() {}	
}

internal const class DefaultWebMod : WebMod { }