package agenda.db;

import haxe.ds.Option;
using tink.CoreApi;
using Lambda;

interface Adapter {
	function add(job:Job):Surprise<Noise, Error>;
	function update(item:Item):Surprise<Noise, Error>;
	function next():Surprise<Option<Item>, Error>;
	function generateId():Future<String>;
}

#if agenda_mongo
class MongoAdapter implements Adapter {
	
	public function new() {
		
	}
	
	public function add(job:Job):Surprise<Noise, Error> {
		throw "not implemented";
	}
	
	public function update(item:Item):Surprise<Noise, Error> {
		throw "not implemented";
	}
	
	public function next():Surprise<Option<Item>, Error> {
		throw "not implemented";
	}
	
	public function generateId():Future<String> {
		
	}
}
#end

#if agenda_file
class FileAdapter implements Adapter {
	
	var path:String;
	
	public function new(path:String) {
		this.path = sys.FileSystem.absolutePath(path);
	}
	
	public function add(job:Job):Surprise<Noise, Error> {
		return isolate(_add.bind(job));
	}
	
	public function update(item:Item):Surprise<Noise, Error> {
		return isolate(_update.bind(item));
	}
	
	public function next():Surprise<Option<Item>, Error> {
		return isolate(_next);
	}
	
	function _add(job:Job):Surprise<Noise, Error> {
		var items = read();
		return generateId() >>
			function(id:String) {
				items.push(new Item(id, job));
				write(items);
				return Success(Noise);
			}
	}
	
	function _update(item:Item):Surprise<Noise, Error> {
		var items = read();
		for(i in 0...items.length) {
			if(items[i].id == item.id) {
				items.splice(i, 1);
				items.insert(i, item);
				write(items);
				break;
			}
		}
		return Future.sync(Success(Noise));
	}
	
	function _next():Surprise<Option<Item>, Error> {
		var now = Date.now().getTime();
		var items = read();
		for(item in items)
		if(now > item.job.schedule.getTime() && item.status == Pending) {
			item.status = Working;
			return _update(item) >> function(_) return Some(item);
		}
		return Future.sync(Success(None));
	}
	
	public function generateId():Future<String> {
		return Future.sync(haxe.crypto.Sha1.encode(Math.random() + '-' + Date.now().getTime()));
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
	
	function read():Array<Item> {
		var data = sys.io.File.getContent(path);
		return try haxe.Unserializer.run(data) catch(e:Dynamic) [];
	}
	
	function write(items:Array<Item>) {
		sys.io.File.saveContent(path, haxe.Serializer.run(items));
	}
}

// enum Action {
// 	Add
// }
#end