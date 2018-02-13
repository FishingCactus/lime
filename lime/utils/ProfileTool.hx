package lime.utils;

#if profile

class ProfileTool {
	public var help:String;
	public var log:Dynamic;
	public var reset:Dynamic;
	public var count:Dynamic;
	private var name:String;
	static var instances:Array<ProfileTool>;

	static function __init__() {
		instances = instances != null ? instances : [];
		untyped $global.Profile = $global.Profile || {};
		untyped $global.Profile.help = function() {
			for(instance in instances) {
				untyped console.log('\nProfile tool "${instance.name}":');
				instance.showHelp();
			}
		}
	}

	public function new(name:String) {
		this.name = name;
		untyped $global.Profile = $global.Profile || {};
		untyped $global.Profile[name] = this;
		instances.push(this);
	}

	public function showHelp() {
		untyped console.log(help);
	}
}

#end
