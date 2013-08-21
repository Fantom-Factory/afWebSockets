using afIoc
using afBedSheet

class WebSocketsModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(WebSocketHandler#)
	}

}
