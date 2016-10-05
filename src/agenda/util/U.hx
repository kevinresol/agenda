package agenda.util;

class U {
	public static function nextDayOfMonth(target:Int):Date {
		var now = Date.now();
		var year = now.getFullYear();
		var month = now.getMonth();
		var day = now.getDay();
		if(day < target) {
			// do nothing
		} else if(month == 11) {
			month = 0;
			year++;
		} else {
			month++;
		}
		return new Date(year, month, target, 0, 0, 0);
	}
}