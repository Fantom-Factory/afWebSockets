using build::BuildPod

class Build : BuildPod {

	new make() {
		podName = "afWebSockets"
		summary = "A WebSockets protocol implementation for Fantom."
		version = Version([0,0,1])

		meta	= [	
			"proj.name"		: "WebSockets",
			"afIoc.module"	: "afWebSockets::WebSocketsModule",
			"repo.private"	: "true",
		]

		index = [
			"afIoc.module"	: "afWebSockets::WebSocketsModule" 
		]

		depends = [
			"sys          1.0", 
			"concurrent   1.0",
			"inet         1.0",
			"web          1.0.67 - 1.0",
			"afConcurrent 1.0.8  - 1.0",
			
			"fwt      1.0",
			"afDuvet      1.0",
			
			// ---- for BedSheet only ----
			"afIoc        2.0.10 - 2.0",
			"afBedSheet   1.4.14 - 1.4"
		]

		srcDirs = [`test/`, `fan/`, `fan/public/`, `fan/public/bs/`, `fan/internal/`]
		resDirs = [`doc/`]
		jsDirs 	= [`js/`]
	}
}
