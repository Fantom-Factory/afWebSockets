using fwt
using gfx
using afWebSockets
using afConcurrent
using concurrent

@Js @NoDoc
class WebSockExample {

	Void main() {
		webSock := WebSocket().open(`ws://localhost:8069/ws`)
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
