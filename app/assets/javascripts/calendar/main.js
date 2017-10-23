function Calendar($selector, params, synchronize) {

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

    // Used to know which weeks has already been fetched
    this.weeksFetched = [];

    this.currentlyFetchingWeeks = {};

    this.eventsFetchedCount = 0;

    this.meetingRoomsEvents = {};
    this.virtualResourcesEvents = {};
    this.calendarAllEvents = {};

    this.currentlyFetchedMeetingRooms = [];

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
        calendar.refreshMeetingRoomSelectOptions();
    });
    if(calendar.initialData.dontShowMinimizeButton) {
        calendar.$selector.find("#minimize-button").hide();
    }
    else {
        calendar.$selector.find("#minimize-button").click(function(e) {
            trackActionV2('Click_on_close_calendar');
            calendar.clickMinimizeButton(e);
        });
    }


    var allEmailsForTracking = calendar.initialData.other_emails.slice();
    allEmailsForTracking.unshift(calendar.initialData.email);

    calendar.distinctIdForTracking = "" + Date.now() + "-" + allEmailsForTracking.join("|");

    calendar.$selector.find(".global-loading").show();
    calendar.$selector.find(".global-loading-message").html("Loading account preferences...");
    this.fetchAccountPreferences(function () {

        calendar.$selector.find(".global-loading-message").html("Loading account calendars...");
        var aiDatesSuggestionsManager = $('#dates-suggestion-manager').scope();
        var timeTravelManager = $('#travel_time_calculator').scope();

        calendar.fetchCalendars(function () {
            calendar.generateEventsToCheck(calendar.initialData.date_times);

            calendar.fullCalendarInit();
            if(synchronize)
                calendar.triggerCalendarsSync();

            // Don't ask AI for dates suggestions in the follow up contacts flow
            if(aiDatesSuggestionsManager) {
                aiDatesSuggestionsManager.fetchAiDatesSuggestionsIfNeeded();
            }
            
            if(timeTravelManager) {
                timeTravelManager.computeSchedulingEventClientsMainAddresses();
            }
            calendar.$selector.find(".global-loading").fadeOut();
        });
    });
}

Calendar.prototype.now = function() {
    var calendar = this;
    if(calendar.initialData.now) {
        return calendar.initialData.now;
    }
    else {
        return moment();
    }
};

Calendar.prototype.generateEventsToCheck = function() {
    var calendar = this;
    calendar.eventsToCheck = [];
    for(var i=0; i < calendar.initialData.date_times.length; i++) {
        var dateObject = calendar.initialData.date_times[i];
        var start = moment(dateObject.date).tz(calendar.getCalendarTimezone());
        var end = start.clone();
        end.add(calendar.getCurrentDuration(), 'm');

        var title = "Suggested";

        if(dateObject.mode == "to_check") {
            title = calendar.generateDelayTitle();
        } else {
            calendar.suggestedEvents.push(dateObject);
        }
        var eventData = calendar.generateEventData({
            title: title,
            start: start,
            end: end
        });
        eventData.editable = false;
        if(dateObject.color) {
            eventData.color = dateObject.color;
        }
        else {
            eventData.color = "#ccc";
        }
        if(dateObject.textColor) {
            eventData.textColor = dateObject.textColor;
        }
        else {
            eventData.textColor = "#000";
        }
        if(dateObject.customHtml) {
            eventData.customHtml = dateObject.customHtml;
        }
        //console.log(eventData);

        window.lastEditedEventToCheck = eventData;
        calendar.eventsToCheck.push(eventData);
    }
};

