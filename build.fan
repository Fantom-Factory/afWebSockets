using build::BuildPod

class Build : BuildPod {

	new make() {
		podName = "afWebSockets"
		summary = "A WebSockets protocol implementation for Fantom."
		version = Version([0,0,1])

		meta	= [	
			"proj.name"		: "Web Sockets",
			"repo.private"	: "true",
		]

		depends = [
			"sys        1.0", 
			"concurrent 1.0",
			"inet       1.0",
			"web        1.0",

			"afConcurrent 1.0.8 - 1.0",
						
			// ---- Testing ----
			"afIoc      2.0.10 - 2.1",
			"afBedSheet 1.4.14 - 1.4",
			"fwt 1.0",
			"gfx 1.0",
			"afDuvet 1.0.12 - 1.0"
		]

		srcDirs = [`test-app/`, `test/`, `fan/`, `fan/public/`, `fan/public/bs/`, `fan/internal/`]
		resDirs = [`doc/`]
		jsDirs 	= [`js/`]
	}
}
