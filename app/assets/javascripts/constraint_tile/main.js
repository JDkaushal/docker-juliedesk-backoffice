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

    var constraintTile = this;

    constraintTile.redraw();

    if(params.data) {
        constraintTile.$selector.find(".constraint-attendee-email").val(params.data.attendee_email);
        constraintTile.$selector.find(".constraint-nature").val(params.data.constraint_nature);
        constraintTile.$selector.find(".constraint-repeat-every").val(params.data.repeat);
        var startDate = moment(params.data.start_date);
        var endDate = moment(params.data.end_date);


        constraintTile.$selector.find(".constraint-start-date").datepicker("setDate", startDate.toDate());
        constraintTile.$selector.find(".constraint-end-date").datepicker("setDate", endDate.toDate());
        constraintTile.$selector.find(".constraint-start-hours").val(startDate.format("HH"));
        constraintTile.$selector.find(".constraint-end-hours").val(endDate.format("HH"));
        constraintTile.$selector.find(".constraint-start-minutes").val(startDate.format("mm"));
        constraintTile.$selector.find(".constraint-end-minutes").val(endDate.format("mm"));

        constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type=checkbox]").removeAttr("checked");
        _.each(params.data.days_of_weeks, function(dayOfWeek) {
            constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type=checkbox][value='" + dayOfWeek + "']").attr("checked", true);
        });
        var startRecurring = moment(params.data.start_recurring);
        constraintTile.$selector.find(".constraint-start-recurring").datepicker("setDate", startRecurring.toDate());

        constraintTile.redrawDatesContainer();
        constraintTile.redrawSentence();
    }
}

