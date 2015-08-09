using afIoc
using afBedSheet

class WebSocketsModule {
	
	static Void defineServices(ServiceDefinitions defs) {
		defs.add(WebSocketHandler#)
	}

}
