package agenda;

import agenda.db.Adapter;
import agenda.Job;
import haxe.Timer;

using DateTools;
using tink.CoreApi;

@:allow(agenda)
class Worker {
	
	var adapter:Adapter;
	var timer:Timer;
	var interval:Int;
	var status:WorkerStatus;
	var stopped:SignalTrigger<Noise> = Signal.trigger();
	
	function new(adapter, ?interval:Int) {
		this.adapter = adapter;
		this.interval = interval == null ? 1000 : interval;
		status = Stopped;
	}
	
	public function start() {
		if(status == Stopped) next();
	}
	
	public function stop():Future<Noise> {
		if(timer != null) timer.stop();
		var result = (stopped:Signal<Noise>).next();
		if(status != Working) stopped.trigger(Noise);
		status = Stopped;
		return result;
	}
	
	function next() {
		status = Working;
		adapter.next().handle(function(o) switch(o) {
			case Success(Some(job)): 
				var future = job.run() >>
					function(_) return switch job.status {
						case Done if(job.options.deleteAfterDone): adapter.remove(job.id);
						default: adapter.update(job);
					}
				future.handle(function(o) switch o {
					case Success(_): if(status != Stopped) next() else stopped.trigger(Noise);
					case Failure(err): trace("Adapter update error:" + err); // TODO
				});
			
			case Success(None): 
				// trace('idle');
				status = Idle;
				timer = Timer.delay(next, interval);
				
			case Failure(err): 
				trace('adapter error:' + err.message);
				status = Idle;
				timer = Timer.delay(next, interval);
				
		});
	}
}

enum WorkerStatus {
	Idle;
	Working;
	Stopped;
}