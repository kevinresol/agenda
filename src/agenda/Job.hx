package agenda;

import haxe.ds.Option;
import agenda.util.U;

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
	public var recurring:Option<RecurType>;
	
	function new(info:JobInfo) {
		if(info.recurring != None) info.options.deleteAfterDone = false;
		
		id = info.id;
		attempts = info.attempts;
		schedule = info.schedule;
		nextRetry = info.nextRetry;
		options = info.options;
		work = info.work;
		status = info.status;
		createDate = info.createDate;
		recurring = info.recurring;
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
	
	public function updateRecurrence() {
		switch recurring {
			case None: return;
			case Some(DayOfMonth(day, time)): schedule = U.nextDayOfMonth(day).delta(time * 1000);
			case Some(Interval(_, interval)): schedule = schedule.delta(interval * 1000);
		}
		status = Pending;
	}
	
	function done() {
		status = Done;
		attempts.push(new Attempt(Success(Noise), schedule));
	}
	
	function fail(err:Error) {
		if(attempts.length >= options.retryCount) 
			status = Failed;
		else {
			status = Errored;
			nextRetry = Date.now().delta(options.retryInterval);
		}
		if(Std.is(err, Error)) err = Error.withData('Error', err);
		attempts.push(new Attempt(Failure(err), schedule));
	}
	
	static function defaultInfo(schedule:Date, work:Work, recurring:Option<RecurType>, options:JobOptions):JobInfo {
		if(options == null) options = {};
		if(options.deleteAfterDone == null) options.deleteAfterDone = false;
		if(options.retryCount == null) options.retryCount = 3;
		if(options.retryInterval == null) options.retryInterval = 5 * 60 * 1000; // 5 minutes
		if(options.priority == null) options.priority = 100; // 5 minutes
		if(options.stale == null) options.stale = 30 * 60 * 1000; // 30 minutes
		return {
			id: uuid(),
			attempts: [],
			schedule: schedule,
			nextRetry: null,
			options: options,
			work: work,
			status: Pending,
			createDate: Date.now(),
			recurring: recurring,
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
	public var schedule:Date; // identify which recurrence
	
	public function new(outcome, schedule, ?date) {
		this.outcome = outcome;
		this.schedule = schedule;
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
	
	/**
		Priority of this job:
		Jobs with higher priority should run first
		default is 100
	**/
	@:optional var priority:Int;
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
	recurring:Option<RecurType>,
}

@:enum
abstract JobStatus(String) to String {
	var Pending = 'pending';
	var Working = 'working';
	var Errored = 'errored';
	var Failed = 'failed';
	var Done = 'done';
}

enum RecurType {
	DayOfMonth(day:Int, time:Int); // day: 1-3, time=seconds from 00:00
	Interval(start:Date, interval:Int); // Interval in seconds
}

