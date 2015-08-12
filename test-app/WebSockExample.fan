using fwt
using gfx

@Js @NoDoc
class WebSockExample {

	Void main() {

		webSock := WebSocket(`http://localhost:8069/`)
		convBox := Text { text = "The conversation:\n"; multiLine = true; editable = false }
		textBox := Text { text = "Say something!" }
		sendMsg := |Event e| {
			echo("sending ws msg")
			webSock.sendText(textBox.text)
			textBox.text = ""
			convBox.repaint
		}

		webSock.onMessage = |MsgEvent msgEnv| {
			echo("received ws msg")
			convBox.text = convBox.text + msgEnv.msg + "\n"			
			convBox.repaint
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
