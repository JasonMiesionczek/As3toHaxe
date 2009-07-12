/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe.translator;

import neko.io.FileInput;
import neko.io.File;
import haxe.io.Eof;
import neko.Lib;

import net.interaxia.as3tohaxe.api.FlashAPI;
import net.interaxia.as3tohaxe.api.ObjectType;
import net.interaxia.as3tohaxe.HaxeFile;
import net.interaxia.as3tohaxe.api.AllTypes;

class Translator {
		
	private var _fileObject:FileInput;
	private var _lines:Array<String>;
	private var _output:List<String>;
	private var _hf:HaxeFile;
	private var _foundPackage:Bool;
	private var _currentLine:Int;
	
	private static var _typeRegs:List<EReg>;
	private static var _typeRegsFlash:List<EReg>;
	private static var _commentLines:List<Int>;

	public function new(inputFile:HaxeFile) {
		_lines = new Array<String>();
		_output = new List<String>();
		_hf = inputFile;
								
		for (l in inputFile.lines) {
			_lines.push(l);
		}
		
		
	}
	
	public static function compileTypes(f:HaxeFile):Void {
		_commentLines = new List<Int>();
		var _withinBlockComment:Bool = false;
		for (line in 0...f.lines.length) {
			var tempLine:String = f.lines[line];
			
			if (isSingleLineComment(tempLine)) {
				//newLines.push(tempLine);
				_commentLines.add(line);
				Lib.println(tempLine);
				continue;
			}
			
			if (isStartOfComment(tempLine)) {
				_withinBlockComment = true;
				//newLines.push(tempLine);
				_commentLines.add(line);
				Lib.println(tempLine);
				continue;
			}
			
			if (_withinBlockComment && isEndOfComment(tempLine)) {
				_withinBlockComment = false;
				//newLines.push(tempLine);
				_commentLines.add(line);
				Lib.println(tempLine);
				continue;
			}
			
			if (_withinBlockComment) {
				//newLines.push(tempLine);
				_commentLines.add(line);
				Lib.println(tempLine);
				continue;
			}
		}
		
		for (line in 0...f.lines.length) {
			checkForTypes(line, f); // this will build the new list of imports
		}
	}
	
	public function translate():Void {
		//Lib.println("Translating "+_hf.fullPath+"...");
		_foundPackage = false;
		var packagePos:Int = -1;
		var _withinBlockComment:Bool = false;
		var newLines:Array<String> = new Array<String>();
		
		for (line in 0..._lines.length) {
			_currentLine = line;
			var tempLine:String = _lines[line];
			
			if (isSingleLineComment(tempLine)) {
				newLines.push(tempLine);
				Lib.println(tempLine);
				continue;
			}
			
			if (isStartOfComment(tempLine)) {
				_withinBlockComment = true;
				newLines.push(tempLine);
				Lib.println(tempLine);
				continue;
			}
			
			if (_withinBlockComment && isEndOfComment(tempLine)) {
				_withinBlockComment = false;
				newLines.push(tempLine);
				Lib.println(tempLine);
				continue;
			}
			
			if (_withinBlockComment) {
				newLines.push(tempLine);
				Lib.println(tempLine);
				continue;
			}
			
			if (!_foundPackage) {
				tempLine = convertPackage(tempLine);
			}
			
			if (_foundPackage && packagePos < 0) {
				packagePos = line;
			}
			tempLine = removeImports(tempLine);
			tempLine = convertClassName(tempLine);
			tempLine = removePublicFromClass(tempLine);
			tempLine = convertInterfaceName(tempLine);
			tempLine = convertConstToVar(tempLine);
			tempLine = convertTypes(tempLine);
			tempLine = convertConstructorName(tempLine);
			tempLine = convertForLoop(tempLine);
			tempLine = addSemiColon(tempLine);
			//_lines[line] = tempLine;
			newLines.push(tempLine);
		}
		
		var tempLines:Array<String> = newLines;
		tempLines.reverse();
		for (line in 0...tempLines.length) {
			var temp:String = StringTools.ltrim(tempLines[line]);
			if (StringTools.startsWith(temp, "}")) {
				tempLines = tempLines.slice(line+1);
				break;
			}
			
		}
		tempLines.reverse();
		newLines = tempLines;
		
		// insert the new import statements just below the package definition.
		for (imp in _hf.imports) {
			var impStr:String = "    import " + imp + ";";
			newLines.insert(packagePos + 1, impStr);
		}
		
		_hf.lines = newLines;
		
		
		
	}
	
