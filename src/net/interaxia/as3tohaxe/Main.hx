package net.interaxia.as3tohaxe;

import neko.FileSystem;
import neko.io.File;
import neko.io.FileOutput;
import neko.io.Path;
import neko.Lib;
import neko.Sys;
import net.interaxia.as3tohaxe.api.CustomTypes;
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
		var outputPath:String = "";
		
		if (Sys.args().length == 0) {
			inputPath = Sys.getCwd();
			
		} else if (Sys.args().length == 2) {
			inputPath = Sys.args()[0];
			outputPath = Sys.args()[1];
		}
		
		try {
			if (!FileSystem.exists(outputPath)) {
				FileSystem.createDirectory(outputPath);
			}
		} catch (msg:String) {
			Lib.println("There was an error creating the specified output directory. Ensure the parent drive/directory exists and you have write permissions to it.");
			return;
		}
		
		
		
		Lib.println("Input path: " + inputPath);
		Lib.println("Output path: " + outputPath);
		
		Lib.println("Scanning input folder...");
		var cpscanner:ClassPathScanner = new ClassPathScanner(inputPath);
		cpscanner.scan();
		
		var haxeFiles:List<HaxeFile> = new List<HaxeFile>();
		
		Lib.println("Inspecting files...");
		for (f in cpscanner.filesToParse) {
			
			var fi:FileInspector = new FileInspector(f);
			var hf:HaxeFile = fi.inspect();
			
			haxeFiles.add(hf);
		}
		
		Lib.println("Collecting type information...");
		CustomTypes.getInstance().setupMatches();
		
		Translator.initTypeRegs();
		
		for (f in haxeFiles) {
			Translator.compileTypes(f);
		}
				
		Lib.println("Translating files...");
		for (f in haxeFiles) {
			var t:Translator = new Translator(f);
			t.translate();
		}
						
		Lib.println("Generating output files...");
		generateOutputFiles(haxeFiles, outputPath);
		Lib.println(haxeFiles.length + " files converted.");
	}
	
	static function generateOutputFiles(files:List < HaxeFile > , output:String) {
		
		for (file in files) {
			var fileName:String = Path.withoutDirectory(Path.withoutExtension(file.fullPath));
			
			if (CustomTypes.getInstance().matches.exists(fileName)) {
				var newfileName:String = CustomTypes.getInstance().matches.get(fileName);
				file.fullPath = StringTools.replace(file.fullPath, fileName, newfileName);
			}
			var fileOutputPath:String = output;
			if (file.filePackage.indexOf(".") >= 0) {
				var packageParts:Array < String > = file.filePackage.split(".");
				fileOutputPath = fileOutputPath + "/" + packageParts.join("/");
				createOutputDirs(packageParts, output);
			}
									
			fileOutputPath += "/" + StringTools.replace(Path.withoutDirectory(file.fullPath), ".as", ".hx");
			
			var fout:FileOutput = File.write(fileOutputPath, false);
			for (line in file.lines) {
				fout.writeString(line+"\n");
			}
			fout.close();
		}
	}
	
	static function createOutputDirs(parts:Array < String > , outputPath:String):Void {
		var currentPath:String = outputPath;
		for (p in parts) {
			currentPath += "/" + p;
			if (!FileSystem.exists(currentPath)) {
				FileSystem.createDirectory(currentPath);
			}
		}
	}
	
}