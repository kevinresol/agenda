package agenda;

import agenda.db.Adapter;

class Agenda {
	
	public var worker(default, null):Worker;
	
	var adapter:Adapter;
	
	public function new(adapter) {
		this.adapter = adapter;
		worker = new Worker(adapter);
	}
	
	public function add(job:Job) {
		return adapter.add(job);
	}
}