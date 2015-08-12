
internal mixin WsLogMsgs {

	static Str handshakeWsVersionHeaderWrongValue(Str wsVersion) {
		"Request 'Sec-WebSocket-Version' header should be '13' - $wsVersion"
	}

	static Str handshakeOriginIsNotAllowed(Str origin, Str[] allowedOrigins) {
		"Request 'Origin' header '${origin}' does not match allowed origins - $allowedOrigins"
	}
}
