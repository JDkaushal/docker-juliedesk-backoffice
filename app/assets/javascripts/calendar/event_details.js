Calendar.prototype.showEventDetails = function(event) {
    var calendar = this;
    calendar.currentEvent = event;
    var $edc = calendar.$selector.find("#event-details-container");

    $edc.find("input.title").val(event.title);
    $edc.find(".start").html(event.start.format("LLL"));
    $edc.find(".end").html(event.end.format("LLL"));


    $edc.find(".start-date").val(event.start.format("YYYY-MM-DD"));
    $edc.find(".start-hours").val(event.start.format("HH"));
    $edc.find(".start-minutes").val(event.start.format("mm"));
    $edc.find(".end-date").val(event.end.format("YYYY-MM-DD"));
    $edc.find(".end-hours").val(event.end.format("HH"));
    $edc.find(".end-minutes").val(event.end.format("mm"));

    $edc.find("input.location").val("");
    $edc.find("textarea.notes").val("");
    $edc.find(".attendees").html("");
    $edc.find(".attendees-list").html("");

    $edc.find("input, textarea").attr("disabled", "disabled");
    $edc.find(".event-date-edit-container").hide();

    $edc.find("#event-delete-button").hide();
    $edc.find("#event-edit-button").hide();
    $edc.find("#event-save-button").hide();
    $edc.find("#event-cancel-button").hide();

    $edc.find(".event-spinner").show();
    $edc.find(".event-details").removeClass("editing");

    $edc.find("#should-notify").attr("checked", false);

    $edc.fadeIn(200);
    if(calendar.accountPreferences.calendar_nature == "icloud" || calendar.accountPreferences.calendar_nature == "exchange") {

        $edc.find(".event-spinner").fadeOut(200);
        $edc.find("input.location").val(event.location);
        $edc.find("textarea.notes").val(event.description);
        $edc.find(".attendees").html("");

        var attendees = [];
        if(event.attendees) attendees = event.attendees;
        var attendeeEmails = [];
        $(attendees).each(function(k, attendee) {
            var $attendee = $("<div>").html(attendee.displayName + " - " + attendee.email + " (" + attendee.responseStatus + ")");
            $attendee.addClass("attendee-text");
            if(attendee.organizer) {
                $attendee.addClass("organizer");
            }
            attendeeEmails.push(attendee.email);
            $edc.find(".attendees").append($attendee);

            $edc.find(".attendees-list").append($("<div>").addClass("attendee").data("email", attendee.email).html(attendee.email));
        });


        $edc.find("#event-delete-button").show();
        $edc.find("#event-edit-button").show();
    }

    return;
    CommonHelpers.externalRequest({
        action: "event_details",
        calendarId: calendar.calendars[event.calIndex].id,
        eventId: event.id,
        access_token: calendar.accountPreferences.access_token
    }, function(response) {
        var location = response.location;
        if(!location) location = "";

        var notes = response.notes;
        if(!notes) notes = "";

        var attendees = response.attendees;

        $edc.find("input.title").val(response.summary);
        $edc.find(".start").html(moment(response.start.dateTime).format("LLL"));
        $edc.find(".end").html(moment(response.end.dateTime).format("LLL"));

        $edc.find("input.location").val(location);
        $edc.find("textarea.notes").val(notes);
        $edc.find(".attendees").html("");
        var attendeeEmails = [];
        $(attendees).each(function(k, attendee) {
            var $attendee = $("<div>").html(attendee.displayName + " - " + attendee.email + " (" + attendee.responseStatus + ")");
            $attendee.addClass("attendee-text");
            if(attendee.organizer) {
                $attendee.addClass("organizer");
            }
            attendeeEmails.push(attendee.email);
            $edc.find(".attendees").append($attendee);

            $edc.find(".attendees-list").append($("<div>").addClass("attendee").data("email", attendee.email).html(attendee.email));
        });

        if(response.organizer && attendeeEmails.indexOf(response.organizer.email)== -1) {
            var $attendee = $("<div>").html(response.organizer.displayName + " - " + response.organizer.email + " (Organizer)");
            $attendee.addClass("attendee-text");
            $attendee.addClass("organizer");
            $edc.find(".attendees").prepend($attendee);
        }


        $edc.find(".event-spinner").fadeOut(200);

        if(response.start.dateTime !== undefined) {
            $edc.find("#event-delete-button").show();
            $edc.find("#event-edit-button").show();

            calendar.currentEvent.title = response.summary;
            calendar.currentEvent.start = moment(response.start.dateTime).tz($("#calendar-timezone").val()).format();
            calendar.currentEvent.end = moment(response.end.dateTime).tz($("#calendar-timezone").val()).format();
            calendar.currentEvent.sequence = response.sequence;

            calendar.currentEvent.attendees = response.attendees;
            calendar.currentEvent.reminders = response.reminders;
            calendar.$selector.find("#calendar").fullCalendar('updateEvent', calendar.currentEvent);
        }
    });


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
//        if (confirm("Are you sure you want to delete this event?")) {
//            chrome.runtime.sendMessage({
//                greeting: "event_delete",
//                email: accountPreferences.email,
//                eventId: currentEvent.id,
//                calendarId: calendars[currentEvent.calIndex].id,
//                calendar_nature: accountPreferences.calendar_nature,
//                access_token: calendar.accountPreferences.access_token,
//            }, function(response) {
//                console.log(response);
//                if(response.status == "success") {
//                    var calendarEvent = $("#calendar").fullCalendar('removeEvents', currentEvent.id);
//                    $("#event-details-container").fadeOut(200);
//                }
//                else {
//                    alert("Error deleting event");
//                }
//            });
//        }
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