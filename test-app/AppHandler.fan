using afIoc
using afBedSheet::Text
using afDuvet::HtmlInjector

internal const class AppHandler {

	@Inject private const WebSockets	webSockets
	@Inject private const HtmlInjector	htmlInjector
	
	new make(|This|in) { in(this) }
	
	WebSocket goGoWebSocket() {
		WebSocket.make() {
			ws := it
			onMessage = |MsgEvent me| { 
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
			 	<title>WebSocket ChatBox Example</title>
			 </head>
			 <body>
			 </body>
			 </html>")
	}
}
