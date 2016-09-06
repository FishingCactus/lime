package lime.tools.helpers;


import haxe.io.Path;
import haxe.Timer;
import haxe.Json;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.Architecture;
import lime.project.Asset;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;
import sys.FileSystem;
import sys.io.File;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end


class HTML5Helper {
	
	
	public static function generateFontData (project:HXProject, font:Asset):String {
		
		var sourcePath = font.sourcePath;
		
		if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
			
			var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
			ProcessHelper.runCommand (Path.directory (sourcePath), "neko", [ PathHelper.findTemplate (templatePaths, "bin/hxswfml.n"), "ttf2hash2", Path.withoutDirectory (sourcePath), FileSystem.fullPath (sourcePath) + ".hash", "-glyphs", font.glyphs ]);
			
		}
		
		return "-resource " + FileSystem.fullPath (sourcePath) + ".hash@__ASSET__" + font.flatName;
		
	}
	
	
	public static function generateWebfonts (project:HXProject, font:Asset):Void {
		
		var suffix = switch (PlatformHelper.hostPlatform) {
			
			case Platform.WINDOWS: "-windows.exe";
			case Platform.MAC: "-mac";
			case Platform.LINUX: "-linux";
			default: return;
			
		}
		
		if (suffix == "-linux") {
			
			if (PlatformHelper.hostArchitecture == Architecture.X86) {
				
				suffix += "32";
				
			} else {
				
				suffix += "64";
				
			}
			
		}
		
		var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
		var fontforge = PathHelper.findTemplate (templatePaths, "bin/fontforge" + suffix);
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			Sys.command ("chmod", [ "+x", fontforge ]);
			
		}
		
		var input = FileSystem.fullPath (font.sourcePath);
		var output_base = Path.withoutExtension(input);

		if (LogHelper.verbose) {
			
			ProcessHelper.runCommand ("", fontforge, [ Path.directory(fontforge) + "/generate-fonts.pe",input, output_base + ".eot", output_base + ".woff", output_base + ".svg" ], true, true, true);
			
		} else {
			
			ProcessHelper.runCommand ("", fontforge, [ Path.directory(fontforge) + "/generate-fonts.pe", input, output_base + ".eot", output_base + ".woff", output_base + ".svg" ]);
			
		}

		try {
			var svg_path = output_base + ".svg";

			var svg_content = File.getContent( svg_path );

			var svg_xml = new haxe.xml.Fast( Xml.parse( svg_content ).firstElement() );

			var font_face = svg_xml.node.defs.node.font.node.resolve('font-face');

			var bbox:Array<Int> = font_face.att.bbox.split(" ").map(function(element) {return Std.parseInt(element);} );
			var height = bbox[3] - bbox[1];

			var unitEm = Std.parseInt( font_face.att.resolve('units-per-em') );
			var ascent = Std.parseInt( font_face.att.ascent );
			var descent = -Std.parseInt( font_face.att.descent );

			var config_path = output_base + ".json";

			File.saveContent( config_path, Json.stringify( { unitEm : unitEm, ascent:ascent, descent:descent,height:height }) );
			font.data = { unitEm : unitEm, ascent:ascent, descent:descent, height:height };
		} catch( e :Dynamic ){
			LogHelper.warn ("Unable to extract font information for " + font.sourcePath );
		}
	}
	
	
	public static function launch (project:HXProject, path:String, port:Int = 3000):Void {
		
		if (project.app.url != null && project.app.url != "") {
			
			ProcessHelper.openURL (project.app.url);
			
		} else {
			
			var suffix = switch (PlatformHelper.hostPlatform) {
				
				case Platform.WINDOWS: "-windows.exe";
				case Platform.MAC: "-mac";
				case Platform.LINUX: "-linux";
				default: return;
				
			}
			
			if (suffix == "-linux") {
				
				if (PlatformHelper.hostArchitecture == Architecture.X86) {
					
					suffix += "32";
					
				} else {
					
					suffix += "64";
					
				}
				
			}
			
			var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
			var node = PathHelper.findTemplate (templatePaths, "bin/node/node" + suffix);
			var server = PathHelper.findTemplate (templatePaths, "bin/node/http-server/http-server");
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				Sys.command ("chmod", [ "+x", node ]);
				
			}
			
			if (project.targetFlags.exists ("port")) {
				
				port = Std.parseInt (project.targetFlags.get ("port"));
				
			}
			
			LogHelper.info ("", " - \x1b[1mStarting local web server:\x1b[0m http://localhost:" + port);
			
			/*Thread.create (function () { 
				
				Sys.sleep (0.5);
				ProcessHelper.openURL ("http://localhost:" + port);
				
			});*/
			
			var args = [ server, path, "-p", Std.string (port), "-c-1", "-o", "--cors" ];
			
			if (!LogHelper.verbose) {
				
				args.push ("--silent");
				
			}
			
			ProcessHelper.runCommand ("", node, args);
			
		}
		
	}
	
	
	public static function minify (project:HXProject, sourceFile:String):Bool {
		
		if (FileSystem.exists (sourceFile)) {
			
			var tempFile = PathHelper.getTemporaryFile (".js");
			
			if (project.targetFlags.exists ("yui")) {
				
				var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
				ProcessHelper.runCommand ("", "java", [ "-Dapple.awt.UIElement=true", "-jar", PathHelper.findTemplate (templatePaths, "bin/yuicompressor-2.4.7.jar"), "-o", tempFile, sourceFile ]);
				
			} else {
				
				var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
				var args = [ "-Dapple.awt.UIElement=true", "-jar", PathHelper.findTemplate (templatePaths, "bin/compiler.jar"), "--js", sourceFile, "--js_output_file", tempFile ];
				
				if (!LogHelper.verbose) {
					
					args.push ("--jscomp_off=uselessCode");
					
				}
				
				ProcessHelper.runCommand ("", "java", args);
				
			}
			
			FileSystem.deleteFile (sourceFile);
			File.copy (tempFile, sourceFile);
			FileSystem.deleteFile (tempFile);
			
			return true;
			
		}
		
		return false;
		
	}
	
	
}
