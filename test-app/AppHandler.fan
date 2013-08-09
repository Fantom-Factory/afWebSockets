
class AppFactory {
	Void create(WebSocket webSocket) {
		app	:= AppHandler(webSocket)
	}
}

class AppHandler {
	
	private WebSocket webSocket
	
	new make(WebSocket webSocket) {
		this.webSocket = webSocket
		
		webSocket.onOpen.add(|->| { 
			Env.cur.err.printLine("ES: onOpen")
		})
		webSocket.onClose.add(|->| { 
			Env.cur.err.printLine("ES: onClose")
		})
		webSocket.onMessage.add(|MsgEvent me| { 
			Env.cur.err.printLine("ES: onMsg - $me.msg")
		})
	}
	
}
