package;

import sys.io.File;
import sys.FileSystem;
import haxe.crypto.Sha1;
import agenda.Job;
import agenda.Agenda;
import agenda.db.adapter.*;

using tink.CoreApi;

class RunTests {
	static function main() {
		var adapter =
			#if filelock
				new FileAdapter('agenda.txt');
			#elseif (js_kit && futurize)
				new MongooseAdapter('mongodb://localhost:27017/test_agenda');
			#end
			
		var agenda = new Agenda(adapter);
		
		// add some jobs
		Future.ofMany([for(i in 0...10) agenda.add(Job.immediate(new MyWork(i)))]).handle(function(_) {
			
			// start the worker
			agenda.worker.start();
			
			// add more jobs
			for(i in 10...20) agenda.add(Job.immediate(new MyWork(i)));
		});
		
		// stop after some time
		haxe.Timer.delay(function() {
			agenda.worker.stop();
			Sys.exit(0);
		}, 2500);
	}
}

class MyWork implements Work {
	
	var i:Int;
	
	public function new(i:Int) {
		this.i = i;
	}
	
	public function work() {
		var filename = '$i.txt';
		File.saveContent(filename, Date.now().toString());
		return Future.sync(Success(Noise));
	}
	
}