function Calendar($selector, params) {

    // Set initial parameters
    this.$selector = $selector;
    this.initialData = {
        email: null,
        mode: "suggest_dates",
        duration: 60,
        date_times: [],
        other_emails: []
    };
    for (var paramName in params) {
        this.initialData[paramName] = params[paramName];
    }

    // Init variables
    this.accountPreferences = {};
    this.calendars = [];
    this.shouldDisplayWeekends = false;
    this.eventDataX = [];
    this.events = [];
    this.eventsToCheck = [];
    this.start = null;
    this.end = null;
    this.eventBeingAdded = null;

    var calendar = this;



    // Event handlers
    calendar.$selector.find("#event-details-container").click(function (e) {
        calendar.clickEventDetailsContainer(e);
    });
    calendar.$selector.find("#calendar-timezone").change(function (e) {
        calendar.changeCalendarTimezone(e);
    });
    calendar.$selector.find("#close-calendars-list-popup").click(function (e) {
        calendar.$selector.find("#calendars-list-popup").hide();
    });
    calendar.$selector.find("#weekends-checkbox").change(function (e) {
        calendar.changeWeekendsCheckbox(e);
    });
    calendar.$selector.find("#minimize-button").click(function(e) {
        calendar.clickMinimizeButton(e);
    });


    // Init fetching
    calendar.$selector.find(".global-loading-message").html("Loading account preferences...");
    this.fetchAccountPreferences(function () {
        calendar.$selector.find(".global-loading-message").html("Loading account calendars...");
        calendar.fetchCalendars(function () {
            for(var i=0; i < this.initialData.date_times.length; i++) {

                var start = moment(this.initialData.date_times[i]).tz(calendar.getCalendarTimezone());
                var end = start.clone();
                end.add('m', calendar.getCurrentDuration());
                var eventData = calendar.generateEventData({
                    start: start,
                    end: end
                });
                eventData.editable = false;
                eventData.color = "#ccc";
                this.eventsToCheck.push(eventData);
            }

            calendar.fullCalendarInit();
            calendar.$selector.find(".global-loading").fadeOut();
        });
    });
}

Calendar.prototype.getMode = function () {
    var calendar = this;
    return calendar.initialData.mode;
};

Calendar.prototype.shouldDisplayCalId = function (calId, email) {
    var calendar = this;

    return (calendar.accountPreferences[email] &&
        calendar.accountPreferences[email].calendars_to_show.indexOf(calId) > -1)
        || calId == "juliedesk-unavailable";

};

Calendar.prototype.updateCurrentEventDateFromInput = function ($container) {
    var calendar = this;
    var mStartDate = moment($container.find("input.start-date").val());
    mStartDate.hours(parseInt($container.find(".start-hours").val()));
    mStartDate.minutes(parseInt($container.find(".start-minutes").val()));
    $container.find(".start").html(mStartDate.format("LLL"));

    calendar.currentEvent.start = moment.tz(mStartDate.format(), $("#calendar-timezone").val());

    var mEndDate = moment($container.find("input.end-date").val());
    mEndDate.hours(parseInt($container.find(".end-hours").val()));
    mEndDate.minutes(parseInt($container.find(".end-minutes").val()));
    $container.find(".end").html(mEndDate.format("LLL"));

    calendar.currentEvent.end = moment.tz(mEndDate.format(), $("#calendar-timezone").val());
};
Calendar.prototype.redrawCalendarsListPopup = function () {
    var calendar = this;

    calsId = [];
    calsSum = [];
    colorIds = [];

    var $calendarsListPopup = $("#calendars-list-popup");
    $calendarsListPopup.find(".calendars").html("");

    calendar.$selector.find("#weekends-checkbox").removeProp("checked");
    if (calendar.shouldDisplayWeekends) {
        calendar.$selector.find("#weekends-checkbox").prop("checked", true);
    }

    var groupedCalendars = _.groupBy(calendar.calendars, 'email');
    for(var email in groupedCalendars) {
        var categoryName = email;
        if(categoryName == "undefined") categoryName = "Other";
        $calendarsListPopup.find(".calendars").append($("<div>").addClass("account-email-category").html(categoryName));
        $(groupedCalendars[email]).each(function (k, calendarItem) {


            calsId.push(calendarItem.id);
            calsSum.push(calendarItem.summary);
            colorIds.push(calendarItem.colorId);

            var $div = $("<div>").addClass("calendar-item");
            var $checkbox = $("<input type='checkbox'>").prop("disabled", "disabled");

            if (calendar.shouldDisplayCalId(calendarItem.id, calendarItem.email)) {
                $checkbox.prop("checked", "checked");
            }
            $div.append($checkbox);
            $div.append($("<div>").addClass('circle').css({backgroundColor: calendar.getCalendarsColors()[parseInt(calendarItem.colorId)].background}));
            $div.append($("<span>").addClass('calendar-name').html(calendarItem.summary));

            if (calendar.shouldDisplayCalId(calendarItem.id, calendarItem.email)) {
                $calendarsListPopup.find(".calendars").append($div);
            }
        });
    }

};

