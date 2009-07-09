/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe.inspector;
import neko.io.FileInput;
import neko.io.File;
import haxe.io.Eof;
import neko.Lib;
import net.interaxia.as3tohaxe.api.CustomTypes;
import net.interaxia.as3tohaxe.HaxeFile;

class FileInspector {

	private var _inputFile:String;
	private var _fileObject:FileInput;
	private var _lines:List<String>;
	private var _package:String;
	private var _types:List<String>;
	private var _hf:HaxeFile;
	
	public function new(file:String) {
		_inputFile = file;
		_lines = new List<String>();
		_types = new List<String>();
	}
	
	public function inspect():HaxeFile {
		_hf = new HaxeFile();
		_hf.fullPath = _inputFile;
		_fileObject = File.read(_inputFile, false);
		try {
			while (true) {
				if (_fileObject.eof()) break;
				var l:String = _fileObject.readLine();
				_lines.add(l);
				_hf.lines.push(l);
			}
		}
		catch (ex:Eof) {}
		_fileObject.close();
		
		detectPackage();
		detectClasses();
		
		return _hf;
		
	}
	
	private function detectPackage():Void {
		var packagePattern = ~/package\s+([a-z.]+)/;
		for (line in _lines) {
			if (packagePattern.match(line)) {
				_package = packagePattern.matched(1);
				_hf.filePackage = _package;
				return;
			}
		}
		
		_package = "";
	}
	
	private function detectClasses():Void {
		var classPattern = ~/public\s+class\s+(\w+)/;
		for (line in _lines) {
			if (classPattern.match(line)) {
				var fullType:String = _package + "." + classPattern.matched(1);
				CustomTypes.getInstance().types.add(fullType);
				
				//Lib.println(fullType);
			}
		}
	}
	
}