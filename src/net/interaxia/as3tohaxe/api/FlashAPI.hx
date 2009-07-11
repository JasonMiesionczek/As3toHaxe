/**
 * ...
 * @author Jason Miesionczek
 */

package net.interaxia.as3tohaxe.api;
import neko.io.File;
import neko.Lib;

class FlashAPI {

	private static var _instance:FlashAPI;
	private var _types:List<String>;
	private var _shortTypes:List<String>;
	public var objTypes(default, null):List<ObjectType>;
	
	public static function getInstance():FlashAPI {
		if (_instance == null) {
			_instance = new FlashAPI();
		}
		
		return _instance;
	}
	
	public var types(getShortTypes, null):List<String>;
	
	private function getShortTypes():List < String > {
		return _shortTypes;
	}
	
	private function new() {
		_types = new List<String>();
		_shortTypes = new List<String>();
		objTypes = new List<ObjectType>();
		var inputXml:String = File.getContent("FlashAPI.xml");
		var x : Xml = Xml.parse(inputXml).firstElement();
		for (p in x.elements()) {
			var pname:String = p.get("name");
			for (e in p.elements()) {
				var ename:String = e.firstChild().nodeValue;
				_shortTypes.add(ename);
				_types.add(pname + "." + ename);
				var objType:ObjectType = new ObjectType();
				objType.typePackage = pname;
				objType.originalName = ename;
				objType.normalizedName = ename;
				objTypes.add(objType);
			}
		}
		
	}
	
	public function getFullTypeByName(name:String):String {
		for (t in _types) {
			if (StringTools.endsWith(t, name)) {
				return t;
			}
			
		}
		
		return "";
	}
	
}