using afIoc
using afBedSheet::Route
using afBedSheet::Routes
using afBedSheet::Text as BsText
using afBedSheet::WebSocketsModuleV1
using afConcurrent::Synchronized
using afDuvet::HtmlInjector
using concurrent::ActorPool
using fwt

internal class Chatbox {	
	static Void main(Str[] args) {
		afBedSheet::Main().main("${AppModule#.qname} 8069".split)
	}
}

@SubModule { modules=[WebSocketsModuleV1#] }
internal class AppModule {
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf) {
		conf.add(Route(`/`, 	ChatboxRoutes#indexPage))
		conf.add(Route(`/ws`,	ChatboxRoutes#serviceWebSocket))
	}
}

internal const class ChatboxRoutes {
	@Inject private const WebSockets	webSockets
	@Inject private const HtmlInjector	htmlInjector
	
	new make(|This|in) { in(this) }

	BsText indexPage() {
		htmlInjector.injectFantomMethod(ChatboxClient#main)
		return BsText.fromHtml(
			"<!doctype>
			 <html>
			 <head>
			 	<title>WebSocket ChatBox Example</title>
			 </head>
			 <body>
			 </body>
			 </html>")
	}
	
	WebSocket serviceWebSocket() {
		WebSocket.make() {
			ws := it
			onMessage = |MsgEvent me| { 
				webSockets.broadcast("${ws.id} says, '${me.msg}'")
			}
		}
	}
}

@Js
internal class ChatboxClient {

	Void main() {
		webSock := WebSocket.make().open(`ws://localhost:8069/ws`)
		convBox := Text { text = "The conversation:\r\n"; multiLine = true; editable = false }
		textBox := Text { text = "Say something!" }
		sendMsg := |Event e| {
			webSock.sendText(textBox.text)
			textBox.text = ""
		}

		webSock.onMessage = |MsgEvent msgEnv| {
			convBox.text += "\r\n" + msgEnv.msg			
		}

		textBox.onAction.add(sendMsg)

		window := Window {
			title = "WebSocket ChatBox Example"
			InsetPane {
				EdgePane {
					center	= convBox
					bottom	= EdgePane {
						center	= textBox
						right	= Button { text = "Send"; onAction.add(sendMsg) }
					}
				},
			},
        }
		
		if (Env.cur.runtime != "js") {
			// ensure event funcs are run in the UI thread
			safeMess := Unsafe(webSock.onMessage)
			webSock.onMessage = |MsgEvent msgEnv| {
				Desktop.callAsync |->| { safeMess.val->call(msgEnv) }
			}

			// call the blocking read() method in a background thread
			safeSock := Unsafe(webSock)
			Synchronized(ActorPool()).async |->| {
				safeSock.val->read
			}
		}

		window.open
	}
}
