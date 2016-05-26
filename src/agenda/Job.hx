package agenda;

using tink.CoreApi;
using DateTools;

@:allow(agenda)
class Job {
	public var id:String;
	public var attempts:Array<Attempt>;
	public var schedule:Date;
	public var deleteAfterDone:Bool;
	public var work:Work;
	public var status:JobStatus;
	public var createDate:Date;
	
	function new(info:JobInfo) {
		id = info.id;
		attempts = info.attempts;
		schedule = info.schedule;
		deleteAfterDone = info.deleteAfterDone;
		work = info.work;
		status = info.status;
		createDate = info.createDate;
	}
	
	public function run():Future<Noise> {
		return work.work().map(function(o) {
			switch o {
				case Success(_): done();
				case Failure(err): fail(err);
			}
			return Noise;
		});
	}
	
	function done() {
		status = Done;
		attempts.push(new Attempt(Success(Noise)));
	}
	
	function fail(err:Error) {
		status = Error;
		attempts.push(new Attempt(Failure(err)));
	}
	
	public static function immediate(work:Work, ?options:JobOptions) {
		var info = defaultInfo(work, options);
		return new Job(info);
	}
	
	public static function at(date:Date, work:Work, ?options:JobOptions) {
		var info = defaultInfo(work, options);
		info.schedule = date;
		return new Job(info);
	}
	
	public static function delay(delayMS:Int, work:Work, ?options:JobOptions) {
		var info = defaultInfo(work, options);
		info.schedule = Date.now().delta(delayMS);
		return new Job(info);
	}
	
	static function defaultInfo(work:Work, options:JobOptions):JobInfo {
		return {
			id: uuid(),
			attempts: [],
			schedule: Date.now(),
			deleteAfterDone: options != null && options.deleteAfterDone != null ? options.deleteAfterDone : true,
			work: work,
			status: Pending,
			createDate: Date.now(),
		}
	}
	
	static var chars = "0123456789ABCDEF".split('');
	static var specialChars = "89AB".split('');
	static function uuid() {
		inline function srandom() return chars[Std.random(16)];
		
		var s = new StringBuf();
		for(i in 0...8)
			s.add(srandom());
		s.add('-');
		for(i in 0...4)
			s.add(srandom());
		s.add('-');
		s.add('4');
		for(i in 0...3)
			s.add(srandom());
		s.add('-');
		s.add(specialChars[Std.random(4)]);
		for(i in 0...3)
			s.add(srandom());
		s.add('-');
		for(i in 0...12)
			s.add(srandom());
		return s.toString();
	}
}

class Attempt {
	
	public var outcome:Outcome<Noise, Error>;
	public var date:Date;
	
	public function new(outcome, ?date) {
		this.outcome = outcome;
		this.date = date == null ? Date.now() : date;
	}
}

typedef JobOptions = {
	?deleteAfterDone:Bool,
}

typedef JobInfo = {
	id:String,
	attempts:Array<Attempt>,
	schedule:Date,
	deleteAfterDone:Bool,
	work:Work,
	status:JobStatus,
	createDate:Date,
}

interface Work {
	function work():Surprise<Noise, Error>;
}

@:enum
abstract JobStatus(String) to String {
	var Pending = 'pending';
	var Working = 'working';
	var Error = 'error';
	var Failed = 'failed';
	var Done = 'done';
}