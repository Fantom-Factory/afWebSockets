using fwt
using gfx

@Js @NoDoc
class WebSockExample {

	Void main() {
		webSock := WebSocket(`ws://localhost:8069/ws`)
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

		Window {
			InsetPane {
				EdgePane {
					center	= convBox
					bottom	= EdgePane {
						center	= textBox
						right	= Button { text = "Send"; onAction.add(sendMsg) }
					}
				},
			},
        }.open
	}
}
