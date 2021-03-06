/*
*
*
*
*
* Written by Nicolas Marlier, updated May 2015
*
*
* This plugin allows an operator to edit time constraints
*
*
* */

/*
*
* Constructor
* new ConstraintTile($selector, params)
* $selector: a jQuery selector in which the input will be rendered
* params: {
*   possible_attendees: an array of possible {name: "name", email: "email"} that might be applied the constraint, default: []
*   locale: locale (default 'en')
*   timezone: default timezone for the constraints (default: "GMT")
*   data: If given, the constraint will be populated with existing constraint data. See below for format #optional
*   cloneCallback: If given, function to handle clone constraint button click,
*   expand: says if the constraint should expand at first
* }
*
* data: {
* attendee_email: an email string that should be contained in possible_attendees params
* constraint_nature: ConstraintTile.NATURE_CAN|ConstraintTile.NATURE_CANT|ConstraintTile.NATURE_PEFERS,
* constraint_when_nature: ConstraintTile.WHEN_NATURE_CUSTOM|ConstraintTile.WHEN_NATURE_RANGE|ConstraintTile.WHEN_NATURE_FROM_DATE|ConstraintTile.WHEN_NATURE_ALWAYS,
*
* dates: Depending on constraint_when_nature value
*       ConstraintTile.WHEN_NATURE_CUSTOM: an array of dates selected
*       ConstraintTile.WHEN_NATURE_RANGE: an array of 2 dates defining a range
*       ConstraintTile.WHEN_NATURE_FROM_DATE: an array of 1 date
*       ConstraintTile.WHEN_NATURE_ALWAYS: ignored
*
* start_time: null or "HH:mm"
* end_time: null or "HH:mm"
* timezone: timezone id, like "America/Los_Angeles",
*
* days_of_weeks: Depending on constraint_when_nature value
*       ConstraintTile.WHEN_NATURE_CUSTOM: ignored
*       ConstraintTile.WHEN_NATURE_RANGE: ignored
*       ConstraintTile.WHEN_NATURE_FROM_DATE: ignored
*       ConstraintTile.WHEN_NATURE_ALWAYS: an array of day indexes selected - e.g.["1", "3"] means "mondays and wednesdays"
*
* }
 */
ConstraintTile.NATURE_CAN               = "can";
ConstraintTile.NATURE_CANT              = "cant";
ConstraintTile.NATURE_PREFERS           = "prefers";

ConstraintTile.WHEN_NATURE_CUSTOM       = "custom";
ConstraintTile.WHEN_NATURE_FROM_DATE    = "from_date";
ConstraintTile.WHEN_NATURE_RANGE        = "range";
ConstraintTile.WHEN_NATURE_ALWAYS       = "always";

function ConstraintTile($selector, params) {
    var constraintTile = this;

    constraintTile.disabled = !!params.disabled;
    constraintTile.possibleAttendees = params.possible_attendees;
    constraintTile.allAttendees = params.all_attendees || [];

    if(params.data && params.data.attendee_email)
        constraintTile.attendee_email = params.data.attendee_email;

    if(!constraintTile.possibleAttendees) {
        constraintTile.possibleAttendees = [];
    }
    if(constraintTile.possibleAttendees.length == 0) {
        if (params.data && params.data.attendee_email != undefined) {
            constraintTile.possibleAttendees.push({
                    name: params.data.attendee_email,
                    email: params.data.attendee_email
                });
        }
        else {
            throw "possible_attendees param required to be a non-empty array";
        }
    }

    constraintTile.$selector = $selector;
    constraintTile.locale = "en";
    if(params.locale)  constraintTile.locale = params.locale;
    constraintTile.timezone = "GMT";
    if(params.timezone)  constraintTile.timezone = params.timezone;
    constraintTile.cloneCallback = null;
    if(params.timezoneDisabled) constraintTile.timezoneDisabled = true;
    if(params.cloneCallback) constraintTile.cloneCallback = params.cloneCallback;
    if(params.fromAI) {
        constraintTile.fromAI = params.fromAI;
        constraintTile.fromAIText = params.data.text;
    }
    if(params.readOnly) {
        constraintTile.readOnly = true;
    }


    var defaultEmail = "";
    if(constraintTile.possibleAttendees && constraintTile.possibleAttendees.length > 0) {
        defaultEmail = constraintTile.possibleAttendees[0].email
    }
    var defaultData = {
        attendee_email: defaultEmail,
        constraint_nature: ConstraintTile.NATURE_CAN,
        constraint_when_nature: ConstraintTile.WHEN_NATURE_FROM_DATE,
        dates: [moment().format("YYYY-MM-DD")],
        start_time: null,
        end_time: null,
        timezone: constraintTile.timezone
    };

    constraintTile.render();

    constraintTile.expanded = params.expand;

    if(!params.expand) {
        constraintTile.$selector.find(".constraint-tile").addClass("notransition");
        constraintTile.$selector.find(".constraint-tile").addClass("minimized");
        setTimeout(function() {
            constraintTile.$selector.find(".constraint-tile").removeClass("notransition");
        }, 10);
    }

    var data = defaultData;
    if(params.data) data = params.data;
    constraintTile.setInitialData(data);
}

