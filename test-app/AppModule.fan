using afIoc
using afBedSheet

@SubModule { modules=[WebSocketsModule#] }
class AppModule {
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(Route(`/ws/***`,	WebSocketHandler#service))

		conf.add(Route(`/web/***`, 		FileHandler#service))
	}
	
	@Contribute { serviceType=FileHandler# }
	static Void contributeFileMapping(MappedConfig conf) {
		conf[`/web/`] = `etc/`.toFile
	}
	
	@Contribute { serviceType=WebSocketHandler# }
	static Void contributeWebSocketMapping(MappedConfig conf) {
		conf[`/ws/`] = AppFactory#create
	}

}
