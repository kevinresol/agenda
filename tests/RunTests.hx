package;

import sys.io.File;
import sys.FileSystem;
import haxe.crypto.Sha1;
import agenda.Job;
import agenda.Agenda;
import agenda.db.Adapter;

using tink.CoreApi;

class RunTests {
	static function main() {
		var agenda = new Agenda(new FileAdapter('agenda.txt'));
		
		// add some jobs
		Future.ofMany([for(i in 0...10) agenda.add(new MyJob(i))]).handle(function(_) {
			
			// start the worker
			agenda.worker.start();
			
			// add more jobs
			for(i in 10...20) agenda.add(new MyJob(i));
		});
		
		// stop after some time
		haxe.Timer.delay(agenda.worker.stop, 2500);
	}
}

class MyJob extends Job {
	
	var i:Int;
	
	public function new(i:Int) {
		super();
		this.i = i;
	}
	
	override function run() {
		var filename = '$i.txt';
		File.saveContent(filename, Date.now().toString());
		return Future.sync(Success(Noise));
	}
	
}