/*
 * Initial render
 */

ConstraintTile.prototype.isValid = function() {
    var validator = new ConstraintValidator(this.getData());
    return validator.validate().valid;
};

ConstraintTile.prototype.validate = function() {
    var constraintTile = this;

    if(constraintTile.fromAI)
        return { valid: true, errors: []};

    validationResult = new ConstraintValidator(this.getData()).validate();
    constraintTile.valid = validationResult.valid;
    return validationResult;
};

ConstraintTile.prototype.displayErrors = function(errors) {
    var constraintTile = this;
    errorFieldsMapping = { 'validateStartEndTime': '#startEndTimeError' }

    constraintTile.$selector.find(".error").hide();
    errors.forEach(function(error) {
        errorFieldSelector = errorFieldsMapping[error];
        if(errorFieldSelector)
            constraintTile.$selector.find(errorFieldSelector).show();
    });
};

ConstraintTile.prototype.hideErrors = function() {
    this.$selector.find(".error").hide();
};


ConstraintTile.prototype.render = function() {
    var constraintTile = this;

    // Render template
    constraintTile.$selector.html(HandlebarsTemplates['constraint_tile/main']());

    // Populate possible attendees select
    _(constraintTile.possibleAttendees).each(function(attendee) {
        constraintTile.$selector.find(".constraint-attendee-email").append($("<option>").val(attendee.email).html(attendee.name + " (" + attendee.email + ")"));
    });

    // Init the timezone picker
    var $timezonePicker = constraintTile.$selector.find(".timezone");
    $timezonePicker.timezonePicker();
    $timezonePicker.val(constraintTile.timezone);
    if(constraintTile.timezoneDisabled) {
        $timezonePicker.attr("disabled", true);
    }

    // Init actions
    constraintTile.initActions();
};

