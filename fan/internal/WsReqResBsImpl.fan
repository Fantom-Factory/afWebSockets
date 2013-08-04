using afBedSheet::HttpRequest
using afBedSheet::HttpResponse

internal class WsReqBsImpl : WsReq {
	private HttpRequest	req
	override Version	httpVersion()	{ req.httpVersion	}
	override Str		httpMethod()	{ req.httpMethod 	}
	override Str:Str	headers()		{ req.headers.map	}
	override InStream	in() 			{ req.in 			}
	new make(HttpRequest req) { this.req = req }
}

internal class WsResBsImpl : WsRes {
	private HttpResponse	res
	override Str:Str		headers()	{ res.headers.map 	}
	override OutStream		out()		{ res.out 			}
	override Void setStatusCode(Int statusCode) { res.statusCode = statusCode } 	
	new make(HttpResponse res) { this.res = res }
}