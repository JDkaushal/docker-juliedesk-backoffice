function ConstraintTile($selector, params) {

    this.daysOfWeek = {
        "0": "monday",
        "1": "tuesday",
        "2": "wednesday",
        "3": "thursday",
        "4": "friday",
        "5": "saturday",
        "6": "sunday"
    };
    this.possibleAttendees = [];
    if(params.possibleAttendees) this.possibleAttendees = params.possibleAttendees;
    this.$selector = $selector;
    this.locale = params.locale;
    this.timezone = params.timezone;

    var constraintTile = this;

    constraintTile.redraw();

    if(params.data) {
        constraintTile.$selector.find(".constraint-attendee-email").val(params.data.attendee_email);
        constraintTile.$selector.find(".constraint-nature").val(params.data.constraint_nature);
        //constraintTile.$selector.find(".constraint-repeat-every").val(params.data.repeat);
        if(params.data.start_date && params.data.end_date) {
            var startDate = moment(params.data.start_date);
            var endDate = moment(params.data.end_date);

            constraintTile.$selector.find(".constraint-start-hours").val(startDate.format("HH"));
            constraintTile.$selector.find(".constraint-end-hours").val(endDate.format("HH"));
            constraintTile.$selector.find(".constraint-start-minutes").val(startDate.format("mm"));
            constraintTile.$selector.find(".constraint-end-minutes").val(endDate.format("mm"));

            constraintTile.$selector.find(".constraint-start-time-end-time-nature").val("custom");
        }
        else {
            constraintTile.$selector.find(".constraint-start-hours").val(12);
            constraintTile.$selector.find(".constraint-end-hours").val(13);
            constraintTile.$selector.find(".constraint-start-minutes").val(0);
            constraintTile.$selector.find(".constraint-end-minutes").val(0);

            constraintTile.$selector.find(".constraint-start-time-end-time-nature").val("all-day");
        }
        constraintTile.$selector.find(".timezone").val(params.data.timezone);


        //constraintTile.$selector.find(".constraint-start-date").datepicker("setDate", startDate.toDate());
        //constraintTile.$selector.find(".constraint-end-date").datepicker("setDate", endDate.toDate());


        constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type=checkbox]").prop("checked", false);
        _.each(params.data.days_of_weeks, function(dayOfWeek) {
            constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type=checkbox][value='" + dayOfWeek + "']").prop("checked", true);
        });
        var startRecurring = moment(params.data.start_recurring);
        constraintTile.$selector.find(".constraint-start-recurring").datepicker("setDate", startRecurring.toDate());

        var endRecurring = moment(params.data.end_recurring);
        constraintTile.$selector.find(".constraint-end-recurring").datepicker("setDate", endRecurring.toDate());

        constraintTile.$selector.find(".constraint-when-nature").val("custom");

        constraintTile.redrawDatesContainer();
        constraintTile.redrawTimesContainer();
        constraintTile.redrawSentence();
    }
}

ConstraintTile.prototype.redraw = function() {
    var constraintTile = this;
    constraintTile.$selector.html(HandlebarsTemplates['constraint_tile/main']());
    _(this.possibleAttendees).each(function(attendee) {
        constraintTile.$selector.find(".constraint-attendee-email").append($("<option>").val(attendee.email).html(attendee.name + " (" + attendee.email + ")"));
    });

    constraintTile.$selector.find("input.constraint-start-date").datepicker().datepicker("setDate", "-0d");
    constraintTile.$selector.find("input.constraint-end-date").datepicker().datepicker("setDate", "-0d");

    constraintTile.$selector.find("input.constraint-start-hours").val(12);
    constraintTile.$selector.find("input.constraint-start-minutes").val(0);

    constraintTile.$selector.find("input.constraint-end-hours").val(13);
    constraintTile.$selector.find("input.constraint-end-minutes").val(0);

    constraintTile.$selector.find("input.constraint-start-recurring").datepicker().datepicker("setDate", "-0d");
    constraintTile.$selector.find("input.constraint-end-recurring").datepicker().datepicker("setDate", "+15d");

    var index = $(".constraint-tile").index(constraintTile.$selector.find(".constraint-tile"));
    constraintTile.$selector.find("input[type=radio].end-recurring").attr("name", "end-recurring-" + index);

    constraintTile.redrawDatesContainer();
    constraintTile.redrawTimesContainer();

    constraintTile.initActions();
    constraintTile.redrawSentence();

    constraintTile.$selector.find(".timezone").timezonePicker();
    constraintTile.$selector.find(".timezone").val(constraintTile.timezone);
};

