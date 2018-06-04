package lime.project;

class PngCompression {

	public var imagePathList:Array<String>;
	public var toolsDir:String;
	public var enabled:Bool;


	public function new () {

		enabled = false;
		imagePathList = new Array<String>();
	}

	public function clone ():PngCompression {

		var pngCompression = new PngCompression ();
		pngCompression.enabled = enabled;
		pngCompression.toolsDir = toolsDir;
		pngCompression.imagePathList = imagePathList;

		return pngCompression;
	}

	
}
