package lime.tools.helpers;

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
}

enum ExecutionCommand {
	BUILD;
	DISABLE;
	IGNORE;
}




class SwfSpritesheetHelper {


	private static var assets:Array<Asset>;
	private static var swfSpritesheet:SwfSpritesheet;
	private static var baseDir:String;
	private static var tempBaseDir:String;
	private static var tempBuildDir:String;
	private static var pathToCacheFile:String;
	private static var atlasBuildCache:AtlasBuildCache;


	public static function createSpritesheet(project:HXProject):Void
	{
		assets = project.assets;
		swfSpritesheet = project.swfSpritesheet;
		baseDir = Sys.getCwd();
		tempBaseDir = PathHelper.combine(baseDir, "TempSpritesheetGeneration");
		tempBuildDir = PathHelper.combine(tempBaseDir, "build");
		pathToCacheFile = PathHelper.combine(tempBaseDir, "atlasBuildCache.json");
		atlasBuildCache = readCacheFile();

		// delete temp build directory
		prepareTempDirectories();
		// copy packFile into temp directory
		copyPackFileToTempDirectory();
		// parse pack.json for setting properties in swfSpritesheet
		parsePackJson();


		var executionCommand:ExecutionCommand = getExecutionCommand();
		LogHelper.info("[SwfSpritesheet] execution command is: --> " + Std.string(executionCommand));

		switch(executionCommand) {
			case ExecutionCommand.BUILD:
				executeBuildCommand();
			case ExecutionCommand.DISABLE:
				executeDisableCommand();
			case ExecutionCommand.IGNORE:
				executeIgnoreCommand();
			default:
		}
	}

	private static function readCacheFile():AtlasBuildCache {
		var atlasBuildCache:AtlasBuildCache;
		if (FileSystem.exists(pathToCacheFile)) {
			var value = File.getContent(pathToCacheFile);
			atlasBuildCache = Json.parse(value);
		} else {
			// first build
			atlasBuildCache = {metaFilePath:"", textureFilePath:""};
		}
		return atlasBuildCache;
	}

	private static function prepareTempDirectories():Void
	{
		if (!FileSystem.exists(tempBaseDir)) {
			PathHelper.mkdir(tempBaseDir);
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
		if (!swfSpritesheet.enabled) {
			executionCommand = ExecutionCommand.DISABLE;
		} else if (swfSpritesheet.preventRebuild && isCurrentTaskRebuild()) {
			executionCommand = ExecutionCommand.IGNORE;
		}
		return executionCommand;
	}

	private static function isCurrentTaskRebuild():Bool {
		//check if current build is a rebuild of the existing atlas
		if (atlasBuildCache.metaFilePath == getFullTargetFilePath("atlas") && atlasBuildCache.textureFilePath == getFullTargetFilePath(swfSpritesheet.outputFormat)) {
			return true;
		} else {
			return false;
		}
	}

	private static function executeBuildCommand():Void {
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
		// delete existing target files and remove assets from assets list
		deleteExistingTextureFiles();
		// delete cache file
		deleteCacheFile();
	}

	private static function executeIgnoreCommand():Void {
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
		argList.push("-cp");
		argList.push(PathHelper.combine(toolsDir, "gdx.jar:") + PathHelper.combine(toolsDir, "gdx-tools.jar"));
		argList.push("com.badlogic.gdx.tools.texturepacker.TexturePacker");
		argList.push(sourceDir);
		argList.push(targetDir);
		argList.push(swfSpritesheet.fileName);

		var result:Int = Sys.command("java", argList);
		if (result != 0) {
			LogHelper.error("[SwfSpritesheet] Could not pack texture: --> " + argList.join(" "));
		}
	}

	private static function saveCurrentTargets():Void {
		atlasBuildCache.metaFilePath = getFullTargetFilePath("atlas");
		atlasBuildCache.textureFilePath =  getFullTargetFilePath(swfSpritesheet.outputFormat);
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
		var targetDir:String = swfSpritesheet.targetDir;
		var numberOfFiles:Int = PathHelper.readDirectory(targetDir).length;
		if (numberOfFiles == 0 && swfSpritesheet.preventRebuild) {
			LogHelper.error("[SwfSpritesheet] there are no generated texture files, set attribute 'preventRebuild' of element <swfSpritesheet/> to false an build again" );
		} else if (numberOfFiles > 2) {
			LogHelper.error("[SwfSpritesheet] more than 2 texture files in target directory, please remove unused texture files in --> " + targetDir);

		}

	}

	private static function deleteCacheFile():Void
	{
		if (FileSystem.exists(pathToCacheFile)) {
			FileSystem.deleteFile(pathToCacheFile);
		}
	}

}