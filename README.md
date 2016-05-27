# agenda

Job scheduler

## Usage

```haxe
static function main() {
	// database adapter, used to persist job data
	// find more adapters in agenda/db/adapters folder
	// or implement your own adapter, see agenda.db.Adapter
	var adapter = new FileAdapter('agenda.txt'); // require `-lib filelock`
	
	// the Agenda instance
	var agenda = new Agenda(adapter);
	
	// create a worker
	// a worker will check the database periodically, and run all the executable jobs one by one
	// you can also create more workers with `agenda.createWorker()` and let them run jobs in parallel
	var worker = agenda.createWorker();
	
	// start the worker
	worker.start();
	
	// add some jobs
	// note: adding jobs are async
	for(i in 0...10) agenda.immediate(new MyWork(i));
	
	// stop the worker after some time
	haxe.Timer.delay(function() worker.stop(), 10000);
}

class MyWork implements Work {
	
	var i:Int;
	
	public function new(i:Int) {
		this.i = i;
	}
	
	// some dummy tasks, write a text file
	public function work() {
		var filename = '$i.txt';
		File.saveContent(filename, Date.now().toString());
		return Future.sync(Success(Noise));
	}
	
}
```

More: see tests folder.

### TODO

- Recursive jobs (e.g. run at :05 of every hour)