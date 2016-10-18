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
        calendar_login_type: params.calendar_login_type,
        calendar_login_email: params.calendar_login_email,
        trackingId: params.trackingId
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
        calendar_login_type: calendar.initialData.default_calendar_login_type,
        calendar_login_email: calendar.initialData.email
    });

    if(calendar.getMode() == "create_event" && calendar.initialData.pickEventCallback) {
        var result = calendar.initialData.pickEventCallback({
            start: moment.tz(eventData.start.format(), calendar.getCalendarTimezone()),
            end: moment.tz(eventData.end.format(), calendar.getCalendarTimezone())
        });
    }
    if(calendar.getMode() == "create_events") {
        if(calendar.initialData.pickEventCallback) {
            calendar.initialData.pickEventCallback({
                start: moment.tz(eventData.start.format(), calendar.getCalendarTimezone()),
                end: moment.tz(eventData.end.format(), calendar.getCalendarTimezone())
            });
        }
    }
    else {
        trackActionV2('Select_availability', {ux_element: 'calendar'});
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

    if(calendar.isCurrentlyLoadingWeek(view.start.clone())) {
        calendar.showLoadingEventsSpinner();
    } else {
        calendar.hideLoadingSpinner();
    }

    var currentBatches = [];
    var daysToFetch = 23;
    var start, end;

    var currentBatchTrackingId = generateTrackingGuid();

    if (typeof calendar.dispStart === "undefined" || typeof calendar.dispEnd === "undefined") {
        calendar.dispStart = view.start.clone();
        calendar.dispEnd = view.end.clone();
        //calendar.dispEnd.add('d', daysToFetch - 7);
        //calendar.dispEnd.add('w', 1);

        currentBatches.push(calendar.dispStart);
        currentBatches.push(calendar.dispStart.clone().add(1, 'w'));
        currentBatches.push(calendar.dispStart.clone().add(2, 'w'));

        //calendar.$selector.find('#calendar').fullCalendar('removeEvents');

        start = calendar.dispStart.format() + "T00:00:00Z";
        end = calendar.dispEnd.format() + "T00:00:00Z";

        //calendar.fetchAllAccountsEvents(start, end);
        var formattedBatchesDates = _.map(currentBatches, function(week) { return week.startOf('isoWeek').format('DD-MM-YYYY') });

        trackActionV2("Calendar_start_loading", {
            batch_type: '3x1',
            weeks: formattedBatchesDates
        });

        _.each(currentBatches, function(batchStartDate) {
            var start = batchStartDate.format() + "T00:00:00Z";
            var end = batchStartDate.clone().add(1, 'w').format() + "T00:00:00Z";

            calendar.fetchAllAccountsEvents(start, end, {trackNetworkResponse: true, formattedBatchesDates: formattedBatchesDates, batchTrackingId: currentBatchTrackingId});
            calendar.addToFetchedWeek(batchStartDate);
        })
    }
    else {
        //if(view.start.isBefore(calendar.dispStart) || view.end.isAfter(calendar.dispEnd)) {

        //if(view.start.isSame(calendar.dispStart) || view.end.isAfter(calendar.dispEnd)) {
        start = view.start.clone();
        var direction = 1;

        if(view.start.isBefore(calendar.dispStart)) {
            direction = -1;
        }

        calendar.dispStart = _.min([calendar.dispStart, view.start.clone()]);
        calendar.dispEnd = _.max([calendar.dispEnd, view.end.clone()]);

        // Voir Retrait des semaines et comparaisons si on est en dehors de la fenetre déjà calculée
        //    if(view.start.isBefore(calendar.dispStart)) {
        //       // end = calendar.dispStart.format() + "T00:00:00Z";
        //        //calendar.dispStart.add('d', 8 - daysToFetch);
        //        //start = calendar.dispStart.format() + "T00:00:00Z";
        //        calendar.dispStart = start.clone();
        //    }
        //    else if(view.start.isSame(calendar.dispEnd) || view.start.isAfter(calendar.dispEnd)){
        //        //start = calendar.dispEnd + "T00:00:00Z";
        //        start = view.start.clone();
        //        calendar.dispEnd = view.end.clone();
        //        //calendar.dispEnd.add('d', daysToFetch);
        //        calendar.dispEnd.add('w', 1);
        //        //end = calendar.dispEnd.format() + "T00:00:00Z";
        //    }

            currentBatches.push(start);
            currentBatches.push(start.clone().add(direction * 1, 'w'));
            currentBatches.push(start.clone().add(direction * 2, 'w'));
            _.each(currentBatches, function(batchStartDate) {
                var start = batchStartDate.format() + "T00:00:00Z";
                var end = batchStartDate.clone().add(1, 'w').format() + "T00:00:00Z";

                if(!calendar.alreadyFetchedWeek(batchStartDate)) {
                    calendar.fetchAllAccountsEvents(start, end, {batchTrackingId: currentBatchTrackingId});
                    calendar.addToFetchedWeek(batchStartDate);
                }
            });
            //calendar.fetchAllAccountsEvents(start, end);
        //}
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
            trackActionV2('Click_on_existing_event', {ux_element: 'calendar'});
            calendar.showEventDetails(event, $(jsEvent.currentTarget));
        }
    }
};

