
internal class AppFactory {
	Void create(WebSocket webSocket) {
		app	:= AppHandler(webSocket)
	}
}

internal class AppHandler {
	
	private WebSocket webSocket
	
	new make(WebSocket webSocket) {
		this.webSocket = webSocket
		
		webSocket.onOpen = |->| { 
			Env.cur.err.printLine("ES: onOpen")
		}
		webSocket.onClose = |->| { 
			Env.cur.err.printLine("ES: onClose")
		}
		webSocket.onMessage = |MsgEvent me| { 
			Env.cur.err.printLine("ES: onMsg - $me.msg")
		}
	}
	
}
