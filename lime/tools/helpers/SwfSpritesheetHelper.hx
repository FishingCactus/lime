package lime.tools.helpers;

import lime.tools.helpers.PathHelper;
import lime.project.Asset;
import lime.project.SwfSpritesheet;
import lime.project.HXProject;
import haxe.Json;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;
import sys.FileSystem;
import sys.io.File;

typedef AtlasConfiguration = {
	var outputFormat : String;
}

typedef AtlasBuildCache = {
	var metaFilePath:String;
	var textureFilePath:String;
	var enabled:Bool;
}

enum ExecutionCommand {
	RESET;
	BUILD;
	DISABLE;
	IGNORE;
}




class SwfSpritesheetHelper {


	private static var assets:Array<Asset>;
	private static var swfSpritesheet:SwfSpritesheet;
	private static var haxedefs:Map <String, Dynamic>;
	private static var baseDir:String;
	private static var tempBaseDir:String;
	private static var tempSwfSpritesheetDir:String;
	private static var tempBuildDir:String;
	private static var pathToCacheFile:String;
	private static var atlasBuildCache:AtlasBuildCache;


	public static function createSpritesheet(project:HXProject):Void
	{
		assets = project.assets;
		swfSpritesheet = project.swfSpritesheet;
		haxedefs = project.haxedefs;
		baseDir = Sys.getCwd();
		tempBaseDir = PathHelper.combine(baseDir, ".temp");
		tempSwfSpritesheetDir = PathHelper.combine(tempBaseDir, "swfSpritesheet");
		tempBuildDir = PathHelper.combine(tempSwfSpritesheetDir, "build");
		pathToCacheFile = PathHelper.combine(tempSwfSpritesheetDir, "atlasBuildCache.json");
		atlasBuildCache = readCacheFile(pathToCacheFile);

		var executionCommand:ExecutionCommand = getExecutionCommand();
		LogHelper.info("[SwfSpritesheet] execution command is: --> " + Std.string(executionCommand));
		LogHelper.info("[SwfSpritesheet] preventSwfTextureBuild --> " + Std.string(haxedefs.exists("preventSwfTextureBuild")));

		switch(executionCommand) {
			case ExecutionCommand.RESET:
				executeResetCommand();
			case ExecutionCommand.BUILD:
				executeBuildCommand();
			case ExecutionCommand.DISABLE:
				executeDisableCommand();
			case ExecutionCommand.IGNORE:
				executeIgnoreCommand();
			default:
		}
	}

	public static function readCacheFile(pathToCacheFile:String):AtlasBuildCache {
		var atlasBuildCache:AtlasBuildCache;
		if (FileSystem.exists(pathToCacheFile)) {
			var value = File.getContent(pathToCacheFile);
			atlasBuildCache = Json.parse(value);
		} else {
			// first build
			atlasBuildCache = {metaFilePath:"", textureFilePath:"", enabled:true};
		}
		return atlasBuildCache;
	}

	private static function removeTempDirectories():Void
	{
		if (FileSystem.exists(tempBaseDir)) {
			PathHelper.removeDirectory(tempBaseDir);
		}
	}

	private static function prepareTempDirectories():Void
	{
		if (!FileSystem.exists(tempSwfSpritesheetDir)) {
			PathHelper.mkdir(tempSwfSpritesheetDir);
		}

		PathHelper.removeDirectory(tempBuildDir);
		PathHelper.mkdir(tempBuildDir);
	}

	private static function copyPackFileToTempDirectory():Void {
		var packConfigPath:String = PathHelper.combine(baseDir, swfSpritesheet.packConfigDir);
		var packFileName:String = "pack.json";
		var sourcePackFile:String = PathHelper.combine(packConfigPath, packFileName);
		var targetPackFile:String = PathHelper.combine(tempBuildDir, packFileName);

		if (FileSystem.exists(sourcePackFile)) {
			FileHelper.copyFile(sourcePackFile, targetPackFile);
		} else {
			LogHelper.error("[SwfSpritesheet] could not find pack.json: --> " + sourcePackFile);
		}
	}

