package agenda;

import agenda.Job;
import agenda.db.Adapter;
import agenda.util.U;

using DateTools;

class Agenda {
	
	var adapter:Adapter;
	
	public function new(adapter) {
		this.adapter = adapter;
	}
	
	public function createWorker(?interval:Int):Worker {
		return new Worker(adapter, interval);
	}
	
	/**
		Queue a job that should be executed as soon as possible.
	**/
	public function immediate(work:WorkGenerator, ?options:JobOptions) {
		return schedule(Date.now(), work, options);
	}
	
	/**
		Queue a job that should be executed at the scheduled date.
	**/
	public function schedule(date:Date, work:WorkGenerator, ?recurring:RecurType, ?options:JobOptions) {
		var info = Job.defaultInfo(date, work(), recurring == null ? None : Some(recurring), options);
		return adapter.add(new Job(info));
	}
	/**
		Queue a job that should be executed after some delay
	**/
	public function delay(delayMS:Int, work:WorkGenerator, ?options:JobOptions) {
		return schedule(Date.now().delta(delayMS), work, options);
	}
	
	public inline function recurring(type:RecurType, work:WorkGenerator, ?options:JobOptions) {
		var date = switch type {
			case DayOfMonth(day, time): U.nextDayOfMonth(day).delta(time * 1000);
			case Interval(start, interval): start;
		}
		return schedule(date, work, type, options);
	}
	
	/**
		Clear all jobs. Use with care.
	**/
	public function clear() {
		return adapter.clear();
	}
}

@:callable
abstract WorkGenerator(Void->Work) from Void->Work to Void->Work {
	@:from
	public static inline function fromWork(work:Work):WorkGenerator
		return function() return work;
}