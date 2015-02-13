Calendar.prototype.showEventDetails = function(event, $currentTarget) {
    var calendar = this;
    calendar.resetEventDetailsContainer();

    // Positioning
    if($currentTarget) {
        var $edc = calendar.$selector.find("#event-details-container");
        if($currentTarget.offset().left < calendar.$selector.width() / 2) {
            $edc.find(".event-details").css({
                top: (calendar.$selector.height() - $edc.find(".event-details").outerHeight()) / 2,
                left: $currentTarget.offset().left + $currentTarget.width() + 10
            });
        }
        else {
            $edc.find(".event-details").css({
                top: (calendar.$selector.height() - $edc.find(".event-details").outerHeight()) / 2,
                left: $currentTarget.offset().left - $edc.find(".event-details").outerWidth() - 10
            });
        }

    }
    calendar.redrawEventDetailsFromEvent(event);
};

Calendar.prototype.resetEventDetailsContainer = function() {
    var calendar = this;
    calendar.$selector.find("#event-details-container").html(calendar.$selector.find("#event-details-template-container").html());
};

Calendar.prototype.redrawEventDetailsFromEvent = function(event) {
    var calendar = this;
    calendar.currentEvent = event;
    var $edc = calendar.$selector.find("#event-details-container");

    $edc.find("input.title").val(event.title);
    $edc.find(".date").html(CommonHelpers.formatDateTimeRange(event.start, event.end, "fr", calendar.getCalendarTimezone()));
    $edc.find("input.location").val(event.location);
    $edc.find("textarea.notes").val(event.description);

    $edc.find(".attendees").html("");
    var attendees = [];
    if(event.attendees) attendees = event.attendees;
    var attendeeEmails = [];
    $(attendees).each(function(k, attendee) {
        var $attendee = $("<div>").addClass("attendee-text");
        $attendee.append($("<div>").addClass("attendee-name").html(attendee.displayName));
        $attendee.append($("<div>").addClass("attendee-email").html(attendee.email));
        $attendee.append($("<div>").addClass("attendee-status").html(attendee.responseStatus));

        if(attendee.organizer) {
            $attendee.addClass("organizer");
        }
        attendeeEmails.push(attendee.email);
        $edc.find(".attendees").append($attendee);

        $edc.find(".attendees-list").append($("<div>").addClass("attendee").data("email", attendee.email).html(attendee.email));
    });

    $edc.find("input, textarea").attr("disabled", "disabled");

//    $edc.find(".start-date").val(event.start.format("YYYY-MM-DD"));
//    $edc.find(".start-hours").val(event.start.format("HH"));
//    $edc.find(".start-minutes").val(event.start.format("mm"));
//    $edc.find(".end-date").val(event.end.format("YYYY-MM-DD"));
//    $edc.find(".end-hours").val(event.end.format("HH"));
//    $edc.find(".end-minutes").val(event.end.format("mm"));

    //$edc.find(".attendees-list").html("");

    if(calendar.getMode() == "select_events") {
        if(calendar.selectedEvents.indexOf(calendar.currentEvent) == -1) {
            $edc.find("#event-select-button").html("Select");
        }
        else {
            $edc.find("#event-select-button").html("Unselect");
        }
        $edc.find("#event-select-button").show();
    }
    else {
        $edc.find("#event-delete-button").show();
    }


    $edc.fadeIn(200);
    return;
    $edc.find(".event-date-edit-container").hide();


    $edc.find("#event-edit-button").hide();
    $edc.find("#event-save-button").hide();
    $edc.find("#event-cancel-button").hide();

    $edc.find(".event-spinner").show();
    $edc.find(".event-details").removeClass("editing");

    $edc.find("#should-notify").attr("checked", false);






    //$edc.find("#event-delete-button").show();
    //$edc.find("#event-edit-button").show();
};

Calendar.prototype.clickEventDetailsContainer = function(e) {
    var calendar = this;
    var $container = calendar.$selector.find("#event-details-container");
    var $target = $(e.target);

    if($target.attr("id") == "event-edit-button") {
        $container.find("input, textarea").removeAttr("disabled");
        $container.find("#event-delete-button").hide();
        $container.find("#event-edit-button").hide();
        $container.find("#event-save-button").show();
        $container.find("#event-cancel-button").show();
        $container.find(".event-date-edit-container").show();
        $container.find(".event-details").addClass("editing");
    }
    else if($target.attr("id") == "event-cancel-button") {
        calendar.showEventDetails(calendar.currentEvent);
    }
    else if($target.attr("id") == "event-save-button") {
//        var title = $container.find("input.title").val()
//        updateCurrentEventDateFromInput($container);
//
//        var attendees = currentEvent.attendees;
//        $container.find(".attendees-list .attendee").each(function() {
//            var email = $(this).data("email");
//            if(!attendees || $.grep(attendees, function(hash) { return hash.email == email}).length == 0) {
//                if(!attendees) attendees = [];
//                attendees.push({email: email});
//            }
//        });
//        chrome.runtime.sendMessage({
//            greeting: "event_update",
//            eventId: currentEvent.id,
//            calendarId: calendars[currentEvent.calIndex].id,
//            access_token: calendar.accountPreferences.access_token,
//            start: currentEvent.start.format(),
//            end: currentEvent.end.format(),
//            summary: title,
//            description: $container.find("textarea.notes").val(),
//            location: $container.find("input.location").val(),
//            sequence: currentEvent.sequence,
//            attendees: attendees,
//            reminders: currentEvent.reminders,
//            sendNotifications: $container.find("#should-notify").prop("checked"),
//            email: accountPreferences.email,
//            calendar_nature: accountPreferences.calendar_nature,
//        }, function(response) {
//            console.log(response);
//            if(response.status == "success") {
//                showEventDetails(currentEvent);
//            }
//            else {
//                alert("Error updating event");
//            }
//
//        });
    }
    else if($target.attr("id") == "event-delete-button") {
        if (confirm("Are you sure you want to delete this event?")) {
            $container.find(".event-spinner").show();
            CommonHelpers.externalRequest({
                action: "delete_event",
                email: calendar.initialData.email,
                event_id: calendar.currentEvent.id,
                calendar_id: calendar.currentEvent.calId
            }, function(response) {
                if(response.status == "success") {
                    $("#event-details-container").fadeOut(200);
                    calendar.refreshEvents();
                }
                else {
                    alert("Error deleting event");
                    console.log("error", response);
                }
            }, function(e) {
                alert("Error deleting event");
                console.log("error", e);
            });
        }
    }
    else if($target.attr("id") == "event-select-button") {
        calendar.selectEvent(calendar.currentEvent);
        calendar.redrawEventDetailsFromEvent(calendar.currentEvent);
    }
    else if($target.hasClass("add-new-attendee")) {
        var email = $container.find("#new-attendee").val();
        $container.find(".attendees-list").append($("<div>").addClass("attendee").data("email", email).html(email));
        $container.find("#new-attendee").val("");
        $container.find("#should-notify").attr("checked", true);
    }
    else if($target.closest(".event-details").length == 0 || $target.hasClass("event-close-button")) {
        $("#event-details-container").fadeOut(200);
    }
};