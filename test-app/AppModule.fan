using afIoc
using afBedSheet::Routes
using afBedSheet::Route

@SubModule { modules=[WebSocketsModule#] }
internal class AppModule {
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf) {
		conf.add(Route(`/`, 	AppHandler#indexPage))
		conf.add(Route(`/ws`,	AppHandler#goGoWebSocket))
	}

}