Calendar.prototype.fetchCalendars = function (callback) {
    var calendar = this;
    calendar.showLoadingSpinner();

    var allEmails = calendar.initialData.other_emails.slice();
    allEmails.unshift(calendar.initialData.email);
    var accountsToWait = 0;
    calendar.calendars = [];

    for(var i = 0; i < allEmails.length; i++) {
        var email = allEmails[i];
        accountsToWait ++;
        CommonHelpers.externalRequest({
            action: "calendars",
            email: email
        }, function (response) {
            for(var j=0; j <response.items.length; j++) {
                var calendarItem = response.items[j];
                calendarItem.email = response.email;
                calendar.calendars.push(calendarItem);
            }

            accountsToWait --;
            if(accountsToWait == 0) {
                calendar.hideLoadingSpinner();

                calendar.calendars.push({
                    id: "juliedesk-unavailable",
                    summary: "Non-working hours",
                    colorId: "0"
                });
                calendar.redrawTimeZoneSelector();
                calendar.redrawCalendarsListPopup();
                if (callback) callback();
            }
        });
    }
};


Calendar.prototype.showLoadingSpinner = function (message) {
    if (!message) message = "Loading...";
    this.$selector.find(".local-loading-message").html(message);
    this.$selector.find(".local-loading").fadeIn(200);
};

Calendar.prototype.hideLoadingSpinner = function () {
    this.$selector.find(".local-loading").fadeOut(200);
};

Calendar.prototype.addForbiddenEvents = function(events) {
    var calendar = this;
    var result = [];
    for(var i in events) {
        var event = {
            title: events[i].title,
            start: events[i].start,
            end: events[i].end,
            url: "NOTAVAILABLE-" + events[i].start,
            startEditable: false,
            durationEditable: false,
            color: "#444",
            textColor: "#aaa",
            calIndex: calendar.calendars.length -1,
            isNotAvailableEvent: true
        };
        result.push(event);
    }
    calendar.$selector.find('#calendar').fullCalendar('addEventSource', result);
};

Calendar.prototype.getEventsToCheck = function() {
    var calendar = this;
    var result = [];
    $.each(calendar.eventsToCheck, function(k, event) {
        var start = event.start.clone().tz(calendar.getCalendarTimezone()).format();
        var end = event.end.clone().tz(calendar.getCalendarTimezone()).format();

        result.push({
            title: event.title,
            start: start,
            end: end,
            color: event.color,
            durationEditable: event.durationEditable,
            editable: event.editable,
            beingAdded: event.beingAdded
        });
    });
    return result;

}

Calendar.prototype.addEventsToCheckIfNeeded = function() {
    var calendar = this;
    if(calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
        return ev.beingAdded
            && !ev.editable;
    }).length == 0) {
        calendar.$selector.find('#calendar').fullCalendar('addEventSource', calendar.getEventsToCheck());
    }
};

Calendar.prototype.fetchAllAccountsEvents = function(start, end) {
    var calendar = this;

    for(var email in calendar.accountPreferences) {
        calendar.fetchEvents(start, end, calendar.accountPreferences[email]);
    }
};
Calendar.prototype.fetchEvents = function (start, end, accountPreferencesHash) {
    var calendar = this;
    calendar.showLoadingSpinner("Loading events...");

    if(!accountPreferencesHash) {
        accountPreferencesHash = calendar.accountPreferences;
    }



    CommonHelpers.externalRequest({
        action: "events",
        email: accountPreferencesHash.email,
        start: start,
        end: end
    }, function (response) {
        calendar.addCal(calendar.getNonAvailableEvents(start, end, accountPreferencesHash), calendar.calendars.length - 1);
        calendar.addEventsToCheckIfNeeded();

        calendar.addAllCals(response.items);
        calendar.hideLoadingSpinner();
    });
};

