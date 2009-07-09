/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe;

class HaxeFile {

	public var filePackage(default, default):String;
	public var lines(default, default):Array<String>;
	public var fullPath(default, default):String;
	public var imports(default, null):List<String>;
	
	public function new() {
		lines = new Array<String>();
		imports = new List<String>();
	}
	
}