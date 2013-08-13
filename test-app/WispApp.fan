using wisp
using webmod
using concurrent

class WispApp {
	
	static Void main(Str[] args) {
		fileMod := FileMod() { it.file = `test-app/websocket.html`.toFile }
		wsMod	:= WebSocketWebMod(WispApp#handler)
		routes	:= ["test": fileMod, "websocket": wsMod]
		root 	:= RouteMod { it.routes = routes }
		
		Env.cur.err.printLine(fileMod.file.normalize.osPath)
		WispService { it.port=8080; it.root=root }.start
		Actor.sleep(Duration.maxVal)
	}
	
	static Void handler(WebSocket webSocket) {
		webSocket.onMessage = |MsgEvent me| {
			echo(me.msg)
		}
	}
}
