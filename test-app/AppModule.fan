using afIoc
using afBedSheet

@SubModule { modules=[WebSocketsModule#] }
internal class AppModule {
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf) {
		conf.add(Route(`/ws`, AppHandler#goGoWebSocket))
	}

}