Calendar.prototype.setBusyStatusOnEvent = function(event, $element, $imgSpanNode, $allDayMaskNode) {
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
                $element.css({'background-color': event.color});
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
    var calendarNode = $('#calendar');
    var calendar = this;
    var defaultDate = calendar.determineCalendarInitialStartDate();
    var travelTimeBackgroundColor = '#C27938';
    var travelTimeIsWarningBackgroundColor = '#CA6A65';
    var noMeetingRoomBackgroundColor = '#E37F7F';
    var travelTimeOpacity = '0.80';
    var currentAllDayMasks = [];

    var columnWidth, columnWidthInt, offsetRowInt;

    var suggestionDatesManager = $('#dates-suggestion-manager').scope();

    //defaultDate = moment("2015-03-01");
    calendarNode.fullCalendar({
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

            if(event.isMeetingRoom) {
                var currentPos = $element.position().left;
                //var meetingRoomBusyDiv = $('<div class="meeting-room-busy"><div class="fc-event-title">No meeting Rooms</div></div>');
                $element.addClass('meeting-room-unavailable');
                //$element.append(meetingRoomBusyDiv);
                $element.find('.fc-event-title').html('<span class="sprite"></span><span class="text">no meeting rooms</span>');
                $element.width(columnWidth);

                // Allow to stick the meeting room label on the left of the row
                $element.css('left', (columnWidthInt * parseInt(currentPos / columnWidthInt) + offsetRowInt) + 'px');
            }

            if(event.isVirtualResource) {
                var currentPos = $element.position().left;
                //var meetingRoomBusyDiv = $('<div class="meeting-room-busy"><div class="fc-event-title">No meeting Rooms</div></div>');
                $element.addClass('meeting-room-unavailable');
                //$element.append(meetingRoomBusyDiv);
                $element.find('.fc-event-title').html('<span class="sprite"></span><span class="text">no Resource ' + event.virtualResourceType + '</span>');
                $element.width(columnWidth);

                // Allow to stick the meeting room label on the left of the row
                $element.css('left', (columnWidthInt * parseInt(currentPos / columnWidthInt) + offsetRowInt) + 'px');
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
                        calendar.setBusyStatusOnEvent(event, $element, $imgSpanNode, $allDayMaskNode);
                    });
                }

            }

            if(event.isNotAvailableEvent) {
                $element.addClass('not-available');
            }

            if(event.isSuggestionFromAi) {
                $element.addClass('suggestion-from-ai');
                var $callToActionsWrapper = $('<div class="call-to-actions-wrapper"></div>');
                var $acceptSprite = $('<span class="call-to-action accept"></span>');
                var $rejectSprite = $('<span class="call-to-action reject"></span>');

                $callToActionsWrapper.append($acceptSprite).append($rejectSprite);

                $element.find('.fc-event-inner').append($callToActionsWrapper);

                $acceptSprite.click(function(e) {
                    e.preventDefault();
                    e.stopPropagation();

                    suggestionDatesManager.acceptAiSuggestion(event.start);
                });

                $rejectSprite.click(function(e) {
                    e.preventDefault();
                    e.stopPropagation();

                    suggestionDatesManager.rejectAiSuggestion(event.start);
                });
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
        viewRender: function(view, element){
            columnWidth = $('.fc-col3.fc-widget-header').css('width');
            columnWidthInt = parseInt(columnWidth);
            offsetRowInt = parseInt($('.fc-agenda-axis').css('width'));
            calendar.fullCalendarViewRender(view, element);
        },
        eventClick: function(event, jsEvent, view) {
            calendar.fullCalendarEventClick(event, jsEvent, view);
            return false;
        }
    });

    calendarNode.on('click', '.fc-button-prev', function(e) {
        trackActionV2('Click_on_change_week', {type: 'previous', value: -1, ux_element: 'backoffice'});
    });

    calendarNode.on('click', '.fc-button-next', function(e) {
        trackActionV2('Click_on_change_week', {type: 'next', value: 1, ux_element: 'backoffice'});
    });

    $('.fc-button-next').after($('<input id="calendar_datepicker" type="text"/>').hide());
    $('.fc-header-title').prepend($('<span class="calendar-datepicker-sprite"></span>'));

    calendarNode.on('click', '.fc-header-title', function(e) {
        $('#calendar_datepicker').datepicker('show');
    });

    $('#calendar_datepicker').datepicker({
        dateFormat: "dd-mm-yy",
        minDate: new Date,
        onSelect: function(dateText, inst){
            var momentedDate = moment(dateText, 'DD-MM-YYYY');
            var selectedWeek = momentedDate.clone().startOf('isoWeek');
            var currentWeek = window.currentCalendar.$selector.find('#calendar').fullCalendar('getView').start;
            var duration = moment.duration(selectedWeek.diff(currentWeek));
            trackActionV2('Click_on_change_week', {type: 'date_picker', value: Math.round(duration.asWeeks()), ux_element: 'backoffice'});

            window.currentCalendar.goToDateAndLoadEvents(momentedDate);
        }
    });

    //calendarNode.on('click', '.fc-button-prevYear, .fc-button-nextYear', function(e) {
    //    console.log('month btn click');
    //    trackActionV2('Click_on_change_month', {ux_element: 'backoffice'});
    //});

};

