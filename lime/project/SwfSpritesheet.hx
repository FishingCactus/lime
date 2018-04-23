package lime.project;


class SwfSpritesheet {
	
	
	public var fileName:String;
	public var targetPath:String;
	public var packConfigPath:String;
	public var toolsPath:String;
	public var active:Bool;
	/** will be parsed and set from pack.json, default is "png" */
	public var outputFormat:String;


	public function new (fileName:String, targetPath:String, packConfigPath:String, toolsPath:String, active:Bool) {
		
		this.fileName = fileName;
		this.targetPath = targetPath;
		this.packConfigPath = packConfigPath;
		this.toolsPath = toolsPath;
		this.active = active;
		this.outputFormat = "png";

	}

	public function clone ():SwfSpritesheet {

		var swfSpritesheet = new SwfSpritesheet (fileName, targetPath, packConfigPath, toolsPath, active);
		return swfSpritesheet;

	}

	
}
