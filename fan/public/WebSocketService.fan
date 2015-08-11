using concurrent

** Registers a `WebSockets` instance as a Fantom service; only needed if working with 'WebMods' directly.  
const class WebSocketService : Service {
	private static const Log 	log 			:= WebSocketService#.pod.log
	private const AtomicRef		webSocketsRef	:= AtomicRef()


	** The wrapped 'WebSockets' instance. 
	** Available after the service starts. 
	WebSockets? webSockets {
				get { webSocketsRef.val }
		private set { webSocketsRef.val = it }
	}

	// ---- Service Lifecycle Methods ------------------------------------------------------------- 

	** Starts the WebSockets service.
	override Void onStart() {
		checkServiceNotStarted
		log.info("Starting IoC...");
	
		webSockets = WebSockets()
	}

	** Shuts down the WebSockets service.
	override Void onStop() {
		if (webSockets == null) {
			log.info("WebSockets Service already stopped.")
			return
		}
		log.info("Stopping WebSockets...");
		webSockets.shutdown
		webSockets = null
	}
	
	// ---- Private Methods -----------------------------------------------------------------------

	private Void checkServiceStarted() {
		if (webSockets == null)
			throw Err("WebSockets Service has not been started")
	}

	private Void checkServiceNotStarted() {
		if (webSockets != null)
			throw Err("WebSockets Service has already started")
	}	
}
