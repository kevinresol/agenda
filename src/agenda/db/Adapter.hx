package agenda.db;

import haxe.ds.Option;
using tink.CoreApi;
using Lambda;

interface Adapter {
	function add(job:Job):Surprise<Noise, Error>;
	function remove(job:Job):Surprise<Noise, Error>;
	function update(job:Job):Surprise<Noise, Error>;
	function next():Surprise<Option<Job>, Error>;
}
