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
	/** will be parsed and set from pack.json, default is "png" */
	public var outputFormat:String;
	public var excludeList:List<ExcludeItem>;




	public function new (fileName:String, targetDir:String, packConfigDir:String, toolsDir:String, enabled:Bool, excludeList:List<ExcludeItem>) {
		
		this.fileName = fileName;
		this.targetDir = targetDir;
		this.packConfigDir = packConfigDir;
		this.toolsDir = toolsDir;
		this.enabled = enabled;
		this.outputFormat = "png";
		this.excludeList = excludeList;

	}

	public function clone ():SwfSpritesheet {

		var swfSpritesheet = new SwfSpritesheet (fileName, targetDir, packConfigDir, toolsDir, enabled, excludeList);
		return swfSpritesheet;

	}

	
}
