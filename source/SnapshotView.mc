using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class SnapshotView extends Ui.DataField {

	var firstFieldMode;
	var firstField;
	var firstFieldLabel;

	var secondFieldMode;
	var secondField;
	var secondFieldLabel;

	var thirdFieldMode;
	var thirdField;
	var thirdFieldLabel;

	var forthFieldMode;
	var forthField;
	var forthFieldLabel;

	var timerFieldMode;
	var batteryField;
	var batteryFieldOffset;

	var speed;
	var currentLap;
	var previousLapDist;
	var previousLapTime;
	var lapSplit;
	var split;

	var timer;
	var timerType;
	var timer_x;
	var timer_y;
	var timerLabel_y;

	var timeField;
	var timeFieldOffset;

	var invertMiddleBackground;
	var foregroundColour;
	var backgroundColour;


	function initialize() {

		DataField.initialize();

		var usePreferences = 1;
		
		var background = 1;  // 0=white; 1=black
		invertMiddleBackground = true;  // ... of the middle two fields only
		timerType = 0; // 0=timer, 1=total elapsed time
		lapSplit = 1.0; // lap split in km or miles

		// 0=dist, 1=curPace, 2=lapPace, 3=avePace, 4=HR, 5=aveHR, 6=Cadence, 7=aveCadence
		firstFieldMode = 4;
		secondFieldMode = 6;
		thirdFieldMode = 2;
		forthFieldMode = 0;		
		timerFieldMode = true;  // true=timer AND time+battery

		if (usePreferences == 1) {
			background = Application.getApp().getProperty("blackBackground");
			invertMiddleBackground = Application.getApp().getProperty("invertMiddleBackground");
			firstFieldMode = Application.getApp().getProperty("firstFieldMode");
			secondFieldMode = Application.getApp().getProperty("secondFieldMode");
			thirdFieldMode = Application.getApp().getProperty("thirdFieldMode");
			forthFieldMode = Application.getApp().getProperty("forthFieldMode");
			lapSplit = Application.getApp().getProperty("lapSplit");
			timerType = Application.getApp().getProperty("timerType");
			timerFieldMode = Application.getApp().getProperty("timerFieldMode");
		}

		if (background == 1) {
			foregroundColour = Gfx.COLOR_WHITE;
			backgroundColour = Gfx.COLOR_BLACK;
		} else {
			foregroundColour = Gfx.COLOR_BLACK;
			backgroundColour = Gfx.COLOR_WHITE;
		}

		timeFieldOffset = 0;
		batteryFieldOffset = 0;

		if (timerFieldMode == true) {
			timer_x = 77;
			timer_y = 143;
			timerLabel_y = 170;
		} else {
			timer_x = 107.5;
			timer_y = 159;
			timerLabel_y = 133;
		}

		if (Sys.getDeviceSettings().distanceUnits == Sys.UNIT_METRIC) {
			split = 1000.0;
		} else {
			split = 1609.0;
		}

		if (lapSplit == null || lapSplit <= 0 || lapSplit > 100) {
			lapSplit = 1.0;
		}
		lapSplit = lapSplit * split;
		
		currentLap = 1;
		previousLapDist = 0.0;
		previousLapTime = 0.0;

	}


	function onLayout(dc) {
	}

	function onShow() {
	}

	function onHide() {
	}


	function onUpdate(dc) {

		dc.setColor(foregroundColour, backgroundColour);
		dc.clear();
		dc.setColor(foregroundColour, Gfx.COLOR_TRANSPARENT);

		// UPDATE FIELDS

		textC(dc, timer_x, timer_y, Gfx.FONT_NUMBER_MEDIUM, timer);
		textC(dc, timer_x, timerLabel_y, Gfx.FONT_XTINY,  "Timer");

		if (timerFieldMode == true) {
			textL(dc, 140 - timeFieldOffset, 138, Gfx.FONT_LARGE, timeField);
			textL(dc, 140 + batteryFieldOffset, 164, Gfx.FONT_LARGE, batteryField);
			var length = dc.getTextWidthInPixels(batteryField, Gfx.FONT_LARGE);
			textL(dc, 140 + length + batteryFieldOffset, 162, Gfx.FONT_MEDIUM, "%");
		}

		textC(dc, 65, 33, Gfx.FONT_NUMBER_MEDIUM, firstField);
		textC(dc, 65, 7, Gfx.FONT_XTINY, firstFieldLabel);

		textC(dc, 147, 33, Gfx.FONT_NUMBER_MEDIUM, secondField);
		textC(dc, 147, 7, Gfx.FONT_XTINY, secondFieldLabel);

		if (invertMiddleBackground == true) {
			// invert the colours of the middle two fields
			dc.setColor(foregroundColour, foregroundColour);	
			dc.fillRectangle(0, 57, 215, 65);
			dc.setColor(backgroundColour, Gfx.COLOR_TRANSPARENT);	
		}

		textC(dc, 54, 94, Gfx.FONT_NUMBER_HOT, thirdField);
		textC(dc, 54, 66, Gfx.FONT_XTINY,  thirdFieldLabel);

		textC(dc, 161, 94, Gfx.FONT_NUMBER_HOT, forthField);
		textC(dc, 161, 66, Gfx.FONT_XTINY,  forthFieldLabel);

		// DRAW LINES

		dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);

		// top horizontal lines
		dc.drawLine(0, 56, 215, 56);
		dc.drawLine(0, 57, 215, 57);

		// bottom horizontal lines
		dc.drawLine(0, 122, 215, 122);
		dc.drawLine(0, 123, 215, 123);

		// top vertical lines
		dc.drawLine(107, 0, 107, 124);
		dc.drawLine(108, 0, 108, 124);

		// bottom vertical lines

		if (timerFieldMode == true) {
			dc.drawLine(134, 124, 134, 180);
			dc.drawLine(135, 124, 135, 180);
		}

		return true;
	}


	function compute(info) {

		if (firstFieldMode == 0) {
			firstFieldLabel = "Distance";
			firstField = toDist(info.elapsedDistance);
		} else if (firstFieldMode == 1) {
			firstFieldLabel = "Cur Pace";
			firstField = fmtSecs(toPace(info.currentSpeed));
		} else if (firstFieldMode == 2) {
			firstFieldLabel = "Lap Pace";
			firstField = fmtSecs(calculateLapPace(info.elapsedDistance, info.timerTime));
		} else if (firstFieldMode == 3) {
			firstFieldLabel = "Ave Pace";
			firstField = fmtSecs(toPace(info.averageSpeed));
		} else if (firstFieldMode == 4) {
			firstFieldLabel = "Heart";
			firstField = toStr(info.currentHeartRate);
		} else if (firstFieldMode == 5) {
			firstFieldLabel = "Ave HR";
			firstField = toStr(info.averageHeartRate);
		} else if (firstFieldMode == 6) {
			firstFieldLabel = "Cadence";
			firstField = toStr(info.currentCadence);
		} else if (firstFieldMode == 7) {
			firstFieldLabel = "Ave Cad";
			firstField = info.averageCadence;
			if (firstField != null) {
				firstField = firstField * 2;
			}
			firstField = toStr(firstField);
		} else {
			firstFieldLabel = "Heart";
			firstField = toStr(info.currentHeartRate);
		}


		if (secondFieldMode == 0) {
			secondFieldLabel = "Distance";
			secondField = toDist(info.elapsedDistance);
		} else if (secondFieldMode == 1) {
			secondFieldLabel = "Cur Pace";
			secondField = fmtSecs(toPace(info.currentSpeed));
		} else if (secondFieldMode == 2) {
			secondFieldLabel = "Lap Pace";
			secondField = fmtSecs(calculateLapPace(info.elapsedDistance, info.timerTime));
		} else if (secondFieldMode == 3) {
			secondFieldLabel = "Ave Pace";
			secondField = fmtSecs(toPace(info.averageSpeed));
		} else if (secondFieldMode == 4) {
			secondFieldLabel = "Heart";
			secondField = toStr(info.currentHeartRate);
		} else if (secondFieldMode == 5) {
			secondFieldLabel = "Ave HR";
			secondField = toStr(info.averageHeartRate);
		} else if (secondFieldMode == 6) {
			secondFieldLabel = "Cadence";
			secondField = toStr(info.currentCadence);
		} else if (secondFieldMode == 7) {
			secondFieldLabel = "Ave Cad";
			secondField = info.averageCadence;
			if (secondField != null) {
				secondField = secondField * 2;
			}
			secondField = toStr(secondField);
		} else {
			secondFieldLabel = "Cadence";
			secondField = toStr(info.currentCadence);
		}


		if (thirdFieldMode == 0) {
			thirdFieldLabel = "Distance";
			thirdField = toDist(info.elapsedDistance);
		} else if (thirdFieldMode == 1) {
			thirdFieldLabel = "Current Pace";
			thirdField = fmtSecs(toPace(info.currentSpeed));
		} else if (thirdFieldMode == 2) {
			thirdFieldLabel = "Lap Pace";
			thirdField = fmtSecs(calculateLapPace(info.elapsedDistance, info.timerTime));
		} else if (thirdFieldMode == 3) {
			thirdFieldLabel = "Ave Pace";
			thirdField = fmtSecs(toPace(info.averageSpeed));
		} else if (thirdFieldMode == 4) {
			thirdFieldLabel = "Heart Rate";
			thirdField = toStr(info.currentHeartRate);
		} else if (thirdFieldMode == 5) {
			thirdFieldLabel = "Ave Heart Rate";
			thirdField = toStr(info.averageHeartRate);
		} else if (thirdFieldMode == 6) {
			thirdFieldLabel = "Cadence";
			thirdField = toStr(info.currentCadence);
		} else if (thirdFieldMode == 7) {
			thirdFieldLabel = "Ave Cadence";
			thirdField = info.averageCadence;
			if (thirdField != null) {
				thirdField = thirdField * 2;
			}
			thirdField = toStr(thirdField);
		} else {
			thirdFieldLabel = "Lap Pace";
			thirdField = fmtSecs(calculateLapPace(info.elapsedDistance, info.timerTime));
		}


		if (forthFieldMode == 0) {
			forthFieldLabel = "Distance";
			forthField = toDist(info.elapsedDistance);
		} else if (forthFieldMode == 1) {
			forthFieldLabel = "Current Pace";
			forthField = fmtSecs(toPace(info.currentSpeed));
		} else if (forthFieldMode == 2) {
			forthFieldLabel = "Lap Pace";
			forthField = fmtSecs(calculateLapPace(info.elapsedDistance, info.timerTime));
		} else if (forthFieldMode == 3) {
			forthFieldLabel = "Ave Pace";
			forthField = fmtSecs(toPace(info.averageSpeed));
		} else if (forthFieldMode == 4) {
			forthFieldLabel = "Heart Rate";
			forthField = toStr(info.currentHeartRate);
		} else if (forthFieldMode == 5) {
			forthFieldLabel = "Ave Heart Rate";
			forthField = toStr(info.averageHeartRate);
		} else if (forthFieldMode == 6) {
			forthFieldLabel = "Cadence";
			forthField = toStr(info.currentCadence);
		} else if (forthFieldMode == 7) {
			forthFieldLabel = "Ave Cadence";
			forthField = info.averageCadence;
			if (forthField != null) {
				forthField = forthField * 2;
			}
			forthField = toStr(forthField);
		} else {
			forthFieldLabel = "Distance";
			forthField = toDist(info.elapsedDistance);
		}


		var time;
		if (timerType == 1) {
			time = info.elapsedTime;
		} else {
			time = info.timerTime;
		}

		if (time != null) {
			time /= 1000;
		} else {
			time = 0.0;
		}

		timer = fmtSecs(time);


		if (timerFieldMode == true) {
		
			timeField = fmtTime(Sys.getClockTime());
			batteryField = Sys.getSystemStats().battery;
			batteryFieldOffset = 0;

			if (batteryField > 99) {
				batteryField = 99;
			} else {
				if (batteryField < 10) {
					batteryFieldOffset = 5;
				}
			}

			batteryField = toStr(batteryField.toNumber());
		}

	}


	function calculateLapPace(distance, time) {

		if (time != null) {
			time /= 1000;
		} else {
			time = 0.0;
		}

		if (time > 0 && distance != null && distance > 0) {

			if (distance - previousLapDist > 0 && time - previousLapTime > 0) {
				speed = (distance - previousLapDist) / (time - previousLapTime);

				if (speed < 0.5) {
					speed = 0;
				}

			} else {
				speed = speed;
			}

			if (distance > lapSplit * currentLap) {
				previousLapDist = distance;
				previousLapTime = time;
				currentLap += 1;
			}

		} else {
			speed = null;
		}
		
		//Sys.println(""+fmtSecs(toPace(speed))+" - "+fmtSecs(toPace(info.averageSpeed))+" - "+fmtSecs(toPace(info.currentSpeed)));

		return toPace(speed);

	}


	function toStr(o) {
		if (o != null && o > 0) {
			return "" + o;
		} else {
			return "---";
		}
	}


	function fmtTime(clock) {

		var h = clock.hour;
		timeFieldOffset = 0;

		if (!Sys.getDeviceSettings().is24Hour) {
			if (h > 12) {
				h -= 12;
			} else if (h == 0) {
				h += 12;
			}
		}

		if (h >= 10) {
			timeFieldOffset = 2;
		}

		return "" + h + ":" + clock.min.format("%02d");
	}

	function fmtSecs(secs) {

		if (secs == null) {
			return "---";
		}

		var s = secs.toLong();
		var hours = s / 3600;
		s -= hours * 3600;
		var minutes = s / 60;
		s -= minutes * 60;

		var fmt;
		if (hours > 0) {
			fmt = "" + hours + ":" + minutes.format("%02d") + ":" + s.format("%02d");
		} else {
			fmt = "" + minutes + ":" + s.format("%02d");
		}

		return fmt;
	}


	function toPace(speed) {
		if (speed == null || speed == 0) {
		return null;
		}

		return split / speed;
	}


	function toDist(dist) {
		if (dist == null) {
			return "0.00";
		}

		dist = dist / split;
		return dist.format("%.2f");
	}


	function textL(dc, x, y, font, s) {
		if (s != null) {
			dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}


	function textC(dc, x, y, font, s) {
		if (s != null) {
			dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}

}