// Compute the date at which the calendar will open
Calendar.prototype.determineCalendarInitialStartDate = function() {
    var calendar = this;
    var initialStartDate = moment();

    if(calendar.initialData.forcedInitialStartDate) {
        return calendar.initialData.forcedInitialStartDate;
    }

    if(calendar.initialData.constraintsData) {
        // constraintNatures order is important
        var constraintsStartDates = {}, constraintNatures = ["prefers", "can"];
        _.each(calendar.initialData.constraintsData, function(dataEntries, attendeeEmail) {
            _.each(dataEntries, function (dataEntry){
                var constraintNature = dataEntry.constraint_nature;
                if(constraintNatures.indexOf(constraintNature) == -1) return;

                if(!constraintsStartDates[constraintNature]) constraintsStartDates[constraintNature] = [];

                if(dataEntry.dates) {
                    _.each(dataEntry.dates, function(date) {
                        constraintsStartDates[constraintNature].push(moment(date));
                    });
                } else if(data.start_time) {
                    constraintsStartDates[constraintNature].push(moment(startTime));
                }
            });
        });

        _.each(constraintNatures, function(nature) {
            var minStartDate = null;
            if(constraintsStartDates[nature]) {
                minStartDate = _.sortBy(constraintsStartDates[nature], function(d) { return d.valueOf(); })[0];
                if(minStartDate && minStartDate > initialStartDate) initialStartDate = minStartDate;
            }
        });

        // We process the 'can' constraints on the same way than the 'prefers' one
        // Because it created problems with the generated "can't" events

        // var allEvents = [];
        // _.each(calendar.initialData.constraintsData, function (dataEntries, attendeeEmail) {
        //     var mNow = moment();
        //     var mOneYearFromNow = moment().add(1, 'y');
        //     var events = ConstraintTile.getEventsFromData(dataEntries, mNow, mOneYearFromNow);
        //     _.each(events.cant, function (event) {
        //         allEvents.push(event);
        //     });
        // });
        //
        // var i = 0;
        // while (conflictingEvent = _.find(allEvents, function (event) {
        //     return event.start <= initialStartDate && event.end > initialStartDate;
        // })) {
        //     if((++i) >= 100) break;
        //     initialStartDate = conflictingEvent.end;
        // }
    }

    // When in an ask_availabilities flow, we will load the calendar from the currently selected date to verify
    if(window.currentEventTile) {
        var event = window.currentEventTile.event;
        initialStartDate =  moment(event.start).tz(event.timezoneId);
    } else if(window.newEventEventTiles) {
        var orderedEvents = _.sortBy(_.map(window.newEventEventTiles, function(eventTile) {
            return eventTile.event;
        }), 'start');

        if(orderedEvents && orderedEvents.length > 0) {
            initialStartDate = orderedEvents[0].start.tz(orderedEvents[0].timezoneId);
        }
    } else if(window.classification == 'ask_availabilities') {
        var dateToVerify = $('.suggested-date-times').data('date-times');

        if(dateToVerify && dateToVerify.length > 0) {
            initialStartDate = moment(dateToVerify[0].date).tz(dateToVerify[0].timezone);
        }
    } else {
        if(calendar.eventsToCheck.length > 0 && calendar.getMode() == "create_event") {
            initialStartDate = $.map(calendar.eventsToCheck, function(v, k) {
                return v.start;
            }).sort()[0];
        }
    }

    if(calendar.getMode() == "suggest_dates") {
        if(calendar.initialData.suggestedDateTimes) {
            var found = false;
            _.each(calendar.initialData.suggestedDateTimes, function(suggestedDateTime) {
                if(found) return;
                var suggested = moment(suggestedDateTime);
                if(suggested > initialStartDate) {
                    initialStartDate = suggested;
                    found = true;
                }
            });
        }
    }

    return initialStartDate;
};

Calendar.prototype.refreshMeetingRoomSelectOptions = function() {
    // var meetingRoomsManager = $('#meeting-rooms-manager').scope();
    // if(meetingRoomsManager)
    //     meetingRoomsManager.populateCreateEventRoomSelect();
};

Calendar.prototype.selectEvent = function (event, selectingOccurrence) {
    var calendar = this;
    if(event.isSelected) {
        event.isSelected = false;
        event.selectingOccurrence = selectingOccurrence;
        calendar.selectedEvents.splice(calendar.selectedEvents.indexOf(event), 1)
    }
    else {
        event.isSelected = true;
        event.selectingOccurrence = selectingOccurrence;
        calendar.selectedEvents.push(event);
    }

    calendar.drawExternalEventSelection();
    calendar.$selector.find('#calendar').fullCalendar('rerenderEvents');
};

Calendar.prototype.registerCalendarCallback = function(type, callback) {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar(type, callback);
};

Calendar.prototype.getMode = function() {
    var calendar = this;
    return calendar.initialData.mode;
};

Calendar.prototype.shouldDisplayCalendarItem = function (calendarItem) {
    var calendar = this;
    var accountPreferences = calendar.accountPreferences[calendarItem.email];
    if($('#meeting-rooms-manager').length > 0) {
        var meetingRoomsToDisplayIds = _.map($('#meeting-rooms-manager').scope().getMeetingRoomsToDisplay(), function(mR) { return mR.id; });
    }
    else {
        var meetingRoomsToDisplayIds = [];
    }


    return (
        accountPreferences &&
        accountPreferences.calendars_to_show[calendarItem.calendar_login_username] &&
        accountPreferences.calendars_to_show[calendarItem.calendar_login_username].indexOf(calendarItem.id) > -1
        ) ||
        calendar.isFakeCalendarId(calendarItem.id) ||
        // If the calendar is a meeting room that we should display
        meetingRoomsToDisplayIds.indexOf(calendarItem.id) >- 1;

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
};

Calendar.prototype.alreadyFetchedWeek = function(currentWeekStartDate) {
    var calendar = this;

    var alreadyFetched = _.find(calendar.weeksFetched, function(weekSDate) {
        return currentWeekStartDate.isSame(weekSDate, 'day');
    });

    return !$.isEmptyObject(alreadyFetched);
};

