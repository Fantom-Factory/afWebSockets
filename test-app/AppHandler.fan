using afIoc

internal class AppHandler {
	
	@Inject private const WebSockets webSockets
	
	new make(|This|in) { in(this) }
	
	WebSocket goGoWebSocket() {
		WebSocket() {
			ws := it
			onOpen = |->| { 
				Env.cur.err.printLine("ES: onOpen")
			}
			onClose = |->| { 
				Env.cur.err.printLine("ES: onClose")
			}
			onMessage = |MsgEvent me| { 
				Env.cur.err.printLine("ES: onMsg - $me.msg")
				webSockets.broadcast("${ws.id} says, '${me.msg}'")
			}
		}
	}
	
}
