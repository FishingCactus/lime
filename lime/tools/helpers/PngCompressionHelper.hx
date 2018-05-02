package lime.tools.helpers;

import lime.project.AssetType;
import lime.project.HXProject;
import lime.project.PngCompression;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;

class PngCompressionHelper {


	private static var baseDir:String;
	private static var pngCompression:PngCompression;


	public static function compressImages(project:HXProject, exportBaseDir:String):Void
	{
		pngCompression = project.pngCompression;
		baseDir = Sys.getCwd();

		for (asset in project.assets) {

			if (asset.type == AssetType.IMAGE) {

				if (pngCompression.imagePathList.indexOf(asset.targetPath) != -1) {
					var path:String = PathHelper.combine (exportBaseDir, asset.targetPath);
					var targetPath:String = PathHelper.combine (baseDir, path);
					LogHelper.info("[PNGCompression] --> image will be compressed: " + targetPath );
					compressImage(targetPath);
				}

			}
		}
	}


	private static function compressImage(targetPath:String):Void
	{
		LogHelper.info("[PNGCompression] start compression: " + pngCompression.toolsDir);

		var toolsPath:String = PathHelper.combine(pngCompression.toolsDir, "pngquant-mac");
		var argList:Array<String> = [];
		argList.push(targetPath);
		argList.push("--output");
		argList.push(targetPath);
		argList.push("--force");

		var result:Int = Sys.command(toolsPath, argList);

		if (result != 0) {
			LogHelper.error("[PNGCompression] Could not compress: --> " + argList.join(" "));
		}


	}



}