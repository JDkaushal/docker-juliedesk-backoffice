function EventTile($selector, params) {
    this.eventId = params.eventId;
    this.calendarId = params.calendarId;
    this.timezoneId = params.timezoneId;
    this.accountEmail = params.accountEmail;
    this.$selector = $selector;
    this.locale = params.locale || "en";
    this.mode = params.mode;
    this.event = params.event;
    this.selectEventCallback = params.selectEventCallback;
    this.doneEditingCallback = params.doneEditingCallback;
    this.afterRedrawCallback = params.afterRedrawCallback;
    this.afterEventFetchedCallback = params.afterEventFetchedCallback;
    this.minimizable = params.minimizable;
    this.static = params.static;
    this.minimized = params.minimized;
    this.afterNewEventEdited = params.afterNewEventEdited;
    this.eventDoesNotExistSelector = params.eventDoesNotExistSelector;

    var eventTile = this;


    eventTile.render();
}
EventTile.prototype.getMode = function() {
    return this.mode;
};
EventTile.prototype.render = function() {
    var eventTile = this;
    eventTile.$selector.html(HandlebarsTemplates['event_tile/main']());

    eventTile.initActions();
};

EventTile.prototype.isEditing = function() {
    var eventTile = this;
    return eventTile.$selector.find(".event-tile-container").hasClass("editing");
};

EventTile.prototype.getTimezoneId = function() {
    var eventTile = this;
    if(eventTile.$selector.find("input.event-timezone-picker").val()) {
        return eventTile.$selector.find("input.event-timezone-picker").val();
    }
    else {
        return eventTile.timezoneId;
    }

};

EventTile.prototype.redraw = function() {
    var eventTile = this;

    eventTile.$selector.find("input.title").val(eventTile.event.title);
    eventTile.$selector.find(".date .date-text").html(CommonHelpers.formatDateTimeRange(eventTile.event.start, eventTile.event.end, eventTile.locale, eventTile.getTimezoneId(), eventTile.event.allDay));
    eventTile.$selector.find("input.location").val(eventTile.event.location);
    eventTile.$selector.find("textarea.notes").val(eventTile.event.description);

    eventTile.$selector.find(".attendees .attendees-list").html("");
    var attendees = [];
    if(eventTile.event.attendees) attendees = eventTile.event.attendees;

    $(attendees).each(function(k, attendee) {
        eventTile.eventDetailsAddAttendeeDiv(attendee);
    });

    eventTile.$selector.find("input, textarea").attr("disabled", "disabled");


    var mStartDate = moment(eventTile.event.start).tz(eventTile.getTimezoneId()).locale(eventTile.locale);
    var mEndDate = moment(eventTile.event.end).tz(eventTile.getTimezoneId()).locale(eventTile.locale);

    if(eventTile.event.beingAdded) {
        mStartDate = moment(eventTile.event.start).locale(eventTile.locale);
        mEndDate = moment(eventTile.event.end).locale(eventTile.locale);

        if(!eventTile.event.end) {
            mEndDate.add("h", 1);
        }
    }

    if(eventTile.event.allDay) {
        mEndDate.add('d', -1);
    }

    eventTile.$selector.find(".start-date").val(mStartDate.format("YYYY-MM-DD"));
    eventTile.$selector.find(".start-hours").val(mStartDate.format("HH"));
    eventTile.$selector.find(".start-minutes").val(mStartDate.format("mm"));
    eventTile.$selector.find(".end-date").val(mEndDate.format("YYYY-MM-DD"));
    eventTile.$selector.find(".end-hours").val(mEndDate.format("HH"));
    eventTile.$selector.find(".end-minutes").val(mEndDate.format("mm"));





    if(eventTile.event.allDay) {
        eventTile.$selector.find(".event-date-all-day").prop("checked", true);
    }
    else {
        eventTile.$selector.find(".event-date-all-day").prop("checked", false);
    }
    eventTile.$selector.find(".event-timezone-picker").timezonePicker();
    eventTile.$selector.find(".event-timezone-picker").val(eventTile.getTimezoneId());



    eventTile.$selector.find("input, textarea").attr("disabled", true);
    eventTile.$selector.find("#event-delete-button").hide();
    eventTile.$selector.find("#event-edit-button").hide();
    eventTile.$selector.find("#event-save-button").hide();
    eventTile.$selector.find("#event-cancel-button").hide();
    eventTile.$selector.find("#event-select-button").hide();
    eventTile.$selector.find(".spinner-container").hide();
    eventTile.$selector.find(".event-tile-container").removeClass("editing");

    eventTile.$selector.find(".event-tile-container").removeClass("minimizable");
    if(eventTile.minimizable && !eventTile.event.beingAdded) {
        eventTile.$selector.find(".event-tile-container").addClass("minimizable");
        if(eventTile.minimized) {
            eventTile.$selector.find(".event-tile-container").addClass("minimized");
        }
    }
    eventTile.$selector.find(".event-tile-container").removeClass("static");
    if(eventTile.static) {
        eventTile.$selector.find(".event-tile-container").addClass("static");
    }

    if(eventTile.getMode() == "select_events") {
        if(eventTile.event.isSelected) {
            eventTile.$selector.find("#event-select-button").html("Unselect");
        }
        else {
            eventTile.$selector.find("#event-select-button").html("Select");
        }
        eventTile.$selector.find("#event-select-button").show();
    }

    if(eventTile.getMode() == "free_calendar") {
        if(eventTile.event.beingAdded) {
            eventTile.$selector.find(".event-tile-container").addClass("editing");
            eventTile.$selector.find("input, textarea").removeAttr("disabled");
            eventTile.$selector.find("#event-edit-button").hide();
            eventTile.$selector.find("#event-save-button").show();
            eventTile.$selector.find("#event-cancel-button").show();
        }
        else if(eventTile.event.owned) {
            eventTile.$selector.find("#event-edit-button").show();
            eventTile.$selector.find("#event-delete-button").show();
        }
    }
    if(eventTile.getMode() == "read_only") {

    }
    if(eventTile.getMode() == "edit_only") {
        if(eventTile.event.owned) {
            eventTile.$selector.find("#event-edit-button").show();
        }
    }
    eventTile.redrawDatePicker();

    if(eventTile.afterRedrawCallback) eventTile.afterRedrawCallback();
};

