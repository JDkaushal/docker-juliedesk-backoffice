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
    if(calendar.getMode() == "read_only") return;

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
    var travelTimeTileCtrl = $('travel-time-tile').scope();

    if(event.isTravelTime) {
        travelTimeTileCtrl.display(event, $(jsEvent.currentTarget));
        travelTimeTileCtrl.$apply();
    } else {

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
    }
};

Calendar.prototype.setBusyStatusOnEvent = function(event, elementOriginalColor, $element, $imgSpanNode, $allDayMaskNode) {
    var calendar = this;
    var timezone = calendar.getCalendarTimezone();
    var newBusy = !event.busy;
    var oldBusy = event.busy;

    CommonHelpers.externalRequest({
        action: "update_event",
        email: calendar.findAccountEmailForEvent(event),
        calendar_login_username: event.calendar_login_username,
        event_id: event.id,
        event_url: event.url,
        calendar_id: event.calId,
        summary: event.title,
        description: event.description,
        attendees: event.attendees,
        location: event.location,
        all_day: event.allDay,
        private: event.private,
        start: event.start.format(),
        end: event.end.format(),
        start_timezone: timezone,
        end_timezone: timezone,
        utc_offset: event.start.zone() / 60.0,
        busy: newBusy
    }, function(response) {
        if(response.status == "success") {
            event.busy = newBusy;

            if(event.busy) {
                $allDayMaskNode.show();
                $element.css({'background-color': '#FD9797'});
                $imgSpanNode.removeClass('free').addClass('busy');
            }else {
                $allDayMaskNode.hide();
                $element.css({'background-color': elementOriginalColor});
                $imgSpanNode.removeClass('busy').addClass('free');
            }

            $.ajax({
                type: 'POST',
                url: '/event_operator_interactions',
                data: {
                    event_infos: {
                        id: event.id,
                        calendar_login_username: event.calendar_login_username,
                        calendar_id: event.calId
                    },
                    modifications_done: {attributes: {busy: {old_state: oldBusy, new_state: newBusy}}}
                }
            })
        }
        else {
            alert("Error updating event");
            console.log(response);
        }
    }, function(response) {
        alert("Error updating event");
        console.log(response);
    });
};

