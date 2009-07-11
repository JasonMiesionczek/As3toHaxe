/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe.api;

class CustomTypes {

	private static var _instance:CustomTypes;
	public static function getInstance():CustomTypes {
		if (_instance == null) {
			_instance = new CustomTypes();
		}
		
		return _instance;
	}
	
	public var types(default, default): List<String>;
	public var matches(default, null): Hash<String>;
	
	private function new() {
		types = new List<String>();
		matches = new Hash<String>();
		
		matches.set("int", "Int");
		matches.set("void", "Void");
		matches.set("Number", "Float");
		matches.set("Array", "Array<Dynamic>");
		matches.set("Boolean", "Bool");
	}
	
	public function setupMatches():Void {
		for (stype in getShortNames()) {
			matches.set(stype, stype.charAt(0).toUpperCase() + stype.substr(1));
		}
	}
	
	public function getTypeNormalized(originalName:String):String {
		for (t in types) {
			if (t == originalName) {
				var idx:Int = t.lastIndexOf(".");
				if (idx >= 0) {
					var type:String = t.substr(idx + 1);
					var orig:String = type;
					type = type.charAt(0).toUpperCase() + type.substr(1);
					return StringTools.replace(t, orig, type);
				}
			}
		}
		
		return originalName;
	}
	
	public function getFullTypeByName(name:String):String {
		for (t in types) {
			if (StringTools.endsWith(t, name)) {
				return getTypeNormalized(t);
			}
		}
		
		return name;
	}
	
	public function getShortNames():List < String > {
		var snames:List<String> = new List<String>();
		for (t in types) {
			var idx:Int = t.lastIndexOf(".");
			if (idx >= 0) {
				snames.add(t.substr(idx+1));
			} else {
				snames.add(t);
			}
		}
		
		return snames;
	}
	
}