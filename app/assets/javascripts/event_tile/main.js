function EventTile($selector, params) {
    this.eventId = params.eventId;
    this.eventUrl = params.eventUrl;
    this.calendarId = params.calendarId;
    this.timezoneId = params.timezoneId;
    this.accountEmail = params.accountEmail;
    this.$selector = $selector;
    this.locale = params.locale || "en";
    this.mode = params.mode;
    this.fromInvitation = params.eventFromInvitation == 'true';
    this.fromInvitationOrganizer = params.eventFromInvitationOrganizer;

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

    this.calendarLoginUsername = params.calendarLoginUsername;
    if(!this.calendarLoginUsername && params.event) {
        this.calendarLoginUsername = params.event.calendar_login_username;
    }

    var eventTile = this;


    eventTile.render();
}
EventTile.prototype.getMode = function() {
    return this.mode;
};
EventTile.prototype.render = function() {
    var eventTile = this;
    eventTile.$selector.html(HandlebarsTemplates['event_tile/main']());

    if(this.fromInvitation) {
        var fromInvitationMessage = 'Invitation from undetermined email';

        if(this.fromInvitationOrganizer) {
            fromInvitationMessage = 'Invitation from ' + this.fromInvitationOrganizer;
        }

        eventTile.$selector.find('.event-from-invitation-container').show();
        eventTile.$selector.find('.event-from-invitation-container .text').text(fromInvitationMessage);
    }

    eventTile.initActions();
};

EventTile.prototype.displayCallingInfosForm = function(){

    var eventTile = this;
    // We display the form in the edit event window when the event is owned by someone (we are editing it)
    var currentAppointment = window.getCurrentAppointment();

    if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual)
    {
        var locationContainerNode = $('.location-container');

        if($('#event_update_virtual_meetings_helper').length == 0){
            locationContainerNode.append('<div id="event_update_virtual_meetings_helper" style="margin-top: 10px;width:270px;"><virtual-meetings-helper id="event_update_vm_ctrl"/></div>');
            angular.bootstrap(document.getElementById("event_update_virtual_meetings_helper"),['virtual-meetings-helper']);
        }

        var vmHelperNode = $('#event_update_vm_ctrl');

        var scope = angular.element(vmHelperNode).scope();
        scope.setEditMode(true);
        scope.forceCurrentConfig = true;
        scope.showHeader = false;
        scope.displayForm = false;
        var otherForm = angular.element($('#virtual-meetings-helper')).scope();
        scope.otherForm = otherForm;
        otherForm.otherForm = scope;

        if(scope.getAttendees().length > 0)
            scope.refresh(scope.getAttendees());

        if($('#event-cancel-button').css('display') == 'block'){
            scope.$apply(function(){scope.displayForm = true; scope.cacheCurrentInterlocutor(); scope.cacheCurrentConf();});

            vmHelperNode.closest('.event-tile-container').css('height', '810px');
            vmHelperNode.closest('.created-event-panel').css('height', '790px');
        }

        var call_instructions = eventTile.event.call_instructions || window.threadComputedData.call_instructions;

        if((currentAppointment.kind != 'hangout' && currentAppointment.kind != 'skype') && !!!call_instructions.details && eventTile.event.location == '')// && eventTile.event.owned)
        {
            locationContainerNode.find('.location').hide();

            if($('#calling-infos-missing').length > 0){
                $('#calling-infos-missing').show();
            }else{
                locationContainerNode.prepend('<div id="calling-infos-missing"><div class="missing-call-informations"></div> <span style="display: inline-block; margin-top: 6px;margin-left: 27px;color: #F6BB67;">Instructions d\'appels manquantes</span></div>');
            }
        }else if(eventTile.event.location){//&& eventTile.event.owned){
            $('input.location').change(function(){
                var $that = $(this);
                scope.$apply(function(){Object.assign(scope.currentConf, {target: 'custom', event_instructions: $that.val(), details: $that.val()});});

            });
        }

        // These 2 functions were moved to the initActions() method below

        //eventTile.$selector.find("#event-edit-button").click(function() {
        //    scope.$apply(function(){scope.displayForm = true; scope.cacheCurrentInterlocutor(); scope.cacheCurrentConf();});
        //
        //    $('.event-tile-container .location').hide();
        //
        //    vmHelperNode.closest('.event-tile-container').css('height', '810px');
        //    vmHelperNode.closest('.created-event-panel').css('height', '790px');
        //});

        //eventTile.$selector.find("#event-cancel-button").click(function() {
        //    scope.$apply(function(){scope.displayForm = false; scope.restoreCachedInterlocutor(); scope.restoreCurrentConf();});
        //
        //    $('.event-tile-container .location').show();
        //    vmHelperNode.closest('.event-tile-container').css('height', '545px');
        //    vmHelperNode.closest('.created-event-panel').css('height', '515px');
        //});

    }
};

