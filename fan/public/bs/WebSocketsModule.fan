using afIoc
using afBedSheet
using concurrent::ActorPool
using afConcurrent::ActorPools

@NoDoc
const class WebSocketsModule {
	
	Str:Obj nonInvasiveIocModule() {
		[
			"services"	: [
				[
					"id"		: WebSockets#.qname,
					"type"		: WebSockets#,
					"scopes"	: ["root"],
					"builder"	: |Obj scope->Obj| {
						actorPools := (ActorPools) scope->serviceById(ActorPools#.qname)
						return WebSockets(actorPools["afWebSockets"]) {
							it.socketReadTimeOut = 5min
						}						
					}
				]
			],

			"contributions" : [
				[
					"serviceId"	: ActorPools#.qname,
					"key"		: "afWebSockets",
					"value"		: ActorPool() { it.name = "afWebSockets" }
				],
				[
					"serviceId"	: "afBedSheet::ResponseProcessors",
					"key"		: WebSocket#,
					"build"		: WebSocketResponseProcessor#
				],
				[
					"serviceId"	: "registryShutdown",
					"key"		: "afWebSockets.shutdown",
					"valueFunc"	: |WebSockets webSockets->Func| {
						|->| { webSockets.shutdown }
					}
				]
			]
		]
	}
}
