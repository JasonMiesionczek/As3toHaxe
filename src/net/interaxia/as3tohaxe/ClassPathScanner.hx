/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe;
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.Lib;

class ClassPathScanner {

	public var rootFiles(default, null) : Array<String>;
	public var filesToParse(default, null) : List<String>;
	
	private var _inputPath:String;
	private var _dirsToSearch:List<String>;
	private var _filesToParse:List<String>;
			
	public function new(path:String) {
		this._inputPath = path;
		this._dirsToSearch = new List<String>();
		filesToParse = new List<String>();
	}
	
	public function scan():Void {
		rootFiles = FileSystem.readDirectory(_inputPath);
		
		for (file in rootFiles) {
			var fullPath:String = _inputPath + "/" + file;
			if (FileSystem.isDirectory(fullPath)) {
				_dirsToSearch.add(fullPath);
			} else {
				if (Path.extension(file) == "as")
					filesToParse.add(fullPath);
			}
		}
		
		for (dir in _dirsToSearch)
			scanDirectory(dir);
	}
	
	private function scanDirectory(dir:String):Void {
		var filesInDir:Array<String> = FileSystem.readDirectory(dir);
		for (file in filesInDir) {
			var fullPath:String = dir + "/" + file;
			if (FileSystem.isDirectory(fullPath)) {
				scanDirectory(fullPath);
			}
			
			var ext:String = Path.extension(file);
			if (ext.toLowerCase() == "as") {
				filesToParse.add(fullPath);
			}
		}
		
		
	}
	
	
	
}