using afIoc
using afBedSheet
using afWebSockets
using concurrent

class BedSheetApp {
  Void main() {
    afBedSheet::Main().main("${AppModule#.qname} 8080".split)
  }
}

@SubModule { modules=[WebSocketsModule#] }
class AppModule {
  @Contribute
  static Void contributeRoutes(OrderedConfig conf) {
    conf.add(Route(`/ws-server`, WebSocketHandler#service))
  }

  @Contribute { serviceType=WebSocketHandler# }
  static Void contributeWebSocketMapping(MappedConfig conf) {
    conf[`/ws-server`] = Handlers#wsServer
  }
}

class Handlers {
  Void wsServer(WebSocket webSocket) {
    webSocket.onMessage = |MsgEvent me| {
      echo(me.msg)
      Actor.sleep(1sec)
      webSocket.sendText("Pong!")
    }
  }
}
