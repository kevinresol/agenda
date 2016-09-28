package agenda;

import agenda.Job;
import agenda.db.Adapter;

using DateTools;
using tink.CoreApi;

class Agenda {
	
	var adapter:Adapter;
	
	public function new(adapter) {
		this.adapter = adapter;
	}
	
	public inline function createWorker(?interval:Int):Worker {
		return new Worker(adapter, interval);
	}
	
	/**
		Queue a job that should be executed as soon as possible.
	**/
	public inline function immediate(work:WorkGenerator, ?options:JobOptions) {
		return schedule(Date.now(), work, options);
	}
	
	/**
		Queue a job that should be executed at the scheduled date.
	**/
	public function schedule(date:Date, work:WorkGenerator, ?options:JobOptions) {
		return Future.async(function(cb) {
			var future = work() >>
				function(work:Work) {
					var info = Job.defaultInfo(work, date, options);
					return adapter.add(new Job(info));
				}
			future.handle(cb);
		});
	}
	/**
		Queue a job that should be executed after some delay
	**/
	public inline function delay(delayMS:Int, work:WorkGenerator, ?options:JobOptions) {
		return schedule(Date.now().delta(delayMS), work, options);
	}
	
	/**
		Clear all jobs. Use with care.
	**/
	public function clear() {
		return adapter.clear();
	}
}

private typedef WorkGen = Void->Surprise<Work, Error>;

@:callable
abstract WorkGenerator(WorkGen) from WorkGen to WorkGen {
	@:from
	public static inline function fromWork(work:Work):WorkGenerator {
		return function() return Future.sync(Success(work));
	}
}