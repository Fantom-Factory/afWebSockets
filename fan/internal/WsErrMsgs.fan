
@Js
internal mixin WsErrMsgs {
	
	static Str handshakeWrongHttpVersion(Version httpVersion) {
		"Invalid HTTP version; expected 'HTTP/1.1' or higher but got 'HTTP/${httpVersion}'"
	}

	static Str handshakeWrongHttpMethod(Str httpMethod) {
		"Invalid HTTP method; expected 'GET' but got '${httpMethod}'"
	}

	static Str handshakeHeaderNotFound(Str wanted, Str:Str headers) {
		"Absent '${wanted}' HTTP header; not found in ${headers}"
	}

	static Str handshakeWrongHeaderValue(Str name, Str expected, Str actual) {
		"Invalid '${name}' HTTP header; expected '${expected}' but got '${actual}'"
	}

	static Str handshakeOriginIsNotAllowed(Str origin, Str[] allowedOrigins) {
		"Invalid 'Origin' HTTP header; '${origin}' does not match list of allowed origins - $allowedOrigins"
	}

	static Str handshakeBadResponseCode(Int resCode, Str resPhrase) {
		"Bad HTTP response code; expected '101 - Switching Protocols' but got '$resCode - $resPhrase'"
	}
	
	static Str handshakeBadAcceptCode() {
		"Bad 'Sec-WebSocket-Accept' HTTP header; does not match computed digest"
	}
	
	static Str wsNotConnected() {
		"WebSocket has not been connected to a HTTP request!"
	}

	static Str wrongWsScheme(Uri url) {
		"WebSocket URLs must have a 'ws' or 'wss' scheme - $url"
	}
}
