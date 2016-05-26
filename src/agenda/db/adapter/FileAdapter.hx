package agenda.db.adapter;

#if filelock
import agenda.Job;
import haxe.ds.Option;
using tink.CoreApi;

class FileAdapter implements agenda.db.Adapter {
	
	var path:String;
	
	public function new(path:String) {
		this.path = sys.FileSystem.absolutePath(path);
	}
	
	public function add(job:Job):Surprise<Noise, Error> {
		return isolate(_add.bind(job));
	}
	
	public function update(job:Job):Surprise<Noise, Error> {
		return isolate(_update.bind(job));
	}
	
	public function next():Surprise<Option<Job>, Error> {
		return isolate(_next);
	}
	
	function _add(job:Job):Surprise<Noise, Error> {
		var jobs = read();
		jobs.push(job);
		write(jobs);
		return Future.sync(Success(Noise));
	}
	
	function _update(job:Job):Surprise<Noise, Error> {
		var jobs = read();
		for(i in 0...jobs.length) {
			if(jobs[i].id == job.id) {
				jobs[i] = job;
				write(jobs);
				break;
			}
		}
		return Future.sync(Success(Noise));
	}
	
	function _next():Surprise<Option<Job>, Error> {
		var now = Date.now().getTime();
		var jobs = read();
		for(job in jobs)
		if(now > job.schedule.getTime()) {
			switch job.status {
				case Pending:
				case Error: // TODO: check retry interval
				default: continue;
			}
			job.status = Working;
			return _update(job) >> function(_) return Some(job);
		}
		return Future.sync(Success(None));
	}
	
	function isolate<T>(f:Void->Surprise<T, Error>):Surprise<T, Error> {
		return Future.async(function(cb) {
			filelock.FileLock.lock(path).handle(function(o) switch o {
				case Success(lock):
					f().handle(function(o) {
						lock.unlock();
						cb(o);
					});
				case Failure(err):
					cb(Failure(err));
			});
		});
	}
	
	function read():Array<Job> {
		var data = sys.io.File.getContent(path);
		return try haxe.Unserializer.run(data) catch(e:Dynamic) [];
	}
	
	function write(jobs:Array<Job>) {
		sys.io.File.saveContent(path, haxe.Serializer.run(jobs));
	}
}
#end