Calendar.prototype.getNonAvailableEvents = function (startTime, endTime, accountPreferencesHash) {
    var calendar = this;
    var result = [];

    var calIndex;

    for (var day in accountPreferencesHash.unbooking_hours) {
        var slots = accountPreferencesHash.unbooking_hours[day];
        var mCurrentTime = moment(startTime);
        while (mCurrentTime < moment(endTime)) {
            if (mCurrentTime.locale("en").format("ddd").toLowerCase() == day) {
                $(slots).each(function (k, slot) {
                    var eventStartTime = mCurrentTime.clone();
                    eventStartTime.hours(slot[0] / 100);
                    eventStartTime.minutes(slot[0] % 100);

                    var eventEndTime = mCurrentTime.clone();
                    eventEndTime.hours(slot[1] / 100);
                    eventEndTime.minutes(slot[1] % 100);

                    calIndex = k;

                    var event = {
                        summary: "Not available",
                        start: {
                            dateTime: eventStartTime.format("YYYY-MM-DDTHH:mm:ssZ")
                        },
                        end: {
                            dateTime: eventEndTime.format("YYYY-MM-DDTHH:mm:ssZ")
                        },
                        url: "NOTAVAILABLE-" + eventStartTime.format("YYYY-MM-DDTHH:mm:ssZ"),
                        startEditable: false,
                        durationEditable: false,
                        color: "#444",
                        textColor: "#aaa",
                        calIndex: k,
                        isNotAvailableEvent: true
                    };
                    result.push(event);
                });
            }
            mCurrentTime.add(1, 'days');
        }
    }

    for(var i=0; i<accountPreferencesHash.temporary_unavailabilities.length; i++) {
        var unavailability = accountPreferencesHash.temporary_unavailabilities[i];
        var event = {
            summary: "Temporary not available",
            start: {
                dateTime: moment(unavailability.start).format("YYYY-MM-DDTHH:mm:ssZ")
            },
            end: {
                dateTime: moment(unavailability.end).format("YYYY-MM-DDTHH:mm:ssZ")
            },
            url: "NOTAVAILABLE-" + moment(unavailability.start).format("YYYY-MM-DDTHH:mm:ssZ"),
            startEditable: false,
            durationEditable: false,
            color: "#444",
            textColor: "#aaa",
            calIndex: calIndex,
            isNotAvailableEvent: true
        };
        result.push(event);
    }
    return result;
};

Calendar.prototype.getCalendarTimezone = function () {
    return this.$selector.find("#calendar-timezone").val()
};

Calendar.prototype.eventDataFromEvent = function (ev, calIndex) {
    var calendar = this;
    var eventData;

    var startTime = ev.start.dateTime;
    var endTime = ev.end.dateTime;
    var allDay = false;

    if (ev.start.dateTime === undefined) {
        startTime = ev.start.date;
        endTime = ev.end.date;
        allDay = true;
    }


    var sstartTime = moment(startTime).tz(calendar.getCalendarTimezone()).format();
    var sendTime = moment(endTime).tz(calendar.getCalendarTimezone()).format();


    // Dont zone non-booking hours
    if (calIndex == calendar.calendars.length - 1) {
        sstartTime = startTime;
        sendTime = endTime;
    }
    eventData = {
        id: ev.id,
        title: ev.summary,
        allDay: allDay,
        start: sstartTime,
        end: sendTime,
        url: ev.htmlLink,
        location: ev.location,
        description: ev.description,
        attendees: ev.attendees,
        startEditable: false,
        durationEditable: false,
        color: calendar.getCalendarsColors()[parseInt(colorIds[calIndex])].background,
        textColor: "#fff",//colors[parseInt(colorIds[calIndex])].foreground,
        calIndex: calIndex,
        sequence: ev.sequence,
        isNotAvailableEvent: ev.isNotAvailableEvent
    };
    eventData.isLocated = calendar.computeIsLocated(eventData);
    return eventData;
};

