package lime.utils;

#if profile

class ProfileTool
{
    public var help:String;
    public var log:Dynamic;
    public var reset:Dynamic;
    public var count:Dynamic;
    private var name:String;

    public function new(name:String)
    {
        this.name = name;
        untyped $global.Profile = $global.Profile || {};
        untyped $global.Profile[name] = this;
    }

    public function showHelp()
    {
        trace('Profile tool "${name}" help:');
        trace(help);
    }
}

#end