ConstraintTile.prototype.setInitialData = function(data) {
    var constraintTile = this;


    // Set AI mode

    constraintTile.setAIMode();

    if(constraintTile.readOnly) {
        constraintTile.$selector.find(".constraint-tile").addClass("read-only");
    }



    // Set attendee email
    constraintTile.$selector.find(".constraint-attendee-email").val(data.attendee_email);

    // Set constraint nature
    constraintTile.setConstraintNature(data.constraint_nature);

    // Set constraint when nature
    constraintTile.setConstraintWhenNature(data.constraint_when_nature);

    // Set start time and end time
    if(data.start_time && data.end_time) {
        var mStartDate = moment("2015-01-01T" + data.start_time);
        var mEndDate   = moment("2015-01-01T" + data.end_time);

        constraintTile.$selector.find(".constraint-start-hours").val(mStartDate.format("HH"));
        constraintTile.$selector.find(".constraint-start-minutes").val(mStartDate.format("mm"));
        constraintTile.$selector.find(".constraint-end-hours").val(mEndDate.format("HH"));
        constraintTile.$selector.find(".constraint-end-minutes").val(mEndDate.format("mm"));

        constraintTile.setStartTimeEndTimeNature("custom");
    }
    else {
        constraintTile.setStartTimeEndTimeNature("all_day");
    }
    constraintTile.startTimeEndTimeChanged();

    // Set timezone
    if(data.timezone) {
        constraintTile.$selector.find(".timezone").val(data.timezone);
    }

    // Redraw dates container (calendar picker or days of week picker)
    constraintTile.redrawDatesContainer();

    // Set selected days
    if(constraintTile.calendarTile) {
        _.each(data.dates, function(date) {
            constraintTile.calendarTile.selectDay(date);
        });
    }

    // Set days of week
    constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week").removeClass("selected");
    _.each(data.days_of_weeks, function(dayOfWeek) {
        constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week[data-value='" + dayOfWeek + "']").addClass("selected");
    });


    // Redraw dates container (all day/morning/afternoon/custom selector and hours selector if needed)
    constraintTile.redrawTimesContainer();

    // Redraw sentence
    constraintTile.redrawSentence();
};

ConstraintTile.prototype.setAIMode = function() {
    var constraintTile = this;
    constraintTile.$selector.find(".constraint-tile").removeClass("from-ai");
    if(constraintTile.fromAI) {
        constraintTile.$selector.find(".constraint-tile").addClass("from-ai");
        constraintTile.$selector.find(".from-ai-text-text").html(constraintTile.fromAIText);
    }
};


ConstraintTile.prototype.setConstraintWhenNature = function(value) {
    var constraintTile = this;
    constraintTile.$selector.find(".constraint-when-nature-selector .nature-option").removeClass("selected");
    constraintTile.$selector.find(".constraint-when-nature-selector .nature-option[data-value='" + value + "']").addClass("selected");
    constraintTile.whenNatureChanged();
};

ConstraintTile.prototype.getConstraintWhenNature = function() {
    var constraintTile = this;
    return constraintTile.$selector.find(".constraint-when-nature-selector .nature-option.selected").data("value");
};

ConstraintTile.prototype.redrawTimesContainer = function() {
    var constraintTile = this;
    var startTimeEndTimeNature = constraintTile.getStartTimeEndTimeNature();
    if(startTimeEndTimeNature == "all_day") {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").hide();
    }
    else {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").show();
    }
};

ConstraintTile.prototype.redrawDatesContainer = function() {
    var constraintTile = this;
    constraintTile.$selector.find(".constraint-dates-days-of-week-container").hide();
    var whenNature = constraintTile.getConstraintWhenNature();

    if(whenNature == ConstraintTile.WHEN_NATURE_ALWAYS) {
        constraintTile.$selector.find(".constraint-calendar-tile-container").hide();
        constraintTile.$selector.find(".constraint-dates-days-of-week-container").show();
    }
    else {
        var calendarTileMode = "custom";
        if(whenNature == ConstraintTile.WHEN_NATURE_FROM_DATE) {
            calendarTileMode = "from_date";
        }
        else if(whenNature == ConstraintTile.WHEN_NATURE_RANGE) {
            calendarTileMode = "range";
        }
        constraintTile.calendarTile = new CalendarTile(constraintTile.$selector.find(".constraint-calendar-tile-container"), {
            mode: calendarTileMode,
            selectionChangedCallback: function() {
                constraintTile.redrawSentence();
            }
        });
        constraintTile.$selector.find(".constraint-calendar-tile-container").show();
    }
};

ConstraintTile.prototype.enable = function() {
    var constraintTile = this;
    constraintTile.disabled = false;
};

ConstraintTile.prototype.disable = function() {
    var constraintTile = this;
    constraintTile.disabled = true;
};



ConstraintTile.prototype.whenNatureChanged = function() {
    var constraintTile = this;
    constraintTile.redrawDatesContainer();
};