ConstraintTile.prototype.getWhenNature = function() {
    var constraintTile = this;
    return constraintTile.$selector.find(".constraint-when-nature").val();
};

ConstraintTile.prototype.getStartEndTimeNature = function() {
    var constraintTile = this;
    return constraintTile.$selector.find(".constraint-start-time-end-time-nature").val();
};

ConstraintTile.prototype.redrawTimesContainer = function() {
    var constraintTile = this;
    if(constraintTile.getStartEndTimeNature() == "all-day") {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").hide();
    }
    else {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").show();
    }
};

ConstraintTile.prototype.redrawDatesContainer = function() {
    var constraintTile = this;
    constraintTile.$selector.find(".constraints-start-end-recurring-container").hide();
    constraintTile.$selector.find(".constraints-start-end-recurring-container *").show();
    if(constraintTile.getWhenNature() == "this-week") {
        constraintTile.$selector.find("input.constraint-start-recurring").val(moment().startOf("week").format("MM/DD/YYYY"));
        constraintTile.$selector.find("input.constraint-end-recurring").val(moment().endOf("week").format("MM/DD/YYYY"));

    }
    else if(constraintTile.getWhenNature() == "next-week") {
        var mStart = moment().startOf("week");
        var mEnd = moment().endOf("week");
        mStart.add("w", 1);
        mEnd.add("w", 1);
        constraintTile.$selector.find("input.constraint-start-recurring").val(mStart.format("MM/DD/YYYY"));
        constraintTile.$selector.find("input.constraint-end-recurring").val(mEnd.format("MM/DD/YYYY"));
    }
    else if(constraintTile.getWhenNature() == "from-date") {
        constraintTile.$selector.find(".constraints-start-end-recurring-container").show();
        constraintTile.$selector.find(".constraints-start-end-recurring-container *").hide();
        constraintTile.$selector.find(".constraints-start-end-recurring-container .constraint-start-recurring").show();
        var mEnd = moment();
        mEnd.add("y", 1);
        constraintTile.$selector.find("input.constraint-end-recurring").val(mEnd.format("MM/DD/YYYY"));
    }
    else if(constraintTile.getWhenNature() == "always") {
        var mStart = moment().startOf("week");
        var mEnd = moment();
        mEnd.add("y", 1);
        constraintTile.$selector.find("input.constraint-start-recurring").val(mStart.format("MM/DD/YYYY"));
        constraintTile.$selector.find("input.constraint-end-recurring").val(mEnd.format("MM/DD/YYYY"));

    }
    else {
        constraintTile.$selector.find(".constraints-start-end-recurring-container").show();
    }

    var data = constraintTile.getData();
    var distanceStartRecurringEndRecurring = (moment(data.end_recurring).endOf("week") - moment(data.start_recurring).startOf("week")) / (3600 * 1000 * 24);

    constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type='checkbox']").each(function() {
        var dayIndex = parseInt($(this).val());
        var date = moment(data.start_recurring).startOf("week");
        date.add(dayIndex, "day");

        $(this).prop("disabled", false);

        if(distanceStartRecurringEndRecurring <= 7) {
            $(this).next().html(date.format("ddd D/MM"));
            if(date < moment(data.start_recurring) || date > moment(data.end_recurring)) {
                $(this).prop("disabled", true);
                $(this).prop("checked", false);
            }
        }
        else {
            $(this).next().html(date.format("ddd"));
        }
    });


};

