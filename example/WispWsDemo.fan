using wisp
using webmod
using concurrent
using afWebSockets

class WispApp {
  static Void main(Str[] args) {
    wsMod   := WebSocketWebMod(Handlers#wsHandler)
    root    := RouteMod { it.routes = ["ws-server": wsMod] }

    WispService { it.port=8080; it.root=root }.start
    Actor.sleep(Duration.maxVal)
  }
}

class Handlers {
  Void wsHandler(WebSocket webSocket) {
    webSocket.onMessage = |MsgEvent me| {
      echo(me.msg)
      Actor.sleep(1sec)
      webSocket.sendText("Pong!")
    }
  }
}
