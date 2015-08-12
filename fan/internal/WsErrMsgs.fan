
@Js
internal mixin WsErrMsgs {
	
	static Str handshakeWrongHttpVersion(Version httpVersion) {
		"WebSocket requests need to be HTTP/1.1 or higher: received HTTP/$httpVersion"
	}

	static Str handshakeWrongHttpMethod(Str httpMethod) {
		"WebSocket requests need to use HTTP GET - received HTTP $httpMethod"
	}

	static Str handshakeHostHeaderNotFound(Str:Str headers) {
		"Request does not contain a 'Host' header - $headers"
	}

	static Str handshakeUpgradeHeaderNotFound(Str:Str headers) {
		"Request does not contain an 'Upgrade' header - $headers"
	}

	static Str handshakeUpgradeHeaderWrongValue(Str upgrade) {
		"Request 'Upgrade' header should be 'websocket' - $upgrade"
	}

	static Str handshakeConnectionHeaderNotFound(Str:Str headers) {
		"Request does not contain a 'Connection' header - $headers"
	}

	static Str handshakeConnectionHeaderWrongValue(Str upgrade) {
		"Request 'Connection' header should be 'Upgrade' - $upgrade"
	}

	static Str handshakeWsVersionHeaderNotFound(Str:Str headers) {
		"Request does not contain a 'Sec-WebSocket-Version' header - $headers"
	}

	static Str handshakeOriginHeaderNotFound(Str:Str headers) {
		"Request does not contain an 'Origin' header - $headers"
	}

	static Str handshakeWsKeyHeaderNotFound(Str:Str headers) {
		"Request does not contain a 'Sec-WebSocket-Key' header - $headers"
	}

	static Str wsNotAttached() {
		"WebSocket has not been attached to a HTTP request!"
	}

	static Str ctorServerOnly() {
		"This WebSocket ctor may only be used on the server"
	}

	static Str ctorClientOnly() {
		"This WebSocket ctor may only be used in a Javascript runtime"
	}
}