EventTile.prototype.isEditing = function() {
    var eventTile = this;
    return eventTile.$selector.find(".event-tile-container").hasClass("editing");
};

EventTile.prototype.setStartAndEnd = function(mStart, mEnd) {
    var eventTile = this;
    eventTile.$selector.find("input.start-date").val(mStart.tz(eventTile.getTimezoneId()).format("YYYY-MM-DD"));
    eventTile.$selector.find("input.start-hours").val(mStart.tz(eventTile.getTimezoneId()).format("HH"));
    eventTile.$selector.find("input.start-minutes").val(mStart.tz(eventTile.getTimezoneId()).format("mm"));

    eventTile.$selector.find("input.end-date").val(mEnd.tz(eventTile.getTimezoneIdForEndDate()).format("YYYY-MM-DD"));
    eventTile.$selector.find("input.end-hours").val(mEnd.tz(eventTile.getTimezoneIdForEndDate()).format("HH"));
    eventTile.$selector.find("input.end-minutes").val(mEnd.tz(eventTile.getTimezoneIdForEndDate()).format("mm"));

    if(eventTile.afterNewEventEdited) eventTile.afterNewEventEdited();
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

EventTile.prototype.getTimezoneIdForEndDate = function() {
    var eventTile = this;
    return eventTile.$selector.find("input.event-timezone-for-end-date-picker").val();
};

EventTile.prototype.enableAll = function() {
    var eventTile = this;

    var vmHelper = angular.element($('#event_update_vm_ctrl')).scope();

    eventTile.$selector.find("input, textarea, select").prop('disabled', false);
    eventTile.$selector.find(".recurrence-link-container").addClass("enabled");

    if(vmHelper && vmHelper.currentConf.target == 'client')
        $('#event_update_vm_ctrl').find('input').prop('disabled', true);
}

EventTile.prototype.disableAll = function() {
    var eventTile = this;
    eventTile.$selector.find("input, textarea, select").prop("disabled", true);
    eventTile.$selector.find(".recurrence-link-container").removeClass("enabled");

    // To be able to interact with the missing call instructions form
    //$('#event_update_vm_ctrl').find('#call_target').prop('disabled', false);
    //$('#event_update_vm_ctrl').find('#call_target_infos').prop('disabled', false);
    //$('#event_update_vm_ctrl').find('#call_support').prop('disabled', false);
    //$('#event_update_vm_ctrl').find('#call_details').prop('disabled', false);
};

EventTile.prototype.getEventStartEnd = function() {
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

        mEnd = moment.tz(eventTile.$selector.find("input.end-date").val(), eventTile.getTimezoneIdForEndDate());
        mEnd.set('h', eventTile.$selector.find("input.end-hours").val());
        mEnd.set('m', eventTile.$selector.find("input.end-minutes").val());
    }

    if(!mStart._isValid || !mEnd._isValid) {
        mStart = eventTile.event.start;
        mEnd = eventTile.event.start;
    }

    return {start: mStart, end: mEnd};
};

