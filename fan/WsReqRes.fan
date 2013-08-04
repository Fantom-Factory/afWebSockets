
internal mixin WsReq {
	abstract Version	httpVersion()
	abstract Str		httpMethod()
	abstract Str:Str	headers()
	abstract InStream	in()
}

internal mixin WsRes {
	abstract Void		setStatusCode(Int statusCode)
	abstract Str:Str	headers()	
	abstract OutStream	out()
}
