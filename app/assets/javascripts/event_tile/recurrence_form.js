function RecurrenceForm($selector, params) {
    var recurrenceForm = this;

    recurrenceForm.parentEventTile = params.parentEventTile;
    recurrenceForm.$selector = $selector;
    recurrenceForm.rrule = params.rrule;
    recurrenceForm.rstart = params.rstart;
    recurrenceForm.ruleChangedCallback = params.ruleChangedCallback;
    recurrenceForm.weekDays = [RRule.MO, RRule.TU, RRule.WE, RRule.TH, RRule.FR, RRule.SA, RRule.SU];

    recurrenceForm.redraw();

    recurrenceForm.$selector.find(".form-entry input[name='interval']").val(1);
    recurrenceForm.$selector.find(".form-entry input[name='count']").val(1);
    var mOneMonth = moment();
    mOneMonth.add(1, 'month');
    recurrenceForm.$selector.find(".form-entry input[name='until']").val(mOneMonth.format("YYYY-MM-DD"));

    if(params.rrule) {
        // ActiveSync return a recurrence rule of the form : 'RRULE:FREQ=X;UNTIL=X...'
        // So in order for RRule to parse it from the string we need to stripe the 'RRULE:' tag from the string
        params.rrule = params.rrule.replace('RRULE:', '');

        recurrenceForm.rule = RRule.fromString(params.rrule);
        var ruleOptions = recurrenceForm.rule.options;

        // Means we have a recurrence string of the form : 'FREQ=WEEKLY'
        // We need to determine the correct byday params since by default if it is not present it will use the current day as value
        // We need to use the day of the week of the event start date instead
        if(params.rrule.indexOf('WEEKLY') > -1 && params.rrule.indexOf('BYDAY') == -1) {
            var currentDay = params.rstart.day();

            // Sunday is 0, but for ruleOptions.byweekday, Sunday is 6
            currentDay = currentDay == 0 ? 6 : currentDay - 1;

            ruleOptions.byweekday = [currentDay];
        }

        if(ruleOptions.freq == RRule.DAILY ||
            ruleOptions.freq == RRule.WEEKLY ||
            ruleOptions.freq == RRule.MONTHLY ||
            ruleOptions.freq == RRule.YEARLY) {
            if(ruleOptions.interval) {
                recurrenceForm.$selector.find(".form-entry input[name='interval']").val(ruleOptions.interval);
            }

            if(ruleOptions.count) {
                recurrenceForm.$selector.find(".form-entry input[name='recurrence-form-end-by'][value='count']").prop("checked", true);
                recurrenceForm.$selector.find(".form-entry input[name='count']").val(ruleOptions.count);
            }
            if(ruleOptions.until) {
                recurrenceForm.$selector.find(".form-entry input[name='recurrence-form-end-by'][value='until']").prop("checked", true);
                recurrenceForm.$selector.find(".form-entry input[name='until']").val(ruleOptions.until.toString());
            }
        }
        if(ruleOptions.freq == RRule.DAILY) {
            recurrenceForm.$selector.find("select[name='freq']").val("daily");
        }
        else if(ruleOptions.freq == RRule.WEEKLY) {
            recurrenceForm.$selector.find("select[name='freq']").val("weekly");
            if(ruleOptions.byweekday) {
                recurrenceForm.$selector.find(".form-entry.week-freq-on input[type=checkbox]").each(function() {
                    var $checkBox = $(this);

                    $checkBox.prop("checked", ruleOptions.byweekday.indexOf(parseInt($checkBox.val())) >= 0);
                });
            }
        }
        else if(ruleOptions.freq == RRule.MONTHLY) {
            recurrenceForm.$selector.find("select[name='freq']").val("monthly");

            if(ruleOptions.bynweekday && ruleOptions.bynweekday.length > 0) {
                recurrenceForm.$selector.find(".form-entry input[name='recurrence-form-month-freq-repeat-on'][value='day-of-week']").prop("checked", true);
            }
        }
        else if(ruleOptions.freq == RRule.YEARLY) {
            recurrenceForm.$selector.find("select[name='freq']").val("yearly");
        }
        else {

        }

        if(ruleOptions.until) {
            var until = ruleOptions.until;
            recurrenceForm.$selector.find("input[name='until']").val(moment(until).format("YYYY-MM-DD"));
        }
    }
    recurrenceForm.changeFrequence();
    recurrenceForm.initActions();

    recurrenceForm.ruleChanged();
}