EventTile.prototype.redraw = function() {
    var eventTile = this;

    eventTile.$selector.find("input.title").val(eventTile.event.title);
    eventTile.$selector.find(".date .date-text").html(CommonHelpers.formatDateTimeRange(eventTile.event.start, eventTile.event.end, eventTile.locale, eventTile.getTimezoneId(), eventTile.event.allDay));
    eventTile.$selector.find("input.location").val(eventTile.event.location);
    eventTile.$selector.find("textarea.notes").val(eventTile.event.description);

    eventTile.$selector.find(".recurrence-container").hide();

    var rrule = "";
    var rstart = moment(eventTile.event.start);

    if(eventTile.recurringEvent) {
        eventTile.$selector.find(".recurrence-link-container .recurrence-text").html("Part of a recurring event");
        if(eventTile.recurringEvent.recurrence && $.isArray(eventTile.recurringEvent.recurrence)) {
            eventTile.$selector.find(".recurrence-container .recurrence-rule").val(eventTile.recurringEvent.recurrence.join("\n"));
            if(eventTile.recurringEvent.recurrence.length > 0) {
                rrule = eventTile.recurringEvent.recurrence[0];
            }
        }
        rstart = moment(eventTile.recurringEvent.start)
    }
    else if(eventTile.event.recurrence && $.isArray(eventTile.event.recurrence) && eventTile.event.recurrence.length > 0) {
        rrule = eventTile.event.recurrence[0];
        rstart = moment(eventTile.event.start)
    }

    eventTile.recurrenceForm = new RecurrenceForm(eventTile.$selector.find(".recurrence-container .recurrence-form-container"), {
        rrule: rrule,
        rstart: rstart,
        parentEventTile: eventTile,
        ruleChangedCallback: function(recurrenceForm) {
            eventTile.$selector.find(".recurrence-container .recurrence-rule").val(recurrenceForm.rrule);
            eventTile.$selector.find(".recurrence-link-container .recurrence-text").html(recurrenceForm.getText());
        }
    });


    eventTile.$selector.find(".attendees .attendees-list").html("");
    var attendees = [];
    if(eventTile.event.attendees) attendees = eventTile.event.attendees;

    $(attendees).each(function(k, attendee) {
        eventTile.eventDetailsAddAttendeeDiv(attendee);
    });

    eventTile.disableAll();


    var dStart = eventTile.event.start;
    var dEnd = eventTile.event.end;

    var mStartDate = moment();
    var mEndDate;
    mStartDate.set("h", 12);
    mStartDate.set("m", 0);
    mStartDate.set("s", 0);
    if(dStart) {
        mStartDate = moment(dStart);
    }

    if(dEnd) {
        mEndDate = moment(dEnd);
    }
    else {
        mEndDate = mStartDate.clone();
        mEndDate.add("h", 1);
    }
    mStartDate = mStartDate.locale(eventTile.locale);
    mEndDate = mEndDate.locale(eventTile.locale);


    if(!eventTile.event.beingAdded) {
        mStartDate = mStartDate.tz(eventTile.getTimezoneId());
        mEndDate = mEndDate.tz(eventTile.getTimezoneId());
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

    eventTile.$selector.find(".event-timezone-for-end-date-picker").timezonePicker();
    eventTile.$selector.find(".event-timezone-for-end-date-picker").val(eventTile.getTimezoneId());




    eventTile.disableAll();
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
            eventTile.enableAll();
            eventTile.$selector.find("#event-edit-button").hide();
            eventTile.$selector.find("#event-save-button").show();
            eventTile.$selector.find("#event-cancel-button").show();
        }
        else {
         //if(eventTile.event.owned)
        eventTile.$selector.find("#event-edit-button").show();
        eventTile.$selector.find("#event-delete-button").show();
        }
    }
    if(eventTile.getMode() == "read_only") {

    }
    if(eventTile.getMode() == "edit_only") {
        //if(eventTile.event.owned) {
            eventTile.$selector.find("#event-edit-button").show();
        //}
        angular.element($('#virtual-meetings-helper')).scope().forcedDetailsFrozen = true;

        $('#virtual-meetings-helper input').prop('disabled', true);
        $('#virtual-meetings-helper select').prop('disabled', true);
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


        mEnd = moment.tz(eventTile.$selector.find("input.end-date").val(), eventTile.getTimezoneIdForEndDate());
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
    
    var description = '';
    var location = '';
    if(eventTile.mode != 'free_calendar'){
        description = eventTile.$selector.find("textarea.notes").val();
        location = eventTile.$selector.find("input.location").val();

        var currentAppointment = window.getCurrentAppointment();

        if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
            if(window.threadComputedData.call_instructions.event_instructions || window.threadComputedData.call_instructions.event_instructions == '')
                location = window.threadComputedData.call_instructions.event_instructions;
        }
    }else{
        description = $(eventTile.$selector[0].childNodes[0]).find("textarea.notes").val();
        location = $(eventTile.$selector[0].childNodes[0]).find("input.location").val();
    }

    return {
        title: eventTile.$selector.find("input.title").val(),
        description: description,
        location: location,
        private: false,
        all_day: allDay,
        start: mStart,
        end: mEnd,
        attendees: attendees,
        recurrence: _.filter(eventTile.$selector.find(".recurrence-rule").val().split("\n"), function(rule) {
                return rule.length > 0;
            }),
        start_timezone: eventTile.getTimezoneId(),
        end_timezone: eventTile.getTimezoneIdForEndDate(),
        utc_offset: mStart.zone() / 60.0
    }
};
EventTile.prototype.fetchRecurringEventIfNeeded = function(callback) {
    var eventTile = this;

    if(eventTile.event && eventTile.event.recurringEventId) {
        var params = {
            action: "get_event",
            email: eventTile.accountEmail,
            event_id: eventTile.event.recurringEventId,
            calendar_id: eventTile.calendarId,
            calendar_login_username: eventTile.calendarLoginUsername,
            fetching_recurring_master: true
        };

        if(eventTile.event.url) {
            params['event_url'] = eventTile.event.url;
        }

        eventTile.showSpinner();
        CommonHelpers.externalRequest(params, function(response) {
            if(response.status == "error") {
                if(response.code == "EventNotFound") {
                    alert("Event not found: " + response.message)
                }
                else {
                    alert("Unable to fetch event: " + response.message)
                }
            }
            else {
                eventTile.hideSpinner();
                eventTile.recurringEvent = eventTile.eventDataFromEvent(response.data);
                eventTile.redraw();
                callback();
            }
        }, function(response) {
            eventTile.hideSpinner();
            alert("Unable to fetch event: " + response.message)
        });
    }
    else {
        eventTile.redraw();
        callback();
    }

};
EventTile.prototype.fetchEvent = function(callback) {
    var eventTile = this;

    // Dirty fix to display the Spinner after the event tile has been drawn, thus avoiding it beeing immediately hidden
    setTimeout(function() {
        eventTile.showSpinner();
    }, 0);
    CommonHelpers.externalRequest({
        action: "get_event",
        email: eventTile.accountEmail,
        event_id: eventTile.eventId,
        event_url: eventTile.eventUrl,
        calendar_id: eventTile.calendarId,
        calendar_login_username: eventTile.calendarLoginUsername
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
            eventTile.hideSpinner();
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

    var sstartTime, sendTime;
    if(ev.allDay) {
        sstartTime = moment(startTime);
        sendTime = moment(endTime);
    }
    else {
        sstartTime = moment(startTime).tz(eventTile.getTimezoneId());
        sendTime = moment(endTime).tz(eventTile.getTimezoneId());
    }


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
        timezoneId: eventTile.getTimezoneId(),
        recurringEventId: ev.recurringEventId,
        recurrence: ev.recurrence,
        calendar_login_username: ev.calendar_login_username,
        calendar_login_type: ev.calendar_login_type
    };

    if(ev.occurrences)
        eventData.occurrences = ev.occurrences;

    if(ev.call_instructions)
        eventData.call_instructions = JSON.parse(ev.call_instructions);
    
    return eventData;
};

EventTile.prototype.showSpinner = function() {
    var eventTile = this;
    console.log(eventTile.$selector.find(".spinner-container"));
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
EventTile.prototype.saveRecurringEvent = function() {
    var eventTile = this;
    eventTile.showSpinner();
    var editedEvent = eventTile.getEditedEvent();

    var recurringStartTime, recurringEndTime;
    if(editedEvent.recurrence.length == 0) {
        recurringStartTime = editedEvent.start;
        recurringEndTime = editedEvent.end;
    }
    else {
        var startDiff = editedEvent.start - moment(eventTile.event.start);
        recurringStartTime = moment(eventTile.recurringEvent.start);
        recurringStartTime.add('s', startDiff / 1000);
        recurringStartTime = recurringStartTime.format();

        var endDiff = editedEvent.end - moment(eventTile.event.end);
        recurringEndTime = moment(eventTile.recurringEvent.end);
        recurringEndTime.add('s', endDiff / 1000);
        recurringEndTime = recurringEndTime.format();
    }

    var recurrence = eventTile.recurringEvent.recurrence;
    recurrence[0] = editedEvent.recurrence[0];

    var params = {
        action: "update_event",
        email: eventTile.accountEmail,
        calendar_login_username: eventTile.event.calendar_login_username,

        event_id: eventTile.recurringEvent.id,
        calendar_id: eventTile.calendarId,

        summary: editedEvent.title,
        description: editedEvent.description,
        attendees: editedEvent.attendees,
        location: editedEvent.location,
        all_day: editedEvent.all_day,
        private: editedEvent.private,
        start: recurringStartTime,
        end: recurringEndTime,
        start_timezone: editedEvent.start_timezone,
        end_timezone: editedEvent.end_timezone,
        recurrence: recurrence
    };

    if(["IcloudLogin", "CaldavLogin"].indexOf(eventTile.event.calendar_login_type) >= 0) {
        params['occurrences'] = eventTile.recurringEvent.occurrences;
    }

    if(eventTile.event.url) {
        params['event_url'] = eventTile.event.url;
    }

    CommonHelpers.externalRequest(params, function(response) {
        if(response.status == "success") {
            if(eventTile.doneEditingCallback) eventTile.doneEditingCallback({
                action: "update_event"
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
};
EventTile.prototype.saveEvent = function(saving_recurring_occurrence) {
    saving_recurring_occurrence = saving_recurring_occurrence || false;

    var eventTile = this;
    var editedEvent = eventTile.getEditedEvent();

    var params = {
        email: eventTile.accountEmail,
        calendar_login_username: eventTile.event.calendar_login_username,

        summary: editedEvent.title,
        description: editedEvent.description,
        attendees: editedEvent.attendees,
        location: editedEvent.location,
        all_day: editedEvent.all_day,
        private: editedEvent.private,
        start: editedEvent.start.format(),
        end: editedEvent.end.format(),
        start_timezone: editedEvent.start_timezone,
        end_timezone: editedEvent.end_timezone,
        utc_offset: editedEvent.utc_offset
    };

    if(!saving_recurring_occurrence) {
        params['recurrence'] = editedEvent.recurrence;
    }

    if(eventTile.event.beingAdded) {
        params['action'] = "create_event";
        eventTile.showSpinner();
        CommonHelpers.externalRequest(params, function(response) {
            if(response.status == "success") {
                eventTile.eventId = response.data.event_id;
                eventTile.eventUrl = response.data.event_url;
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
        params['action'] = "update_event";
        params['event_id'] = eventTile.eventId;
        params['event_url'] = eventTile.eventUrl;
        params['calendar_id'] = eventTile.calendarId;

        if(saving_recurring_occurrence) {
            params['saving_occurrence'] = true;
            params['event_id'] = eventTile.event.id;

            if(["IcloudLogin", "CaldavLogin"].indexOf(eventTile.event.calendar_login_type) >= 0) {
                //var occurenceEventId = eventTile.recurringEvent.id + '__' + eventTile.event.start.tz('UTC').format("YYYYMMDD[T]HHmmss[Z]");
                //var occurenceEventId = eventTile.recurringEvent.id;
                //params['event_id'] = occurenceEventId;
                if(eventTile.recurringEvent) {
                    params['recurringEvent'] = eventTile.recurringEvent;
                    params['original_start'] = eventTile.event.start.tz(eventTile.getTimezoneId()).format();
                    params['event_id'] = eventTile.recurringEvent.id;
                }

            }else if(eventTile.event.calendar_login_type == "ActivesyncLogin") {
                params['original_start'] = eventTile.event.start.tz(eventTile.getTimezoneId()).format();
                params['original_end'] = eventTile.event.end.tz(eventTile.getTimezoneIdForEndDate()).format();
                params['original_summary'] = eventTile.event.title;
                params['original_location'] = eventTile.event.location;
                params['event_id'] = eventTile.recurringEvent.id;
            }
        }

        CommonHelpers.externalRequest(params, function(response) {
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
EventTile.prototype.confirmRecurringEventUpdate = function(params) {

    var eventTile = this;
    eventTile.$selector.find(".recurrence-confirm-container").html(HandlebarsTemplates['event_tile/recurrence_confirm_popup']()).fadeIn(200);

    // Wordings
    eventTile.$selector.find(".recurrence-confirm-container .message .message-situation").html(localize("events.recurring_event.this_event_is_part_of_recurring"));
    eventTile.$selector.find(".recurrence-confirm-container .message .message-question").html(localize("events.recurring_event.what_to_update"));
    if(params.mode == "delete") {
        eventTile.$selector.find(".recurrence-confirm-container .message .message-question").html(localize("events.recurring_event.what_to_delete"));
    }
    eventTile.$selector.find(".recurrence-confirm-container .recurrence-confirm-all-occurrences-button").html(localize("events.recurring_event.all_occurrences"));
    eventTile.$selector.find(".recurrence-confirm-container .recurrence-confirm-this-occurrence-button").html(localize("events.recurring_event.this_occurrence"));
    eventTile.$selector.find(".recurrence-confirm-container .recurrence-confirm-cancel-button").html(localize("common.cancel"));


    eventTile.$selector.find(".recurrence-confirm-container .recurrence-confirm-cancel-button").click(function() {
        eventTile.$selector.find(".recurrence-confirm-container").fadeOut(200);
    });
    eventTile.$selector.find(".recurrence-confirm-container .recurrence-confirm-all-occurrences-button").click(function() {
        eventTile.$selector.find(".recurrence-confirm-container").fadeOut(200);
        if(params.allOccurrencesCallback) {
            params.allOccurrencesCallback();
        }
    });
    eventTile.$selector.find(".recurrence-confirm-container .recurrence-confirm-this-occurrence-button").click(function() {
        eventTile.$selector.find(".recurrence-confirm-container").fadeOut(200);
        if(params.thisOccurrenceCallback) {
            params.thisOccurrenceCallback();
        }
    });
};

EventTile.prototype.deleteEvent = function(params) {
    var eventTile = this;
    eventTile.showSpinner();
    if(!params)  params = {};
    var eventIdToDelete = eventTile.eventId;

    if(params.deletingOccurrences && ['IcloudLogin', 'CaldavLogin', 'ActivesyncLogin'].indexOf(eventTile.event.calendar_login_type) >= 0) {
        if(["IcloudLogin", "CaldavLogin"].indexOf(eventTile.event.calendar_login_type) >= 0) {
            var editedEvent = eventTile.getEditedEvent();
            params = {
                action: "update_event",
                email: eventTile.accountEmail,
                calendar_login_username: eventTile.event.calendar_login_username,

                event_id: eventTile.eventId,
                event_url: eventTile.eventUrl,
                calendar_id: eventTile.calendarId,

                summary: eventTile.event.title,
                description: eventTile.event.description,
                attendees: eventTile.event.attendees,
                location: eventTile.event.location,
                all_day: eventTile.event.all_day,
                private: eventTile.event.private,
                start: eventTile.event.start.format(),
                end: eventTile.event.end.format(),
                start_timezone: editedEvent.start_timezone,
                end_timezone: editedEvent.end_timezone,
                utc_offset: eventTile.event.utc_offset,
                saving_occurrence: true,
                deletingOccurrence: true,
                recurringEvent: eventTile.recurringEvent,
                original_start: eventTile.event.start.tz(eventTile.getTimezoneId()).format()
            };
        }else if(eventTile.event.calendar_login_type == 'ActivesyncLogin') {
            params = {
                action: "delete_event",
                email: eventTile.accountEmail,
                calendar_login_username: eventTile.event.calendar_login_username,
                event_id: eventIdToDelete,
                instance_id: eventTile.event.start.format(),
                calendar_id: eventTile.calendarId
            };
        }
    } else {
        if(params.recurring) {
            if(eventTile.recurringEvent) {
                eventIdToDelete = eventTile.recurringEvent.id;
            }
            else {
                alert("Trying to delete the recurring event, but no recurring event for this event");
                return;
            }
        }

        params = {
            action: "delete_event",
            email: eventTile.accountEmail,
            calendar_login_username: eventTile.event.calendar_login_username,
            event_id: eventIdToDelete,
            calendar_id: eventTile.calendarId
        };

        if(eventTile.eventUrl || eventTile.event.url) {
            params['event_url'] = eventTile.eventUrl || eventTile.event.url;
        }
    }

    CommonHelpers.externalRequest(params, function(response) {
        if(response.status == "success") {
            if(eventTile.doneEditingCallback) eventTile.doneEditingCallback({
                action: params.action
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

EventTile.prototype.showRecurrenceContainer = function() {
    var eventTile = this;
    eventTile.$selector.find(".recurrence-container").css({left: 330}).show().animate({left: 0}, 200);
};

EventTile.prototype.hideRecurrenceContainer = function() {
    var eventTile = this;
    eventTile.$selector.find(".recurrence-container").animate({left: 330}, 200, function() {
        $(this).hide();
    });
};

EventTile.prototype.initActions = function() {
    var eventTile = this;

    eventTile.$selector.find("#event-edit-button").click(function() {
        var currentAppointment = window.getCurrentAppointment();

        eventTile.enableAll();
        eventTile.$selector.find("#event-delete-button").hide();
        eventTile.$selector.find("#event-edit-button").hide();

        if(eventTile.getMode() != "edit_only") {
            eventTile.$selector.find("#event-save-button").show();
        }
        eventTile.$selector.find("#event-cancel-button").show();
        eventTile.$selector.find(".event-tile-container").addClass("editing");

        eventTile.redrawDatePicker();

        if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual){
            var vmHelperNode = $('#event_update_vm_ctrl');
            var scope = angular.element(vmHelperNode).scope();

            if(!!scope)
                scope.$apply(function(){scope.displayForm = true; scope.cacheCurrentInterlocutor(); scope.cacheCurrentConf();});

            if(eventTile.mode != 'free_calendar') {
                $('.event-tile-container .location').hide();
            }

            vmHelperNode.closest('.event-tile-container').css('height', '810px');
            vmHelperNode.closest('.created-event-panel').css('height', '790px');

        }else{
            $('.event-tile-container .location').show();
        }

        reProcessTitle();
        updateCurrentEventNotes();

        if(eventTile.afterRedrawCallback) eventTile.afterRedrawCallback();
    });

    eventTile.$selector.find("#event-cancel-button").click(function() {
        var currentAppointment = window.getCurrentAppointment();

        var vmHelperNode = $('#event_update_vm_ctrl');
        var scope = angular.element(vmHelperNode).scope();

        if(!!scope)
            scope.$apply(function(){scope.displayForm = false; scope.restoreCachedInterlocutor(); scope.restoreCurrentConf();});

        vmHelperNode.closest('.event-tile-container').css('height', '545px');
        vmHelperNode.closest('.created-event-panel').css('height', '515px');

        $('.event-tile-container .location').show();

        if(window.threadComputedData && !window.threadComputedData.is_virtual_appointment){
            $('#calling-infos-missing').hide();
        }

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

        if(eventTile.recurringEvent) {
            if(eventTile.getEditedEvent().recurrence.length == 0) {
                eventTile.saveRecurringEvent();
            }
            else {
                eventTile.confirmRecurringEventUpdate({
                    thisOccurrenceCallback: function() {
                        eventTile.saveEvent(true);
                    },
                    allOccurrencesCallback: function() {
                        eventTile.saveRecurringEvent();
                    }
                });
            }
        }
        else {
            eventTile.saveEvent();
        }
    });
    eventTile.$selector.find("#event-delete-button").click(function(e) {
        if(eventTile.recurringEvent) {
            eventTile.confirmRecurringEventUpdate({
                mode: "delete",
                thisOccurrenceCallback: function() {
                    eventTile.deleteEvent({deletingOccurrences: true});
                },
                allOccurrencesCallback: function() {
                    eventTile.deleteEvent({
                        recurring: true
                    });
                }
            });
        }
        else {
            if (confirm("Are you sure you want to delete this event?")) {
                eventTile.deleteEvent();
            }
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
            var mEndDate = editedEvent.start.clone().tz(eventTile.getTimezoneIdForEndDate());
            mEndDate.add("h", 1);


            eventTile.$selector.find("input.end-date").val(mEndDate.format("YYYY-MM-DD"));
            eventTile.$selector.find("input.end-hours").val(mEndDate.format("HH"));
            eventTile.$selector.find("input.end-minutes").val(mEndDate.format("mm"));
        }
        if(eventTile.afterNewEventEdited) eventTile.afterNewEventEdited();
    });

    eventTile.$selector.find("input.event-timezone-picker").on("autocompleteselect", function(e, ui) {
        eventTile.$selector.find("input.event-timezone-for-end-date-picker").val(ui.item.value);
    });
    eventTile.$selector.find("input.event-timezone-picker").on("autocompletechange", function(e, ui) {
        if(eventTile.afterNewEventEdited) eventTile.afterNewEventEdited();
    });

    eventTile.$selector.find("input.event-timezone-for-end-date-picker").on("autocompletechange", function(e) {
        if(eventTile.afterNewEventEdited) eventTile.afterNewEventEdited();
    });

    eventTile.$selector.find("input.event-date-all-day").change(function(e) {
        eventTile.redrawDatePicker();
    });

    eventTile.$selector.find(".recurrence-container .recurrence-back-button").click(function() {
        eventTile.hideRecurrenceContainer();
    });

    eventTile.$selector.find(".recurrence-link-container").click(function() {
        if($(this).hasClass("enabled")) {
            var calendarLoginTypeActivatedForRecurrence =  ["GoogleLogin"];

            if(window.featuresHelper.isFeatureActive("recurrence_ews")) {
                calendarLoginTypeActivatedForRecurrence.push("EwsLogin");
            }
            if(window.featuresHelper.isFeatureActive("recurrence_exchange")) {
                calendarLoginTypeActivatedForRecurrence.push("ExchangeLogin");
            }
            if(window.featuresHelper.isFeatureActive("recurrence_icloud")) {
                calendarLoginTypeActivatedForRecurrence.push("IcloudLogin");
            }
            if(window.featuresHelper.isFeatureActive("recurrence_caldav")) {
                calendarLoginTypeActivatedForRecurrence.push("CaldavLogin");
            }
            if(window.featuresHelper.isFeatureActive("recurrence_activesync")) {
                calendarLoginTypeActivatedForRecurrence.push("ActivesyncLogin");
            }

            if(calendarLoginTypeActivatedForRecurrence.indexOf(eventTile.event.calendar_login_type) == -1 ) {
                alert("Recurring events are not supported for this account. Please send to admin.")
            }
            else {
                eventTile.showRecurrenceContainer();
            }
        }
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
        e.stopPropagation();
    });
};