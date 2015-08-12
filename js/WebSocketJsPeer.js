
fan.afWebSockets.WebSocketJsPeer = fan.sys.Obj.$extend(fan.sys.Obj)
fan.afWebSockets.WebSocketJsPeer.prototype.$ctor = function(self) { }

fan.afWebSockets.WebSocketJsPeer.nextId = 0;
fan.afWebSockets.WebSocketJsPeer.prototype.connect = function(self, url, protocols) {
	var paddedId = fan.sys.Str.padl(fan.afWebSockets.WebSocketJsPeer.nextId.toString(), 4, 48);
	self.id$(fan.sys.Uri.fromStr("afWebSocket:" + paddedId));
	fan.afWebSockets.WebSocketJsPeer.nextId++;

	// in Chrome you can't pass 'null' or 'undefined' as a protocol - it gets converted to a str and sent up!
	self.webSocket = protocols ? new WebSocket(url.toStr(), protocols.m_values) : new WebSocket(url.toStr());

	self.webSocket.onopen = function() {
		var onOpen = self.onOpen();
		if (onOpen != null)
			onOpen.call();
	};

	self.webSocket.onmessage = function(event) {
		var onMessage = self.onMessage();
		if (onMessage == null) return;
		var msgEvent = fan.afWebSockets.MsgEvent.make(
			fan.sys.Func.make(
				fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it", "afWebSockets::MsgEvent", false)]),
				fan.sys.Void.$type,
				function(it) {
					it.m_msg = event.data;
				}
			)
		);
		onMessage.call(msgEvent);
	};

	self.webSocket.onerror = function(event) {
		console.warn(event);
		var onError = $this.onError();
		if (onError == null) return;
		onError.call(fan.sys.Err.make("Error"));
	};

	self.webSocket.onclose = function(event) {
		var onClose = self.onClose();
		if (onClose == null) null;
		var closeEvent = fan.afWebSockets.CloseEvent.make(
			fan.sys.Func.make(
				fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it", "afWebSockets::CloseEvent", false)]),
				fan.sys.Void.$type,
				function(it) {
					it.m_code		= fan.sys.ObjUtil.coerce(event.code, fan.sys.Int.$type.toNullable());
					it.m_reason		= event.reason;
					it.m_wasClean	= event.wasClean ? event.wasClean : true;
				}
			)
		);
		onClose.call(closeEvent);
	};
}

fan.afWebSockets.WebSocketJsPeer.prototype.sendText = function(self, data) {
	self.webSocket.send(data);
	console.log("sent data")
}

fan.afWebSockets.WebSocketJsPeer.prototype.close = function(self, code, reason) {
	if (code   === undefined) code   = fan.sys.ObjUtil.coerce(1000, fan.sys.Int.$type.toNullable());
	if (reason === undefined) reason = null;
	self.webSocket.close(code, reason);
}

fan.afWebSockets.WebSocketJsPeer.prototype.bufferedAmount = function(self) {
	return self.webSocket.bufferedAmount;
}

fan.afWebSockets.WebSocketJsPeer.prototype.readyState = function(self) {
	var readyState = self.webSocket.readyState;
	return fan.afWebSockets.ReadyState.m_vals.get(readyState);
}

