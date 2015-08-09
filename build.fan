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
			"sys 1.0", 
			"web 1.0",

			"afIoc      2.0.10 - 2.1",
			"afBeanUtils     1+",
			
			"afBedSheet 1.4.14 - 1.4",
			
			// ---- Testing ----
			"inet 1.0"
		]

		srcDirs = [`test-app/`, `test/`, `fan/`, `fan/public/`, `fan/public/bs/`, `fan/internal/`]
		resDirs = [`doc/`]
	}
}