ConstraintTile.prototype.redraw = function() {
    var constraintTile = this;
    constraintTile.$selector.html(HandlebarsTemplates['constraint_tile/main']());
    _(this.possibleAttendees).each(function(attendee) {
        constraintTile.$selector.find(".constraint-attendee-email").append($("<option>").val(attendee.email).html(attendee.name));
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

    constraintTile.initActions();
    constraintTile.redrawSentence();
};

ConstraintTile.prototype.getRepeatEvery = function() {
    var constraintTile = this;
    return constraintTile.$selector.find(".constraint-repeat-every").val();
};

ConstraintTile.prototype.redrawDatesContainer = function() {
    var constraintTile = this;

    constraintTile.$selector.find(".constraint-start-date").hide();
    constraintTile.$selector.find(".constraint-end-date").hide();
    constraintTile.$selector.find(".constraint-dates-days-of-week-container").hide();
    constraintTile.$selector.find(".start-recurring-container").hide();
    constraintTile.$selector.find(".end-recurring-container").hide();


    if(constraintTile.getRepeatEvery() == "never") {
        constraintTile.$selector.find(".constraint-start-date").show();
        constraintTile.$selector.find(".constraint-end-date").show();
    }
    else if(constraintTile.getRepeatEvery() == "dayly") {
        constraintTile.$selector.find(".start-recurring-container").show();
        constraintTile.$selector.find(".end-recurring-container").show();
    }
    else if(constraintTile.getRepeatEvery() == "weekly") {
        constraintTile.$selector.find(".constraint-dates-days-of-week-container").show();
        constraintTile.$selector.find(".start-recurring-container").show();
        constraintTile.$selector.find(".end-recurring-container").show();
    }
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

    constraintTile.$selector.find(".constraint-repeat-every").change(function(e) {
        constraintTile.redrawDatesContainer();
    });

    constraintTile.$selector.find("*").change(function(e) {
        constraintTile.checkDates();
        constraintTile.redrawSentence();
    });

    constraintTile.$selector.find(".remove-constraint-button").click(function() {
        constraintTile.$selector.remove();
    })
};



ConstraintTile.prototype.redrawSentence = function() {
    var constraintTile = this;
    var sentence = "";
    data = constraintTile.getData();
    var attendeeName = _.find(constraintTile.possibleAttendees, function(attendee) {
        return attendee.email == data.attendee_email;
    }).name;
    sentence += attendeeName + " " + localize("constraints." + data.constraint_nature);

    if(data.repeat == "never") {
        sentence += " from " + moment(data.start_date).format(localize("email_templates.common.full_date_format")) + " to " + moment(data.end_date).format(localize("email_templates.common.full_date_format"));
    }
    else if(data.repeat == "dayly") {
        sentence += " every day from " + moment(data.start_date).format("HH:mm") + " to " + moment(data.end_date).format("HH:mm");
    }
    else if(data.repeat == "weekly") {
        sentence += " on " + _.map(data.days_of_weeks, function(dayOfWeek) {return constraintTile.daysOfWeek[dayOfWeek]}).join(", ") + " from " + moment(data.start_date).format("HH:mm") + " to " + moment(data.end_date).format("HH:mm");
    }
    if(data.repeat != "never") {
        if(moment(data.start_recurring) > moment()) {
            sentence += ", starting on " + moment(data.start_recurring).format("dddd DD MMMM YYYY")
        }
        if(data.end_recurring) {
            sentence += ", ending on " + moment(data.end_recurring).format("dddd DD MMMM YYYY")
        }
    }
    constraintTile.$selector.find(".constraint-sentence").html(sentence);
    constraintTile.$selector.data("constraint", data);
};

ConstraintTile.prototype.getData = function() {
    var constraintTile = this;

    var startDate = moment(constraintTile.$selector.find(".constraint-start-date").val());
    startDate.set("h", constraintTile.$selector.find(".constraint-start-hours").val());
    startDate.set("m", constraintTile.$selector.find(".constraint-start-minutes").val());

    var endDate = moment(constraintTile.$selector.find(".constraint-end-date").val());
    endDate.set("h", constraintTile.$selector.find(".constraint-end-hours").val());
    endDate.set("m", constraintTile.$selector.find(".constraint-end-minutes").val());

    var endRecurring = moment(constraintTile.$selector.find(".constraint-end-recurring").val()).format();
    if(constraintTile.$selector.find("input.end-recurring:checked").val() == "never") {
        endRecurring = null;
    }


    return {
        attendee_email: constraintTile.$selector.find(".constraint-attendee-email").val(),
        constraint_nature: constraintTile.$selector.find(".constraint-nature").val(),
        repeat: constraintTile.$selector.find(".constraint-repeat-every").val(),
        start_date: startDate.format(),
        end_date: endDate.format(),
        days_of_weeks: constraintTile.$selector.find(".constraint-dates-days-of-week-container input[type=checkbox]:checked").map(function() {return $(this).val();}).get(),
        start_recurring: moment(constraintTile.$selector.find(".constraint-start-recurring").val()).format(),
        end_recurring: endRecurring
    }
};

ConstraintTile.getEventsFromData = function (data_entries, start_date, end_date) {
    var cantResult = [];
    var dontPreferResult = [];

    //console.log("start, end", start_date, end_date);

    data_entries = ConstraintTile.deployConstraints(data_entries, start_date, end_date);
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
        cant: cantResult,
        dontPrefer: dontPreferResult
    };
};

ConstraintTile.deployConstraints = function(data_entries, start_date, end_date) {
    var result = [];
    var currentDate;
    _.each(data_entries, function(data) {

        var realStartDate = start_date.clone();
        var realEndDate = end_date.clone();
        realStartDate.add('d', -1);
        if(data.start_recurring) {
            realStartDate = _.max([realStartDate, moment(data.start_recurring)]);
        }
        if(data.end_recurring) {
            var endRecurring = moment(data.end_recurring);
            endRecurring.add('d', 1);
            realEndDate = _.min([realEndDate, endRecurring]);
        }

        if(data.repeat == "dayly") {
            currentDate = realStartDate.clone();

            while(currentDate < realEndDate) {
                var mStartDate = currentDate.clone();
                mStartDate.set("h", moment(data.start_date).hours());
                mStartDate.set("m", moment(data.start_date).minutes());

                var mEndDate = currentDate.clone();
                mEndDate.set("h", moment(data.end_date).hours());
                mEndDate.set("m", moment(data.end_date).minutes());
                result.push({
                    start_date: mStartDate.format("YYYY-MM-DDTHH:mm"),
                    end_date: mEndDate.format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: data.constraint_nature
                });
                currentDate.add('d', 1);
            }
        }
        else if(data.repeat == "weekly") {
            currentDate = realStartDate.clone();

            while(currentDate < realEndDate) {
                var weekDay = "" + (currentDate.isoWeekday() - 1);
                if(data.days_of_weeks.indexOf(weekDay) > -1) {
                    var mStartDate = currentDate.clone();
                    mStartDate.set("h", moment(data.start_date).hours());
                    mStartDate.set("m", moment(data.start_date).minutes());

                    var mEndDate = currentDate.clone();
                    mEndDate.set("h", moment(data.end_date).hours());
                    mEndDate.set("m", moment(data.end_date).minutes());
                    result.push({
                        start_date: mStartDate.format("YYYY-MM-DDTHH:mm"),
                        end_date: mEndDate.format("YYYY-MM-DDTHH:mm"),
                        constraint_nature: data.constraint_nature
                    });
                }
                currentDate.add('d', 1);
            }
        }
        else if(data.repeat == "never") {
            result.push({
                start_date: moment(data.start_date).format("YYYY-MM-DDTHH:mm"),
                end_date: moment(data.end_date).format("YYYY-MM-DDTHH:mm"),
                constraint_nature: data.constraint_nature
            });
        }
    });
    return result;
};