window.presenters = {};

window.presenters.redrawEvent = function(params) {
    $(".messages-thread-info-panel .created-event-panel .fetching-spinner-container").show();
    $(".messages-thread-info-panel .created-event-panel").find("input, textarea").attr('disabled', true);
    $(".messages-thread-info-panel .created-event-panel").show();
    CommonHelpers.externalRequest({
        action: "get_event",
        email: params.accountEmail,
        event_id: params.eventId,
        calendar_id: params.calendarId
    }, function(e) {

        window.currentEventData = e.data;
        $(".created-event-panel .event-summary input").val(e.data.summary);
        $(".created-event-panel .event-date div").html(CommonHelpers.formatDateTimeRange(e.data.start.dateTime, e.data.end.dateTime, "<%= I18n.locale %>", window.threadAccount.default_timezone_id, e.data.allDay));
        $(".created-event-panel .event-date").data("start", e.data.start.dateTime);
        $(".created-event-panel .event-date").data("end", e.data.end.dateTime);

        $(".created-event-panel .event-location input").val(e.data.location);
        $(".created-event-panel .event-notes textarea").val(e.data.description);
        $(".created-event-panel .event-notes textarea").elastic();
        var $attendeesDiv = $(".created-event-panel .event-attendees .event-attendees-div");
        $attendeesDiv.html("");
        $(e.data.attendees).each(function(k, attendee) {
            var $attendee = $("<div>").html(attendee.displayName + " - " + attendee.email + " (" + attendee.responseStatus + ")");
            $attendee.addClass("attendee-text");
            if(attendee.organizer) {
                $attendee.addClass("organizer");
            }
            $attendeesDiv.append($attendee);
        });
        $attendeesDiv.show();

        if(e.data.private) {
            $(".created-event-panel .event-private input").prop("checked", true);
        }
        else {
            $(".created-event-panel .event-private input").removeAttr("checked");
        }


        // Edit attendees code

        var addAttendeeToEventCreatedEditList = function(email, name, checked, addedAttendees) {
            if(!addedAttendees) {
                addedAttendees = [];
            }
            var $attendee = $("<div>").data("email", email).data("name", name).addClass("attendee");
            if(checked) {
                $attendee.append($("<input type='checkbox' checked>"));
            }
            else {
                $attendee.append($("<input type='checkbox'>"));
            }
            $attendee.append($("<span>").html(email).addClass("attendee-text"));
            $attendeesEditDivList.append($attendee);
            addedAttendees.push(email);
            return addedAttendees;
        };

        var $attendeesEditDiv = $(".created-event-panel .event-attendees .event-attendees-edit-div");
        $attendeesEditDiv.html("");
        $attendeesEditDivList = $("<div>");
        var addedAttendees = [];
        $(e.data.attendees).each(function(k, attendee) {
            addedAttendees = addAttendeeToEventCreatedEditList(attendee.email, attendee.name, true, addedAttendees);
        });

        var allContacts = $("#contacts-data-list .contact").map(function() {
            return {
                email: $(this).data("email"),
                name: $(this).data("name")
            }
        }).get();

        $(allContacts).each(function(k, contact) {
            if(addedAttendees.indexOf(contact.email) < 0) {
                addedAttendees = addAttendeeToEventCreatedEditList(contact.email, contact.name, false, addedAttendees);
            }
        });
        $attendeesEditDiv.append($attendeesEditDivList);
        $addAttendeeDiv = $("<div>").addClass("add-attendee-div");
        $addAttendeeDiv.append($("<input>"));
        $addAttendeeDiv.append($("<div>").addClass("add-attendee-button btn btn-success btn-xs").html("Add"));
        $attendeesEditDiv.append($addAttendeeDiv);

        $(".created-event-panel .add-attendee-div .add-attendee-button").click(function() {
            var email = $(".created-event-panel .add-attendee-div input").val();
            $(".created-event-panel .add-attendee-div input").val("");
            addAttendeeToEventCreatedEditList(email, "", true);
        });
        $attendeesEditDiv.hide();
        // - - - - - - - - - - - - - - - -

        $(".messages-thread-info-panel .created-event-panel .fetching-spinner-container").hide();

        if(params.callback) {
            params.callback();
        }
    });
};
