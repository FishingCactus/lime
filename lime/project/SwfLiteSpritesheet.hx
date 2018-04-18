package lime.project;

class SwfLiteSpritesheet {
	
	
	public var sourcePath:String;
	public var targetPath:String;
	public var fileName:String;

	
	public function new (sourcePath:String, targetPath:String, fileName:String) {
		
		this.sourcePath = sourcePath;
		this.targetPath = targetPath;
		this.fileName = fileName;
	}

	public function clone ():SwfLiteSpritesheet {

		var swfLiteSpritesheet = new SwfLiteSpritesheet (sourcePath, targetPath, fileName);
		return swfLiteSpritesheet;

	}

	
}
