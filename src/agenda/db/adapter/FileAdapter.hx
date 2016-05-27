package agenda.db.adapter;

#if filelock
import agenda.Job;
import haxe.ds.Option;

using tink.CoreApi;
using DateTools;

class FileAdapter implements agenda.db.Adapter {
	
	var path:String;
	
	public function new(path:String) {
		this.path = sys.FileSystem.absolutePath(path);
	}
	
	public function add(job:Job):Surprise<Noise, Error> {
		return isolate(_add.bind(job));
	}
	
	public function remove(id:String):Surprise<Noise, Error> {
		return isolate(_remove.bind(id));
	}
	
	public function update(job:Job):Surprise<Noise, Error> {
		return isolate(_update.bind(job));
	}
	
	public function next():Surprise<Option<Job>, Error> {
		return isolate(_next);
	}
	
	function _add(job:Job):Surprise<Noise, Error> {
		switch read() {
			case Success(jobs):
				jobs.push(job);
				write(jobs);
				return Future.sync(Success(Noise));
			case Failure(err): return Future.sync(Failure(err));
		}
	}
	
	function _remove(id:String):Surprise<Noise, Error> {
		switch read() {
			case Success(jobs):
				for(i in 0...jobs.length) {
					if(jobs[i].id == id) {
						jobs.splice(i, 1);
						write(jobs);
						break;
					}
				}
				return Future.sync(Success(Noise));
			case Failure(err): return Future.sync(Failure(err));
		}
	}
	
	function _update(job:Job):Surprise<Noise, Error> {
		switch read() {
			case Success(jobs):
				for(i in 0...jobs.length) {
					if(jobs[i].id == job.id) {
						jobs[i] = job;
						write(jobs);
						break;
					}
				}
				return Future.sync(Success(Noise));
			case Failure(err): return Future.sync(Failure(err));
		}
	}
	
	function _next():Surprise<Option<Job>, Error> {
		var now = Date.now();
		var nowTime = now.getTime();
		switch read() {
			case Success(jobs):
				for(job in jobs)
				if(nowTime > job.schedule.getTime()) {
					switch job.status {
						case Pending: // good, this is the one we are finding
						case Errored | Working if(nowTime > job.nextRetry.getTime()): // good, this is the one we are finding
						default: continue;
					}
					job.status = Working;
					job.nextRetry = now.delta(job.options.stale);
					return _update(job) >> function(_) return Some(job);
				}
				return Future.sync(Success(None));
			case Failure(err): return Future.sync(Failure(err));
		}
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
	
	function read():Outcome<Array<Job>, Error> {
		if(!sys.FileSystem.exists(path)) return Success([]);
		var data = sys.io.File.getContent(path);
		return try
			Success(haxe.Unserializer.run(data))
		catch(e:Dynamic) {
			Failure(Error.withData('Error during unserializing', e));
		}
	}
	
	function write(jobs:Array<Job>) {
		sys.io.File.saveContent(path, haxe.Serializer.run(jobs));
	}
}
#end