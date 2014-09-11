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

			"afIoc 2.0+",
			"afBedSheet 1.0+"
		]

		srcDirs = [`test-app/`, `test/`, `test/internal/`, `test/internal/utils/`, `fan/`, `fan/public/`, `fan/internal/`, `fan/internal/utils/`]
		resDirs = [`doc/`]
	}
}
