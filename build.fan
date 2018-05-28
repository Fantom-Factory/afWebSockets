using build::BuildPod
using build::Target
using compiler

class Build : BuildPod {

	new make() {
		podName = "afWebSockets"
		summary = "A pure Fantom implementation of the W3C WebSocket API for use by clients and servers"
		version = Version("0.1.1")

		meta	= [	
			"pod.dis"		: "WebSockets",
			"afIoc.module"	: "afWebSockets::WebSocketsModule",
			"repo.tags"		: "web",
			"repo.public"	: "false"
		]

		depends = [
			"sys          1.0.70 - 1.0", 
			"concurrent   1.0.70 - 1.0",
			"inet         1.0.70 - 1.0",
			"web          1.0.70 - 1.0",
			"afConcurrent 1.0.20 - 1.0",
			
			// ---- for BedSheet only ----
			"afIoc        3.0.6  - 3.0",
			"afBedSheet   1.5.10 - 1.5",

			// ---- for testing ----
			"fwt          1.0",
			"afDuvet      1.1"
		]

		srcDirs = [`fan/`, `fan/internal/`, `fan/public/`, `fan/public/bs/`, `test/`]
		resDirs = [`doc/`]
		jsDirs 	= [`js/`]
	}
	
	File? podFile
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		super.compile
		
		// remove afIoc and afBedSheet from the depends list
		log.info("Removing Ioc and BedSheet from pod depends")
		toRemove	:= "afIoc afBedSheet afDuvet fwt".split
		tempDir		:= ZipUtils.unzip(podFile, ZipUtils.createTempDir("ws-")).deleteOnExit
		propsFile	:= tempDir + `meta.props`
		metaProps	:= propsFile.readProps
		newDepends	:= metaProps["pod.depends"].split(';').map { Depend(it) }.exclude |Depend d -> Bool| { toRemove.contains(d.name) }.join(";")
		metaProps["pod.depends"] = newDepends
		propsFile.writeProps(metaProps)
		ZipUtils.zip(tempDir, podFile)
	}

	override Void onCompileFan(CompilerInput ci) {
		podFile = ci.outDir + `${ci.podName}.pod`
	}	
}


** A collection of Zip / File utilities.
class ZipUtils {
	
	** Compresses the given file and returns the compressed .zip file.
	** 'toCompress' may be a directory.
	** 
	** If 'destFile' is null, it defaults to '${toCompress.basename}.zip' 
	** 
	** The options map is used to customise zipping:
	**  - bufferSize: an 'Int' that defines the stream buffer size. Defaults to 16Kb.
	**  - incFolderName: set to 'true' to include the containing folder name in the zip path
	static File zip(File toCompress, File? destFile := null, [Str:Obj]? options := null) {
		if (destFile != null && destFile.isDir)
			throw ArgErr("Destination can not be a directory - ${destFile}")

		bufferSize	:= options?.get("bufferSize") ?: 16*1024
		dstFile		:= destFile ?: toCompress.parent + `${toCompress.basename}.zip` 
		zip			:= Zip.write(dstFile.out(false, bufferSize))		
		parentUri 	:= toCompress.isDir && options?.get("incFolderName") == true ? toCompress.parent.uri : toCompress.uri
		
		try {
			toCompress.walk |src| {
				if (src.isDir) return
				path := src.uri.relTo(parentUri)
				out  := zip.writeNext(path)
				try {
					src.in(bufferSize).pipe(out)
				} finally
					out.close
			}
		} finally
			zip.close

		return dstFile
	}

	** Decompresses the given file and returns the directory it was unzipped to.
	** 
	** The options map is used to customise zipping:
	**  - bufferSize: an 'Int' that defines the stream buffer size. Defaults to 16Kb.
	static File unzip(File toDecompress, File? destDir := null, [Str:Obj]? options := null) {
		if (toDecompress.isDir)
			throw ArgErr("Destination can not be a directory - ${toDecompress}")
		if (destDir != null && !destDir.isDir)
			throw ArgErr("Destination must be a directory - ${destDir}")
		
		bufferSize	:= options?.get("bufferSize") ?: 16*1024
		dstDir		:= destDir ?: toDecompress.parent
		zip			:= Zip.read(toDecompress.in(bufferSize))
		try {
			File? entry
			while ((entry = zip.readNext) != null) {
				entry.copyTo(dstDir + entry.uri.relTo(`/`), ["overwrite":true])
			}
		} finally {
			zip.close
		}
		
		return dstDir
	}
	
	** Create a temporary directory which is guaranteed to be a new, empty
	** directory with a unique name.  The dir name will be generated using
	** the specified prefix and suffix.  
	** 
	** If dir is non-null then it is used as the file's parent directory,
	** otherwise the system's default temporary directory is used.
	** 
	** Examples:
	**   File.createTemp("x", "-etc") => `/tmp/x67392-etc/`
	**   File.createTemp.deleteOnExit => `/tmp/fan-5284/`
	**
	** See the Fantom forum topic [File.createTempDir()]`http://fantom.org/forum/topic/2424`.
	static File createTempDir(Str prefix := "fan-", Str suffix := "", File? dir := null) {
		tempFile := File.createTemp(prefix, suffix, dir ?: Env.cur.tempDir)
		dirName  := tempFile.name
		tempFile.delete
		tempDir  := tempFile.parent.createDir(dirName)
		return tempDir
	}
}