Calendar.prototype.computeIsLocated = function (event) {
    if (event.isNotAvailableEvent) {
        return false;
    }
    if (moment(event.end).diff(moment(event.start), 'minutes') < 60) {
        return false;
    }
    if (/ (call)|(tel)|(confcall) /.test(event.summary)) {
        return false;
    }

    return true;
};

Calendar.prototype.addAllCals = function (calEvents) {
    var calendar = this;
    for (var k = 0; k < calEvents.length; k++) {
        var ev = calEvents[k];

        var x = 0;
        for (var i = 0; i < calendar.calendars.length; i++) {
            if (calendar.calendars[i].id == ev.calId) {
                x = i;
                break;
            }
        }
        var eventData = calendar.eventDataFromEvent(ev, x);

        calendar.eventDataX.push(eventData);
    }
    calendar.$selector.find('#calendar').fullCalendar('addEventSource', calendar.eventDataX);
    calendar.eventDataX = [];
};
Calendar.prototype.addCal = function (calEvents, x) {
    var calendar = this;
    for (var k = 0; k < calEvents.length; k++) {
        var ev = calEvents[k];
        var eventData = calendar.eventDataFromEvent(ev, x);

        calendar.eventDataX.push(eventData);
    }

    calendar.$selector.find('#calendar').fullCalendar('addEventSource', calendar.eventDataX);
    calendar.eventDataX = [];
    calendar.hideLoadingSpinner();
};


Calendar.prototype.drawExternalEventCreation = function () {
    var calendar = this;
    if (calendar.getMode() == "suggest_dates") return;
    if (calendar.eventBeingAdded) {
        window.postMessage({
            message: "drawExternalEventCreation",
            eventStart: calendar.eventBeingAdded.start.format()
        }, "*");
    }
};

Calendar.prototype.changeWeekendsCheckbox = function () {
    var calendar = this;

    var currentDate = calendar.$selector.find('#calendar').fullCalendar('getDate');
    var currentEvents = calendar.$selector.find('#calendar').fullCalendar('clientEvents');

    calendar.$selector.find('#calendar').fullCalendar('destroy');
    calendar.shouldDisplayWeekends = calendar.$selector.find("#weekends-checkbox:checked").length > 0;

    calendar.fullCalendarInit();

    $('#calendar').fullCalendar('gotoDate', currentDate);
    $('#calendar').fullCalendar('addEventSource', currentEvents);
};

    Calendar.prototype.goToDateTime = function(dateTime) {
    var calendar = this;
    calendar.$selector.find("#calendar").fullCalendar('gotoDate', moment(dateTime));
};

Calendar.prototype.selectSuggestedEvent = function(dateTime) {
    var calendar = this;
    var matchingEvents = calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
        return ev.beingAdded
            && ev.start.isSame(moment(dateTime));
    });
    if(matchingEvents.length > 0) {
        calendar.addEvent(matchingEvents[0]);
        calendar.$selector.find("#calendar").fullCalendar('gotoDate', matchingEvents[0].start);
    }
};

Calendar.prototype.refreshEvents = function() {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar('removeEvents');
    calendar.fetchAllAccountsEvents(calendar.dispStart.format() + "T00:00:00Z", calendar.dispEnd.format() + "T00:00:00Z");
};

Calendar.prototype.addEvent = function (event) {
    var calendar = this;
    if (calendar.getMode() == "suggest_dates") {
        calendar.events.push(event);
    }
    else {
        calendar.$selector.find("#calendar").fullCalendar("removeEvents", function (ev) {
            return ev.beingAdded
                && ev.editable
                && !ev.start.isSame(event.start);
        });
        $.each(calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
            return ev.beingAdded;
        }), function() {
            this.color = "#ccc";
        });
        calendar.eventBeingAdded = calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
            return ev.beingAdded
                && ev.start.isSame(event.start);
        })[0];
        calendar.eventBeingAdded.color = "rgb(40, 166, 203)";
        calendar.$selector.find('#calendar').fullCalendar('rerenderEvents');
        calendar.updateEventCreation();
    }

};

