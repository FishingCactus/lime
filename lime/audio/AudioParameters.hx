package lime.audio;

class AudioParameters {
    public var start:Int;
    public var duration:Int;

    public function new(start:Int = 0, duration:Int) {
        this.start = start;
        this.duration = duration;
    }
}