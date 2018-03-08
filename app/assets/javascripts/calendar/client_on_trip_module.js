function ClientOnTripCalendarModule(params) {
    this.calendarTimezone = params.calendarTimezone;
    this.mainClientOnTrip = params.mainClientOnTrip;
    this.currentClientOnTripMasks = [];
}

ClientOnTripCalendarModule.prototype.fullCalendarViewRender = function(fullCalendarView, fullCalendarElement) {
    var clientOnTripCalendarModule = this;
    if(!featuresHelper.isFeatureActive("show_client_on_trip_on_calendar")) {
        return;
    }

    clientOnTripCalendarModule.currentClientOnTripMasks = []

    var currentDateForClientOnTripDate = fullCalendarView.start.clone();

    while(currentDateForClientOnTripDate < fullCalendarView.end) {
        clientOnTripCalendarModule.currentClientOnTripMasks.push({
            date:  moment.tz(currentDateForClientOnTripDate.format(), clientOnTripCalendarModule.calendarTimezone),
            left: fullCalendarView.colContentLeft(fullCalendarView.dateToCell(currentDateForClientOnTripDate).col),
            width: fullCalendarView.getColWidth(),
            visible: clientOnTripCalendarModule.mainClientOnTrip != null
        })
        currentDateForClientOnTripDate.add('d', 1)
    }
}

ClientOnTripCalendarModule.prototype.fullCalendarEventAfterAllRender = function(fullCalendarView) {
    var clientOnTripCalendarModule = this;

    if(!featuresHelper.isFeatureActive("show_client_on_trip_on_calendar")) {
        return;
    }

    var fcEventContainer = fullCalendarView.element.find(".fc-event-container").last();
    var calendarHeight = fcEventContainer.parent().height();

    _.each(clientOnTripCalendarModule.currentClientOnTripMasks, function(clientOnTripMask) {
        if(clientOnTripMask.visible) {
            fcEventContainer.append($("<div>").addClass("client-on-trip-mask").css({
                width: clientOnTripMask.width,
                height: calendarHeight,
                left: clientOnTripMask.left
            }));
        }
    });
}

ClientOnTripCalendarModule.prototype.fullCalendarEventAfterRender = function(fullCalendarEvent, fullCalendarElement, fullCalendarView) {
    var clientOnTripCalendarModule = this;

    if(!featuresHelper.isFeatureActive("show_client_on_trip_on_calendar")) {
        return;
    }


    if(fullCalendarEvent.id && fullCalendarEvent.allDay && fullCalendarEvent.aiMetadata && fullCalendarEvent.aiMetadata.location_indication != null) {
        _.each(clientOnTripCalendarModule.currentClientOnTripMasks, function (clientOnTripMask) {
            if(clientOnTripMask.date.diff(fullCalendarEvent.start, 'days') >= 0 &&
                clientOnTripMask.date.diff(fullCalendarEvent.end, 'days') < 0) {

                if(clientOnTripCalendarModule.mainClientOnTrip && fullCalendarEvent.aiMetadata.location_indication === clientOnTripCalendarModule.mainClientOnTrip.label) {
                    clientOnTripMask.visible = false;
                }
                else {
                    clientOnTripMask.visible = true;
                }
            }
        });
    }
}