package lime.project;



class ExcludeItem {

	public var path:String;

	public function new (path:String) {
		this.path = path;
	}
}


class SwfSpritesheet {

	public var fileName:String;
	public var targetDir:String;
	public var packConfigDir:String;
	public var toolsDir:String;
	public var enabled:Bool;
	public var outputFormat:String; //will be parsed and set from pack.json
	public var excludeList:List<ExcludeItem>;

	public function new () {
		
		fileName = "swfSpritesheet";
		enabled = false;
		outputFormat = "png";
		excludeList = new List<ExcludeItem>();

	}

	public function clone ():SwfSpritesheet {

		var swfSpritesheet = new SwfSpritesheet ();
		swfSpritesheet.fileName = fileName;
		swfSpritesheet.targetDir = targetDir;
		swfSpritesheet.packConfigDir = packConfigDir;
		swfSpritesheet.toolsDir = toolsDir;
		swfSpritesheet.enabled = enabled;
		swfSpritesheet.outputFormat = outputFormat;
		swfSpritesheet.excludeList = excludeList;

		return swfSpritesheet;
	}

	
}
