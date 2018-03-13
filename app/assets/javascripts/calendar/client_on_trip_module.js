function ClientOnTripCalendarModule(params) {
    this.calendarTimezone = params.calendarTimezone;
    this.mainClientOnTrip = params.mainClientOnTrip;
    this.active = params.active;
    this.currentClientOnTripMasks = [];
}

ClientOnTripCalendarModule.prototype.fullCalendarViewRender = function(fullCalendarView, fullCalendarElement) {
    var clientOnTripCalendarModule = this;
    if(!clientOnTripCalendarModule.active) {
        return;
    }

    clientOnTripCalendarModule.currentClientOnTripMasks = []

    var currentDateForClientOnTripDate = fullCalendarView.start.clone();

    while(currentDateForClientOnTripDate < fullCalendarView.end) {
        clientOnTripCalendarModule.currentClientOnTripMasks.push({
            date:  moment.tz(currentDateForClientOnTripDate.format(), clientOnTripCalendarModule.calendarTimezone),
            left: fullCalendarView.colContentLeft(fullCalendarView.dateToCell(currentDateForClientOnTripDate).col),
            width: fullCalendarView.getColWidth(),
            visible: clientOnTripCalendarModule.mainClientOnTrip != null,
            value: null
        })
        currentDateForClientOnTripDate.add('d', 1)
    }
}

ClientOnTripCalendarModule.prototype.fullCalendarEventAfterAllRender = function(fullCalendarView) {
    var clientOnTripCalendarModule = this;

    if(!clientOnTripCalendarModule.active) {
        return;
    }

    var fcEventContainer = fullCalendarView.element.find(".fc-event-container").last();
    var calendarHeight = fcEventContainer.parent().height();

    var $tr = $("<tr>").addClass("client-on-trip-header");
    $tr.append($("<th>"));

    var i = 0;
    fullCalendarView.element.find("thead tr .client-on-trip-label").remove();


    _.each(clientOnTripCalendarModule.currentClientOnTripMasks, function(clientOnTripMask) {
        if(clientOnTripMask.visible) {
            fcEventContainer.append($("<div>").addClass("client-on-trip-mask").css({
                width: clientOnTripMask.width,
                height: calendarHeight,
                left: clientOnTripMask.left
            }));
        }

        var valueToDisplay = clientOnTripMask.value || "Default";
        if(!valueToDisplay || valueToDisplay === "") {
            valueToDisplay = "Default"
        }
        
        var $header = $("<div>").addClass("client-on-trip-label").html($("<span>").addClass("value").html(valueToDisplay).addClass(clientOnTripMask.visible ? "incorrect" : "correct"));
        fullCalendarView.element.find("thead tr th.fc-col" + i).append($header);
        i += 1;
    });




}

ClientOnTripCalendarModule.prototype.fullCalendarEventAfterRender = function(fullCalendarEvent, fullCalendarElement, fullCalendarView) {
    var clientOnTripCalendarModule = this;

    if(!clientOnTripCalendarModule.active) {
        return;
    }

    var eventLocationIndication = fullCalendarEvent.aiMetadata.location_indication;
    if(eventLocationIndication === '') {
        eventLocationIndication = null;
    }


    if(fullCalendarEvent.id && fullCalendarEvent.allDay && fullCalendarEvent.aiMetadata && eventLocationIndication != null) {
        _.each(clientOnTripCalendarModule.currentClientOnTripMasks, function (clientOnTripMask) {
            if(clientOnTripMask.date.diff(fullCalendarEvent.start, 'days') >= 0 &&
                clientOnTripMask.date.diff(fullCalendarEvent.end, 'days') < 0) {

                if(clientOnTripCalendarModule.mainClientOnTrip && eventLocationIndication === clientOnTripCalendarModule.mainClientOnTrip.label) {
                    clientOnTripMask.visible = false;
                    clientOnTripMask.value = eventLocationIndication;
                }
                else {
                    clientOnTripMask.visible = true;
                    clientOnTripMask.value = eventLocationIndication;
                }
            }
        });
    }
}