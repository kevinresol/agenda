package agenda.db;

import haxe.ds.Option;
using tink.CoreApi;

/**
	A database adapter.
	
	Notes to implementors:
	- Each of the following actions must be atomic. (especially `next()`)
**/
interface Adapter {
	/**
		Add a new Job to the database
	**/
	function add(job:Job):Surprise<Noise, Error>;
	
	/**
		Remove a Job from the database
	**/
	function remove(id:String):Surprise<Noise, Error>;
	
	/**
		Update a Job in the database (match it by job.id)
	**/
	function update(job:Job):Surprise<Noise, Error>;
	
	/**
		Get the next executable Job from the database. 
		
		Executable job is one of the following:
		- `status == Pending`
		- `status == Errored && now > nextRetry` (errored jobs to be retried)
		- `status == Working && now > nextRetry` (stale / hang jobs)
		
		When one is fetched, the job status must be updated (atomically) to `Working`,
		and nextRetry must be set to `now + options.stale`
		That would prevent multiple workers to fetch and execute the same job.
	**/
	function next():Surprise<Option<Job>, Error>;
	
	/**
		Clear all jobs.
	**/
	function clear():Surprise<Noise, Error>;
}
