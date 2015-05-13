CalendarTile.MODE_RANGE                 = "range";
CalendarTile.MODE_FROM_DATE             = "from_date";


CalendarTile.ONLY_DATE_MOMENT_FORMAT    = "YYYY-MM-DD";

function CalendarTile($selector, params) {
    var calendarTile = this;
    calendarTile.$selector = $selector;
    calendarTile.initialParams = params;

    calendarTile.mCurrentFirstDay = moment().startOf("month").startOf("day");
    calendarTile.selectedDays = [];

    calendarTile.mode = calendarTile.initialParams.mode;
    if(!calendarTile.mode) {
        calendarTile.mode = CalendarTile.MODE_RANGE;
    }
    if(calendarTile.mode == CalendarTile.MODE_FROM_DATE) {
        calendarTile.selectedDays = [moment().format(CalendarTile.ONLY_DATE_MOMENT_FORMAT)];
    }

    calendarTile.$selector.html(HandlebarsTemplates['calendar_tile/main']());
    calendarTile.initActions();
    calendarTile.redraw();
}
CalendarTile.prototype.redraw = function() {
    var calendarTile = this;

    calendarTile.$selector.find(".month-container").html(calendarTile.mCurrentFirstDay.format("MMMM YYYY"));

    var dayNamesContainer = calendarTile.$selector.find(".day-names-container");
    dayNamesContainer.html("");
    var firstDay = calendarTile.mCurrentFirstDay.clone().startOf("week");

    var daysContainer = calendarTile.$selector.find(".days-container");
    daysContainer.html("");
    var lastDay = calendarTile.mCurrentFirstDay.clone().endOf("month").endOf("week");
    var currentDay = firstDay.clone();
    var currentWeek = null;
    while(currentDay <= lastDay) {
        if(dayNamesContainer.find(".day-name").length < 7) {
            var $dayName = $("<div>").addClass("day-name").html(currentDay.format("ddd"));
            dayNamesContainer.append($dayName);
        }

        if(currentWeek != currentDay.week()) {
            var $weekContainer = $("<div>").addClass("week-container").data("week", currentDay.format(CalendarTile.ONLY_DATE_MOMENT_FORMAT));
            var $weekSelectorContainer = $("<div>").addClass("week-selector-container");
            var $weekSelector = $("<div>").addClass("week-selector").data("week", currentDay.format(CalendarTile.ONLY_DATE_MOMENT_FORMAT));
            $weekSelectorContainer.append($weekSelector);
            $weekContainer.append($weekSelectorContainer);
            daysContainer.append($weekContainer);
            currentWeek = currentDay.week();
        }
        var $weekContainer = daysContainer.find(".week-container:last");

        var $day = $("<div>").addClass("day").html(currentDay.format("D")).data("day", currentDay.format(CalendarTile.ONLY_DATE_MOMENT_FORMAT));
        if(calendarTile.isDaySelected(currentDay.format(CalendarTile.ONLY_DATE_MOMENT_FORMAT))) {
            $day.addClass("selected");
        }

        if(currentDay.isSame(moment().startOf('day'))) {
            $day.addClass("today");
        }
        if(currentDay.month() == calendarTile.mCurrentFirstDay.month()) {
            $day.addClass("good-month");
        }
        else {
            $day.addClass("other-month");
        }
        $weekContainer.append($day);
        currentDay.add(1, 'day');
    }

    if(calendarTile.mode != "custom") {
        calendarTile.$selector.find(".week-container .week-selector").hide();
    }

    calendarTile.redrawImplicitSelectedDays();

    calendarTile.$selector.find(".week-container").each(function() {
         var $weekContainer = $(this);
         if($weekContainer.find(".day:not(.selected)").length == 0) {
             $weekContainer.find(".week-selector").addClass("selected");
         }
    });
};

CalendarTile.prototype.isDaySelected = function(day) {
    var calendarTile = this;
    return _(calendarTile.selectedDays).filter(function(selectedDay) {
        return selectedDay == day;
    }).length > 0;
};

CalendarTile.prototype.removeDayFromSelected = function(day) {
    var calendarTile = this;
    calendarTile.selectedDays = _(calendarTile.selectedDays).reject(function(selectedDay) {
        return selectedDay == day;
    });
};

CalendarTile.prototype.selectDay = function(day) {
    var calendarTile = this;
    if(calendarTile.mode == "from_date") {
        calendarTile.unselectAllDays();
    }

    calendarTile.$selector.find(".day").filter(function() {
        return $(this).data("day") == day;
    }).addClass("selected");


    if(!calendarTile.isDaySelected(day)) {
        calendarTile.selectedDays.push(day);
    }

    calendarTile.redrawImplicitSelectedDays();

    var $weekContainer = calendarTile.$selector.find(".week-container").filter(function() {
        return $(this).data("week") == moment(day).startOf("week").format(CalendarTile.ONLY_DATE_MOMENT_FORMAT);
    });
    if($weekContainer.find(".day:not(.selected)").length == 0) {
        $weekContainer.find(".week-selector").addClass("selected");
    }
};