	private static function isSingleLineComment(input:String):Bool {
		var temp:String = StringTools.ltrim(input);
		var temp2:String = StringTools.rtrim(input);
		if (StringTools.startsWith(temp, "//")) {
			return true;
		}
		
		if (StringTools.startsWith(temp, "/*") && StringTools.endsWith(temp2, "*/")) {
			return true;
		}
		
		return false;
	}
	
	private static function isStartOfComment(input:String):Bool {
		var temp:String = StringTools.ltrim(input);
		if (StringTools.startsWith(temp, "/*")) {
			return true;
		}
		
		return false;
	}
	
	private static function isEndOfComment(input:String):Bool {
		var temp:String = StringTools.rtrim(input);
		if (StringTools.endsWith(temp, "*/")) {
			return true;
		}
		
		return false;
	}
	
	private function addSemiColon(input:String):String {
		//var idx:Int = input.indexOf("//");
		if (input.length == 0 || StringTools.trim(input) == "") return input;
		var temp:String = input;
		//var orig:String = input;
		
		//if (idx >= 0) {
			//temp = temp.substr(0, idx - 1);
			temp = StringTools.rtrim(temp);
			if (!StringTools.endsWith(temp, "}") &&
				!StringTools.endsWith(temp, "{") &&
				!StringTools.endsWith(temp, ";") &&
				!StringTools.endsWith(temp, "*/")) {
				temp += ";";
			}
		//}
		
		return temp;
	}
	
	private function removePublicFromClass(input:String):String {
		var classPattern = ~/public\s+class/;
		if (classPattern.match(input)) {
			return StringTools.replace(input, "public ", "");
		}
		
		return input;
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
		var constPattern = ~/function\s+(\w+)\(\S*\)/;
		if (constPattern.match(input)) {
			var t:String = constPattern.matched(1);
			for (stype in AllTypes.getInstance().getAllOrigNames(false)) {
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
	
	private function convertInterfaceName(input:String):String {
		var classPattern = ~/public\s+interface\s+(\w+)/;
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
	
	private function convertConstToVar(input:String):String {
		var temp:String = input;
		var constPattern = ~/\s+const\s+\S+/;
		
		if (constPattern.match(input)) {
			temp = StringTools.replace(temp, "const", "var");
		}
		
		return temp;
	}
	
	private function convertTypes(input:String):String {
		var temp:String = input;
		
		
		var patterns:Array<EReg> = [ ~/var\s+\w+\s*:\s*(\w+)[;\s]*/, 	// var definition pattern
									 ~/new\s+(\w+)\(\S*\)/,				// object init pattern
									 ~/:(\w+)/,							// function def pattern
									 ~/function\s+\S+\(\S*\):(\S*)/,	// function return pattern
									 ~/\W*(\w+)./];						// static function call pattern
									
		for (pattern in patterns) {
			if (pattern.match(input)) {
				var typeToConvert:String = pattern.matched(1);
				var objType:ObjectType = AllTypes.getInstance().getTypeByOrigName(typeToConvert, true);
				if (objType != null) {
						var newType:String = objType.normalizedName;
						temp = StringTools.replace(input, typeToConvert, newType);
				}
				
				
			}
		}
		
		return temp;
	}
		
	
	private static function checkForTypes(lineNum:Int, hf:HaxeFile):Void {
		for (lineNums in _commentLines) {
			if (lineNums == lineNum) {
				return;
			}
		}
		var input:String = hf.lines[lineNum];
		for (stype in AllTypes.getInstance().getAllOrigNames(false)) {
			//Lib.println("checking for: " + stype);
			if (input.indexOf(stype) >= 0) {
				addImport(AllTypes.getInstance().getTypeByOrigName(stype, false).getFullNormalizedName(), hf);
			}
		}
	}
	
	private static function addImport(imp:String, hf:HaxeFile):Void {
		//Lib.println("adding import: " + imp);
		for (i in hf.imports) {
			if (i == imp) {
				return;
			}
		}
		
		hf.imports.add(imp);
	
	}
	
}