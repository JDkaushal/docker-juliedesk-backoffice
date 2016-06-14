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

    this.fakeCalendarIds = ["juliedesk-unavailable", "juliedesk-strong-constraints", "juliedesk-light-constraints", "juliedesk-public-holidays"];

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

    this.firstLoaded = false;

    this.selectedEvents = [];
    this.publicHolidaysAdded = false;

    this.suggestedEvents = [];

    var calendar = this;

    // Event handlers
    calendar.$selector.find("#event-details-container").click(function (e) {
        calendar.clickEventDetailsContainer(e);
    });
    calendar.$selector.find("#calendar-timezone").change(function (e) {
        calendar.changeCalendarTimezone(false);
    });
    calendar.$selector.find("#close-calendars-list-popup").click(function (e) {
        calendar.$selector.find("#calendars-list-popup").hide();
    });
    calendar.$selector.find("#weekends-checkbox").change(function (e) {
        calendar.changeWeekendsCheckbox(e);
    });
    calendar.$selector.on("change", ".calendar-item input[type='checkbox']", function (e) {
        calendar.changeShowCalendarCheckbox(e);
    });
    calendar.$selector.find("#minimize-button").click(function(e) {
        calendar.clickMinimizeButton(e);
    });

    var allEmailsForTracking = calendar.initialData.other_emails.slice();
    allEmailsForTracking.unshift(calendar.initialData.email);

    calendar.distinctIdForTracking = "" + Date.now() + "-" + allEmailsForTracking.join("|");
    // Init fetching
    trackEvent("Click_on_open_calendar", {
        distinct_id: calendar.distinctIdForTracking,
        client_emails: allEmailsForTracking,
        initial_action: "Open calendar"
    });
    calendar.$selector.find(".global-loading-message").html("Loading account preferences...");
    this.fetchAccountPreferences(function () {
        calendar.$selector.find(".global-loading-message").html("Loading account calendars...");
        calendar.fetchCalendars(function () {
            for(var i=0; i < calendar.initialData.date_times.length; i++) {
                var dateObject = calendar.initialData.date_times[i];
                var start = moment(dateObject.date).tz(calendar.getCalendarTimezone());
                var end = start.clone();
                end.add('m', calendar.getCurrentDuration());

                var title = "Suggested";
                if(dateObject.mode == "to_check") {
                    title = calendar.generateDelayTitle();
                }else {
                    calendar.suggestedEvents.push(dateObject);
                }
                var eventData = calendar.generateEventData({
                    title: title,
                    start: start,
                    end: end
                });
                eventData.editable = false;
                eventData.color = "#ccc";
                console.log('events to check', eventData);
                calendar.eventsToCheck.push(eventData);
            }

            calendar.fullCalendarInit();

            calendar.$selector.find(".global-loading").fadeOut();
        });
    });
}

Calendar.prototype.selectEvent = function (event) {
    var calendar = this;
    if(event.isSelected) {
        event.isSelected = false;
        calendar.selectedEvents.splice(calendar.selectedEvents.indexOf(event), 1)
    }
    else {
        event.isSelected = true;
        calendar.selectedEvents.push(event);
    }

    calendar.drawExternalEventSelection();
    calendar.$selector.find('#calendar').fullCalendar('rerenderEvents');
};

Calendar.prototype.registerCalendarCallback = function(type, callback) {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar(type, callback);
};

Calendar.prototype.getMode = function () {
    var calendar = this;
    return calendar.initialData.mode;
};

Calendar.prototype.shouldDisplayCalendarItem = function (calendarItem) {
    var calendar = this;
    var accountPreferences = calendar.accountPreferences[calendarItem.email];

    return (
        accountPreferences &&
        accountPreferences.calendars_to_show[calendarItem.calendar_login_username] &&
        accountPreferences.calendars_to_show[calendarItem.calendar_login_username].indexOf(calendarItem.id) > -1
        ) ||
        calendar.isFakeCalendarId(calendarItem.id);

};

