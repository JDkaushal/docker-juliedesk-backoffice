Calendar.prototype.generateEventData = function(params) {
    var title = "";
    if(params.title) {
        title = params["title"]
    }

    var allDay = false;
    if(params.start instanceof Object && params.start._isAMomentObject) {
        allDay = params.start._ambigTime;
    }
    return {
        title: title,
        start: params.start,
        end: params.end,
        color:"rgb(40, 166, 203)",
        allDay: allDay,
        durationEditable: false,
        editable: true,
        beingAdded: true,
        calendar_login_username: params.calendar_login_username,
        calendar_login_type: params.calendar_login_type
    };
};

Calendar.prototype.fullCalendarSelect = function(start, end, jsEvent, view) {
    var calendar = this;
    calendar.$selector.find('#calendar').fullCalendar('unselect');

    if(calendar.getMode() == "select_events") return;

    // Forbid suggestion or creation in the past
    if(moment.tz(start.format(), calendar.getCalendarTimezone()).isBefore(moment())) {
        return;
    }

    var realEnd = start.clone();
    realEnd.add('m', calendar.getCurrentDuration());

    var title = calendar.generateDelayTitle();

    if(calendar.getMode() == "free_calendar" || calendar.getMode() == "create_events") {
        title = localize("events.new_event");
        realEnd = end;
        if((realEnd - start) / 1000 / 60 < 60) {
            realEnd = start.clone();
            realEnd.add('m', 60);
        }
    }
    
    var eventData = calendar.generateEventData({
        title: title,
        start: start,
        end: realEnd,
        calendar_login_username: calendar.initialData.default_calendar_login_username,
        calendar_login_type: calendar.initialData.default_calendar_login_type
    });
    if(calendar.getMode() == "create_events") {
        if(calendar.initialData.pickEventCallback) {
            calendar.initialData.pickEventCallback({
                start: moment.tz(eventData.start.format(), calendar.getCalendarTimezone()),
                end: moment.tz(eventData.end.format(), calendar.getCalendarTimezone())
            });
        }
    }
    else {
        calendar.$selector.find('#calendar').fullCalendar('renderEvent', eventData, true);
        calendar.addEvent(eventData);
        calendar.drawEventList();

        if(calendar.getMode() == "free_calendar") {
            calendar.showEventDetails(eventData, calendar.$selector.find(".fc-event.fc-event-draggable"));
        }
    }


};

Calendar.prototype.fullCalendarEventDrop = function(event, delta, revertFunc, jsEvent, ui, view) {
    var calendar = this;
    calendar.addEvent(event);
    calendar.drawEventList();
};
Calendar.prototype.fullCalendarEventDragStart = function(event, jsEvent, ui, view) {
    var calendar = this;
    for(var k=0; k<calendar.events.length; k++){
        if(calendar.events[k].start.isSame(event.start)){
            calendar.events.splice(k, 1);
            break;
        }
    }
};
Calendar.prototype.fullCalendarEventAfterAllRender = function(view) {
    var calendar = this;
    calendar.addEventsCountLabels();
};

Calendar.prototype.fullCalendarViewRender = function(view, element) {
    var calendar = this;
    calendar.$selector.find(".fc-agenda-axis.fc-widget-header.fc-first:eq(0)").html($("<img>").attr("id", "calendars-list-popup-toggle-button")).css({textAlign: "center"});
    calendar.$selector.find("#calendars-list-popup-toggle-button").click(function(event){
        calendar.$selector.find("#calendars-list-popup").toggle();
    });

    var daysToFetch = 23;

    if (typeof calendar.dispStart === "undefined" || typeof calendar.dispEnd === "undefined") {
        calendar.dispStart = view.start.clone();
        calendar.dispEnd = view.end.clone();
        calendar.dispEnd.add('d', daysToFetch - 7);

        calendar.$selector.find('#calendar').fullCalendar('removeEvents');

        var start = calendar.dispStart.format() + "T00:00:00Z";
        var end = calendar.dispEnd.format() + "T00:00:00Z";

        calendar.fetchAllAccountsEvents(start, end);

    }
    else {
        if(view.start.isBefore(calendar.dispStart) || view.end.isAfter(calendar.dispEnd)) {
            var start, end;
            if(view.start.isBefore(calendar.dispStart)) {
                end = calendar.dispStart.format() + "T00:00:00Z";
                calendar.dispStart = view.start.clone();
                calendar.dispStart.add('d', 8 - daysToFetch);
                start = calendar.dispStart.format() + "T00:00:00Z";
            }
            else {
                start = calendar.dispEnd.format() + "T00:00:00Z";
                calendar.dispEnd = view.end.clone();
                calendar.dispEnd.add('d', daysToFetch);
                end = calendar.dispEnd.format() + "T00:00:00Z";
            }

            calendar.fetchAllAccountsEvents(start, end);
        }
    }
};
Calendar.prototype.fullCalendarEventClick = function(event, jsEvent, view) {
    var calendar = this;
    if (event.beingAdded) {
        if(calendar.getMode() == "suggest_dates" && event.editable) {
            for(var k=0; k<calendar.events.length; k++){
                if(calendar.events[k].start.isSame(event.start)){
                    calendar.events.splice(k, 1);
                }
            }
            calendar.$selector.find('#calendar').fullCalendar('removeEvents', function(toremove){
                return toremove.start.isSame(event.start)
                    && toremove.beingAdded;
            });
            calendar.drawEventList();
        }
        else if(calendar.getMode() == "create_event"  && event.title == "") {
            calendar.addEvent(event);
        }
    }
    else {
        calendar.showEventDetails(event, $(jsEvent.currentTarget));
    }
};

Calendar.prototype.fullCalendarInit = function() {
    var calendar = this;
    var defaultDate = moment();
    if(calendar.eventsToCheck.length > 0 && calendar.getMode() == "create_event") {
        defaultDate = $.map(calendar.eventsToCheck, function(v, k) {
           return v.start;
        }).sort()[0];
    }
    //defaultDate = moment("2015-03-01");
    $('#calendar').fullCalendar({
        header: {
            left: 'today prev,next title',
            center: '',
            right: ''
        },
        defaultDate: defaultDate,
        weekends: calendar.shouldDisplayWeekends,
        lang: CommonHelpers.getLocale(),
        editable: true,
        snapDuration: {minutes: 15},
        scrollTime:'09:00:00',
        height: calendar.initialData.height,
        allDayMaxHeight: 120,
        selectable: true,
        selectHelper: true,
        defaultView:'agendaWeek',
        timeZone: "local",
        select: function(start, end, jsEvent, view) {
            calendar.fullCalendarSelect(start, end, jsEvent, view)
        },
        eventDrop: function(event, delta, revertFunc, jsEvent, ui, view) {
            calendar.fullCalendarEventDrop(event, delta, revertFunc, jsEvent, ui, view);
        },
        eventDragStart: function(event, jsEvent, ui, view) {
            calendar.fullCalendarEventDragStart(event, jsEvent, ui, view);
        },
        eventAfterAllRender: function(view) {
            calendar.fullCalendarEventAfterAllRender(view)
        },
        viewRender: function(view, element) {
            calendar.fullCalendarViewRender(view, element);
        },
        eventClick: function(event, jsEvent, view) {
            calendar.fullCalendarEventClick(event, jsEvent, view);
            return false;
        }
    });
};