ConstraintTile.prototype.checkDates = function() {
    var constraintTile = this;
    var data = constraintTile.getData();
    if(moment(data.end_date) <= moment(data.start_date)) {
        constraintTile.$selector.find("input.constraint-end-date").val(constraintTile.$selector.find("input.constraint-start-date").val());
        constraintTile.$selector.find("input.constraint-end-hours").val(parseInt(constraintTile.$selector.find("input.constraint-start-hours").val(), 10) + 1);
        constraintTile.$selector.find("input.constraint-end-minutes").val(constraintTile.$selector.find("input.constraint-start-minutes").val());
    }
};

ConstraintTile.prototype.initActions = function() {
  var constraintTile = this;

    constraintTile.$selector.find(".constraint-when-nature").change(function(e) {
        constraintTile.redrawDatesContainer();
    });
    constraintTile.$selector.find(".constraint-start-recurring, .constraint-end-recurring").change(function(e) {
        constraintTile.redrawDatesContainer();
    });

    constraintTile.$selector.find(".constraint-start-time-end-time-nature").change(function(e) {
        constraintTile.redrawTimesContainer();
    });

    constraintTile.$selector.find("*").change(function(e) {
        constraintTile.checkDates();
        constraintTile.redrawSentence();
    });

    constraintTile.$selector.find(".timezone").autocomplete({
        change: function( event, ui ) {
            constraintTile.checkDates();
            constraintTile.redrawSentence();
        }
    });

    constraintTile.$selector.find(".remove-constraint-button").click(function() {
        constraintTile.$selector.remove();
    });

    constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week ").click(function(e) {
        if(!$(e.target).is("input")) {
            var $input = $(this).find("input");
            $input.prop('checked', !$input.prop("checked")).change();
        }
    });

    constraintTile.$selector.find(".quick-selectors .select-all").click(function() {
        $(this).closest(".constraint-dates-days-of-week-container").find("input[type=checkbox]").prop('checked', true).change();
    });

    constraintTile.$selector.find(".quick-selectors .unselect-all").click(function() {
        $(this).closest(".constraint-dates-days-of-week-container").find("input[type=checkbox]").prop('checked', false).change();
    });

    constraintTile.$selector.find(".quick-time-selectors .select-morning").click(function() {
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-start-hours").val(8);
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-start-minutes").val(0);
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-end-hours").val(12);
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-end-minutes").val(0).change();
    });

    constraintTile.$selector.find(".quick-time-selectors .select-afternoon").click(function() {
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-start-hours").val(14);
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-start-minutes").val(0);
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-end-hours").val(22);
        $(this).closest(".constraint-start-hours-end-hours-container").find(".constraint-end-minutes").val(0).change();
    });
};



ConstraintTile.prototype.redrawSentence = function() {
    var constraintTile = this;
    var oldLocale = getCurrentLocale();
    setCurrentLocale(constraintTile.locale);

    var sentence = "";
    data = constraintTile.getData();
    var attendee = _.find(constraintTile.possibleAttendees, function(attendee) {
        return attendee.email == data.attendee_email;
    });
    var attendeeName = data.attendee_email;
    if(attendee) {
        attendeeName = attendee.name;
    }
    sentence += attendeeName + " " + localize("constraints." + data.constraint_nature);


    if(data.repeat == "never") {
        sentence += " " + localize("constraints.from") + " " + moment(data.start_date).locale(constraintTile.locale).format(localize("email_templates.common.full_date_format")) + " " + localize("constraints.to") + " " + moment(data.end_date).locale(constraintTile.locale).format(localize("email_templates.common.full_date_format"));
    }
    else if(data.repeat == "dayly") {
        sentence += " " + localize("constraints.every_day");
    }
    else if(data.repeat == "weekly") {
        if(data.days_of_weeks.length == 7) {
            sentence += " " + localize("constraints.every_day");
        }
        else {
            sentence += " " + localize("constraints.on_days") + " " + _.map(data.days_of_weeks, function(dayOfWeek) {
                return moment().locale(constraintTile.locale).day(dayOfWeek).format("dddd");
            }).join(", ");
        }
    }
    if(data.start_date) {
        sentence += " " + localize("constraints.from") + " " + moment(data.start_date).locale(constraintTile.locale).format("HH:mm") + " " + localize("constraints.to") + " " + moment(data.end_date).locale(constraintTile.locale).format("HH:mm");
    }
    if(data.repeat != "never") {
        sentence += ", " + localize("constraints.starting_on") + " " + moment(data.start_recurring).locale(constraintTile.locale).format("dddd DD MMMM YYYY")
        sentence += ", " + localize("constraints.ending_on") + " " + moment(data.end_recurring).locale(constraintTile.locale).format("dddd DD MMMM YYYY")
    }
    constraintTile.$selector.find(".constraint-sentence").html(sentence);
    constraintTile.$selector.data("constraint", data);

    setCurrentLocale(oldLocale);
};

