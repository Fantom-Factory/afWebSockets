using afIoc
using afBedSheet

internal class WebSocketsModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(WebSocketHandler#)
	}

}
