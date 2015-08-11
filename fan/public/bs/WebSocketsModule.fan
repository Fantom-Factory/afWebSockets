using afIoc
using afBedSheet

internal class WebSocketsModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(WebSockets#)
	}

}
