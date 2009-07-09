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
	private var _lines:Array<String>;
	private var _output:List<String>;
	private var _hf:HaxeFile;
	private var _foundPackage:Bool;
	
	private static var _typeRegs:List<EReg>;
	private static var _typeRegsFlash:List<EReg>;
	

	public function new(inputFile:HaxeFile) {
		_lines = new Array<String>();
		_output = new List<String>();
		_hf = inputFile;
								
		for (l in inputFile.lines) {
			_lines.push(l);
		}
		
		
	}
	
	public static function compileTypes(f:HaxeFile):Void {
		for (line in f.lines) {
			checkForTypes(line, f); // this will build the new list of imports
		}
	}
	
	public function translate():Void {
		//Lib.println("Translating "+_hf.fullPath+"...");
		_foundPackage = false;
		var packagePos:Int = -1;
		var newLines:Array<String> = new Array<String>();
		
		for (line in 0..._lines.length) {
			var tempLine:String = _lines[line];
			if (!_foundPackage) {
				tempLine = convertPackage(tempLine);
			}
			
			if (_foundPackage && packagePos < 0) {
				packagePos = line;
			}
			tempLine = removeImports(tempLine);
			tempLine = convertClassName(tempLine);
			tempLine = convertTypes(tempLine);
			tempLine = convertConstructorName(tempLine);
			tempLine = convertForLoop(tempLine);
						
			//_lines[line] = tempLine;
			newLines.push(tempLine);
		}
		
		// insert the new import statements just below the package definition.
		for (imp in _hf.imports) {
			var impStr:String = "    import " + imp + ";";
			newLines.insert(packagePos + 1, impStr);
		}
		
		_hf.lines = newLines;
		
		
		
	}
	
	private function convertForLoop(input:String):String {
		var temp:String = input;
		var forPattern = ~/for\s*\(var\s+(\w+):\w+\s*=\s*(\d+);\1[<>=]+(\w+)\s*;\s*\1\S+\)\s*/;
		var forReplacePattern = ~/var\s+(\w+):\w+\s*=\s*(\d+);\1[<>=]+(\w+)\s*;\s*\1[^\)]*/;
		
		if (forPattern.match(input)) {
			var variable:String = forPattern.matched(1);
			var min:String = forPattern.matched(2);
			var max:String = forPattern.matched(3);
			
			var newFor:String = variable + " in " + min + "..." + max;
			temp = forReplacePattern.replace(temp, newFor);
		}
		
		return temp;
		
	}
	
	private function convertConstructorName(input:String):String {
		var constPattern = ~/function\s+(\w+)\(\.*\)[^:]/;
		if (constPattern.match(input)) {
			var t:String = constPattern.matched(1);
			for (stype in CustomTypes.getInstance().getShortNames()) {
				if (t == stype) { // if this function name matches a custom type name
					return StringTools.replace(input, t, "new");
				}
			}
		}
		
		return input;
	}
	
	private function removeImports(input:String):String {
		var importPattern = ~/import\s+\S+/;
		if (importPattern.match(input)) {
			return "";
		}
		
		return input;
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
				//Lib.println(typeToConvert + " => " + newType);
				temp = StringTools.replace(input, typeToConvert, newType);
			}
		}
		
		if (typeNewPattern.match(input)) {
			var typeToConvert:String = typeNewPattern.matched(1);
			var newType:String = CustomTypes.getInstance().matches.get(typeToConvert);
			if (newType != null) {
				//Lib.println(typeToConvert + " => " + newType);
				temp = StringTools.replace(input, typeToConvert, newType);//typeNewPattern.replace(temp, newType);
			}
		}
		
		return temp;
	}
	
	public static function initTypeRegs():Void {
		_typeRegs = new List<EReg>();
		_typeRegsFlash = new List<EReg>();
		for (stype in CustomTypes.getInstance().getShortNames()) {
			var reg:EReg = new EReg(":\\s*(" + stype + ")", "");
			_typeRegs.add(reg);
			//var reg:EReg = new EReg("public\\s+class\\s+(" + stype + ")", "");
			//_typeRegs.add(reg);
		}
		
		for (stype in FlashAPI.getInstance().types) {
			var reg:EReg = new EReg(":\\s*(" + stype + ")", "");
			_typeRegsFlash.add(reg);
		}
	}
	
	private static function checkForMatch(input:String):String {
		for (reg in _typeRegs) {
			if (reg.match(input)) {
				return reg.matched(1);
			}
		}
		
		return null;
	}
	
	private static function checkForMatchFlash(input:String):String {
		for (reg in _typeRegsFlash) {
			if (reg.match(input)) {
				return reg.matched(1);
			}
		}
		
		return null;
	}
	
	private static function checkForTypes(input:String, hf:HaxeFile):Void {
		var stype:String = checkForMatch(input);
		
		if (stype != null) {
			//Lib.println(stype);
			var out:String = addImport(CustomTypes.getInstance().getFullTypeByName(stype), hf);
			//Lib.println(out);
			//CustomTypes.getInstance().matches.set(stype, out.substr(out.lastIndexOf(".")+1));
		}
		
		stype = checkForMatchFlash(input);
		
		if (stype != null) {
			addImport(FlashAPI.getInstance().getFullTypeByName(stype), hf);
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
			//Lib.println("    import " + imp);
		}
		
		return out;
	}
	
}