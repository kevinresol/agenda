package agenda.db;

import agenda.Job;

using tink.CoreApi;

class Item {
	public var id:String;
	public var attempts:Array<Attempt>;
	public var job:Job;
	
	public var status:ItemStatus;
	public var created:Date;
	
	public function new(id:String, job:Job){
		this.id = id;
		this.job = job;
		attempts = [];
		created = Date.now();
		status = Pending;
	}
	
	public function done() {
		status = Done;
		attempts.push(new Attempt(Success(Noise)));
	}
	
	public function fail(err:Error) {
		status = Error;
		attempts.push(new Attempt(Failure(err)));
	}
}

private class Attempt {
	
	public var outcome:Outcome<Noise, Error>;
	public var date:Date;
	
	public function new(outcome) {
		this.outcome = outcome;
		this.date = Date.now();
	}
}

enum ItemStatus {
	Pending;
	Working;
	Error;
	Done;
}