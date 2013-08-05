
internal class AppRun {
	
	static Void main(Str[] args) {
//		afBedSheet::Main().main("-proxy ${AppModule#.qname} 8069".split)
		afBedSheet::Main().main("${AppModule#.qname} 8069".split)
	}
}