ConstraintTile.prototype.setStartTimeEndTimeNature = function(value) {
    var constraintTile = this;
    constraintTile.$selector.find(".constraint-start-time-end-time-nature-selector .nature-option").removeClass("selected");
    constraintTile.$selector.find(".constraint-start-time-end-time-nature-selector .nature-option[data-value='" + value + "']").addClass("selected");
};
ConstraintTile.prototype.getStartTimeEndTimeNature = function() {
    var constraintTile = this;
    return constraintTile.$selector.find(".constraint-start-time-end-time-nature-selector .nature-option.selected").data("value");
};

ConstraintTile.prototype.startTimeEndTimeNatureChanged = function() {
    var constraintTile = this;
    var startTimeEndTimeNature = constraintTile.getStartTimeEndTimeNature();
    constraintTile.redrawTimesContainer();
    if(startTimeEndTimeNature == "morning") {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-start-hours").val(8);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-start-minutes").val(0);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-end-hours").val(12);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-end-minutes").val(0);
    }
    else if(startTimeEndTimeNature == "afternoon") {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-start-hours").val(14);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-start-minutes").val(0);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-end-hours").val(20);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-end-minutes").val(0);
    }
    else if(startTimeEndTimeNature == "custom") {
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-start-hours").val(8);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-start-minutes").val(0);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-end-hours").val(20);
        constraintTile.$selector.find(".constraint-start-hours-end-hours-container").find(".constraint-end-minutes").val(0);
    }

    constraintTile.redrawSentence();
};

ConstraintTile.prototype.getStartTimeEndTime = function() {
    var constraintTile = this;
    var mStartTime = moment();
    mStartTime.hours(constraintTile.$selector.find(".constraint-start-hours").val());
    mStartTime.minutes(constraintTile.$selector.find(".constraint-start-minutes").val());
    startTime =  mStartTime.format("HH:mm");

    var mEndTime = moment();
    mEndTime.hours(constraintTile.$selector.find(".constraint-end-hours").val());
    mEndTime.minutes(constraintTile.$selector.find(".constraint-end-minutes").val());
    endTime =  mEndTime.format("HH:mm");

    return {
        startTime: startTime,
        endTime: endTime
    };
};

ConstraintTile.prototype.startTimeEndTimeChanged = function() {
    var constraintTile = this;

    if(constraintTile.getStartTimeEndTimeNature() == "all_day") {
        return;
    }

    var startTimeEndTime = constraintTile.getStartTimeEndTime();
    var morningStartTimeEndTime = {
        startTime: "08:00",
        endTime: "12:00"
    };
    var afternoonStartTimeEndTime = {
        startTime: "14:00",
        endTime: "20:00"
    };

    if(startTimeEndTime.startTime == morningStartTimeEndTime.startTime &&
        startTimeEndTime.endTime == morningStartTimeEndTime.endTime) {
        constraintTile.setStartTimeEndTimeNature("morning");
    }
    else if(startTimeEndTime.startTime == afternoonStartTimeEndTime.startTime &&
        startTimeEndTime.endTime == afternoonStartTimeEndTime.endTime) {
        constraintTile.setStartTimeEndTimeNature("afternoon");
    }
    else {
        constraintTile.setStartTimeEndTimeNature("custom");
    }


    constraintTile.redrawSentence();
};

ConstraintTile.prototype.attendeeChanged = function() {
    var constraintTile = this;
    constraintTile.attendee_email = constraintTile.$selector.find(".constraint-attendee-email").val();
    var attendee = constraintTile.getAttendee();
    if(attendee)
        constraintTile.disabled = !attendee.isPresent;
};

