package lime.project;

class PngCompression {

	public var imagePathList:Array<String>;
	public var toolsDir:String;
	public var enabled:Bool;


	public function new (imagePathList:Array<String>, toolsDir:String, enabled:Bool) {

		this.imagePathList = imagePathList;
		this.toolsDir = toolsDir;
		this.enabled = enabled;

	}

	public function clone ():PngCompression {
		var pngCompression = new PngCompression (imagePathList, toolsDir, enabled);
		return pngCompression;
	}

	
}
