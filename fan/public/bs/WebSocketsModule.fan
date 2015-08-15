using afIoc
using afBedSheet
using concurrent::ActorPool

@NoDoc
class WebSocketsModule {
	
	@Build
	static WebSockets buildWebSockets(ActorPools actorPools) {
		WebSockets(actorPools["afWebSockets"]) {
			it.socketReadTimeOut = 5min
		}
	}
	
	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(Configuration conf) {
		conf[WebSocket#] = conf.autobuild(WebSocketResponseProcessor#)
	}

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config["afWebSockets"] = ActorPool() { it.name = "afWebSockets" }
	}
	
	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeRegistryShutdown(Configuration config, WebSockets webSockets) {
		config["afWebSockets.shutdown"] = |->| { webSockets.shutdown }
	}
}