ConstraintTile.prototype.initActions = function() {
  var constraintTile = this;

    constraintTile.$selector.find(".constraint-when-nature").change(function(e) {
        constraintTile.redrawDatesContainer();
    });

    constraintTile.$selector.find(".timezone").autocomplete({
        change: function( event, ui ) {
            constraintTile.redrawSentence();
        }
    });

    constraintTile.$selector.find(".constraint-start-time-end-time-nature-selector .nature-option").click(function() {
        if(!$(this).closest(".input-like").hasClass("disabled"))  {
            constraintTile.$selector.find(".constraint-start-time-end-time-nature-selector .nature-option").removeClass("selected");
            $(this).addClass("selected");

            constraintTile.startTimeEndTimeNatureChanged();
        }
    });


    constraintTile.$selector.find(".constraint-when-nature-selector .nature-option").click(function() {
        if(!$(this).closest(".input-like").hasClass("disabled"))  {
            constraintTile.$selector.find(".constraint-when-nature-selector .nature-option").removeClass("selected");
            $(this).addClass("selected");
            constraintTile.whenNatureChanged();
            constraintTile.redrawSentence();
        }
    });

    constraintTile.$selector.find(".constraint-start-hours, .constraint-start-minutes, .constraint-end-hours, .constraint-end-minutes").change(function() {
        constraintTile.startTimeEndTimeChanged();
    });

    constraintTile.$selector.find(".constraint-attendee-email").change(function() {
        constraintTile.attendeeChanged();
        var attendee = constraintTile.getAttendee();
        if(attendee && !attendee.isPresent) {
            constraintTile.disabled = true;
        }
        constraintTile.redrawSentence();
    });

    constraintTile.$selector.find(".constraint-nature-selector .nature-option").click(function() {
        if(!$(this).closest(".input-like").hasClass("disabled"))  {
            constraintTile.$selector.find(".constraint-nature-selector .nature-option").removeClass("selected");
            $(this).addClass("selected");

            constraintTile.redrawSentence();
        }
    });

    constraintTile.$selector.find(".from-ai-buttons .from-ai-button.reject").click(function() {
        constraintTile.$selector.remove();

        // TODO: do that in a not dirty way
        var index = window.contraintsTiles.indexOf(constraintTile);
        if(index >= 0)
            window.contraintsTiles.splice(index, 1);
    });

    constraintTile.$selector.find(".from-ai-buttons .from-ai-button.accept").click(function() {
        constraintTile.fromAI = false;
        constraintTile.setAIMode();
        constraintTile.validate();
        constraintTile.redrawSentence();
    });

    constraintTile.$selector.find(".remove-constraint-button").click(function() {
        constraintTile.$selector.remove();

        // TODO: do that in a not dirty way
        var index = window.contraintsTiles.indexOf(constraintTile);
        if(index >= 0)
            window.contraintsTiles.splice(index, 1);
    });

    constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week").click(function(e) {
        if(!$(this).hasClass("disabled"))  {
            $(this).toggleClass("selected");

            if(constraintTile.$selector.find(".constraint-dates-days-of-week-container:not(.selected)").length > 0) {
                constraintTile.$selector.find(".constraint-dates-days-of-week-container .quick-selector").removeClass("selected");
            }
            else {
                constraintTile.$selector.find(".constraint-dates-days-of-week-container .quick-selector").addClass("selected");
            }

            constraintTile.redrawSentence();
        }
    });

    constraintTile.$selector.find(".constraint-dates-days-of-week-container .quick-selector").click(function() {
        if(!$(this).hasClass("disabled"))  {
            if(constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week:not(.selected)").length > 0) {
                constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week").addClass("selected");
                $(this).addClass("selected");
            }
            else {
                constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week").removeClass("selected");
                $(this).removeClass("selected");
            }
            constraintTile.redrawSentence();
        }
    });


    constraintTile.$selector.find(".expand-constraint-button").click(function() {
        constraintTile.expand();
    });

    constraintTile.$selector.find(".minimize-constraint-button").click(function() {
        constraintTile.minimize();
    });

    constraintTile.$selector.find(".clone-constraint-button").click(function() {
        if(constraintTile.cloneCallback) {
            constraintTile.$selector.find(".constraint-tile").addClass("minimized");
            constraintTile.cloneCallback(constraintTile.getData());
        }
    });
};

ConstraintTile.prototype.expand = function() {
    var constraintTile = this;

    if(constraintTile.$selector.find(".constraint-tile").hasClass("minimized"))
        constraintTile.$selector.find(".constraint-tile").toggleClass("minimized");

    constraintTile.expanded = true;
    constraintTile.redrawSentence();
};

