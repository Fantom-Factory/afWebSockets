using wisp
using webmod
using concurrent

** Keep this class out of the main src tree as I don't want to depend on the 3 'using' pods above.
class WebModApp {
	
	static Void main(Str[] args) {
		fileMod := FileMod() { it.file = `websocket.html`.toFile }
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
