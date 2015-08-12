using afIoc
using afBedSheet
using afDuvet::HtmlInjector

internal class AppHandler {
	
	@Inject private const WebSockets webSockets
	@Inject private const HtmlInjector htmlInjector
	
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

	Text indexPage() {
		htmlInjector.injectFantomMethod(WebSockExample#main)
		return Text.fromHtml(
			"<!doctype>
			 <html>
			 <head>
			 	<title>WebSocket Example</title>
			 </head>
			 <body>
			 </body>
			 </html>")
	}
}