ConstraintTile.prototype.minimize = function() {
    var constraintTile = this;

    if(!constraintTile.$selector.find(".constraint-tile").hasClass("minimized"))
        constraintTile.$selector.find(".constraint-tile").toggleClass("minimized");

    constraintTile.expanded = false;
    constraintTile.redrawSentence();
};

ConstraintTile.prototype.scrollTo = function(callback) {
    var constraintTile = this;

    $scrollable = constraintTile.$selector.closest('.scrollable');
    $scrollable.animate({
        scrollTop: $scrollable .scrollTop() + constraintTile.$selector.position().top - $('.message-container').height() - 5
    }, 1000, function() { if(callback) callback() });
};



ConstraintTile.prototype.getAttendee = function() {
    var constraintTile = this;
    return _.find(constraintTile.possibleAttendees, function(possibleAttendee) {
       return possibleAttendee.email === constraintTile.attendee_email;
    });
};

ConstraintTile.prototype.redrawSentence = function() {
    var constraintTile = this;
    var oldLocale = getCurrentLocale();
    setCurrentLocale(constraintTile.locale);

    var sentence = "";
    data = constraintTile.getData();
    if(!data) {
        sentence = "<span class='invalid'>" + localize("constraints.invalid_constraint") + "</span>";
    }
    else {
        var attendee = _.find(constraintTile.allAttendees, function(attendee) {
            return attendee.email == data.attendee_email;
        });

        var attendeeName = data.attendee_email;
        if(attendee) {
            attendeeName = attendee.name;
        }
        sentence += "<span class='attendee-name'>" + attendeeName + "</span> <span class='constraint-nature " + data.constraint_nature + "'>" + localize("constraints." + data.constraint_nature) + "</span><br/>";


        if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_ALWAYS) {
            if(data.days_of_weeks.length == 7) {
                sentence += " " + localize("constraints.every_day");
            }
            else {
                sentence += " " + localize("constraints.on_days") + " " + _.map(data.days_of_weeks, function(dayOfWeek) {
                    return "<span class='date'>" + moment().locale(constraintTile.locale).day(dayOfWeek).format("dddd") + "</span>";
                }).join(", ");
            }
        }
        else if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_FROM_DATE) {
            sentence += " " + localize("constraints.from_date") + "  " + "<span class='date'>" + moment(data.dates[0]).locale(constraintTile.locale).format("dddd DD MMMM YYYY") + "</span>";
        }
        else if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_RANGE) {
            var mDates = _.map(data.dates, function(day) { return moment(day) });
            var mFromDate = _.min(mDates);
            var mTtoDate = _.max(mDates);
            sentence += " " + localize("constraints.from_date") + " " + "<span class='date'>" + mFromDate.locale(constraintTile.locale).format("dddd DD MMMM YYYY") + "</span><br/>" + localize("constraints.to_date") + " <span class='date'>" + mTtoDate.locale(constraintTile.locale).format("dddd DD MMMM YYYY") + "</span>";
        }
        else if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_CUSTOM) {
            sentence += " " + _(_(data.dates).sort()).map(function(date) {
                return "<span class='date'>" + moment(date).locale(constraintTile.locale).format("dddd DD MMMM YYYY") + "</span>";
            }).join(", <br/>");
        }

        if(data.start_time) {
            sentence += "<br/>" + localize("constraints.from") + " <span class='time'>" + data.start_time + "</span> " + localize("constraints.to") + " <span class='time'>" + data.end_time + "</span><br/><span class='timezone'>" + data.timezone + "</span>";
        }


        constraintTile.$selector.find(".constraintLayer, .constraintStatus").hide();
        validationResult = constraintTile.validate();

        if(constraintTile.expanded) {
            if(validationResult.valid)
                constraintTile.hideErrors();
            else
                constraintTile.displayErrors(validationResult.errors);
        }
        else if(validationResult.valid === false){
            constraintTile.$selector.find(".constraintInvalid, .constraintInvalid .constraintStatus").show();
        }
        else if(constraintTile.disabled && !constraintTile.fromAI){
            constraintTile.$selector.find(".constraintDisabled").show();
            statusSelector = attendee.status === 'optional' ? ".constraintStatus.optionalStatus" : ".constraintStatus.notPresentStatus";
            constraintTile.$selector.find(statusSelector).show();
        }
        else {  }

    }



    constraintTile.$selector.find(".constraint-sentence").html(sentence);
    constraintTile.$selector.data("constraint", data);

    setCurrentLocale(oldLocale);
};

