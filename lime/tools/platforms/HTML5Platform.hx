package lime.tools.platforms;

import haxe.Json;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PathHelper;
import lime.project.Asset;
import haxe.io.Path;
import haxe.Template;
import lime.tools.helpers.AssetHelper;
import lime.tools.helpers.DeploymentHelper;
import lime.tools.helpers.FileHelper;
import lime.tools.helpers.HTML5Helper;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.AssetType;
import lime.project.HXProject;
import lime.project.PlatformTarget;
import sys.io.File;
import sys.FileSystem;


typedef AtlasConfiguration = {
	var outputFormat : String;
}


class HTML5Platform extends PlatformTarget {
	
	
	private var outputFile:String;
	
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		initialize (command, _project);
		
		super (command, _project, targetFlags);
		
	}
	
	
	public override function build ():Void {
		
		if (project.app.main != null) {
			
			var type = "release";
			
			if (project.debug) {
				
				type = "debug";
				
			} else if (project.targetFlags.exists ("final")) {
				
				type = "final";
				
			}
			
			var hxml = targetDirectory + "/haxe/" + type + ".hxml";
			ProcessHelper.runCommand ("", "haxe", [ hxml ] );
			
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.copyFile (targetDirectory + "/obj/ApplicationMain.js", outputFile);
				
			}
			
			if (project.targetFlags.exists ("minify") || type == "final") {
				
				HTML5Helper.minify (project, targetDirectory + "/bin/" + project.app.file + ".js");
				
			}
			
		}
		
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			PathHelper.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {
		
		DeploymentHelper.deploy (project, targetFlags, targetDirectory, "HTML5");
		
	}
	
	
	public override function display ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		var context = project.templateContext;
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		
		var template = new Template (File.getContent (hxml));
		
		Sys.println (template.execute (context));
	}
	
	
	private function initialize (command:String, project:HXProject):Void {
	
		targetDirectory = project.app.path + "/html5";
		outputFile = targetDirectory + "/bin/" + project.app.file + ".js";

	}
	
	
	public override function run ():Void {
		
		HTML5Helper.launch (project, targetDirectory + "/bin");
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		var destination = targetDirectory + "/bin/";
		PathHelper.mkdir (destination);
		
		var useWebfonts = true;
		
		for (haxelib in project.haxelibs) {
			
			if (haxelib.name == "openfl-html5-dom" || haxelib.name == "openfl-bitfive") {
				
				useWebfonts = false;
				
			}
			
		}


		//start spritesheet generation before copy of assets from Assets to Export folder

		if (Sys.getEnv("swfSpritesheet") == "true")
		{
			createSpritesheet();
		}

		
		for (asset in project.assets) {
			
			if (asset.type == AssetType.FONT) {
				
				if (useWebfonts) {
					
					HTML5Helper.generateWebfonts (project, asset);
					asset.targetPath = Path.withoutExtension (asset.targetPath);
					
				} else {
					
					project.haxeflags.push (HTML5Helper.generateFontData (project, asset));
					
				}
				
			}
			
		}
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		if (LogHelper.verbose) {
			
			project.haxedefs.set ("verbose", 1);
			
		}
		
		var context = project.templateContext;
		
		context.WIN_FLASHBACKGROUND = StringTools.hex (project.window.background, 6);
		context.OUTPUT_DIR = targetDirectory;
		context.OUTPUT_FILE = outputFile;
		
		if (project.targetFlags.exists ("webgl")) {
			
			context.CPP_DIR = targetDirectory + "/obj";
			
		}
		
		context.linkedLibraries = [];
		
		for (dependency in project.dependencies) {
			
			if (StringTools.endsWith (dependency.name, ".js")) {
				
				context.linkedLibraries.push (dependency.name);
				
			} else if (StringTools.endsWith (dependency.path, ".js") && FileSystem.exists (dependency.path)) {
				
				var name = Path.withoutDirectory (dependency.path);
				
				context.linkedLibraries.push ("./lib/" + name);
				FileHelper.copyIfNewer (dependency.path, PathHelper.combine (destination, PathHelper.combine ("lib", name)));
				
			}
			
		}


		for (asset in project.assets) {


			var path = PathHelper.combine (destination, asset.targetPath);

			if (asset.type != AssetType.TEMPLATE) {

				if (asset.type != AssetType.FONT) {
					LogHelper.warn ("DESTINATION \"" + path+ "\"");
					PathHelper.mkdir (Path.directory (path));
					FileHelper.copyAssetIfNewer (asset, path);


				} else if (useWebfonts) {
					
					PathHelper.mkdir (Path.directory (path));
					var ext = "." + Path.extension (asset.sourcePath);
					var source = Path.withoutExtension (asset.sourcePath);
					
					for (extension in [ ext, ".eot", ".woff", ".svg" ]) {
						
						if (FileSystem.exists (source + extension)) {
							FileHelper.copyIfNewer (source + extension, path + extension);
						} else {
							
							LogHelper.warn ("Could not find generated font file \"" + source + extension + "\"");
							
						}
						
					}
					
				}
				
			}
			
		}
		
		FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/template", destination, context);
		
		if (project.app.main != null) {
			
			FileHelper.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/haxe", targetDirectory + "/haxe", context, true, false);
			FileHelper.recursiveCopyTemplate (project.templatePaths, "html5/hxml", targetDirectory + "/haxe", context);
				
			if (project.targetFlags.exists ("webgl")) {
				
				FileHelper.recursiveCopyTemplate (project.templatePaths, "webgl/hxml", targetDirectory + "/haxe", context, true, false);
				
			}
			
		}
		
		for (asset in project.assets) {
			
			var path = PathHelper.combine (destination, asset.targetPath);
			
			if (asset.type == AssetType.TEMPLATE) {
				
				PathHelper.mkdir (Path.directory (path));
				FileHelper.copyAsset (asset, path, context);
				
			}
			
		}



		AssetHelper.createManifest (project, PathHelper.combine (destination, "manifest"));

	}

	private function createSpritesheet():Void
	{
		var baseDir:String = Sys.getCwd();
		var tempFolder:String = PathHelper.combine(baseDir, "TempSpritesheetGeneration");

		PathHelper.removeDirectory(tempFolder);
		PathHelper.mkdir(tempFolder);

		var workingList:Array<Asset> = project.assets.copy();

		for (asset in workingList) {
			if (asset.markedForSpritesheet) {

				// copy assets into temp folder and remove them from assets list! --> don't need to be loaded after spritesheet generation anymore
				project.assets.remove(asset);
				var targetPath = PathHelper.combine (tempFolder, asset.targetPath);

				FileHelper.copyAssetIfNewer (asset, targetPath);
			}

		}


		var packConfigPath:String = PathHelper.combine(baseDir, project.swfLiteSpritesheet.packConfigPath);
		var packFileName:String = "pack.json";
		var sourcePackFile:String = PathHelper.combine(packConfigPath, packFileName);
		var targetPackFile:String = PathHelper.combine(tempFolder, packFileName);

		//LogHelper.info("copy for spritesheet: " + packFilePath + ", " + tempFolder);

		FileHelper.copyFile(sourcePackFile, targetPackFile);

		var toolsDir:String = PathHelper.combine(baseDir, project.swfLiteSpritesheet.toolsPath);
		var sourcePath:String = tempFolder;
		var targetPath:String = PathHelper.combine(baseDir, project.swfLiteSpritesheet.targetPath);

		LogHelper.info(toolsDir);
		var argList:Array<String> = [];
		argList.push("-cp");
		argList.push(PathHelper.combine(toolsDir, "gdx.jar:") + PathHelper.combine(toolsDir, "gdx-tools.jar"));
		argList.push("com.badlogic.gdx.tools.texturepacker.TexturePacker");
		argList.push(sourcePath);
		argList.push(targetPath);
		argList.push(project.swfLiteSpritesheet.fileName);

		Sys.command("java", argList);
		LogHelper.info(argList.toString());



		//TODO add atlas to the assets

		var exportPath:String = PathHelper.combine(targetDirectory, "bin");
		var sourcePathGeneratedSpritesheet:String = PathHelper.combine(baseDir, project.swfLiteSpritesheet.targetPath);
		var targetPathGeneratedSpriteSheet:String = project.swfLiteSpritesheet.targetPath; //export target will be added later






		var pathToPackFile:String = PathHelper.combine(sourcePath, "pack.json");
		var packFileExists:Bool = FileSystem.exists(pathToPackFile);

		if (packFileExists) {
			LogHelper.info("pack.json exists");
			var value = File.getContent(PathHelper.combine(sourcePath, "pack.json"));
			var atlasConfiguration:AtlasConfiguration = Json.parse(value);
			project.swfLiteSpritesheet.outputFormat = atlasConfiguration.outputFormat;
			LogHelper.info("outputformat is " + atlasConfiguration.outputFormat);
		}

		var textureFileNameWithExtension:String = project.swfLiteSpritesheet.fileName + "." + project.swfLiteSpritesheet.outputFormat;
		var atlasFilenameWithExtension:String = project.swfLiteSpritesheet.fileName + "." + "atlas";


		//TODO check if texture/atlas already existexists!!!!! Otherwise it will be loaded twice!
		project.assets.push (new Asset (PathHelper.combine(sourcePathGeneratedSpritesheet, textureFileNameWithExtension), PathHelper.combine(targetPathGeneratedSpriteSheet, textureFileNameWithExtension)));
		project.assets.push (new Asset (PathHelper.combine(sourcePathGeneratedSpritesheet, atlasFilenameWithExtension), PathHelper.combine(targetPathGeneratedSpriteSheet, atlasFilenameWithExtension)));


	}


	private function prepareTempFolder():Void
	{
		//creates a temp folder for spritesheet generation
		PathHelper.mkdir (project.swfLiteSpritesheet.targetPath);
	}

	
	@ignore public override function install ():Void {}
	@ignore public override function rebuild ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}