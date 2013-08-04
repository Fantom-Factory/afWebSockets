using afIoc
using afBedSheet

class WebSocketsModule {
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(Route(`/gogo/*`,	WebSocketHandler#service))
		
		conf.add(Route(`/web/***`, 		FileHandler#service))
	}
	
	@Contribute { serviceType=FileHandler# }
	static Void contributeFileMapping(MappedConfig conf) {
		conf[`/web/`] = `etc/`.toFile
	}

}