	private static function parsePackJson():Void {

		var pathToPackFile:String = PathHelper.combine(tempBuildDir, "pack.json");
		var value = File.getContent(pathToPackFile);
		var atlasConfiguration:AtlasConfiguration = Json.parse(value);
		swfSpritesheet.outputFormat = atlasConfiguration.outputFormat;
	}

	private static function getExecutionCommand():ExecutionCommand {
		var executionCommand:ExecutionCommand = ExecutionCommand.BUILD;
		if (Sys.getEnv("swfSpritesheet") != "true") {
			executionCommand = ExecutionCommand.RESET; // no swfSpritesheet tag found in project.xml
		} else if (!swfSpritesheet.enabled) {
			executionCommand = ExecutionCommand.DISABLE;
		} else if (haxedefs.exists("preventSwfTextureBuild") && getNumberOfFilesInTargetDirectory() != 0) {
			executionCommand = ExecutionCommand.IGNORE;
		}
		return executionCommand;
	}

	private static function executeResetCommand():Void {
		// delete all temp files
		removeTempDirectories();
	}

	private static function executeBuildCommand():Void {
		// delete temp build directory
		prepareTempDirectories();
		// copy packFile into temp directory
		copyPackFileToTempDirectory();
		// parse pack.json for setting properties in swfSpritesheet
		parsePackJson();
		// assets marked for spritesheet will be copied to temp directory and removed from assets list
		moveAssetsToTempDirectory();
		// delete existing target files and remove assets from assets list
		deleteExistingTextureFiles();
		// create texture with gdxLib
		packTextureWithCommandLineTool();
		// save current target directory for rebuild file validation
		saveCurrentTargets();
		// check if more than 2 files located in target directory
		checkNumberOfFilesInTargetDirectory();
		// metaFile (*.atlas) and textureFile (*.png) will be added to the assets list
		addTextureFilesToAssetsList();

	}

	private static function executeDisableCommand():Void {
		// delete temp build directory
		prepareTempDirectories();
		// delete existing target files and remove assets from assets list
		deleteExistingTextureFiles();
		// save current enabled flag rebuild file validation
		saveCurrentTargets();
	}

	private static function executeIgnoreCommand():Void {
		// delete temp build directory
		prepareTempDirectories();
		// assets marked for spritesheet will be copied to temp directory and removed from assets list
		moveAssetsToTempDirectory();

		checkNumberOfFilesInTargetDirectory();
	}


	private static function deleteExistingTextureFiles():Void {
		deleteExistingTextureFile(atlasBuildCache.metaFilePath);
		deleteExistingTextureFile(atlasBuildCache.textureFilePath);
	}

	private static function deleteExistingTextureFile(targetPath:String):Void {
		if (FileSystem.exists(targetPath)) {
			LogHelper.info("[SwfSpritesheet] deleted file: --> " + targetPath);
			FileSystem.deleteFile(targetPath);
		}

		var workingList:Array<Asset> = assets.copy();
		for (asset in workingList) {
			if (asset.targetPath == targetPath) {
				LogHelper.info("[SwfSpritesheet] removed from assets list: --> " + targetPath);
				assets.remove(asset);
			}
		}
	}

	private static function moveAssetsToTempDirectory():Void
	{
		var workingList:Array<Asset> = assets.copy();
		for (asset in workingList) {
			if (asset.markedForSpritesheet) {
				// remove assets from assets list! --> don't need to be loaded after spritesheet generation anymore
				assets.remove(asset);

				// copy assets into temp folder
				var targetPath = PathHelper.combine (tempBuildDir, asset.targetPath);
				FileHelper.copyAssetIfNewer (asset, targetPath);
			}
		}
	}

