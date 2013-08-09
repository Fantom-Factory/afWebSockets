using build::BuildPod

class Build : BuildPod {

	new make() {
		podName = "afWebSockets"
		summary = "An implementation of WebSockets for BedSheet"
		version = Version([0,0,1])

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"vcs.uri"		: "https://bitbucket.org/SlimerDude/afwebsockets",
					"proj.name"		: "AF-WebSockets",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true",
				]

		depends = ["sys 1.0",  "web 1.0",
					"afIoc 1.3+", "afBedSheet 1.0+"]
		srcDirs = [`test-app/`, `test/`, `test/internal/`, `test/internal/utils/`, `fan/`, `fan/public/`, `fan/internal/`, `fan/internal/utils/`]
		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
