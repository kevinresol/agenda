package agenda;

import agenda.Job;
import agenda.db.Adapter;
using DateTools;

class Agenda {
	
	var adapter:Adapter;
	
	public function new(adapter) {
		this.adapter = adapter;
	}
	
	public function createWorker():Worker {
		return new Worker(adapter);
	}
	
	/**
		Queue a job that should be executed as soon as possible.
	**/
	public function immediate(work:Work, ?options:JobOptions) {
		var info = Job.defaultInfo(work, options);
		return adapter.add(new Job(info));
	}
	
	/**
		Queue a job that should be executed at the scheduled date.
	**/
	public function schedule(date:Date, work:Work, ?options:JobOptions) {
		var info = Job.defaultInfo(work, options);
		info.schedule = date;
		return adapter.add(new Job(info));
	}
	/**
		Queue a job that should be executed after some delay
	**/
	public function delay(delayMS:Int, work:Work, ?options:JobOptions) {
		var info = Job.defaultInfo(work, options);
		info.schedule = Date.now().delta(delayMS);
		return adapter.add(new Job(info));
	}
}