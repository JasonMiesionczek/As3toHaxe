/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe.translator;

import neko.io.FileInput;
import neko.io.File;
import haxe.io.Eof;
import neko.Lib;
import net.interaxia.as3tohaxe.api.CustomTypes;
import net.interaxia.as3tohaxe.api.FlashAPI;
import net.interaxia.as3tohaxe.HaxeFile;

class Translator {
		
	private var _fileObject:FileInput;
	private var _lines:List<String>;
	private var _output:List<String>;
	private var _hf:HaxeFile;
	private var _foundPackage:Bool;
	

	public function new(inputFile:HaxeFile) {
		_lines = new List<String>();
		_output = new List<String>();
		_hf = inputFile;
		
		
		
		
		for (l in inputFile.lines) {
			_lines.add(l);
		}
		
		
	}
	
	public static function compileTypes(f:HaxeFile):Void {
		for (line in f.lines) {
			checkForTypes(line, f); // this will build the new list of imports
		}
	}
	
	public function translate():Void {
		Lib.println(_hf.fullPath);
		_foundPackage = false;
		
		for (line in _lines) {
			var tempLine:String = line;
			if (!_foundPackage) {
				tempLine = convertPackage(tempLine);
			}
			tempLine = convertClassName(tempLine);
			tempLine = convertTypes(tempLine);
			
			Lib.println(tempLine);
		}
		
	}
	
	private function removeImports(input:String):String {
		
	}
	
	private function convertClassName(input:String):String {
		var classPattern = ~/public\s+class\s+(\w+)/;
		var temp:String = input;
		if (classPattern.match(input)) {
			var className:String = classPattern.matched(1);
			var newName:String = className.charAt(0).toUpperCase() + className.substr(1);
			temp = StringTools.replace(temp, className, newName);
		}
		
		return temp;
	}
	
	private function convertPackage(input:String):String {
		var temp:String = input;
		
		if (input.indexOf(_hf.filePackage) >= 0) {
			var idx:Int = input.indexOf(" {");
			if (idx >= 0) {
				temp = StringTools.replace(temp, " {", ";");
				_foundPackage = true;
			}
		}
		
		return temp;
	}
	
	private function convertTypes(input:String):String {
		var temp:String = input;
		var typeDefPattern = ~/var\s+\w+\s*:\s*(\w+)[;\s]*/;
		var typeNewPattern = ~/new\s+(\w+)\(\S*\)/;
		
		if (typeDefPattern.match(input)) {
			var typeToConvert:String = typeDefPattern.matched(1);
			var newType:String = CustomTypes.getInstance().matches.get(typeToConvert);
			if (newType != null) {
				Lib.println(typeToConvert + " => " + newType);
				temp = StringTools.replace(input, typeToConvert, newType);
			}
		}
		
		if (typeNewPattern.match(input)) {
			var typeToConvert:String = typeNewPattern.matched(1);
			var newType:String = CustomTypes.getInstance().matches.get(typeToConvert);
			if (newType != null) {
				Lib.println(typeToConvert + " => " + newType);
				temp = StringTools.replace(input, typeToConvert, newType);//typeNewPattern.replace(temp, newType);
			}
		}
		
		return temp;
	}
	
	private static function checkForTypes(input:String, hf:HaxeFile):Void {
		for (stype in CustomTypes.getInstance().getShortNames()) {
			if (input.indexOf(stype) >= 0) {
				var out:String = addImport(CustomTypes.getInstance().getFullTypeByName(stype), hf);
				CustomTypes.getInstance().matches.set(stype, out.substr(out.lastIndexOf(".")+1));
			}
		}
		
		for (stype in FlashAPI.getInstance().types) {
			if (input.indexOf(stype) >= 0) {
				addImport(FlashAPI.getInstance().getFullTypeByName(stype), hf);
			}
		}
	}
	
	private static function addImport(imp:String, hf:HaxeFile):String {
		var found:Bool = false;
		var out:String = "";
		for (i in hf.imports) {
			if (i == imp) {
				found = true;
				out = i;
				break;
			}
		}
		
		if (!found) {
			hf.imports.add(imp);
			out = imp;
			Lib.println("    import " + hf.imports.last());
		}
		
		return out;
	}
	
}