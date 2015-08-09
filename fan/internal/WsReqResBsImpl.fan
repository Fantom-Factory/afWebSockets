using afBedSheet::HttpRequest
using afBedSheet::HttpResponse
using web

internal class WsReqBsImpl : WsReq {
	private HttpRequest	req
	override Version	httpVersion()	{ req.httpVersion	}
	override Str		httpMethod()	{ req.httpMethod 	}
	override Str:Str	headers()		{ req.headers.map	}
	override InStream	in() 			{ req.body.in 		}
	new make(HttpRequest req) { this.req = req }
}

internal class WsResBsImpl : WsRes {
	private HttpResponse	res
	private WebRes	res2
	override Str:Str		headers()	{ res2.headers 	}
	override OutStream		out()		{ res.out 			}
	override Void setStatusCode(Int statusCode) { res.statusCode = statusCode } 	
	new make(HttpResponse res, WebRes	res2) { this.res = res; this.res2=res2 }
}