Calendar.prototype.fullCalendarInit = function() {
    var calendar = this;
    var defaultDate = moment();
    var travelTimeBackgroundColor = '#C27938';
    var travelTimeIsWarningBackgroundColor = '#CA6A65';
    var travelTimeOpacity = '0.80';
    var currentAllDayMasks = [];

    if(calendar.eventsToCheck.length > 0 && calendar.getMode() == "create_event") {
        defaultDate = $.map(calendar.eventsToCheck, function(v, k) {
           return v.start;
        }).sort()[0];
    }

    if(calendar.getMode() == "suggest_dates" && calendar.initialData.constraintsData) {
        var allEvents = [];
        _.each(calendar.initialData.constraintsData, function(dataEntries, attendeeEmail) {
            var mNow = moment();
            var mOneYearFromNow = moment();
            mOneYearFromNow.add('y', 1);
            var events = ConstraintTile.getEventsFromData(dataEntries, mNow, mOneYearFromNow);
            _.each(events.cant, function(event) {
                allEvents.push(event);
            });
        });
        var i=0;
        while(conflictingEvent = _.find(allEvents, function(event) {
            return event.start <= defaultDate && event.end > defaultDate;
        }) && i<100) {
            i += 1;
            defaultDate = conflictingEvent.end;
        }
    }

    //defaultDate = moment("2015-03-01");
    $('#calendar').fullCalendar({
        header: {
            left: 'today prevYear,prev,next,nextYear title',
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
        eventAfterRender: function(event, element, view) {
            var $element = $(element);
            var currentElementTop = $element.position().top;

            if(event.isTravelTime) {
                var travelTimeDiv = $('<div class="travel-time-wrapper ' + event.travelTimeType + '"></div>');
                var travelTimeInnerDiv = $('<div class="travel-time-inner-wrapper"></div>');
                var travelTimeDuration = $('<span class="duration"></span>');
                var travelTimeSprite = $('<span class="sprite"></span>');

                if(event.isWarning) {
                    $element.css('background-color', travelTimeIsWarningBackgroundColor);
                } else {
                    $element.css('background-color', travelTimeBackgroundColor);
                }

                $element.css('opacity', travelTimeOpacity);

                var minutes = event.travelTime % 60;

                if(minutes < 10) {
                    minutes  = '0' + minutes;
                }

                event.formattedTravelTime = Math.floor(event.travelTime / 60) + 'h' + minutes;

                travelTimeDuration.html(event.formattedTravelTime);

                travelTimeInnerDiv.append(travelTimeDuration).append(travelTimeSprite);
                travelTimeDiv.append(travelTimeInnerDiv);

                $element.html(travelTimeDiv);

                //$element.wrap('<a href="' + event.travelTimeGoogleDestinationUrl + '" target="_blank"></a>');



                if(event.eventInfoType == 'before') {
                    travelTimeInnerDiv.css('padding-top', $element.height() - travelTimeInnerDiv.height());
                    $element.css('border-radius', '7px 7px 0px 0px');
                    $element.css('top', currentElementTop + 2);
                } else {
                    $element.css('border-radius', '0px 0px 7px 7px');
                    $element.css('top', currentElementTop - 2);
                }
            }

            if(event.isDefaultDelay) {
                var defaultDelayDiv = $('<div class="default-delay-wrapper"></div>');
                var defaultDelayInnerDiv = $('<div class="default-delay-inner-wrapper"></div>');
                var defaultDelayDuration = $('<span class="duration"></span>');
                var defaultDelaySprite = $('<span class="sprite"></span>');

                var defaultDelay = event.travelTime + 'min. delay';

                $element.css('opacity', travelTimeOpacity);

                defaultDelayDuration.html(defaultDelay);

                defaultDelayDuration.append(defaultDelaySprite);

                defaultDelayInnerDiv.append(defaultDelayDuration);
                defaultDelayDiv.append(defaultDelayInnerDiv);
                $element.html(defaultDelayDiv);

                if(event.isWarning) {
                    $element.css('background-color', travelTimeIsWarningBackgroundColor);
                } else {
                    $element.css('background-color', travelTimeBackgroundColor);
                }

                if(event.eventInfoType == 'before') {
                    $element.css('border-radius', '7px 7px 0px 0px');
                    $element.css('top', currentElementTop + 2);
                } else {
                    $element.css('border-radius', '0px 0px 7px 7px');
                    $element.css('top', currentElementTop - 2);
                }
            }

            if(event.isLocated && event.location) {
                var eventLocation = $('<div class="fc-event-location"></div>');
                var locationText = $('<span class="location"></span>');
                var locationSprite = $('<span class="sprite"></span>');

                locationText.html(event.location);

                eventLocation.append(locationSprite).append(locationText);
                $element.find('.fc-event-inner').append(eventLocation);

            }

            if(event.allDay && (event.calendar_login_type != 'IcloudLogin' || event.calendar_login_type != 'CaldavLogin')) {
                var busyImgClickable = true;

                $element.addClass('event-allday');
                var $imgSpanNode = $('<span class="allday-busy-img"></span>');
                var $allDayMaskNode = $('<div class="allday-mask"></div>');
                var elementOriginalColor = $('.event-allday').css('background-color');

                $element.append($imgSpanNode);

                $allDayMaskNode.width($element.width());
                $allDayMaskNode.css({left: $element.position().left});

                if(event.busyLocked) {
                    event.busy = true;
                    busyImgClickable = false;
                    $imgSpanNode.css('cursor' , 'not-allowed');
                }

                if(event.busy) {
                    $imgSpanNode.addClass('busy');
                    $element.css({'background-color': '#FD9797'});
                    $allDayMaskNode.show();
                } else {
                    $imgSpanNode.addClass('free');
                    $allDayMaskNode.hide();
                }

                currentAllDayMasks.push($allDayMaskNode);

                if(busyImgClickable) {
                    $imgSpanNode.click(function(e) {
                        e.preventDefault();
                        e.stopPropagation();
                        calendar.setBusyStatusOnEvent(event, elementOriginalColor, $element, $imgSpanNode, $allDayMaskNode);
                    });
                }

            }

            if(event.isNotAvailableEvent) {
                $element.addClass('not-available');
            }
        },
        eventAfterAllRender: function(view) {
            calendar.fullCalendarEventAfterAllRender(view);

            var fcEventContainer = $('.fc-event-container').last();
            var calendarHeight = fcEventContainer.parent().height();

            _.each(currentAllDayMasks, function(allDayMaskNode) {
                allDayMaskNode.height(calendarHeight);
                fcEventContainer.append(allDayMaskNode);
            });

            currentAllDayMasks = [];
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

