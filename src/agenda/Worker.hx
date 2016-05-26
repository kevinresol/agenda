package agenda;

import agenda.db.Adapter;
import agenda.Job;
import haxe.Timer;

using tink.CoreApi;

class Worker {
	
	var adapter:Adapter;
	var timer:Timer;
	var interval:Int;
	var status:WorkerStatus;
	
	public function new(adapter, interval = 1000) {
		this.adapter = adapter;
		this.interval = interval;
		status = Stopped;
	}
	
	public function start() {
		if(status == Stopped) next();
	}
	
	public function stop() {
		if(timer != null) timer.stop();
		status = Stopped;
	}
	
	function next() {
		status = Working;
		adapter.next().handle(function(o) switch(o) {
			case Success(Some(job)): 
				var future = job.run() >>
					function(_) return switch job.status {
						case Done if(job.options.deleteAfterDone): adapter.remove(job);
						default: adapter.update(job);
					}
				future.handle(function(o) switch o {
					case Success(_): if(status != Stopped) next();
					case Failure(err): trace("Adapter update error:" + err); // TODO
				});
			
			case Success(None): 
				trace('idle');
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