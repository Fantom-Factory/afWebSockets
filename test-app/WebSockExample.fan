using fwt
using gfx

@Js @NoDoc
class WebSockExample {

	Void main() {
		webSock := WebSocket.make()
		convBox := Text { text = "The conversation:\n"; multiLine = true; editable = false }
		textBox := Text { text = "Say something!" }
		sendMsg := |Event e| {
			webSock.sendText(textBox.text)
			textBox.text = ""
		}

		webSock.onMessage = |MsgEvent msgEnv| {
			convBox.text += msgEnv.msg + "\n"			
		}

		textBox.onAction.add(sendMsg)

		window := Window {
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

		window.onOpen {
			webSock.open(`ws://localhost:8069/ws`)
        }
		
		window.open
	}
}
