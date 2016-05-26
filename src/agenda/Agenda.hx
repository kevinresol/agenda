package agenda;

import agenda.Job;
import agenda.db.Adapter;
using DateTools;

class Agenda {
	
	public var worker(default, null):Worker;
	
	var adapter:Adapter;
	
	public function new(adapter) {
		this.adapter = adapter;
		worker = new Worker(adapter);
	}
	
	public function immediate(work:Work, ?options:JobOptions) {
		var info = Job.defaultInfo(work, options);
		return adapter.add(new Job(info));
	}
	
	public function schedule(date:Date, work:Work, ?options:JobOptions) {
		var info = Job.defaultInfo(work, options);
		info.schedule = date;
		return adapter.add(new Job(info));
	}
	
	public function delay(delayMS:Int, work:Work, ?options:JobOptions) {
		var info = Job.defaultInfo(work, options);
		info.schedule = Date.now().delta(delayMS);
		return adapter.add(new Job(info));
	}
}