ConstraintTile.prototype.getData = function() {
    var constraintTile = this;

    var startDate = moment();
    startDate.set("h", constraintTile.$selector.find(".constraint-start-hours").val());
    startDate.set("m", constraintTile.$selector.find(".constraint-start-minutes").val());
    startDate = startDate.format();

    var endDate = moment();
    endDate.set("h", constraintTile.$selector.find(".constraint-end-hours").val());
    endDate.set("m", constraintTile.$selector.find(".constraint-end-minutes").val());
    endDate = endDate.format();

    var timezone = constraintTile.$selector.find(".timezone").val();

    if(constraintTile.$selector.find(".constraint-start-time-end-time-nature").val() == "all-day") {
        startDate = null;
        endDate = null;
    }

    var startRecurring = moment(constraintTile.$selector.find(".constraint-start-recurring").val(), "MM/DD/YYYY").format("YYYY-MM-DD");
    var endRecurring = moment(constraintTile.$selector.find(".constraint-end-recurring").val(), "MM/DD/YYYY").format("YYYY-MM-DD");

    return {
        attendee_email: constraintTile.$selector.find(".constraint-attendee-email").val(),
        constraint_nature: constraintTile.$selector.find(".constraint-nature").val(),
        repeat: "weekly",
        start_date: startDate,
        end_date: endDate,
        timezone: timezone,
        days_of_weeks: constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type=checkbox]:checked").map(function() {return $(this).val();}).get(),
        start_recurring: startRecurring,
        end_recurring: endRecurring
    }
};