ConstraintTile.prototype.getData = function() {
    var constraintTile = this;

    var whenNature = constraintTile.getConstraintWhenNature();
    var dates = [];
    var daysOfWeek = [];
    if(whenNature == ConstraintTile.WHEN_NATURE_ALWAYS) {
        dates = [];
        daysOfWeek = constraintTile.$selector.find(".constraint-dates-days-of-week-container .day-of-week.selected").map(function() {return $(this).data("value");}).get();
        if(daysOfWeek.length == 0) {
            return null;
        }
    }
    else {
        if(!constraintTile.calendarTile) {
            return null;
        }
        var selectedDays = constraintTile.calendarTile.selectedDays;

        if(whenNature == ConstraintTile.WHEN_NATURE_RANGE) {
            dates = selectedDays;
            if(dates.length != 2) {
                return null;
            }
        }
        else if(whenNature == ConstraintTile.WHEN_NATURE_FROM_DATE) {
            dates = selectedDays;
            if(dates.length != 1) {
                return null;
            }
        }
        else if(whenNature == ConstraintTile.WHEN_NATURE_CUSTOM) {
            dates = selectedDays;
            if(dates.length == 0) {
                return null;
            }
        }
        else {
            return null;
        }
    }

    var startTime = null;
    var endTime = null;
    if(constraintTile.getStartTimeEndTimeNature() != "all_day") {
        var startTimeEndTime = constraintTile.getStartTimeEndTime();
        startTime = startTimeEndTime.startTime;
        endTime = startTimeEndTime.endTime;
    }
    var timezone = constraintTile.$selector.find(".timezone").val();

    return {
        attendee_email: constraintTile.attendee_email || constraintTile.$selector.find(".constraint-attendee-email").val(),
        constraint_nature: constraintTile.getConstraintNature(),
        constraint_when_nature: whenNature,
        disabled: constraintTile.disabled,

        dates: dates,

        start_time: startTime,
        end_time: endTime,
        timezone: timezone,

        days_of_weeks: daysOfWeek
    }
};

ConstraintTile.prototype.setConstraintNature = function(nature) {
    var constraintTile = this;
    constraintTile.$selector.find(".constraint-nature-selector .nature-option").removeClass("selected");
    constraintTile.$selector.find(".constraint-nature-selector .nature-option[data-value='" + nature + "']").addClass("selected");
    return constraintTile.$selector.find(".constraint-nature-selector .nature-option[data-value='" + nature + "']").addClass("selected");
};


