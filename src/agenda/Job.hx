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
			status = Errored;
			nextRetry = Date.now().delta(options.retryInterval);
		}
		attempts.push(new Attempt(Failure(err)));
	}
	
	static function defaultInfo(work:Work, options:JobOptions):JobInfo {
		if(options == null) options = {};
		if(options.deleteAfterDone == null) options.deleteAfterDone = false;
		if(options.retryCount == null) options.retryCount = 3;
		if(options.retryInterval == null) options.retryInterval = 5 * 60 * 1000; // 5 minutes
		if(options.stale == null) options.stale = 30 * 60 * 1000; // 30 minutes
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
	
	/**
		Delete the job from database after done
	**/
	@:optional var deleteAfterDone:Bool;
	
	/**
		Number of retry when a job is finished with error
	**/
	@:optional var retryCount:Int;
	
	/**
		Number of milliseconds to wait before trying a errored job
	**/
	@:optional var retryInterval:Int;
	
	/**
		Number of milliseconds for a job to be considered as stale
		(i.e. a job has been working for too long, it may has crashed without reporting an error properly)
	**/
	@:optional var stale:Int;
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

@:enum
abstract JobStatus(String) to String {
	var Pending = 'pending';
	var Working = 'working';
	var Errored = 'errored';
	var Failed = 'failed';
	var Done = 'done';
}