ConstraintTile.getEventsFromData = function (data_entries, start_date, end_date) {
    var deployedDataEntries = ConstraintTile.deployConstraints(data_entries, start_date, end_date);
    return ConstraintTile.getEventsFromDataFromDeployedConstraints(deployedDataEntries, start_date, end_date);
};
ConstraintTile.getEventsFromDataFromDeployedConstraints = function (data_entries, start_date, end_date) {
    var cantResult = [];
    var dontPreferResult = [];

    var currentStart;

    if(_.find(data_entries, function(data) {
       return data.constraint_nature == "can";
    })) {
        var canTimeWindows =_.map(_.filter(data_entries, function(data) {
            return data.constraint_nature == "can";
        }), function(data) {
            return {
                start: moment(data.start_date),
                end: moment(data.end_date)
            };
        });
        canTimeWindows = _.sortBy(canTimeWindows, function(timeWindow) {
            return timeWindow.start;
        });

        currentStart = start_date.clone();
        _.each(canTimeWindows, function(timeWindow) {
            if(currentStart < timeWindow.start && currentStart < end_date) {
                cantResult.push({
                    start: currentStart.clone(),
                    end: _.min([timeWindow.start.clone(), end_date.clone()])
                });
            }
            currentStart = _.max([currentStart, timeWindow.end]);
        });
        if(currentStart < end_date) {
            cantResult.push({
                start: currentStart.clone(),
                end: end_date.clone()
            });
        }
    }
    else if(_.find(data_entries, function(data) {
        return data.constraint_nature == "cant";
    })) {
        var cantTimeWindows =_.map(_.filter(data_entries, function(data) {
            return data.constraint_nature == "cant";
        }), function(data) {
            return {
                start: moment(data.start_date),
                end: moment(data.end_date)
            };
        });
        cantTimeWindows = _.sortBy(cantTimeWindows, function(timeWindow) {
            return timeWindow.start;
        });

        currentStart = start_date.clone();
        _.each(cantTimeWindows, function(timeWindow) {
            if(currentStart < end_date && currentStart < timeWindow.end) {
                cantResult.push({
                    start: _.max([currentStart.clone(), timeWindow.start.clone()]),
                    end: _.min([timeWindow.end.clone(), end_date.clone()])
                });
            }
            currentStart = _.max([currentStart.clone(), timeWindow.end.clone()]);
        });
    }

    if(_.find(data_entries, function(data) {
        return data.constraint_nature == "prefers";
    })) {
        prefersTimeWindows = _.map(_.filter(data_entries, function(data) {
            return data.constraint_nature == "prefers";
        }), function(data) {
            return {
                start: moment(data.start_date),
                end: moment(data.end_date)
            };
        });
        prefersTimeWindows = _.sortBy(prefersTimeWindows, function(timeWindow) {
            return timeWindow.start;
        });
        currentStart = start_date.clone();
        _.each(prefersTimeWindows, function(timeWindow) {
            console.log("currentStart", currentStart);
            if(currentStart < timeWindow.start && currentStart < end_date) {
                dontPreferResult.push({
                    start: currentStart.clone(),
                    end: _.min([timeWindow.start.clone(), end_date.clone()])
                });
            }
            currentStart = _.max([currentStart, timeWindow.end]);
        });
        if(currentStart < end_date) {
            dontPreferResult.push({
                start: currentStart.clone(),
                end: end_date.clone()
            });
        }
    }

    return {
        cant: _.filter(cantResult, function(event) {return event.end - event.start > 1000 * 60;}),
        dontPrefer: _.filter(dontPreferResult, function(event) {return event.end - event.start > 1000 * 60;})
    };
};

ConstraintTile.deployConstraints = function(data_entries, start_date, end_date) {
    var result = [];
    var currentDate;
    _.each(data_entries, function(data) {

        var realStartDate = start_date.clone();
        var realEndDate = end_date.clone();
        realStartDate.add('d', -1);

        realStartDate = _.max([
            realStartDate,
            moment.tz(data.start_recurring, data.timezone).startOf("day")
        ]);

        realEndDate = _.min([
            realEndDate,
            moment.tz(data.end_recurring, data.timezone).endOf("day")
        ]);


        if(data.repeat == "weekly") {
            currentDate = realStartDate.clone().tz(data.timezone);


            while(currentDate < realEndDate) {
                var weekDay = "" + currentDate.isoWeekday();
                if(data.days_of_weeks.indexOf(weekDay) > -1) {
                    var mStartDate = currentDate.clone();
                    var mEndDate = currentDate.clone();
                    if(data.start_date && data.end_date) {
                        mStartDate.set("h", moment(data.start_date).hours());
                        mStartDate.set("m", moment(data.start_date).minutes());


                        mEndDate.set("h", moment(data.end_date).hours());
                        mEndDate.set("m", moment(data.end_date).minutes());
                    }
                    else {
                        mStartDate = mStartDate.startOf("day");
                        mEndDate = mEndDate.endOf("day");
                    }

                    result.push({
                        start_date: mStartDate.format("YYYY-MM-DDTHH:mmZ"),
                        end_date: mEndDate.format("YYYY-MM-DDTHH:mmZ"),
                        constraint_nature: data.constraint_nature
                    });
                }
                currentDate.add('d', 1);
            }
        }
    });
    _.each(["can", "prefers"], function(constraintNature) {
        if(_.filter(result, function(event) {
            return event.constraint_nature == constraintNature;
        }).length == 0 && _.filter(data_entries, function(data_entry) {
            return data_entry.constraint_nature == constraintNature;
        }).length > 0) {
            result.push(ConstraintTile.deployConstraints(_.filter(data_entries, function(data_entry) {
                return data_entry.constraint_nature == constraintNature;
            }), moment("1000-01-01"), moment("4000-01-01"))[0]);
        }
    });

    return result;
};