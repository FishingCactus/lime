package lime.audio;

class ExtraSoundOptions {
    public var start:Int;
    public var duration:Int;
    public var preload:Int;

    public function new(start:Int, duration:Int, preload:Int) {
        this.start = start;
        this.duration = duration;
        this.preload = preload;
    }
}