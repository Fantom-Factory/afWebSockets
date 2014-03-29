using afIoc
using afBedSheet

class WebSocketsModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bind(WebSocketHandler#)
	}

}