RecurrenceForm.prototype.changeFrequence = function() {
    var recurrenceForm = this;
    if(recurrenceForm.getFrequence() == "daily") {
        recurrenceForm.$selector.find(".form-entry.every").show();
        recurrenceForm.$selector.find(".form-entry.week-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.month-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.end").show();

        recurrenceForm.$selector.find(".repeat-every-what").html("days");
    }
    else if(recurrenceForm.getFrequence() == "weekly") {
        recurrenceForm.$selector.find(".form-entry.every").show();
        recurrenceForm.$selector.find(".form-entry.week-freq-on").show();
        recurrenceForm.$selector.find(".form-entry.month-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.end").show();

        recurrenceForm.$selector.find(".repeat-every-what").html("weeks");
    }
    else if(recurrenceForm.getFrequence() == "monthly") {
        recurrenceForm.$selector.find(".form-entry.every").show();
        recurrenceForm.$selector.find(".form-entry.week-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.month-freq-on").show();
        recurrenceForm.$selector.find(".form-entry.end").show();

        recurrenceForm.$selector.find(".repeat-every-what").html("months");
    }
    else if(recurrenceForm.getFrequence() == "yearly") {
        recurrenceForm.$selector.find(".form-entry.every").show();
        recurrenceForm.$selector.find(".form-entry.week-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.month-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.end").show();

        recurrenceForm.$selector.find(".repeat-every-what").html("years");
    }
    else {
        recurrenceForm.$selector.find(".form-entry.every").hide();
        recurrenceForm.$selector.find(".form-entry.week-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.month-freq-on").hide();
        recurrenceForm.$selector.find(".form-entry.end").hide();
    }
};
RecurrenceForm.prototype.initActions = function() {
    var recurrenceForm = this;
    recurrenceForm.$selector.find("select[name='freq']").change(function() {
       recurrenceForm.changeFrequence();
       recurrenceForm.ruleChanged();
    });

    recurrenceForm.$selector.find(".form-entry input").change(function() {
        recurrenceForm.ruleChanged();
    });
};
RecurrenceForm.prototype.ruleChanged = function() {
    var recurrenceForm = this;
    var ruleOptions = {};
    var rstart = recurrenceForm.parentEventTile.getEventStartEnd().start;

    if(recurrenceForm.getFrequence() == "daily") {
        ruleOptions.freq =  RRule.DAILY;
    }
    else if(recurrenceForm.getFrequence() == "weekly") {
        ruleOptions.freq = RRule.WEEKLY;
        ruleOptions.byweekday =  recurrenceForm.$selector.find(".form-entry.week-freq-on input[type=checkbox]:checked").map(function () {
                var $checkBox = $(this);
                return recurrenceForm.weekDays[parseInt($checkBox.val())];
            }).get();
    }
    else if(recurrenceForm.getFrequence() == "monthly") {
        ruleOptions.freq = RRule.MONTHLY;

        if(recurrenceForm.$selector.find(".form-entry input[name='recurrence-form-month-freq-repeat-on'][value='day-of-week']:checked").length > 0) {
            var nth = Math.floor((rstart.date()-1)/7) + 1;
            if(nth > 4) nth = -1;

            ruleOptions.byweekday = [recurrenceForm.weekDays[rstart.isoWeekday() - 1].nth(nth)];
        }else{
            ruleOptions.bymonthday = rstart.date();
        }
    }
    else if(recurrenceForm.getFrequence() == "yearly") {
        ruleOptions.freq = RRule.YEARLY;
        ruleOptions.bymonth = rstart.month() + 1;
        ruleOptions.bymonthday = rstart.date();
    }

    if(recurrenceForm.getFrequence() == "daily" ||
        recurrenceForm.getFrequence() == "weekly" ||
        recurrenceForm.getFrequence() == "monthly" ||
        recurrenceForm.getFrequence() == "yearly"
        ) {
        var interval = parseInt(recurrenceForm.$selector.find("input[name='interval']").val());
        if(interval && interval > 1) {
            ruleOptions.interval = interval;
        }

        var recurrenceEnd = recurrenceForm.$selector.find("input[name='recurrence-form-end-by']:checked").val();
        if(recurrenceEnd == "count") {
            var count = parseInt(recurrenceForm.$selector.find("input[name='count']").val());
            if(!count) count = 1;
            ruleOptions.count = count;
        }
        else if(recurrenceEnd == "until") {
            var mUntil = moment(recurrenceForm.$selector.find("input[name='until']").val());
            mUntil.add(1, 'd');
            ruleOptions.until = mUntil.toDate();
        }

        recurrenceForm.rule = new RRule(ruleOptions);
        recurrenceForm.rrule = recurrenceForm.rule.toString();
        recurrenceForm.$selector.find(".recurrence-as-text").html(recurrenceForm.rule.toText());
    }
    else {
        recurrenceForm.rule = null;
        recurrenceForm.rrule = "";
        recurrenceForm.$selector.find(".recurrence-as-text").html("No recurrence");
    }



    if(recurrenceForm.ruleChangedCallback) {
        recurrenceForm.ruleChangedCallback(recurrenceForm);
    }
};

RecurrenceForm.prototype.getText = function() {
    var recurrenceForm = this;
    if(recurrenceForm.rule) {
        return "Recurs " + recurrenceForm.rule.toText();
    }
    else {
        return "Don't recur ";
    }
};

RecurrenceForm.prototype.getFrequence = function() {
    var recurrenceForm = this;
    return recurrenceForm.$selector.find("select[name='freq']").val();
};

RecurrenceForm.prototype.redraw = function() {
    var recurrenceForm = this;
    recurrenceForm.$selector.html(HandlebarsTemplates['event_tile/recurrence_form']());
};