	private static function packTextureWithCommandLineTool():Void
	{
		LogHelper.info("[SwfSpritesheet] start creation of texture files");
		var toolsDir:String = PathHelper.combine(baseDir, swfSpritesheet.toolsDir);
		var sourceDir:String = tempBuildDir;
		var targetDir:String = PathHelper.combine(baseDir, swfSpritesheet.targetDir);

		var argList:Array<String> = [];
		argList.push("-Djava.awt.headless=true");
		argList.push("-cp");
		argList.push(PathHelper.combine(toolsDir, "gdx.jar:") + PathHelper.combine(toolsDir, "gdx-tools.jar"));
		argList.push("com.badlogic.gdx.tools.texturepacker.TexturePacker");
		argList.push(sourceDir);
		argList.push(targetDir);
		argList.push(swfSpritesheet.fileName);

		LogHelper.info("[SwfSpritesheet] argList: --> " + argList.join(" "));

		var result:Int = Sys.command("java", argList);
		if (result != 0) {
			LogHelper.error("[SwfSpritesheet] Could not pack texture: --> " + argList.join(" "));
		}
	}

	private static function saveCurrentTargets():Void {
		atlasBuildCache.metaFilePath = getFullTargetFilePath("atlas");
		atlasBuildCache.textureFilePath =  getFullTargetFilePath(swfSpritesheet.outputFormat);
		atlasBuildCache.enabled = swfSpritesheet.enabled;
		var fileContent:String = Json.stringify(atlasBuildCache);
		File.saveContent(pathToCacheFile, fileContent);
	}


	private static function addTextureFilesToAssetsList():Void
	{
		//related path from haxe/Export folder of the project --> f.i. Assets/spritesheets
		var targetDirGeneratedSpriteSheet:String = swfSpritesheet.targetDir;
		addTextureFileToAssetsList(getFullTargetFilePath("atlas"));
		addTextureFileToAssetsList(getFullTargetFilePath(swfSpritesheet.outputFormat));
	}

	private static function getFullTargetFilePath(extension:String):String {
		var targetDirGeneratedSpritesheet:String = swfSpritesheet.targetDir;
		var filenameWithExtension:String = swfSpritesheet.fileName + "." + extension;
		var targetFilePath:String = PathHelper.combine(targetDirGeneratedSpritesheet, filenameWithExtension);
		return targetFilePath;
	}

	private static function addTextureFileToAssetsList(targetFilePath:String):Void {
		//first check if file is already added to the assets list ( in case of spritesheet was already generated in a previous build
		if (isAssetMarkedForExport(targetFilePath)) {
			LogHelper.info("[SwfSpritesheet] asset already added: --> " + targetFilePath);
		} else {
			assets.push (new Asset (targetFilePath, targetFilePath));
			LogHelper.info("[SwfSpritesheet] asset added: --> " + targetFilePath);
		}
	}

	private static function isAssetMarkedForExport(targetPath:String):Bool {
		var isMarked:Bool = false;
		for (asset in assets) {
			if (asset.targetPath == targetPath) {
				isMarked = true;
				break;
			}

		}
		return isMarked;
	}

	private static function checkNumberOfFilesInTargetDirectory():Void {
		var numberOfFiles:Int = getNumberOfFilesInTargetDirectory();
		if (getNumberOfFilesInTargetDirectory() == 0) {
			LogHelper.error("[SwfSpritesheet] there are no generated texture files, build with compilerflag '-clean' and without haxedef 'preventSwfTextureBuild'" );
		} else if (numberOfFiles > 2) {
			LogHelper.error("[SwfSpritesheet] more than 2 texture files in target directory, please remove unused texture files in --> " + swfSpritesheet.targetDir);

		}

	}

	private static function getNumberOfFilesInTargetDirectory():Int {
		var numberOfFiles:Int = 0;
		var targetDir:String = swfSpritesheet.targetDir;
		var filesList:Array<String> = PathHelper.readDirectory(targetDir);
		if (filesList != null) {
			numberOfFiles = PathHelper.readDirectory(targetDir).length;
		}
		return numberOfFiles;
	}

	private static function deleteCacheFile():Void
	{
		if (FileSystem.exists(pathToCacheFile)) {
			FileSystem.deleteFile(pathToCacheFile);
		}
	}

}