ConstraintTile.prototype.getConstraintNature = function() {
    var constraintTile = this;
    return constraintTile.$selector.find(".constraint-nature-selector .nature-option.selected").data("value");
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
       return data.constraint_nature == ConstraintTile.NATURE_CAN;
    })) {
        var canTimeWindows =_.map(_.filter(data_entries, function(data) {
            return data.constraint_nature == ConstraintTile.NATURE_CAN;
        }), function(data) {
            return {
                start: moment(data.start_date || data.dates[0]),
                end: moment(data.end_date || data.dates[1])
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
        return data.constraint_nature == ConstraintTile.NATURE_CANT;
    })) {
        var cantTimeWindows =_.map(_.filter(data_entries, function(data) {
            return data.constraint_nature == ConstraintTile.NATURE_CANT;
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
        return data.constraint_nature == ConstraintTile.NATURE_PREFERS;
    })) {
        prefersTimeWindows = _.map(_.filter(data_entries, function(data) {
            return data.constraint_nature == ConstraintTile.NATURE_PREFERS;
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

ConstraintTile.deployConstraints = function(data_entries, start_date, end_date, alreadyRecurring) {
    var result = [];
    var currentDate;
    _.each(data_entries, function(data) {

        var realStartDate = start_date.clone();
        var realEndDate = end_date.clone();
        realStartDate.add(-1, 'd');

        if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_ALWAYS) {

        }
        else if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_FROM_DATE) {
            realStartDate = _.max([
                realStartDate,
                moment.tz(data.dates[0], data.timezone).startOf("day")
            ]);
        }
        else if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_RANGE) {
            var mDates = _.map(data.dates, function(date) { return moment.tz(date, data.timezone); });
            realStartDate = _.max([
                realStartDate,
                _.min(mDates).startOf("day")
            ]);
            realEndDate = _.min([
                realEndDate,
                _.max(mDates).endOf("day")
            ]);
        }
        else if(data.constraint_when_nature == ConstraintTile.WHEN_NATURE_CUSTOM) {

        }

        currentDate = realStartDate.clone().tz(data.timezone);


        while(currentDate <= realEndDate) {
            var weekDay = "" + currentDate.isoWeekday();
            if(
                (data.constraint_when_nature == ConstraintTile.WHEN_NATURE_ALWAYS &&
                data.days_of_weeks.indexOf(weekDay) > -1) ||
                (data.constraint_when_nature == ConstraintTile.WHEN_NATURE_FROM_DATE) ||
                (data.constraint_when_nature == ConstraintTile.WHEN_NATURE_RANGE) ||
                (data.constraint_when_nature == ConstraintTile.WHEN_NATURE_CUSTOM &&
                    data.dates.indexOf(currentDate.format(CalendarTile.ONLY_DATE_MOMENT_FORMAT)) > -1)
                ) {
                var mStartDate = currentDate.clone();
                var mEndDate = currentDate.clone();
                if(data.start_time && data.end_time) {
                    mStartTime = moment("2015-01-01T" + data.start_time);
                    mStartDate.set("h", mStartTime.hours());
                    mStartDate.set("m", mStartTime.minutes());

                    mEndTime = moment("2015-01-01T" + data.end_time);
                    mEndDate.set("h", mEndTime.hours());
                    mEndDate.set("m", mEndTime.minutes());
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
            currentDate.add(1, 'd');
        }
    });

    if(!alreadyRecurring) {
        _.each(["can", "prefers"], function(constraintNature) {
            if(_.filter(result, function(event) {
                return event.constraint_nature == constraintNature;
            }).length == 0 && _.filter(data_entries, function(data_entry) {
                return data_entry.constraint_nature == constraintNature;
            }).length > 0) {
                var fakeStartDate = start_date.clone();
                fakeStartDate.add(-2, 'd');
                var fakeEndDate = start_date.clone();
                fakeEndDate.add(-1, 'd');
                result.push({
                    start_date: fakeStartDate.format("YYYY-MM-DDTHH:mmZ"),
                    end_date: fakeEndDate.format("YYYY-MM-DDTHH:mmZ"),
                    constraint_nature: constraintNature
                });
            }
        });
    }


    return result;
};

var ConstraintValidator = function(constraintData) {
    this.constraintData = constraintData;
};

ConstraintValidator.prototype.validators = ["validateStartEndTime"];

ConstraintValidator.prototype.validate = function() {
    var _self = this;
    var validationErrors = this.validators
            .map(function(validator) { return { validator: validator, valid: _self[validator]()} })
            .filter(function(validationResult) { return !validationResult.valid });

    return { valid: validationErrors.length === 0, errors: validationErrors.map(function(validationErrors) { return validationErrors.validator }) };
}

ConstraintValidator.prototype.validateStartEndTime = function() {
    if(this.constraintData.start_time && this.constraintData.end_time) {
        var startTime = this.constraintData.start_time + ':00';
        var endTime = this.constraintData.end_time + ':00';
        return Date.parse('01/01/2000 ' + startTime) < Date.parse('01/01/2000 ' + endTime);
    }
    return true;
};