Calendar.prototype.redrawCalendarsListPopup = function () {
    var calendar = this;
    var meetingRoomsManager = $('#meeting-rooms-manager').scope();

    var $calendarsListPopup = $("#calendars-list-popup");
    $calendarsListPopup.find(".calendars").html("");

    calendar.$selector.find("#weekends-checkbox").removeProp("checked");
    if (calendar.shouldDisplayWeekends) {
        calendar.$selector.find("#weekends-checkbox").prop("checked", true);
    }

    var groupedCalendars = _.groupBy(calendar.calendars, 'groupEmail');

    for(var email in groupedCalendars) {
        var groupedCalendarsByCalendarLogin = _.groupBy(groupedCalendars[email], 'calendar_login_username');
        for(var calendarLoginUsername in groupedCalendarsByCalendarLogin) {
            var categoryName = email + " - " + calendarLoginUsername;
            if(email == "undefined") categoryName = "Other";
            $calendarsListPopup.find(".calendars").append($("<div>").addClass("account-email-category").html(categoryName));
            $(groupedCalendarsByCalendarLogin[calendarLoginUsername]).each(function (k, calendarItem) {
                var $div = $("<div>").addClass("calendar-item");
                $div.data("email", calendarItem.email);
                $div.data("calendar-id", calendarItem.id);
                $div.data("calendar-login-username", calendarItem.calendar_login_username);
                $div.data("calendar-summary", calendarItem.summary);

                if(calendarItem.is_resource) {
                    $div.addClass('is-meeting-room');
                    // For meeting rooms
                    $div.data("room-capacity", calendarItem.capacity);
                    $div.data("room-can-visio", calendarItem.can_visio);
                    $div.data("room-can-confcall", calendarItem.can_confcall);
                }

                var $checkbox = $("<input type='checkbox'>");

                if(calendarItem.email != calendar.initialData.email && !calendarItem.is_resource) {
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

    // if(meetingRoomsManager) {
    //     meetingRoomsManager.populateCreateEventRoomSelect();
    // }

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
    var meetingRoomsManager = $('#meeting-rooms-manager').scope();

    // Here we are setting the Ews meeting rooms in the calendars property to handle them as normal calendars
    // This way they will appear in the meeting rooms section in the calendar selection Popup of the display calendar
    if(meetingRoomsManager) {
        var meetingRooms = [];

        _.each(meetingRoomsManager.getAvailableMeetingRooms(), function(mRs, clientEmail) {
            _.each(mRs, function(room) {
                room.is_resource = true;
                room.groupEmail = 'Meeting Rooms';
                room.email = clientEmail;
                meetingRooms.push(room)
            });
        });

        calendar.calendars = calendar.calendars.concat(meetingRooms);
    }

    // if(getCurrentAddressObject) {
    //
    //     var currentAddress = getCurrentAddressObject();
    //
    //     if(currentAddress) {
    //
    //         var meetingRooms = angular.copy(currentAddress.available_meeting_rooms);
    //         _.each(meetingRooms, function(mR) {
    //             mR.is_resource = true;
    //             mR.groupEmail = 'Meeting Rooms';
    //             mR.email = calendar.initialData.email;
    //         });
    //
    //         // var ewsMeetingRooms = _.filter(currentAddress.available_meeting_rooms, function(mR) {
    //         //     mR.is_resource = true;
    //         //     mR.groupEmail = 'Meeting Rooms';
    //         //     mR.email = calendar.initialData.email;
    //         //     return mR.calendar_login_username == "ews_company_meeting_room";
    //         // });
    //
    //         calendar.calendars = calendar.calendars.concat(meetingRooms);
    //     }
    // }

    for(var i = 0; i < allEmails.length; i++) {
        var email = allEmails[i];
        accountsToWait ++;
        CommonHelpers.externalRequest({
            action: "calendars",
            email: email
        }, function (response) {
            var failedCalendarsLogins = [];

            for(var k=0; k < response.statuses.length; k++) {
                var currentResponseStatus = response.statuses[k];
                if(currentResponseStatus.sync_status == "sync_failed") {
                    failedCalendarsLogins.push(currentResponseStatus.calendar_login_username);
                }
            }

            if(failedCalendarsLogins.length > 0) {
                alert('Calendars sync failed for: ' + failedCalendarsLogins.join(', '));
            } else {
                for(var j=0; j < response.items.length; j++) {
                    var calendarItem = response.items[j];
                    calendarItem.email = response.email;
                    // if(calendarItem.is_resource) {
                    //     calendarItem.groupEmail = 'Meeting Rooms';
                    // }else {
                        calendarItem.groupEmail = response.email;
                    //}
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
            textColor: event.textColor,
            durationEditable: event.durationEditable,
            editable: event.editable,
            beingAdded: event.beingAdded,
            customHtml: event.customHtml
        });
    });
    return {
        id: "events_to_check_source_id",
        events: result
    };

};

Calendar.prototype.addToFetchedWeek = function(week) {
    var calendar = this;

    if(calendar.weeksFetched.indexOf(week) == -1) {
        calendar.weeksFetched.push(week);
    }
};

Calendar.prototype.addEventsToCheckIfNeeded = function() {
    var calendar = this;
    if(calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
        return ev.beingAdded
            && !ev.editable;
    }).length == 0) {
        calendar.currentEventsToCheckSourceObject = calendar.getEventsToCheck();
        calendar.$selector.find('#calendar').fullCalendar('addEventSource', calendar.currentEventsToCheckSourceObject);
    }
};

Calendar.prototype.reloadEventsToCheck = function() {
    var calendar = this;
    calendar.removeEventsToCheck();
    calendar.generateEventsToCheck();
    calendar.addEventsToCheckIfNeeded();
};
Calendar.prototype.removeEventsToCheck = function() {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar('removeEvents', function(event) {
        return event.source.id == "events_to_check_source_id";
    });
};

Calendar.prototype.checkHideLoadingSpinner = function(start, end) {
    var calendar = this;
    var currentView = calendar.$selector.find('#calendar').fullCalendar('getView');
    var onView = currentView.start >= start && currentView.start <= end;

    if(onView) {
        calendar.hideLoadingSpinner();
    }
};

Calendar.prototype.isCurrentlyLoadingWeek = function(week) {
    var calendar = this;
    week = moment(week.format() + "T00:00:00Z");

    var fetchingStatus = calendar.currentlyFetchingWeeks[week.format()];
    return fetchingStatus && fetchingStatus > 0;
};

Calendar.prototype.showLoadingEventsSpinner = function() {
    var calendar = this;
    calendar.showLoadingSpinner("Loading events...");
};

Calendar.prototype.fetchAllAccountsEvents = function(start, end, trackingOptions) {
    var calendar = this;
    var localWaitingAccounts = 0;
    var momentedStart = moment(start);
    var momentedEnd = moment(end);
    var formattedStart = momentedStart.format();

    var travelTimeCalculator = window.featuresHelper.isFeatureActive('travel_time_v2') ? null : $('#travel_time_calculator').scope();
    var meetingRoomsManager = $('#meeting-rooms-manager').scope();
    var virtualMeetingHelper = $('#virtual-meetings-helper').scope();

    trackingOptions = trackingOptions || {};

    var allEmailsForTracking = calendar.initialData.other_emails.slice();
    allEmailsForTracking.unshift(calendar.initialData.email);

    var currentView = calendar.$selector.find('#calendar').fullCalendar('getView');
    var onView = currentView.start >= momentedStart && currentView.start <= momentedEnd;

    var allClientsPreferencesHash = [];

    // We only display the loader if we are currently loading the week we are displaying
    if(onView) {
        calendar.showLoadingEventsSpinner();
    }

    calendar.currentlyFetchingWeeks[formattedStart] = 0;

    for(var email in calendar.accountPreferences) {
        localWaitingAccounts += 1;

        calendar.currentlyFetchingWeeks[formattedStart] += 1;
        var preferenceHash = calendar.accountPreferences[email];
        allClientsPreferencesHash.push(preferenceHash);



        calendar.fetchEvents(start, end, preferenceHash, function(responseItems) {
            localWaitingAccounts -= 1;
            calendar.currentlyFetchingWeeks[formattedStart] -= 1;

            // We hide the spinner if we are currently the week that has finished being loaded
            if(calendar.currentlyFetchingWeeks[formattedStart] == 0) {
                delete calendar.currentlyFetchingWeeks[formattedStart];
                calendar.checkHideLoadingSpinner(momentedStart, momentedEnd);
            }

            if(trackingOptions.trackNetworkResponse) {
                trackActionV2("Calendar_data_displayed", {
                    calendar_id: email,
                    batch_type: '3x1',
                    week: momentedStart.format('DD-MM-YYYY'),
                    events_count: responseItems.length
                });
            }

            // Every calls have been finished
            if($.isEmptyObject(calendar.currentlyFetchingWeeks)) {
                if(calendar.initialData.calendarandEventsLoadedFirstTimeCallback) {
                    calendar.initialData.calendarandEventsLoadedFirstTimeCallback();
                    calendar.initialData.calendarandEventsLoadedFirstTimeCallback = null;
                }

                if(window.allCalendarEventsFetched) {
                    window.allCalendarEventsFetched();
                }

                if(trackingOptions.trackNetworkResponse) {
                    trackActionV2("Calendar_loaded", {
                        calendar_id: email,
                        batch_type: '3x1',
                        events_count: calendar.eventsFetchedCount,
                        weeks: trackingOptions.formattedBatchesDates
                    });
                }

                if(travelTimeCalculator) {
                    // var currentLastIndex = calendar.calendarAllEvents[currentPrefHash.email].length - 1;
                    //
                    // var lastBatchResult  = calendar.calendarAllEvents[currentPrefHash.email][currentLastIndex];
                    _.each(allClientsPreferencesHash, function(currentPrefHash) {
                        travelTimeCalculator.processForClient(currentPrefHash, _.flatten(calendar.calendarAllEvents[currentPrefHash.email]));
                        // Clear the array for next batch
                        calendar.calendarAllEvents[currentPrefHash.email] = [];
                    });
                }

                if(meetingRoomsManager) {
                    meetingRoomsManager.checkIfDetectAvailabilities();
                }

                if(virtualMeetingHelper && virtualMeetingHelper.usingVirtualResources()) {
                    virtualMeetingHelper.determineFirstAvailableVirtualResource();
                }

                calendar.calendarAllEvents[preferenceHash.email] = [];
            }
        }, trackingOptions);
    }
};



Calendar.prototype.redrawFullCalendar = function() {
    var calendar = this;
    calendar.$selector.find("#calendar").fullCalendar("render");
};

Calendar.prototype.fetchEvents = function (start, end, accountPreferencesHash, callback, trackingOptions) {
    var calendar = this;
    var travelTimeCalculator = $('#travel_time_calculator').scope();
    var meetingRoomsManager =  $('#meeting-rooms-manager').scope();
    var neededMeetingRoomsCount = 0;
    var currentAppointment = window.getCurrentAppointment();
    var unavailableEvents = [];
    //var allEvents = [];
    var meeting_rooms_to_show = {};
    var virtualResourcesToShow = [];
    var momentedStart = moment(start);

    if(calendar.initialData.meeting_rooms_to_show) {
        meeting_rooms_to_show = calendar.initialData.meeting_rooms_to_show;
    }

    if (window.threadAccount && accountPreferencesHash.email === window.threadAccount.email) {
        //meeting_rooms_to_show[window.threadAccount.email] = [];
        //if (accountPreferencesHash.email == window.threadAccount.email) {
        _.each($('.calendar-item.is-meeting-room input[type="checkbox"]:checked'), function (c) {
            var calendarItemNode = $(c).closest('.calendar-item');
            //var currentRoomId = calendarItemNode.data('calendar-id');
            meeting_rooms_to_show[calendarItemNode.data('calendar-login-username')] = meeting_rooms_to_show[calendarItemNode.data('calendar-login-username')] || [];
            meeting_rooms_to_show[calendarItemNode.data('calendar-login-username')].push(calendarItemNode.data('calendar-id'));

            // Only fetch the meeting room if it is not already being fetched for another client
            // if(calendarItemNode.data('email') === accountPreferencesHash.email) {
            //     meeting_rooms_to_show[calendarItemNode.data('calendar-login-username')] = meeting_rooms_to_show[calendarItemNode.data('calendar-login-username')] || [];
            //     meeting_rooms_to_show[calendarItemNode.data('calendar-login-username')].push(calendarItemNode.data('calendar-id'));
            // }
        });
        //}

        meeting_rooms_to_show[window.threadAccount.email] = _.uniq(meeting_rooms_to_show[window.threadAccount.email]);

        if(meeting_rooms_to_show[window.threadAccount.email].length > 0) {
            neededMeetingRoomsCount = meetingRoomsManager.widgets.length;
        }

        if (currentAppointment && currentAppointment.appointment_kind_hash.is_virtual && window.threadAccount.virtual_appointments_company_support_config &&
            window.threadComputedData && window.threadComputedData.call_instructions) {
            var virtualAppoinementCompanySupport = _.find(window.threadAccount.virtual_appointments_company_support_config, function (support) {
                return support.resource_type == window.threadComputedData.call_instructions.support;
            });

            if (virtualAppoinementCompanySupport && virtualAppoinementCompanySupport.virtual_resources) {
                virtualResourcesToShow = _.map(virtualAppoinementCompanySupport.virtual_resources, function (resource) {
                    return resource.id;
                });
            }
        }
    }

    var requestTrackingId = null;
    var requestTracked = null;
    if (typeof RequestTracking === 'undefined' || RequestTracking == null || calendar.initialData.dontTrackRequests) {

    }
    else {

        requestTracked = new RequestTracking();

        requestTrackingId = requestTracked.create({
            request_type: 'list_events',
            properties: {
                client_email: accountPreferencesHash.email,
                request_strategy: '3X1',
                request_group: trackingOptions.batchTrackingId,
                start_date: start,
                end_date: end,
                provider: _.map((window.threadAccount.calendar_logins || []), function (cal) {
                    return cal.type;
                }).join(', '),
                using_calendar_server: window.threadAccount.using_calendar_server
            }
        });
    }

    var params = {
        action: "events",
        email: accountPreferencesHash.email,
        calendar_ids: accountPreferencesHash.calendar_ids_to_show_override,
        meeting_rooms_to_show: meeting_rooms_to_show,
        needed_meeting_rooms_count: neededMeetingRoomsCount,
        virtual_resources_to_show: virtualResourcesToShow,
        start: start,
        end: end,
        trackingId: requestTrackingId
    };
    if(calendar.initialData.as_at_date) {
        params.as_at_date = calendar.initialData.as_at_date;
    }
    if(calendar.initialData.compute_meeting_rooms_via_backend) {
        params.compute_meeting_rooms_unavailabilities = true;
    }
    if(calendar.initialData.constraintsData) {
        params.constraints_data = _.flatten(_.values(currentCalendar.initialData.constraintsData));
    }

    // if(window.threadComputedData.linked_attendees && window.threadComputedData.linked_attendees[accountPreferencesHash.email]) {
    //     params.linked_attendees = window.threadComputedData.linked_attendees[accountPreferencesHash.email];
    // }

    // We compute the linked attendees events only on the main account event list call (even if multi clients have linked attendees on the thread)
    // So we can merge the results easily
    if(window.threadComputedData && !$.isEmptyObject(window.threadComputedData.linked_attendees) && accountPreferencesHash.email ==  window.threadAccount.email) {
        var presentAttendeesEmails = _.map(window.presentAttendees(), function(att){return att.email});
        params.linked_attendees = {};

        _.each(window.threadComputedData.linked_attendees, function(attendees, mainAccount) {
            params.linked_attendees[mainAccount] = _.intersection(presentAttendeesEmails, attendees);
        });
        //params.linked_attendees = window.threadComputedData.linked_attendees;
    }

    CommonHelpers.externalRequest(params, function (response) {
        if(!window.lastEventSync)
            window.lastEventSync = (new Date()).toISOString();
        var eventsCount = response.items.length;

        if(trackingOptions.trackNetworkResponse) {
            calendar.eventsFetchedCount += eventsCount;

            trackActionV2("Calendar_data_received", {
                calendar_id: accountPreferencesHash.email,
                batch_type: '3x1',
                week: momentedStart.format('DD-MM-YYYY'),
                events_count: eventsCount
            });
        }

        if (typeof requestTracked === 'undefined' || requestTracked == null) {

        }
        else {
            requestTracked.update({
                network_finished_date: moment().valueOf(),
                properties: {
                    events_count: eventsCount
                }
            });
        }

        unavailableEvents = calendar.getNonAvailableEvents(start, end, accountPreferencesHash);

        calendar.addCal(unavailableEvents);
        calendar.addEventsToCheckIfNeeded();

        calendar.addAllCals(response.items);

        if(response.constraints_events) {
            calendar.addCal(calendar.handleConstraintsFromBackend(response.constraints_events));
        }

        if(travelTimeCalculator) {
            // Allow us to detect easily if the events are following or followed by unavailable events
            calendar.calendarAllEvents[accountPreferencesHash.email].push(response.items);
            calendar.calendarAllEvents[accountPreferencesHash.email].push(unavailableEvents);
        }

        if (typeof requestTracked === 'undefined' || requestTracked == null) {

        }
        else {
            requestTracked.update({
                global_finished_date: moment().valueOf()
            });
        }

        if(callback) callback(response.items);
    });
};

// Calendar.prototype.addConstraintsDataEventsViaBackend = function(startTime, endTime) {
//     var calendar = this;
//
//     CommonHelpers.externalRequest({
//             action: "deploy_constraints",
//             constraints_data: _.flatten(_.values(calendar.initialData.constraintsData)),
//             start: startTime,
//             end: endTime
//         },
//         function (response) {
//             calendar.addCal(calendar.handleConstraintsFromBackend(response.data));
//         }
//     );
// };

Calendar.prototype.handleConstraintsFromBackend = function(data) {
    var result = [];
    var calendar = this;

    _.each(data, function(eventsHash, attendeeEmail) {

        _.each(eventsHash.cant, function(ev) {

            var event = {
                summary: attendeeEmail + " not available",
                start: {
                    dateTime: moment(ev.start).tz(calendar.getCalendarTimezone()).format()
                },
                end: {
                    dateTime: moment(ev.end).tz(calendar.getCalendarTimezone()).format()
                },
                startEditable: false,
                durationEditable: false,
                calId: "juliedesk-strong-constraints",
                isNotAvailableEvent: true,
                constraintType: 'cant'
            };
            result.push(event);
        });

        _.each(eventsHash.dont_prefers, function(ev) {
            var event = {
                summary: attendeeEmail + " prefers not",
                start: {
                    dateTime: moment(ev.start).tz(calendar.getCalendarTimezone()).format()
                },
                end: {
                    dateTime: moment(ev.end).tz(calendar.getCalendarTimezone()).format()
                },
                startEditable: false,
                durationEditable: false,
                calId: "juliedesk-light-constraints",
                isNotAvailableEvent: true,
                constraintType: 'dontPrefer'
            };
            result.push(event);
        });
    });

    return result;
};

Calendar.prototype.computeConstraintsDataEvents = function(data, startTime, endTime) {
    var result = [];
    var calendar = this;

    _.each(data, function(dataEntries, attendeeEmail) {
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
                isNotAvailableEvent: true,
                constraintType: 'cant'
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
                isNotAvailableEvent: true,
                constraintType: 'dontPrefer'
            };
            result.push(event);
        });
    });


    return result;
};


Calendar.prototype.bookingHoursUnavailabilities = function(startTime, endTime, accountPreferencesHash, clientTimezone, targetTimezone) {

    var eventTitle = "Not available";
    if(accountPreferencesHash.full_name) {
        eventTitle += ' [' +  accountPreferencesHash.full_name + ']';
    }
    var color = "#444";
    var textColor = "#aaa";
    var calId = "juliedesk-unavailable";

    var mStartTime = moment(startTime);
    var mEndTime = moment(endTime);
    var mCurrentTime = mStartTime.clone().tz(clientTimezone);
    mCurrentTime.hours(0);
    mCurrentTime.minutes(0);

    var events = [];

    while (mCurrentTime < mEndTime) {
        var dayKeyInClientTimezone = mCurrentTime.tz(clientTimezone).locale("en").format("ddd").toLowerCase();
        var unbookingHoursSlotsForDay = accountPreferencesHash.unbooking_hours[dayKeyInClientTimezone] || [];

        _.each(unbookingHoursSlotsForDay, function (slot) {
            var eventStartTime = mCurrentTime.clone();
            eventStartTime.hours(slot[0] / 100);
            eventStartTime.minutes(slot[0] % 100);
            eventStartTime.tz(targetTimezone);

            var eventEndTime = mCurrentTime.clone();
            eventEndTime.hours(slot[1] / 100);
            eventEndTime.minutes(slot[1] % 100);
            eventEndTime.tz(targetTimezone);

            var url = "NOTAVAILABLE-" + eventStartTime.format("YYYY-MM-DDTHH:mm:ssZ");

            events.push({
                summary: eventTitle,
                start: {
                    dateTime: eventStartTime.format("YYYY-MM-DDTHH:mm:ssZ")
                },
                end: {
                    dateTime: eventEndTime.format("YYYY-MM-DDTHH:mm:ssZ")
                },
                url: url,
                startEditable: false,
                durationEditable: false,
                color: color,
                textColor: textColor,
                calId: calId,
                isNotAvailableEvent: true
            });
        });

        mCurrentTime.add(1, 'days');
    }

    return events;
};

Calendar.prototype.getNonAvailableEvents = function (startTime, endTime, accountPreferencesHash) {
    var calendar = this;

    var virtualAppointment = window.getCurrentAppointment() && window.getCurrentAppointment().appointment_kind_hash.is_virtual;

    var currentTimezone = calendar.getCalendarTimezone();
    var clientTimezone = currentTimezone;
    if(virtualAppointment) {
        var accountAttendee = _.find(window.threadComputedData.attendees, function(attendee) {
            return attendee.email == accountPreferencesHash.email;
        });
        if(accountAttendee && accountAttendee.timezone) {
            clientTimezone = accountAttendee.timezone;
        }
        else {
            clientTimezone = accountPreferencesHash.default_timezone_id;
        }

    }
    else {
        if(window.threadComputedData && window.threadComputedData.timezone) {
            clientTimezone = window.threadComputedData.timezone
        }
    }
    var targetTimezone = currentTimezone;

    var result = calendar.bookingHoursUnavailabilities(startTime, endTime, accountPreferencesHash, clientTimezone, targetTimezone);

    if(!calendar.publicHolidaysAdded) {
        for(var i=0; i<accountPreferencesHash.public_holidays_dates.length; i++) {
            var publicHoliday = accountPreferencesHash.public_holidays_dates[i];

            if(!!publicHoliday) {
                var mStartDate = moment(publicHoliday.date);
                var mEndDate = mStartDate.clone();
                mEndDate.add(1, 'd');

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
    if(ev.calendar_login_type != 'EwsLogin' && (calendar.isFakeCalendarId(ev.calId) || (ev.all_day))) {
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

    eventData = {
        id: ev.id,
        title: ev.summary,
        allDay: ev.all_day,
        aiMetadata: ev.ai_metadata || {},
        isSuggestionFromAi: ev.isSuggestionFromAi,
        isTravelTime: ev.isTravelTime,
        isDefaultDelay: ev.isDefaultDelay,
        // Allow to know if the event is from a meeting room
        isMeetingRoom: ev.is_meeting_room,
        isLinkedAttendeesBusy: ev.is_linked_attendees_busy,
        isVirtualResource: ev.is_virtual_resource,
        virtualResourceId: ev.virtual_resource_id,
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
        computed_location: ev.computed_location,
        travel_time_before: ev.travel_time_before,
        travel_time_after: ev.travel_time_after,
        position: ev.position,
        max_duration_before: ev.max_duration_before,
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
        busyLocked: ev.busyLocked,
        organizerEmail: ev.organizer && ev.organizer.email,
        alreadySuggested: ev.alreadySuggested,
        trackingId: ev.trackingId,
        event_history_event_id: ev.is_historical_data ? ev.event_id : null
    };
    eventData.isLocated = calendar.computeIsLocated(eventData);

    if(ev.is_travel_time)
        Object.assign(eventData, calendar.computeTravelTimeData(ev));
    if(ev.is_travel_delay)
        Object.assign(eventData, calendar.computeDefaultDelayData(ev));

    return eventData;
};



Calendar.prototype.computeDefaultDelayData = function(ev) {
    var eventData = {};
    eventData.isDefaultDelay = true;
    eventData.travelTimeOriginalStartTime = moment(ev.original_start);
    eventData.travelTimeOriginalEndTime = moment(ev.original_end);
    eventData.eventInfoType = ev.position;
    eventData.location = ev.computed_location;
    eventData.travelTime = Math.round(ev.duration/60);
    eventData.isWarning = ev.truncated;
    eventData.location = ev.location;
    eventData.travelTimeType = 'defaultDelay';
    return eventData;
};

Calendar.prototype.computeTravelTimeData = function(ev) {
    var eventData = {};
    eventData.isTravelTime = true;
    eventData.travelTimeOriginalStartTime = moment(ev.original_start);
    eventData.travelTimeOriginalEndTime = moment(ev.original_end);
    eventData.eventInfoType = ev.position;
    eventData.travelTime = Math.round(ev.duration/60);
    eventData.isWarning = ev.truncated;
    eventData.from_location = ev.from_location;
    eventData.to_location = ev.to_location;
    eventData.location = ev.position == 'before' ? ev.to_location : ev.from_location;
    eventData.travelTimeType = 'travelTime';
    if(ev.from_location && ev.to_location)
        eventData.travelTimeGoogleDestinationUrl = 'https://www.google.com/maps/dir/' + encodeURIComponent(ev.from_location)  + '/' + encodeURIComponent(ev.to_location);

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

    var localMeetingRoomsEvents = {};
    var localVirtualResourcesEvents = {};
    // calendar.meetingRoomsEvents = {};
    // calendar.virtualResourcesEvents = {};
    var meetingRoomsManager = $('#meeting-rooms-manager').scope();
    var virtualMeetingHelper = $('#virtual-meetings-helper').scope();

    var meetingRoomsIds = [];
    if(meetingRoomsManager) {
        _.each(_.flatten(_.values(meetingRoomsManager.getAvailableMeetingRooms())), function(mR) {
            meetingRoomsIds.push(mR.id);
            localMeetingRoomsEvents[mR.id] = [];
            calendar.meetingRoomsEvents[mR.id] = calendar.meetingRoomsEvents[mR.id] || [];
        });
    }

    if(virtualMeetingHelper && virtualMeetingHelper.isCurrentAppointmentVirtual()) {
        var currentVAConfig = virtualMeetingHelper.getCurrentVAConfig();
        var virtualResources = currentVAConfig && currentVAConfig.virtual_resources;
        var virtualResourcesIds = [];

        if(virtualResources && virtualResources.length > 0) {
            _.each(virtualResources, function(vR) {
                virtualResourcesIds.push(vR.id);
                localVirtualResourcesEvents[vR.id] = [];
                calendar.virtualResourcesEvents[vR.id] = calendar.virtualResourcesEvents[vR.id] || [];
            });
        }
    }

    _.each(calEvents, function(calEvent) {
        //var x = 0;
        //for (var i = 0; i < calendar.calendars.length; i++) {
        //    if (calendar.calendars[i].id == ev.calId) {
        //        x = i;
        //        break;
        //    }
        //}

        var eventData = calendar.eventDataFromEvent(calEvent);

        // We don't add the individual meeting rooms events to the displayed events on the calendar
        if(meetingRoomsIds.indexOf(eventData.calId) > -1) {
            localMeetingRoomsEvents[eventData.calId].push(eventData);
            calendar.meetingRoomsEvents[eventData.calId].push(eventData);
        } else if(eventData.isVirtualResource && virtualResourcesIds.indexOf(eventData.virtualResourceId) > -1) {
            localVirtualResourcesEvents[eventData.virtualResourceId].push(eventData);
            calendar.virtualResourcesEvents[eventData.virtualResourceId].push(eventData);
        } else {
            calendar.eventDataX.push(eventData);
        }
    });

    // if(meetingRoomsManager) {
    //     calendar.eventDataX = calendar.eventDataX.concat(meetingRoomsManager.getOverlappingEvents(localMeetingRoomsEvents));
    // }

    if(virtualMeetingHelper && virtualMeetingHelper.isCurrentAppointmentVirtual()) {
        calendar.eventDataX = calendar.eventDataX.concat(virtualMeetingHelper.getOverlappingVirtualResourcesEvents(localVirtualResourcesEvents));
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
               url: event.url,
               organizerEmail: event.organizerEmail,
               selectingOccurrence: event.selectingOccurrence
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

    $(".calendar-item:not(.is-meeting-room) input[type='checkbox']:checked").each(function() {
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
    var calendarNode = $('#calendar');

    var currentDate = calendar.$selector.find('#calendar').fullCalendar('getDate');
    var currentEvents = calendar.$selector.find('#calendar').fullCalendar('clientEvents');

    calendar.$selector.find('#calendar').fullCalendar('destroy');
    calendar.shouldDisplayWeekends = calendar.$selector.find("#weekends-checkbox:checked").length > 0;

    calendar.fullCalendarInit();

    //calendarNode.fullCalendar('removeEvents');
    calendarNode.fullCalendar('gotoDate', currentDate);
    //calendarNode.fullCalendar('addEventSource', currentEvents);
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

Calendar.prototype.goToDateAndLoadEvents = function(momentDate) {
    var calendar = this;

    calendar.goToDateTime(momentDate);
    calendar.$selector.find("#calendar").fullCalendar("render");
};

Calendar.prototype.refreshEvents = function() {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar('removeEvents');
    calendar.fetchAllAccountsEvents(calendar.dispStart.format() + "T00:00:00Z", calendar.dispEnd.format() + "T00:00:00Z");
};

Calendar.prototype.resetMeetingRoomsEvents = function() {
    var calendar = this;
    calendar.meetingRoomsEvents = {};
};

Calendar.prototype.triggerCalendarsSync = function() {
    var calendar = this;

    for(var email in calendar.accountPreferences) {
        var preferenceHash = calendar.accountPreferences[email];

        CommonHelpers.externalRequest({
            action: "synchronize",
            email: preferenceHash.email,
            calendar_ids: preferenceHash.calendar_ids_to_show_override
        }, function() {});
    }
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

Calendar.prototype.reRenderEvents = function() {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar('rerenderEvents');
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

Calendar.prototype.clearEvents = function() {
    var calendar = this;

    calendar.$selector.find('#calendar').fullCalendar('removeEvents');
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

Calendar.prototype.drawEventList = function (options) {
    var calendar = this;
    calendar.drawExternalEventsList(options);
};

Calendar.prototype.drawExternalEventsList = function (options) {
    if(!options) options = {};
    if(!options.alsoAllowOn) options.alsoAllowOn = [];

    var calendar = this;
    if (calendar.getMode() != "suggest_dates" && options.alsoAllowOn.indexOf(calendar.getMode()) == -1) return;

    // We return only events added by clicking
    var dateTimes = calendar.$selector.find("#calendar").fullCalendar("clientEvents", function (ev) {
        return ev.beingAdded && ev.editable;
    }).sort(function (a, b) {
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
            calendar.calendarAllEvents[response.email] = [];

            accountsToWait --;
            if(accountsToWait == 0 && callback) callback();
        });
    }
};
Calendar.prototype.clickMinimizeButton = function(e) {
    var calendar = this;
    calendar.$selector.addClass("minimized");
};