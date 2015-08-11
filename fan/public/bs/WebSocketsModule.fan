using afIoc
using afBedSheet
using concurrent

internal class WebSocketsModule {
	
	@Build
	WebSockets buildWebSockets(ActorPools actorPools) {
		WebSockets(actorPools["afBedSheet.webSockets"])
	}
	
	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(Configuration conf) {
		conf[WebSocket#] = conf.autobuild(WebSocketResponseProcessor#)
	}

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config["afBedSheet.webSockets"] = ActorPool() { it.name = "afBedSheet.webSockets" }
	}
}
