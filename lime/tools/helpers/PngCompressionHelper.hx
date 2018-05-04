package lime.tools.helpers;

import lime.project.Platform;
import lime.project.AssetType;
import lime.project.HXProject;
import lime.project.PngCompression;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;
import sys.FileSystem;

class PngCompressionHelper {


	private static var baseDir:String;
	private static var pngCompression:PngCompression;


	public static function compressImages(project:HXProject, exportBaseDir:String):Void
	{
		pngCompression = project.pngCompression;
		baseDir = Sys.getCwd();

		checkIfImagePathesValid(exportBaseDir);

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

	private static function checkIfImagePathesValid(exportBaseDir:String):Void {
		var fullExportDir:String = PathHelper.combine (baseDir, exportBaseDir);
		for (imagePath in pngCompression.imagePathList) {
			var path:String = PathHelper.combine (fullExportDir, imagePath);
			if (!FileSystem.exists(path)) {
				LogHelper.error("[PNGCompression] --> path to file does not exist, please check attribute 'path' of <image/> in <pngCompression/>: " + path );
			}
		}
	}



	private static function compressImage(targetPath:String):Void
	{
		var fileName:String = getPlatformFileName();
		var toolsPath:String = PathHelper.combine(pngCompression.toolsDir, "pngquant-mac");
		var argList:Array<String> = [];
		argList.push(targetPath);
		argList.push("--output");
		argList.push(targetPath);
		argList.push("--force");
		argList.push("--verbose");
		argList.push("--strip");

		var result:Int = Sys.command(toolsPath, argList);

		if (result != 0) {
			LogHelper.error("[PNGCompression] Could not compress: --> " + argList.join(" "));
		}


	}


	private static function getPlatformFileName():String {
		var fileName:String = "";
		switch (PlatformHelper.hostPlatform) {
			case Platform.WINDOWS:
				fileName = "pngquant-win.exe";
			case Platform.MAC:
				fileName = "pngquant-mac";
			default:
				LogHelper.error("[PNGCompression] Platform does not support pngquant: --> " + PlatformHelper.hostPlatform);
		}
		return fileName;
	}

}