Calendar.prototype.isFakeCalendarId = function(calendarId) {
    var calendar = this;
    return calendar.fakeCalendarIds.indexOf(calendarId) > -1;
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
Calendar.prototype.generateDelayTitle = function() {
    var calendar = this;
    var delayB = _.max(calendar.accountPreferences, function(accountPreference) {
        return accountPreference.delay_between_appointments;
    }).delay_between_appointments;

    return "Delay: " + delayB + "'";
}
Calendar.prototype.redrawCalendarsListPopup = function () {
    var calendar = this;

    var $calendarsListPopup = $("#calendars-list-popup");
    $calendarsListPopup.find(".calendars").html("");

    calendar.$selector.find("#weekends-checkbox").removeProp("checked");
    if (calendar.shouldDisplayWeekends) {
        calendar.$selector.find("#weekends-checkbox").prop("checked", true);
    }

    var groupedCalendars = _.groupBy(calendar.calendars, 'email');
    for(var email in groupedCalendars) {
        var groupedCalendarsByCalendarLogin = _.groupBy(groupedCalendars[email], 'calendar_login_username');
        for(var calendarLoginUsername in groupedCalendarsByCalendarLogin) {
            var categoryName = email + " - " + calendarLoginUsername;
            if(email == "undefined") categoryName = "Other";
            $calendarsListPopup.find(".calendars").append($("<div>").addClass("account-email-category").html(categoryName));
            $(groupedCalendarsByCalendarLogin[calendarLoginUsername]).each(function (k, calendarItem) {
                var $div = $("<div>").addClass("calendar-item");
                $div.data("email", email);
                $div.data("calendar-id", calendarItem.id);
                $div.data("calendar-login-username", calendarItem.calendar_login_username);

                var $checkbox = $("<input type='checkbox'>");

                if(email != calendar.initialData.email) {
                    $checkbox.prop("disabled", "disabled");
                }

                if (calendar.shouldDisplayCalendarItem(calendarItem)) {
                    $checkbox.prop("checked", "checked");
                }
                $div.append($checkbox);
                $div.append($("<div>").addClass('circle').css({backgroundColor: calendar.getCalendarColor(calendarItem)}));
                $div.append($("<span>").addClass('calendar-name').html(calendarItem.summary));


                $calendarsListPopup.find(".calendars").append($div);
            });
        }
    }

};

Calendar.prototype.allEmails = function() {
    var calendar = this;
    var allEmails = calendar.initialData.other_emails.slice();
    allEmails.unshift(calendar.initialData.email);
    return allEmails;
};

Calendar.prototype.findAccountEmailForEvent = function(event) {
    if(isStagingEnv()){
        return getStagingTargetEmail();
    }else{
        var calendar = this;
        if(event.calendar_login_email) {
            return event.calendar_login_email;
        }
        var calendarId = event.calId;

        var calendarObject = _.find(calendar.calendars, function(calendar) {
            return calendar.id == calendarId;
        });
        return calendarObject.email;
    }
};

Calendar.prototype.fetchCalendars = function (callback) {
    var calendar = this;
    calendar.showLoadingSpinner();


    var allEmails = calendar.allEmails();
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
                calendar.calendars.push({
                    id: "juliedesk-strong-constraints",
                    summary: "Contacts strong constraints",
                    colorId: "30"
                });
                calendar.calendars.push({
                    id: "juliedesk-light-constraints",
                    summary: "Contacts light constraints",
                    colorId: "31"
                });

                calendar.calendars.push({
                    id: "juliedesk-public-holidays",
                    summary: "Public holidays",
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
    this.$selector.find(".local-loading-container").fadeIn(200);
};

Calendar.prototype.hideLoadingSpinner = function () {
    this.$selector.find(".local-loading-container").fadeOut(200);
};

Calendar.prototype.addForbiddenEvents = function(events) {
    var calendar = this;
    var result = [];
    for(var i in events) {
        var start = moment.tz(events[i].start, "UTC").tz(calendar.getCalendarTimezone()).format();
        var end = moment.tz(events[i].end, "UTC").tz(calendar.getCalendarTimezone()).format();

        var event = {
            title: events[i].title,
            start: start,
            end: end,
            url: "NOTAVAILABLE-" + events[i].start,
            startEditable: false,
            durationEditable: false,
            color: "#444",
            textColor: "#aaa",
            calId: "juliedesk-unavailable",
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

};

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
    var localWaitingAccounts = 0;

    var allEmailsForTracking = calendar.initialData.other_emails.slice();
    allEmailsForTracking.unshift(calendar.initialData.email);
    trackEvent("Click_on_open_calendar", {
        distinct_id: calendar.distinctIdForTracking,
        client_emails: allEmailsForTracking,
        initial_action: "Fetching events"
    });

    calendar.showLoadingSpinner("Loading events...");

    calendar.addCal(calendar.getConstraintsDataEvents(start, end));
    for(var email in calendar.accountPreferences) {
        localWaitingAccounts += 1;

        calendar.fetchEvents(start, end, calendar.accountPreferences[email], function() {
            localWaitingAccounts -= 1;
            if(localWaitingAccounts == 0) {
                calendar.hideLoadingSpinner();

                if(calendar.initialData.calendarandEventsLoadedFirstTimeCallback) {
                    calendar.initialData.calendarandEventsLoadedFirstTimeCallback();
                    calendar.initialData.calendarandEventsLoadedFirstTimeCallback = null;
                }

                if(window.allCalendarEventsFetched) {
                    window.allCalendarEventsFetched();
                }
            }

            trackEvent("Calendar_is_opened", {
                distinct_id: calendar.distinctIdForTracking,
                client_emails: allEmailsForTracking
            });
        });
    }
};

Calendar.prototype.redrawFullCalendar = function() {
    var calendar = this;
    calendar.$selector.find("#calendar").fullCalendar("render");
};

Calendar.prototype.fetchEvents = function (start, end, accountPreferencesHash, callback) {
    var calendar = this;
    var travelTimeCalculator = $('#travel_time_calculator').scope();
    var unavailableEvents = [];
    var allEvents = [];

    CommonHelpers.externalRequest({
        action: "events",
        email: accountPreferencesHash.email,
        calendar_ids: accountPreferencesHash.calendar_ids_to_show_override,
        start: start,
        end: end
    }, function (response) {
        unavailableEvents = calendar.getNonAvailableEvents(start, end, accountPreferencesHash);

        calendar.addCal(unavailableEvents);
        calendar.addEventsToCheckIfNeeded();
        calendar.addAllCals(response.items);

        if(travelTimeCalculator) {
            // Allow us to detect easily if the events are following or followed by unavailable events
            allEvents.push(response.items);
            allEvents.push(unavailableEvents);

            travelTimeCalculator.processForClient(accountPreferencesHash, _.flatten(allEvents));
        }

        if(callback) callback();
    });
};
Calendar.prototype.getConstraintsDataEvents = function(startTime, endTime) {
    var result = [];
    var calendar = this;
    _.each(calendar.initialData.constraintsData, function(dataEntries, attendeeEmail) {
        var eventsFromData = ConstraintTile.getEventsFromData(dataEntries, moment(startTime), moment(endTime));
        _.each(eventsFromData.cant, function(ev) {

            var event = {
                summary: attendeeEmail + " not available",
                start: {
                    dateTime: ev.start.tz(calendar.getCalendarTimezone()).format()
                },
                end: {
                    dateTime: ev.end.tz(calendar.getCalendarTimezone()).format()
                },
                startEditable: false,
                durationEditable: false,
                calId: "juliedesk-strong-constraints",
                isNotAvailableEvent: true
            };
            result.push(event);
        });

        _.each(eventsFromData.dontPrefer, function(ev) {
            var event = {
                summary: attendeeEmail + " prefers not",
                start: {
                    dateTime: ev.start.tz(calendar.getCalendarTimezone()).format()
                },
                end: {
                    dateTime: ev.end.tz(calendar.getCalendarTimezone()).format()
                },
                startEditable: false,
                durationEditable: false,
                calId: "juliedesk-light-constraints",
                isNotAvailableEvent: true
            };
            result.push(event);
        });
    });


    return result;
};
Calendar.prototype.getNonAvailableEvents = function (startTime, endTime, accountPreferencesHash) {
    var calendar = this;
    var result = [];
    var currentTimezone = calendar.getCalendarTimezone();
    var usingAnotherTimeZone = window.threadAccount.default_timezone_id != currentTimezone;

    for (var day in accountPreferencesHash.unbooking_hours) {
        var slots = accountPreferencesHash.unbooking_hours[day];
        var mCurrentTime = moment(startTime);

        while (mCurrentTime < moment(endTime)) {
            if (mCurrentTime.locale("en").format("ddd").toLowerCase() == day) {

                var currentDay = mCurrentTime.day();
                $(slots).each(function (k, slot) {
                    var eventStartTime = mCurrentTime.clone().tz(accountPreferencesHash.default_timezone_id);
                    eventStartTime.day(currentDay);
                    eventStartTime.hours(slot[0] / 100);
                    eventStartTime.minutes(slot[0] % 100);

                    var eventEndTime = mCurrentTime.clone().tz(accountPreferencesHash.default_timezone_id);
                    eventEndTime.day(currentDay);
                    eventEndTime.hours(slot[1] / 100);
                    eventEndTime.minutes(slot[1] % 100);

                    if(usingAnotherTimeZone) {
                        eventStartTime.tz(currentTimezone);
                        eventEndTime.tz(currentTimezone);
                    }

                    if(accountPreferencesHash.default_timezone_id != currentTimezone) {
                        eventStartTime.tz(currentTimezone);
                        eventEndTime.tz(currentTimezone);
                    }

                    var event_title = "Not available";

                    if(accountPreferencesHash.full_name) {
                        event_title += ' [' +  accountPreferencesHash.full_name + ']';
                    }

                    var event = {
                        summary: event_title,
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
                        calId: "juliedesk-unavailable",
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
            calId: "juliedesk-unavailable",
            isNotAvailableEvent: true
        };
        result.push(event);
    }

    if(!calendar.publicHolidaysAdded) {
        for(var i=0; i<accountPreferencesHash.public_holidays_dates.length; i++) {
            var publicHoliday = accountPreferencesHash.public_holidays_dates[i];
            var mStartDate = moment(publicHoliday.date);
            var mEndDate = mStartDate.clone();
            mEndDate.add("d", 1);

            var event = {
                summary: "FERIE : " + publicHoliday.name,
                start: {
                    date: mStartDate.format("YYYY-MM-DD")
                },
                end: {
                    date: mEndDate.format("YYYY-MM-DD")
                },
                url: "PUBLIC-HOLLIDAY-" + publicHoliday.date + "-" + publicHoliday.name,
                startEditable: false,
                durationEditable: false,
                color: "#444",
                textColor: "#aaa",
                calId: "juliedesk-public-holidays",
                isNotAvailableEvent: true,
                busyLocked: true
            };
            result.push(event);
        }
        calendar.publicHolidaysAdded = true;
    }

    return result;
};

Calendar.prototype.getCalendarTimezone = function () {
    return this.$selector.find("#calendar-timezone").val()
};

Calendar.prototype.eventDataFromEvent = function (ev) {
    var calendar = this;
    var eventData;

    var startTime = ev.start.dateTime;
    var endTime = ev.end.dateTime;

    var travelTimeOriginalStartTime = undefined;
    var travelTimeOriginalEndTime = undefined;

    if(ev.isTravelTime) {
        travelTimeOriginalStartTime = ev.originalStart.dateTime;
        travelTimeOriginalEndTime = ev.originalEnd.dateTime;
    }

    if (ev.start.dateTime === undefined) {
        startTime = ev.start.date;
        endTime = ev.end.date;
    }


    var sstartTime = moment(startTime).tz(calendar.getCalendarTimezone()).format();
    var sendTime = moment(endTime).tz(calendar.getCalendarTimezone()).format();


    // Dont zone non-booking hours and all day events
    if (calendar.isFakeCalendarId(ev.calId) || ev.all_day) {
        sstartTime = startTime;
        sendTime = endTime;
    }

    var eventCalendar = _.find(calendar.calendars, function(calendarItem) {
        return calendarItem.id == ev.calId && calendar.shouldDisplayCalendarItem(calendarItem);
    });
    var color = calendar.getCalendarColor(null);
    if(eventCalendar) {
        color = calendar.getCalendarColor(eventCalendar);
    }

    //console.log(ev);
    eventData = {
        id: ev.id,
        title: ev.summary,
        allDay: ev.all_day,
        isTravelTime: ev.isTravelTime,
        isDefaultDelay: ev.isDefaultDelay,
        travelTime: ev.travelTime,
        eventInfoType: ev.eventInfoType,
        travelTimeGoogleDestinationUrl: ev.travelTimeGoogleDestinationUrl,
        isWarning: ev.isWarning,
        travelTimeOriginalStartTime: travelTimeOriginalStartTime,
        travelTimeOriginalEndTime: travelTimeOriginalEndTime,
        busy: ev.busy,
        start: sstartTime,
        end: sendTime,
        url: ev.htmlLink,
        location: ev.location,
        description: ev.description,
        attendees: ev.attendees,
        startEditable: false,
        durationEditable: false,
        color: color,
        calId: ev.calId,
        textColor: "#fff",
        sequence: ev.sequence,
        private: ev.private,
        owned: ev.owned,
        isNotAvailableEvent: ev.isNotAvailableEvent,
        recurringEventId: ev.recurringEventId,
        recurrence: ev.recurrence,
        preview: ev.preview,
        calendar_login_username: ev.calendar_login_username,
        calendar_login_type: ev.calendar_login_type,
        busyLocked: ev.busyLocked
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
        var eventData = calendar.eventDataFromEvent(ev);

        calendar.eventDataX.push(eventData);
    }
    calendar.$selector.find('#calendar').fullCalendar('addEventSource', calendar.eventDataX);
    calendar.eventDataX = [];
};
Calendar.prototype.addCal = function (calEvents) {
    var calendar = this;
    for (var k = 0; k < calEvents.length; k++) {
        var ev = calEvents[k];
        var eventData = calendar.eventDataFromEvent(ev);

        calendar.eventDataX.push(eventData);
    }

    calendar.$selector.find('#calendar').fullCalendar('addEventSource', calendar.eventDataX);
    calendar.eventDataX = [];
};


Calendar.prototype.drawExternalEventSelection = function () {
    var calendar = this;
    if (calendar.getMode() != "select_events") return;
    window.postMessage({
        message: "drawExternalEventSelection",
        events: _.map(calendar.selectedEvents, function(event) {

           var mStart = moment.tz(event.start.format(), calendar.getCalendarTimezone());
           var mEnd = moment.tz(event.end.format(), calendar.getCalendarTimezone());
           return {
               title: event.title,
               start: mStart.format(),
               end: mEnd.format(),
               attendees: event.attendees,
               id: event.id,
               calId: event.calId,
               duration: parseInt((mEnd - mStart) / 60000, 10),
               location: event.location,
               notes: event.description,
               calendar_login_username: event.calendar_login_username,
               url: event.url
           }
        })
    }, "*");
};

Calendar.prototype.drawExternalEventCreation = function () {
    var calendar = this;
    if (calendar.getMode() != "create_event") return;
    if (calendar.eventBeingAdded) {
        window.postMessage({
            message: "drawExternalEventCreation",
            eventStart: moment.tz(calendar.eventBeingAdded.start.format(), calendar.getCalendarTimezone()).format()
        }, "*");
    }
};

Calendar.prototype.changeShowCalendarCheckbox = function(e) {
    var calendar = this;
    calendar.accountPreferences[calendar.initialData.email].calendar_ids_to_show_override = calendar.getCheckedMainAccountCalendarIds();
    calendar.refreshEvents();
};

Calendar.prototype.getCheckedMainAccountCalendarIds = function(e) {
    var calendar = this;

    var result = {};

    $(".calendar-item input[type='checkbox']:checked").each(function() {
        var $calendarItem = $(this).closest(".calendar-item");
        if($calendarItem.data("email") == calendar.initialData.email) {
            var calendarId = $calendarItem.data("calendar-id");
            var calendarLoginUsername = $calendarItem.data("calendar-login-username");
            if(!result[calendarLoginUsername]) {
                result[calendarLoginUsername] = [];
            }
            result[calendarLoginUsername].push(calendarId);
        }
    });

    return result;
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

Calendar.prototype.findAndSelectEvent = function(params) {
    var calendar = this;
    var matchingEvents = calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
        return ev.start.isSame(moment(params.start)) && ev.end.isSame(moment(params.end)) && ev.title == params.title;
    });

    if(matchingEvents.length > 0) {
        calendar.selectEvent(matchingEvents[0]);
    }
};

Calendar.prototype.selectSuggestedEvent = function(dateTime) {
    var calendar = this;
    var matchingEvents = calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
        return ev.beingAdded
            && ev.start.isSame(moment(dateTime))
            && ev.title != "Suggested";
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
        if(event) {
            calendar.$selector.find("#calendar").fullCalendar("removeEvents", function (ev) {
                return ev.beingAdded
                    && ev.editable
                    && (!ev.start.isSame(event.start) || !ev.end.isSame(event.end));
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

        }
        else {
            calendar.$selector.find("#calendar").fullCalendar("removeEvents", function (ev) {
                return ev.beingAdded
                    && ev.editable
            });
            calendar.eventBeingAdded = undefined;
        }
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
                && !calendar.isFakeCalendarId(event.calId)
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

Calendar.prototype.changeCalendarTimezone = function (conserveEvents) {
    var calendar = this;

    calendar.$selector.find('#calendar').fullCalendar('removeEvents');
    if(!conserveEvents) {
        calendar.events = [];
    }
    calendar.drawEventList();

    calendar.fetchAllAccountsEvents(calendar.dispStart.format() + "T00:00:00Z", calendar.dispEnd.format() + "T00:00:00Z");

    if(conserveEvents) {
        calendar.$selector.find('#calendar').fullCalendar('addEventSource', currentCalendar.events);
    }
};

Calendar.prototype.drawEventList = function () {
    var calendar = this;
    calendar.drawExternalEventsList();
};

Calendar.prototype.drawExternalEventsList = function () {
    var calendar = this;
    if (calendar.getMode() != "suggest_dates") return;
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

Calendar.prototype.selectTimezone = function(timezone, conserveEvents) {
    var calendar = this;
    $('#calendar-timezone').val( timezone );
    calendar.changeCalendarTimezone(conserveEvents);
};
Calendar.prototype.clearTimeZoneSelector = function () {
    var calendar = this;
    calendar.$selector.find("#calendar-timezone").empty();
};
Calendar.prototype.redrawTimeZoneSelector = function () {
    var calendar = this;

    var allTimeZones = [];

    // Clear previously set timezones if needed
    calendar.clearTimeZoneSelector();

    // Add default timezone if needed
    if(allTimeZones.indexOf(calendar.initialData.default_timezone_id) == -1) {
        //calendar.$selector.find("#calendar-timezone").append(
        //    $("<option>").val(calendar.initialData.default_timezone_id).html(calendar.initialData.default_timezone_id)
        //);
        allTimeZones.push(calendar.initialData.default_timezone_id);
    }

    // Add all other clients timezones
    _.each(calendar.accountPreferences, function(account) {
        allTimeZones.push(account.default_timezone_id);
    });

    console.log('here', allTimeZones);
    // Add all calendars timezones
    $(calendar.calendars).each(function (k, calendarItem) {
        if (calendar.shouldDisplayCalendarItem(calendarItem)) {
            if (calendarItem.timezone && allTimeZones.indexOf(calendarItem.timezone) == -1) {
                allTimeZones.push(calendarItem.timezone);
                //calendar.$selector.find("#calendar-timezone").append(
                //    $("<option>").val(calendarItem.timezone).html(calendarItem.timezone + " (" + calendarItem.id + ")")
                //);
            }
        }
    });

    // Add additional timezones if needed
    if(calendar.initialData.additional_timezone_ids) {
        _.each(calendar.initialData.additional_timezone_ids, function(timezone_id) {
            if(allTimeZones.indexOf(timezone_id) == -1) {
                //calendar.$selector.find("#calendar-timezone").append(
                //    $("<option>").val(timezone_id).html(timezone_id)
                //);
                allTimeZones.push(timezone_id);
            }
        });
    }

    allTimeZones = _.uniq(allTimeZones);

    _.each(allTimeZones, function(timezone) {
        calendar.$selector.find("#calendar-timezone").append(
            $("<option>").val(timezone).html(timezone)
        );
    });
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