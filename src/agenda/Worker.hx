package agenda;

import agenda.db.Adapter;
import agenda.db.Item;
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
			case Success(Some(item)): 
				run(item).handle(function(_) if(status != Stopped) next());
			
			case Success(None): 
				trace('idle');
				status = Idle;
				timer = Timer.delay(next, interval);
				
			case Failure(err): 
				trace(err.message);
				
		});
	}
	
	function run(item:Item) {
		return item.job.run() >>
			function(o) {
				switch o {
					case Success(_): item.done();
					case Failure(err): item.fail(err);
				}
				return adapter.update(item);
			}
	}
}

enum WorkerStatus {
	Idle;
	Working;
	Stopped;
}