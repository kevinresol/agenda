package agenda.db.adapter;

#if (js_kit && futurize)

import haxe.ds.Option;
import haxe.Serializer;
import haxe.Unserializer;
import agenda.Job;
import agenda.db.adapter.MongooseAdapter.AttemptHelper.*;
import js.npm.mongoose.Mongoose;
using tink.CoreApi;
using DateTools;

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
	
	public function remove(id:String):Surprise<Noise, Error> {
		return @:futurize manager.remove({_id: id}, $cb0);
	}
	
	public function update(job:Job):Surprise<Noise, Error> {
		return @:futurize manager.update({_id: job.id}, toJobData(job), $cb) >>
			function(_) return Success(Noise);
	}
	
	public function next():Surprise<Option<Job>, Error> {
		var now = Date.now();
		return @:futurize manager.findOneAndUpdate({
			schedule: {"$lte": Date.now()},
			"$or": untyped [
				{status: Pending},
				{status: {"$in":[Errored, Working]}, nextRetry: {"$lte": now}},
			]
		}, {
			status: Working,
			nextRetry: now.delta(20000), // HACK: prevent others picking up this job, give us some time to update the nextRetry field later below
		}, {"new": true, sort: {'options.priority': -1, schedule: 1}}, $cb) >>
			function(job:AgendaJob)
				return if(job == null)
					Future.sync(Success(None))
				else {
					job.nextRetry = now.delta(job.options.stale);
					@:futurize job.save($cb) >>
						function(_) return Success(Some(job.toJob()));
				}
	}
	
	public function clear():Surprise<Noise, Error> {
		return @:futurize manager.remove({}, $cb0);
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
			recurring: switch job.recurring {
				case None: null;
				case Some(DayOfMonth(day, time)): {type: 'DayOfMonth', day: day, time: time}
				case Some(Interval(start, interval)): {type: 'Interval', start: start, interval: interval}
			}
		}
	}
}

class AttemptHelper {
	public static function toAttemptData(attempt:Attempt):AttemptData {
		return {
			outcome: Serializer.run(attempt.outcome),
			date: attempt.date,
			schedule: attempt.schedule,
		}
	}
	
	public static function toAttempt(data:AttemptData):Attempt {
		return new Attempt(Unserializer.run(data.outcome), data.schedule, data.date);
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
	recurring:{
		type:String,
		?day:Int,
		?time:Int,
		?start:Date,
		?interval:Int,
	},
}

typedef AttemptData = {
	outcome:String, // serialized
	date:Date,
	schedule:Date,
}

class AgendaJobManager extends js.npm.mongoose.macro.Manager<AgendaJobData, AgendaJob> {}

@:schemaOptions({
	autoIndex: true,
	typeKey: '__type__',
})
class AgendaJob extends js.npm.mongoose.macro.Model<AgendaJobData> {
	public function toJob():Job {
		return new Job({
			id: id,
			attempts: attempts.map(toAttempt),
			schedule: schedule,
			nextRetry: nextRetry,
			options: options,
			work: Unserializer.run(work),
			status: status,
			createDate: createDate,
			recurring: switch recurring {
				case null: None;
				case {type: 'DayOfMonth', day: day, time: time}: Some(DayOfMonth(day, time));
				case {type: 'Interval', start: start, interval: interval}: Some(Interval(start, interval));
				case _: None;
			}
		});
	}
}

#end