EventTile.prototype.eventDetailsAddAttendeeDiv = function(attendee) {
    var eventTile = this;

    var $attendee = $(HandlebarsTemplates['event_tile/attendee'](attendee));
    if(attendee.organizer)  $attendee.addClass("organizer");
    eventTile.$selector.find(".attendees .attendees-list").append($attendee);

    eventTile.redrawAttendeesCountBadge();
};

EventTile.prototype.redrawAttendeesCountBadge = function() {
    var eventTile = this;
    eventTile.$selector.find(".attendees-count-badge").html(eventTile.$selector.find(".attendees .attendees-list .attendee-text").length);
};

EventTile.prototype.getEditedEvent = function() {
    var eventTile = this;

    var allDay = eventTile.$selector.find("input.event-date-all-day:checked").length > 0;
    var mStart, mEnd;
    if(allDay) {
        mStart = moment.tz(eventTile.$selector.find("input.start-date").val(), "UTC");
        mEnd = moment.tz(eventTile.$selector.find("input.end-date").val(), "UTC");
        mEnd.add("d", 1);
    }
    else {
        mStart = moment.tz(eventTile.$selector.find("input.start-date").val(), eventTile.getTimezoneId());
        mStart.set('h', eventTile.$selector.find("input.start-hours").val());
        mStart.set('m', eventTile.$selector.find("input.start-minutes").val());


        mEnd = moment.tz(eventTile.$selector.find("input.end-date").val(), eventTile.getTimezoneId());
        mEnd.set('h', eventTile.$selector.find("input.end-hours").val());
        mEnd.set('m', eventTile.$selector.find("input.end-minutes").val());
    }


    var attendees = eventTile.$selector.find(".attendee-text").map(function() {
        var name = $(this).find(".attendee-name").html();
        var email = $(this).find(".attendee-email").html();
        return {
            email: email,
            name: name
        };
    }).get();

    return {
        title: eventTile.$selector.find("input.title").val(),
        description: eventTile.$selector.find("textarea.notes").val(),
        location: eventTile.$selector.find("input.location").val(),
        private: false,
        all_day: allDay,
        start: mStart.tz("UTC"),
        end: mEnd.tz("UTC"),
        attendees: attendees
    }
};

