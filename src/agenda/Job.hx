package agenda;

using tink.CoreApi;
using DateTools;

class Job {
	public var schedule(default, null):Date;
	
	public function new() {
		schedule = Date.now();
	}
	
	public function run():Surprise<Noise, Error> {
		throw "abstract method";
	}
}

class DelayedJob extends Job {
	public function new(delay_ms:Int) {
		super();
		schedule = Date.now().delta(delay_ms);
	}
}

class ScheduledJob extends Job {
	public function new(schedule:Date) {
		super();
		this.schedule = schedule;
	}
}