Calendar.prototype.getLocale = function () {
    return "fr";
};

Calendar.prototype.getCurrentDuration = function () {
    var calendar = this;
    return calendar.initialData.duration;
};

Calendar.prototype.updateEventCreation = function () {
    var calendar = this;
    calendar.drawExternalEventCreation();
};


Calendar.prototype.addEventsCountLabels = function () {
    var calendar = this;
    calendar.$selector.find(".events-count-label").remove();
    var startDate = calendar.$selector.find('#calendar').fullCalendar("getView").start;
    var days = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
    var minCount = 1000;
    for (var i = 0; i < 7; i++) {
        var day = days[i];
        var date = startDate.clone().add(i, "days");

        var events = calendar.$selector.find('#calendar').fullCalendar('clientEvents', function (event) {
            return !event.beingAdded
                && event.calIndex != calendar.calendars.length - 1
                && event.start < date.clone().endOf('day')
                && event.end > date.clone().startOf('day');
        });

        var count = events.length;
        var className = "warning";
//        if (count < calendar.accountPreferences.max_number_of_appointments) {
//            className = "ras";
//        }
//        else {
//            if (calendar.$selector.find(".fc-widget-header.fc-" + day).length > 0) {
//                minCount = Math.min(minCount, count);
//            }
//        }


        calendar.$selector.find(".fc-widget-header.fc-" + day).append($("<div>").addClass("events-count-label").addClass("count-" + count).addClass(className).html("" + count));
    }
    calendar.$selector.find(".events-count-label.count-" + minCount).addClass("best-of-worst");
};

Calendar.prototype.changeCalendarTimezone = function (e) {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar('removeEvents');
    calendar.events = [];
    calendar.drawEventList();

    calendar.fetchAllAccountsEvents(calendar.dispStart.format() + "T00:00:00Z", calendar.dispEnd.format() + "T00:00:00Z");
};

Calendar.prototype.drawEventList = function () {
    var calendar = this;
    calendar.drawExternalEventsList();
};

Calendar.prototype.drawExternalEventsList = function () {
    var calendar = this;
    if (calendar.getMode() == "create_event") return;
    var dateTimes = calendar.events.sort(function (a, b) {
        if (a.start.isAfter(b.start))return 1; else return -1;
    });
    dateTimes = $.map(dateTimes, function (v) {
        return moment.tz(v.start.format(), calendar.getCalendarTimezone()).format();
    });

    window.postMessage({
        message: "drawExternalEventsList",
        date_times: dateTimes
    }, "*");
};


Calendar.prototype.redrawTimeZoneSelector = function () {
    var calendar = this;

    console.log(calendar.calendars);
    var allTimeZones = [];
    $(calendar.calendars).each(function (k, calendarItem) {
        if (calendar.shouldDisplayCalId(calendarItem.id, calendarItem.email)) {
            if (calendarItem.timezone && allTimeZones.indexOf(calendarItem.timezone) == -1) {
                allTimeZones.push(calendarItem.timezone);
                calendar.$selector.find("#calendar-timezone").append(
                    $("<option>").val(calendarItem.timezone).html(calendarItem.timezone + " (" + calendarItem.id + ")")
                );
            }
        }
    });

    if(allTimeZones.indexOf(calendar.initialData.default_timezone_id) == -1) {
        calendar.$selector.find("#calendar-timezone").append(
            $("<option>").val(calendar.initialData.default_timezone_id).html(calendar.initialData.default_timezone_id)
        );
    }
};
Calendar.prototype.fetchAccountPreferences = function (callback) {
    var calendar = this;

    var accountsToWait = 0;
    var allEmails = calendar.initialData.other_emails.slice();
    allEmails.unshift(calendar.initialData.email);
    for(var i = 0; i<allEmails.length; i++) {
        accountsToWait ++;
        var email = allEmails[i];
        CommonHelpers.externalRequest({
            action: "getJulieDeskPreferences",
            email: email
        }, function (response) {
            calendar.accountPreferences[response.email] = response;

            accountsToWait --;
            if(accountsToWait == 0 && callback) callback();
        });
    }
};
Calendar.prototype.clickMinimizeButton = function(e) {
    var calendar = this;
    calendar.$selector.addClass("minimized");
};