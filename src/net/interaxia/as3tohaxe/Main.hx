package net.interaxia.as3tohaxe;

import neko.io.Path;
import neko.Lib;
import neko.Sys;
import net.interaxia.as3tohaxe.api.FlashAPI;
import net.interaxia.as3tohaxe.inspector.FileInspector;
import net.interaxia.as3tohaxe.translator.Translator;

/**
 * ...
 * @author Jason Miesionczek
 */

class Main {
	
	static function main() {
		var inputPath:String = "";
		if (Sys.args().length == 0) {
			inputPath = Sys.getCwd();
			Lib.println(inputPath);
		}
		
		var cpscanner:ClassPathScanner = new ClassPathScanner("d:\\development\\ffilmation");
		cpscanner.scan();
		
		var haxeFiles:List<HaxeFile> = new List<HaxeFile>();
		
		for (f in cpscanner.filesToParse) {
			
			var fi:FileInspector = new FileInspector(f);
			var hf:HaxeFile = fi.inspect();
			
			haxeFiles.add(hf);
			
			
		}
		
		for (f in haxeFiles) {
			Translator.compileTypes(f);
		}
		
		for (f in haxeFiles) {
			var t:Translator = new Translator(f);
			t.translate();
		}
	}
	
}