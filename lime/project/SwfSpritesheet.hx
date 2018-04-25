package lime.project;


class SwfSpritesheet {
	
	
	public var fileName:String;
	public var targetDir:String;
	public var packConfigDir:String;
	public var toolsDir:String;
	public var enabled:Bool;
	public var preventRebuild:Bool;
	/** will be parsed and set from pack.json, default is "png" */
	public var outputFormat:String;


	public function new (fileName:String, targetDir:String, packConfigDir:String, toolsDir:String, enabled:Bool, preventRebuild:Bool) {
		
		this.fileName = fileName;
		this.targetDir = targetDir;
		this.packConfigDir = packConfigDir;
		this.toolsDir = toolsDir;
		this.enabled = enabled;
		this.preventRebuild = preventRebuild;
		this.outputFormat = "png";

	}

	public function clone ():SwfSpritesheet {

		var swfSpritesheet = new SwfSpritesheet (fileName, targetDir, packConfigDir, toolsDir, enabled, preventRebuild);
		return swfSpritesheet;

	}

	
}