EventTile.prototype.fetchEvent = function(callback) {
    var eventTile = this;
    eventTile.showSpinner();
    CommonHelpers.externalRequest({
        action: "get_event",
        email: eventTile.accountEmail,
        event_id: eventTile.eventId,
        calendar_id: eventTile.calendarId
    }, function(response) {
        if(response.status == "error") {
            if(response.code == "EventNotFound") {
                eventTile.showEventDoesNotExist();
            }
            else {
                alert("Unable to fetch event: " + response.message)
            }
        }
        else {
            eventTile.event = eventTile.eventDataFromEvent(response.data);
            if(eventTile.afterEventFetchedCallback) eventTile.afterEventFetchedCallback();
            if(callback) callback(response.data);
        }
    }, function(response) {
        eventTile.hideSpinner();
        alert("Error fetching event");
        console.log(response);
    });
};

EventTile.prototype.eventDataFromEvent = function(ev) {
    var eventTile = this;
    var eventData;

    var startTime = ev.start.dateTime;
    var endTime = ev.end.dateTime;

    if (ev.start.dateTime === undefined) {
        startTime = ev.start.date;
        endTime = ev.end.date;
    }

    var sstartTime = moment(startTime).tz(eventTile.getTimezoneId()).format();
    var sendTime = moment(endTime).tz(eventTile.getTimezoneId()).format();


    eventData = {
        id: ev.id,
        title: ev.summary,
        allDay: ev.all_day,
        start: sstartTime,
        end: sendTime,
        url: ev.htmlLink,
        location: ev.location,
        description: ev.description,
        attendees: ev.attendees,
        startEditable: false,
        durationEditable: false,
        calId: ev.calId,
        private: ev.private,
        owned: ev.owned,
        timezoneId: eventTile.getTimezoneId()
    };
    return eventData;
};

EventTile.prototype.showSpinner = function() {
    var eventTile = this;
    eventTile.$selector.find(".spinner-container").fadeIn(200);
};

EventTile.prototype.showEventDoesNotExist = function() {
    var eventTile = this;
    if(eventTile.eventDoesNotExistSelector) {
        eventTile.$selector.find(".event-does-not-exist-container").html(eventTile.eventDoesNotExistSelector);
    }
    eventTile.$selector.find(".event-does-not-exist-container").fadeIn(200);
};