CalendarTile.prototype.unselectDay = function(day) {
    var calendarTile = this;
    calendarTile.$selector.find(".day").filter(function() {
        return $(this).data("day") == day;
    }).removeClass("selected");

    calendarTile.removeDayFromSelected(day);

    var $weekContainer = calendarTile.$selector.find(".week-container").filter(function() {
        return $(this).data("week") == moment(day).startOf("week").format(CalendarTile.ONLY_DATE_MOMENT_FORMAT);
    });
    $weekContainer.find(".week-selector").removeClass("selected");
};
CalendarTile.prototype.unselectAllDays = function() {
    var calendarTile = this;
    calendarTile.selectedDays = [];
    calendarTile.$selector.find(".day").removeClass("selected");
    calendarTile.$selector.find(".day").removeClass("implicit-selected");
    calendarTile.$selector.find(".week-selector").removeClass("selected");
};
CalendarTile.prototype.toggleSelectDay = function(day) {
    var calendarTile = this;
    if(calendarTile.isDaySelected(day)) {
        calendarTile.unselectDay(day);
    }
    else {
        calendarTile.selectDay(day);
    }
};

CalendarTile.prototype.selectDayForRange = function(day) {
    var calendarTile = this;
    if(calendarTile.selectedDays.length == 0) {
        calendarTile.selectDay(day);
    }
    else if(calendarTile.selectedDays.length == 1) {
        calendarTile.selectDay(day);
    }
    else {
        calendarTile.unselectAllDays();
//        var minDay = _.min(calendarTile.selectedDays);
//        var maxDay = _.max(calendarTile.selectedDays);
//        var mediumDay =  minDay + (maxDay - minDay) / 2;
//        if(day > mediumDay) {
//            calendarTile.unselectDay(maxDay);
//        }
//        else {
//            calendarTile.unselectDay(minDay);
//        }
        calendarTile.selectDay(day);
    }
};

CalendarTile.prototype.redrawImplicitSelectedDays = function() {
    var calendarTile = this;
    calendarTile.$selector.find(".day").removeClass("implicit-selected");

    if(calendarTile.mode == "from_date") {
        if(calendarTile.selectedDays.length == 1) {
            calendarTile.$selector.find(".day").each(function() {
                if(moment($(this).data("day")) > moment(calendarTile.selectedDays[0])) {
                    $(this).addClass("implicit-selected");
                }
            });
        }
    }
    else if(calendarTile.mode == "range") {
        if(calendarTile.selectedDays.length == 2) {
            calendarTile.$selector.find(".day").each(function() {
                if(moment($(this).data("day")) > _.min(_.map(calendarTile.selectedDays, function(day) {return moment(day);})) &&
                    moment($(this).data("day")) < _.max(_.map(calendarTile.selectedDays, function(day) {return moment(day);}))) {
                    $(this).addClass("implicit-selected");
                }
            });
        }
    }
};

CalendarTile.prototype.selectionChangedCallback = function() {
    var calendarTile = this;
    if(calendarTile.initialParams.selectionChangedCallback) {
        calendarTile.initialParams.selectionChangedCallback();
    }
};

CalendarTile.prototype.initActions = function() {
    var calendarTile = this;

    calendarTile.$selector.find(".back-button").click(function() {
        if(calendarTile.$selector.find("calendar-tile").hasClass("disabled")) return;

        calendarTile.mCurrentFirstDay.add(-1, 'month');
        calendarTile.redraw();
    });
    calendarTile.$selector.find(".next-button").click(function() {
        if(calendarTile.$selector.find("calendar-tile").hasClass("disabled")) return;

        calendarTile.mCurrentFirstDay.add(1, 'month');
        calendarTile.redraw();
    });

    calendarTile.$selector.find(".calendar-tile").on("click", ".day", function() {
        if(calendarTile.$selector.find("calendar-tile").hasClass("disabled")) return;

        var day = $(this).data("day");
        if(calendarTile.mode == "custom") {
            calendarTile.toggleSelectDay(day);
        }
        else if(calendarTile.mode == "from_date") {
            calendarTile.selectDay(day);
        }
        else if(calendarTile.mode == "range") {
            calendarTile.selectDayForRange(day);
        }
        calendarTile.selectionChangedCallback();
    });

    calendarTile.$selector.find(".calendar-tile").on("click", ".week-selector", function() {
        if(calendarTile.$selector.find("calendar-tile").hasClass("disabled")) return;

        if($(this).hasClass("selected")) {
            $(this).closest(".week-container").find(".day").each(function() {
                var day = $(this).data("day");
                calendarTile.unselectDay(day);
            });
        }
        else {
            $(this).closest(".week-container").find(".day").each(function() {
                var day = $(this).data("day");
                calendarTile.selectDay(day);
            });
        }
        calendarTile.selectionChangedCallback();
    });
};