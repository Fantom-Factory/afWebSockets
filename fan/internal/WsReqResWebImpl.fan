using web::WebReq
using web::WebRes

internal class WsReqWebImpl : WsReq {
	private WebReq		req
	override Version	httpVersion()	{ req.version 	}
	override Str		httpMethod()	{ req.method 	}
	override Str:Str	headers()		{ req.headers 	}
	override InStream	in() 			{ req.in 		}
	new make(WebReq req) { this.req = req }
}

internal class WsResWebImpl : WsRes {
	private WebRes		res
	override Str:Str	headers()	{ res.headers }
	override OutStream	out()		{ res.out }
	override Void setStatusCode(Int statusCode) { res.statusCode = statusCode } 	
	new make(WebRes res) { this.res = res }
}