EventTile.prototype.hideSpinner = function() {
    var eventTile = this;
    eventTile.$selector.find(".spinner-container").fadeOut(200);
};
EventTile.prototype.redrawDatePicker = function() {
    var eventTile = this;
    eventTile.$selector.find(".hours-and-minutes").show();
    if(eventTile.$selector.find("input.event-date-all-day:checked").length > 0) {
        eventTile.$selector.find(".hours-and-minutes").hide();
    }
};
EventTile.prototype.saveEvent = function() {
    var eventTile = this;
    var editedEvent = eventTile.getEditedEvent();

    if(eventTile.event.beingAdded) {
        eventTile.showSpinner();
        CommonHelpers.externalRequest({
            action: "create_event",
            email: eventTile.accountEmail,

            summary: editedEvent.title,
            description: editedEvent.description,
            attendees: editedEvent.attendees,
            location: editedEvent.location,
            all_day: editedEvent.all_day,
            private: editedEvent.private,
            start: editedEvent.start.format(),
            end: editedEvent.end.format()
        }, function(response) {
            if(response.status == "success") {
                eventTile.eventId = response.data.event_id;
                eventTile.calendarId = response.data.calendar_id;
                eventTile.fetchEvent(function() {
                    eventTile.redraw();
                    if(eventTile.doneEditingCallback) eventTile.doneEditingCallback({
                        action: "create_event"
                    });
                });
            }
            else {
                eventTile.hideSpinner();
                alert("Error creating event");
                console.log(response);
            }
        }, function(response) {
            eventTile.hideSpinner();
            alert("Error creating event");
            console.log(response);
        });
    }
    else {
        eventTile.showSpinner();
        CommonHelpers.externalRequest({
            action: "update_event",
            email: eventTile.accountEmail,

            event_id: eventTile.eventId,
            calendar_id: eventTile.calendarId,

            summary: editedEvent.title,
            description: editedEvent.description,
            attendees: editedEvent.attendees,
            location: editedEvent.location,
            all_day: editedEvent.all_day,
            private: editedEvent.private,
            start: editedEvent.start.format(),
            end: editedEvent.end.format()
        }, function(response) {
            if(response.status == "success") {
                eventTile.fetchEvent(function() {
                    eventTile.redraw();
                    if(eventTile.doneEditingCallback) eventTile.doneEditingCallback({
                        action: "update_event"
                    });
                });
            }
            else {
                eventTile.hideSpinner();
                alert("Error updating event");
                console.log(response);
            }
        }, function(response) {
            eventTile.hideSpinner();
            alert("Error updating event");
            console.log(response);
        });
    }
};
EventTile.prototype.deleteEvent = function() {
    var eventTile = this;
    eventTile.showSpinner();
    CommonHelpers.externalRequest({
        action: "delete_event",
        email: eventTile.accountEmail,
        event_id: eventTile.eventId,
        calendar_id: eventTile.calendarId
    }, function(response) {
        if(response.status == "success") {
            if(eventTile.doneEditingCallback) eventTile.doneEditingCallback({
                action: "delete_event"
            });
        }
        else {
            eventTile.hideSpinner();
            alert("Error deleting event");
            console.log("error", response);
        }
    }, function(e) {
        eventTile.hideSpinner();
        alert("Error deleting event");
        console.log("error", e);
    });
};
EventTile.prototype.initActions = function() {
    var eventTile = this;
    eventTile.$selector.find("#event-edit-button").click(function() {
        eventTile.$selector.find("input, textarea").removeAttr("disabled");
        eventTile.$selector.find("#event-delete-button").hide();
        eventTile.$selector.find("#event-edit-button").hide();

        if(eventTile.getMode() != "edit_only") {
            eventTile.$selector.find("#event-save-button").show();
        }
        eventTile.$selector.find("#event-cancel-button").show();
        eventTile.$selector.find(".event-tile-container").addClass("editing");

        eventTile.redrawDatePicker();

        if(eventTile.afterRedrawCallback) eventTile.afterRedrawCallback();
    });

    eventTile.$selector.find("#event-cancel-button").click(function() {
        if(eventTile.event.beingAdded) {
            if(eventTile.doneEditingCallback) eventTile.doneEditingCallback({
                action: "cancel_event_creation"
            });
        }
        else {
            eventTile.redraw();
        }
    });

    eventTile.$selector.find("#event-save-button").click(function() {
        eventTile.saveEvent();
    });
    eventTile.$selector.find("#event-delete-button").click(function(e) {
        if (confirm("Are you sure you want to delete this event?")) {
            eventTile.deleteEvent();
        }
    });

    eventTile.$selector.find("#event-select-button").click(function(e) {
        if(eventTile.selectEventCallback)  eventTile.selectEventCallback();
    });

    eventTile.$selector.find(".add-attendee-button").click(function(e) {
        addAttendee();
    });

    eventTile.$selector.find("#add_attendee_input").keyup(function(e) {
        if(e.which == 13) {
            addAttendee();
        }
    });

    eventTile.$selector.find(".minimize-button").click(function() {
        eventTile.$selector.find(".event-tile-container").toggleClass("minimized");
        eventTile.minimized = eventTile.$selector.find(".event-tile-container").hasClass("minimized");
    });

    eventTile.$selector.find("input.start-date, input.start-hours, input.start-minutes, input.end-date, input.end-hours, input.end-minutes").change(function(e) {
        var editedEvent = eventTile.getEditedEvent();
        if(editedEvent.end <= editedEvent.start) {
            eventTile.$selector.find("input.end-date").val(eventTile.$selector.find("input.start-date").val());
            eventTile.$selector.find("input.end-hours").val(parseInt(eventTile.$selector.find("input.start-hours").val(), 10) + 1);
            eventTile.$selector.find("input.end-minutes").val(eventTile.$selector.find("input.start-minutes").val());
        }
        if(eventTile.afterNewEventEdited) eventTile.afterNewEventEdited();
    });

    eventTile.$selector.find("input.event-timezone-picker").on("autocompletechange", function(e) {
        if(eventTile.afterNewEventEdited) eventTile.afterNewEventEdited();
    });

    eventTile.$selector.find("input.event-date-all-day").change(function(e) {
        eventTile.redrawDatePicker();
    });

    var addAttendee = function() {
        var email = eventTile.$selector.find("#add_attendee_input").val();
        eventTile.$selector.find("#add_attendee_input").val("");
        eventTile.eventDetailsAddAttendeeDiv({
            email: email
        });
        eventTile.$selector.find(".attendees-list").scrollTop(eventTile.$selector.find(".attendees-list")[0].scrollHeight);
    };

    eventTile.$selector.on("click", ".remove-attendee-button", function(e) {
        $(this).closest(".attendee-text").remove();
        eventTile.redrawAttendeesCountBadge();
    });
};