package agenda.db.adapter;

#if (js_kit && futurize)

import haxe.ds.Option;
import haxe.Serializer;
import haxe.Unserializer;
import agenda.Job;
import js.npm.mongoose.Mongoose;
using tink.CoreApi;

@:build(futurize.Futurize.build())
class MongooseAdapter implements agenda.db.Adapter {
	
	var manager:AgendaJobManager;
	
	public function new(connectionString:String) {
		var mongoose = new Mongoose();
		mongoose.connect(connectionString);
		manager = AgendaJobManager.build(mongoose, 'AgendaJob');
	}
	
	public function add(job:Job):Surprise<Noise, Error> {
		return @:futurize manager.create(toJobData(job), $cb) >>
			function(_) return Success(Noise);
	}
	
	public function update(job:Job):Surprise<Noise, Error> {
		return @:futurize manager.update({_id: job.id}, toJobData(job), $cb) >>
			function(result) return result.ok == 1 ? Success(Noise) : Failure(tink.core.Error.withData('Mongoose update error', result));
	}
	
	public function next():Surprise<Option<Job>, Error> {
		return @:futurize manager.findOne({
			schedule: {"$lte": Date.now()},
			"$or": untyped [
				{status: Pending},
				{status: Error, nextRetry: {"$lte": Date.now()}},
			]
		}, $cb) >>
			function(job:AgendaJob) return job == null ? Success(None) : Success(Some(job.toJob(toAttempt)));
	}
	
	function toJobData(job:Job):AgendaJobData {
		return {
			_id: job.id,
			attempts: job.attempts.map(toAttemptData),
			schedule: job.schedule,
			nextRetry: job.nextRetry,
			options: job.options,
			work: Serializer.run(job.work),
			status: job.status,
			createDate: job.createDate,
		}
	}
	
	function toAttemptData(attempt:Attempt):AttemptData {
		return {
			outcome: Serializer.run(attempt.outcome),
			date: attempt.date,
		}
	}
	
	function toAttempt(data:AttemptData):Attempt {
		return new Attempt(Unserializer.run(data.outcome), data.date);
	}
}

typedef AgendaJobData = {
	_id:String,
	attempts:Array<AttemptData>,
	schedule:Date,
	nextRetry:Date,
	options:JobOptions,
	work:String,
	status:JobStatus,
	createDate:Date,
}

typedef AttemptData = {
	outcome:String, // serialized
	date:Date,
}

class AgendaJobManager extends js.npm.mongoose.macro.Manager<AgendaJobData, AgendaJob> {}

@:schemaOptions({
	autoIndex: true,
	typeKey: '__type__',
})
class AgendaJob extends js.npm.mongoose.macro.Model<AgendaJobData> {
	public function toJob(toAttempt):Job {
		return new Job({
			id: id,
			attempts: attempts.map(toAttempt),
			schedule: schedule,
			nextRetry: nextRetry,
			options: options,
			work: Unserializer.run(work),
			status: status,
			createDate: createDate,
		});
	}
}

#end