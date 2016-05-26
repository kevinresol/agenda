package agenda;

using tink.CoreApi;
using DateTools;

@:allow(agenda)
class Job {
	public var id:String;
	public var attempts:Array<Attempt>;
	public var schedule:Date;
	public var nextRetry:Date;
	public var options:JobOptions;
	public var work:Work;
	public var status:JobStatus;
	public var createDate:Date;
	
	function new(info:JobInfo) {
		id = info.id;
		attempts = info.attempts;
		schedule = info.schedule;
		nextRetry = info.nextRetry;
		options = info.options;
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
		if(attempts.length >= options.retryCount) 
			status = Failed;
		else {
			status = Error;
			nextRetry = Date.now().delta(options.retryIntervalMS);
		}
		attempts.push(new Attempt(Failure(err)));
	}
	
	static function defaultInfo(work:Work, options:JobOptions):JobInfo {
		if(options == null) options = {};
		if(options.deleteAfterDone == null) options.deleteAfterDone = true;
		if(options.retryCount == null) options.retryCount = 3;
		if(options.retryIntervalMS == null) options.retryIntervalMS = 5 * 60 * 1000;
		return {
			id: uuid(),
			attempts: [],
			schedule: Date.now(),
			nextRetry: null,
			options: options,
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
	?retryCount:Int,
	?retryIntervalMS:Int,
}

typedef JobInfo = {
	id:String,
	attempts:Array<Attempt>,
	schedule:Date,
	nextRetry:Date,
	options:JobOptions,
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