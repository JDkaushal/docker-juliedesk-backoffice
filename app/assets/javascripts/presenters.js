window.presenters = {};

window.presenters.redrawEvent = function(params) {
    $(".messages-thread-info-panel .created-event-panel .fetching-spinner-container").show();
    $(".messages-thread-info-panel .created-event-panel").show();
    CommonHelpers.externalRequest({
        action: "get_event",
        email: params.accountEmail,
        event_id: params.eventId,
        calendar_id: params.calendarId
    }, function(e) {
        $(".created-event-panel .event-summary").text(e.data.summary);
        $(".created-event-panel .event-date div").html(CommonHelpers.formatDateTimeRange(e.data.start.dateTime, e.data.end.dateTime, "<%= I18n.locale %>"));
        $(".created-event-panel .event-location div").text(e.data.location);
        $(".created-event-panel .event-notes textarea").val(e.data.description);
        $(".created-event-panel .event-notes textarea").elastic();
        var $attendeesDiv = $(".created-event-panel .event-attendees div");
        $attendeesDiv.html("");
        $(e.data.attendees).each(function(k, attendee) {
            var $attendee = $("<div>").html(attendee.displayName + " - " + attendee.email + " (" + attendee.responseStatus + ")");
            $attendee.addClass("attendee-text");
            if(attendee.organizer) {
                $attendee.addClass("organizer");
            }
            $attendeesDiv.append($attendee);
        });

        $(".messages-thread-info-panel .created-event-panel .fetching-spinner-container").hide();

        if(params.callback) {
            params.callback();
        }
    });
};