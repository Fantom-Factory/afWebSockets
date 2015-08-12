using fwt
using gfx
using afWebSockets
using afConcurrent
using concurrent

@Js @NoDoc
class WebSockExample {

	Void main() {
		webSock := WebSocket().open(`ws://localhost:8069/ws`)
		convBox := Text { text = "The conversation:\n"; multiLine = true; editable = false }
		textBox := Text { text = "Say something!" }
		sendMsg := |Event e| {
			webSock.sendText(textBox.text)
			textBox.text = ""
		}

		webSock.onMessage = |MsgEvent msgEnv| {
			echo("msf $msgEnv.msg")
			convBox.text += "\n" + msgEnv.msg + "\n"			
		}

		webSock.onOpen = |->| {
			echo("onOpen")
		}

		webSock.onClose = |CloseEvent ce| {
			echo("onClose $ce")
		}

		webSock.onError = |Err err| {
			err.trace
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

		if (Env.cur.runtime != "js") {
			unsafe := Unsafe(webSock)
			window.onActive {
				Synchronized(ActorPool()).async |->| {
					echo("opening unsafe")
					webSocket	:= (WebSocket) unsafe.val
					onMessage	:= Unsafe(webSocket.onMessage)
					webSocket.onMessage = |MsgEvent msgEnv| {
						Desktop.callAsync |->| { onMessage.val->call(msgEnv) }
					}
					webSocket.read
				}
	        }
		}
		
		window.open
	}
}
