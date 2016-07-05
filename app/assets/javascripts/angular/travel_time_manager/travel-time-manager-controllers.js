(function(){

    var app = angular.module('travel-time-manager-controllers', ['templates']);

    app.directive('travelTimeTile', function(){
        return {
            restrict: 'E',
            templateUrl: 'travel-time-tile.html',
            controller: ['$scope', '$element', function($scope, $element) {

                $scope.displayTile = false;
                var $backgroundDiv = $('#travel-time-details-container');

                // To close the form when clicking outside the element
                $(document).mouseup(function(e) {
                    var container = $($element[0]);

                    if (!container.is(e.target) // if the target of the click isn't the container...
                        && container.has(e.target).length === 0 && $scope.displayTile) // ... nor a descendant of the container
                    {
                        $scope.close();

                        if(!$scope.$$phase)
                            $scope.$apply();
                    }
                });

                $scope.display = function(travelTimeEvent, currentTarget) {
                    // travelTimeEvent.start is a momentJS object
                    $scope.currentStartDate = travelTimeEvent.travelTimeOriginalStartTime.locale('fr');
                    $scope.currentEndDate = travelTimeEvent.travelTimeOriginalEndTime.locale('fr');

                    if(travelTimeEvent.eventInfoType == 'before') {
                        $scope.currentOrigin = window.threadComputedData.location;
                        $scope.currentDestination = travelTimeEvent.location || 'Non défini';
                    } else {
                        $scope.currentOrigin = travelTimeEvent.location || 'Non défini';
                        $scope.currentDestination = window.threadComputedData.location;
                    }

                    $scope.currentTravelTime = travelTimeEvent.formattedTravelTime;
                    $scope.currentGoogleDirectionUrl = travelTimeEvent.travelTimeGoogleDestinationUrl;
                    $scope.isWarning = travelTimeEvent.travelTimeIsWarning;

                    $scope.placeElement(currentTarget);

                    $backgroundDiv.show();
                    $scope.displayTile = true;
                };

                $scope.close = function() {
                    $backgroundDiv.hide();
                    $scope.displayTile = false;
                    $scope.currentStartDate = undefined;
                    $scope.currentEndDate = undefined;
                    $scope.currentOrigin = undefined;
                    $scope.currentDestination = undefined;
                    $scope.currentTravelTime = undefined;
                    $scope.currentGoogleDirectionUrl = undefined;
                };

                $scope.placeElement = function(currentTarget) {
                    var calendar = window.currentCalendar;
                    var height = currentTarget.offset.top;

                    if(currentTarget.offset().left < calendar.$selector.width() / 2) {
                        $element.css({
                            top: height,
                            left: currentTarget.offset().left + currentTarget.width() + 10,
                            right: "auto",
                            bottom: "auto"
                        });
                    }
                    else {
                        $element.css({
                            top: height,
                            left: currentTarget.offset().left - $element.width() - 10,
                            right: "auto",
                            bottom: "auto"
                        });
                    }
                };

                //$scope.close();
            }],
            controllerAs: 'travelTimeTileCtrl'
        }
    });

    app.controller('travelTimeCalculator', ['$scope', function($scope) {

        var googleMatrixDestinationLimitNumber = 25;
        var googleUsedTravelModeForMax = ['driving', 'transit'];
        // Allow us to prevent having to recalculate this fixed length every time
        var googleUsedTravelModeForMaxCount = 2;

        $scope.events = {};
        $scope.originCoordinates = [];
        $scope.preferedMeanOfTransport = undefined;
        $scope.googleMatrixService = undefined;
        $scope.travelTimeEvents = {};
        $scope.defaultDelayEvents = {};
        $scope.defaultDelayByClient = {};

        // Used when the window.threadAccount.travel_time_transport_mode is set to 'max'.
        // In this mode we take the longest duration between the driving one and the transit one
        // As these requests are asynchronous, we need to store the intermediate values somewhere
        $scope.maxDistanceTmp = {};

        // Handle the multiple asynchronous requests
        $scope.pendingGoogleMatrixCall = {};
        // -----------------------------------------

        $scope.init = function() {
            if(window.threadComputedData.location_coordinates && window.threadComputedData.location_coordinates.length > 0) {
                $scope.originCoordinates = window.threadComputedData.location_coordinates;
            }

            $scope.preferedMeanOfTransport = window.threadAccount.travel_time_transport_mode;

            // Allow to deactivate the google api when testing by setting var window.google = false
            if(google) {
                $scope.googleMatrixService = new google.maps.DistanceMatrixService();
                if($scope.originCoordinates && $scope.originCoordinates.length > 0) {
                    $scope.originCoordinates = new google.maps.LatLng($scope.originCoordinates[0], $scope.originCoordinates[1]);
                }
            }
        };

        $scope.processForClient = function(clientPrefs, events) {
            var email = clientPrefs.email;
            $scope.defaultDelayByClient[email] = clientPrefs.delay_between_appointments;

            $scope.travelTimeEvents[email] = [];
            $scope.defaultDelayEvents[email] = [];

            $scope.setEvents(email, events);

            if(window.threadComputedData.location_coordinates && window.threadComputedData.location_coordinates.length > 0) {
                $scope.selectEventsToCompute(email);
                $scope.calculate(email);
            }

            if($scope.defaultDelayByClient[email] && $scope.defaultDelayByClient[email] > 0) {
                $scope.computeDefaultAppointmentDelay(email);
            }
        };

        $scope.setEvents = function(email, events) {
            // We don't take into account the all day events and the events coming from the meeting rooms
            $scope.events[email] = _.reject(events, function(e) {
                return e.all_day || e.is_meeting_room;
            });
        };

        $scope.sortEventsStartDate = function(events) {
            return _.sortBy(events, function(e) {
                return moment(e.start.date || e.start.dateTime).valueOf();
            });
        };

        //$scope.sortEventsEndDate = function(email) {
        //    return _.sortBy($scope.events[email], function(e) {
        //        return moment(e.end.date || e.end.dateTime).valueOf();
        //    });
        //};

        $scope.selectEventsToCompute = function(email) {

            var startDateSortedEventsAsc = $scope.sortEventsStartDate($scope.events[email]);
            // Make a copy of the array so we can safely reverse it then use both later on
            var startDateSortedEventsDesc = Array.prototype.slice.call(startDateSortedEventsAsc).reverse();

            _.each($scope.events[email], function(e) {
                if(!!e.location) {

                    $scope.detectAvailableEdges(email, e, {
                        startDateSortedEventsDesc: startDateSortedEventsDesc,
                        startDateSortedEventsAsc: startDateSortedEventsAsc
                    });

                    e.calculateTravelTime = !e.lowerEdgeBusy || !e.upperEdgeBusy;
                } else {
                    e.calculateTravelTime = false;
                }
            });
        };

        $scope.detectAvailableEdges = function(email, e, params) {

            var nextEvent, previousEvent;

// Calendar server return the start and end date as {date: XXX} whereas multi_calendar return {dateTime: XXX}

            if(!e.all_day && !e.isNotAvailableEvent) {
                e.start.dateTime = e.start.dateTime || e.start.date;
                e.end.dateTime = e.end.dateTime || e.end.date;
            }

            var currentStartDate = moment(e.start.dateTime);
            var currentEndDate = moment(e.end.dateTime);

            // The lower edge of an event is the start date
            // The upper edge of an event is the end date
            e.lowerEdgeBusy = false;
            e.upperEdgeBusy = false;

            // If the lower Edge is not busy (aka not event overlap on the start date of the current event), it means that we are going to calculate the travel time
            // before this particular event and then display it
            // So we will store the next event
            if(previousEvent = _.find($scope.events[email], function(event) {
                    return e.id != event.id && $scope.lowerEdgeIsBusyCondition(currentStartDate, event);
                })) {
                e.lowerEdgeBusy = true;
            } else {
                if(previousEvent = _.find(params.startDateSortedEventsDesc, function(event) {
                        return currentStartDate.isAfter(event.end.dateTime || event.end.date);
                    })) {
                    e.lowerEdgeMaxTimeDisplay = currentStartDate.diff(previousEvent.end.dateTime || previousEvent.end.date, 'minutes');
                }
            }

            if(nextEvent = _.find($scope.events[email], function(event) {
                    return e.id != event.id && $scope.upperEdgeIsBusyCondition(currentEndDate, event);
                })) {
                e.upperEdgeBusy = true;
            } else {
                if(nextEvent = _.find(params.startDateSortedEventsAsc, function(event) {
                        // Discard events that are all day without being tagged as they are (like public holidays)
                        // To do that we just check if the start property object has a property dateTime
                        // (in the case of all day events like public holidays, the start property object has a 'date' property
                        return currentEndDate.isBefore(event.start.dateTime || event.start.date);
                    })) {
                    e.upperEdgeMaxTimeDisplay = -(currentEndDate.diff(nextEvent.start.dateTime || nextEvent.start.date, 'minutes'));
                }
            }
        };

        $scope.upperEdgeIsBusyCondition = function(currentEndDate, event) {
            var eventStartDate = moment(event.start.dateTime || event.start.date);
            var eventEndDate = moment(event.end.dateTime || event.end.date);

            return currentEndDate.isBetween(eventStartDate, eventEndDate, 'minute', '[)');
        };

        $scope.lowerEdgeIsBusyCondition = function(currentStartDate, event) {
            var eventStartDate = moment(event.start.dateTime || event.end.date);
            var eventEndDate = moment(event.end.dateTime || event.end.date);

            return currentStartDate.isBetween(eventStartDate, eventEndDate, 'minute', '(]');
        };

        $scope.calculate = function(email) {
            var eventsToCompute = _.filter($scope.events[email], function(e) {
               return e.calculateTravelTime;
            });

            // If there are no events to compute ofr the travel time, we still be displayed the appointments default delay
            if(eventsToCompute.length > 0) {
                $scope.computeEvents(email, eventsToCompute);
            } else {
                if($scope.defaultDelayByClient[email] && $scope.defaultDelayByClient[email] > 0) {
                    $scope.travelTimeEvents[email] = [];
                    $scope.computeDefaultAppointmentDelay(email);
                }
            }

        };

        $scope.computeEvents = function(email, events) {
            $scope.maxDistanceTmp[email] = {};
            $scope.pendingGoogleMatrixCall[email] = 0;

            var groupedEvents = $scope.decomposeEventsIntoFittingGroups(events);

            if($scope.preferedMeanOfTransport == 'max') {
                //console.log('MAX of the means of transport');
                _.each(googleUsedTravelModeForMax, function(travelMode) {
                    $scope.simpleGoogleMatrixRequest(email, groupedEvents, travelMode);
                });
            } else {
                $scope.simpleGoogleMatrixRequest(email, groupedEvents, $scope.preferedMeanOfTransport);
            }
        };

        $scope.simpleGoogleMatrixRequest = function(email, groupedEvents, travelMode) {
            $scope.performGoogleRequests(
                email,
                groupedEvents,
                $scope.getGoogleTravelMode(travelMode)
            );
        };

        $scope.getGoogleTravelMode = function(rawTravelMode) {
            var travelMode = google.maps.TravelMode.DRIVING;

            switch(rawTravelMode) {
                case 'driving':
                    travelMode = google.maps.TravelMode.DRIVING;
                    break;
                case 'transit':
                    travelMode = google.maps.TravelMode.TRANSIT;
                    break;
            }

            return travelMode;
        };

        $scope.decomposeEventsIntoFittingGroups = function(events) {
            // Google distance Matrix API specify that you can only submit 25 destinations for each request
            // So we are going to split all our destinations in packages containing maximum 25 items

            return _.chain(events).groupBy(function(element, index){
                        return Math.floor(index/googleMatrixDestinationLimitNumber);
                    }).toArray()
                        .value();
        };

        $scope.performGoogleRequests = function(email, groupedEvents, travelMode) {
            var currentDestinations = [];
            var origin = $scope.originCoordinates;

            _.each(groupedEvents, function(events) {
                currentDestinations = _.map(events, function(e) { return e.location; });
                $scope.makeGoogleMatrixRequest(email, travelMode, [origin], currentDestinations, events);
            });
        };

        $scope.makeGoogleMatrixRequest = function(email, travelMode, origins, destinations, events) {
            if($scope.googleMatrixService) {
                $scope.pendingGoogleMatrixCall[email] += 1;

                //console.log(travelMode);

                $scope.googleMatrixService.getDistanceMatrix(
                    {
                        origins: origins,
                        destinations: destinations,
                        travelMode: travelMode
                    }, function(response, status) {
                        $scope.handleGoogleMatrixResponse(response, status, events, email)
                    });
            }
        };

        $scope.handleGoogleMatrixResponse = function(response, status, events, email) {
            $scope.pendingGoogleMatrixCall[email] -= 1;

            //console.log('Google Matrix Response ' + email, response);

            if (status == google.maps.DistanceMatrixStatus.OK) {
                //var currentDuration;
                var currentIndex = 0;
                var currentEvent, currentEventId, currentDestination;
                var destinations = response.destinationAddresses;

                _.each(response.rows[0].elements, function(element) {
                    //currentDuration = null;
                    currentEvent = events[currentIndex];
                    //currentEventId = currentEvent.id;
                    currentDestination = destinations[currentIndex];

                    $scope.handleResponseElement(email, element, currentEvent, currentDestination);

                    //if(element.status == google.maps.DistanceMatrixStatus.OK) {
                    //    currentDuration = element.duration;
                    //    if(currentDuration) {
                    //        currentDuration = Math.floor(currentDuration.value / 60);
                    //        // Element.duration.value is an integer representing the duration in seconds
                    //        // We divide it by 60 then floor it to obtain an approximated duration in minutes
                    //        $scope.addCurrentDurationToMaxTmp(email, currentEventId, currentDuration);
                    //    }
                    //} else {
                    //    $scope.addCurrentDurationToMaxTmp(email, currentEventId, currentDuration);
                    //}
                    //
                    //$scope.getMaxDurationForEventThenCompute(email, currentEvent, currentDestination);
                    currentIndex += 1;
                });
            }

            //console.log($scope.events);
            //console.log($scope.maxDistanceTmp);
            if($scope.pendingGoogleMatrixCall[email] == 0) {
                $scope.addTravelTimeEventsToCalendar(email);

                if($scope.defaultDelayByClient[email] && $scope.defaultDelayByClient[email] > 0) {
                    $scope.computeDefaultAppointmentDelay(email);
                }
            }
        };

        $scope.handleResponseElement = function(email, element, event, destination) {
            var currentDuration = null;
            var currentEventId = event.id;

            if(element.status == google.maps.DistanceMatrixStatus.OK) {
                currentDuration = element.duration;
                if(currentDuration) {
                    currentDuration = Math.floor(currentDuration.value / 60);
                    // Element.duration.value is an integer representing the duration in seconds
                    // We divide it by 60 then floor it to obtain an approximated duration in minutes
                    $scope.addCurrentDurationToMaxTmp(email, currentEventId, currentDuration);
                }
            } else {
                $scope.addCurrentDurationToMaxTmp(email, currentEventId, currentDuration);
            }

            $scope.getMaxDurationForEventThenCompute(email, event, destination);
        };

        $scope.getMaxDurationForEventThenCompute = function(email, event, destination) {
            var eventId = event.id;
            var maxDistanceData = $scope.maxDistanceTmp[email];

            //console.log(maxDistanceData);

            // In the case where we want the max value for the travel time duration, we  don't do anything until we have all the duration data for this event
            if($scope.preferedMeanOfTransport == 'max') {
                if(!maxDistanceData[eventId]) {
                    //console.log(email, 'here 1');
                    return;
                }
                if(maxDistanceData[eventId].length != googleUsedTravelModeForMaxCount) {
                    //console.log(email, 'here 2');
                    return;
                }
            }

            var max = $scope.getMaxDurationForEvent(email, eventId);

            if(max) {
                $scope.buildInfoEvent(email, 'travelTime', event, max, destination);
                //$scope.computeTravelTimeWithEvent(email, event, max);
            }
        };

        $scope.getMaxDurationForEvent = function(email, eventId) {
            var result = null;

            var maxDetails = _.max($scope.maxDistanceTmp[email][eventId], function(details) {
                return details.duration;
            });

            if(maxDetails)
                result = Math.ceil(maxDetails.duration + (0.25 * maxDetails.duration));

            return result;
        };

        $scope.addCurrentDurationToMaxTmp = function(email, eventId, duration) {
            var details = {duration: duration};

            if($scope.maxDistanceTmp[email][eventId]) {
                $scope.maxDistanceTmp[email][eventId].push(details);
            }else {
                $scope.maxDistanceTmp[email][eventId] = [details];
            }
        };

        //$scope.computeTravelTimeWithEvent = function(email, event, travelTime) {
        //    var foundEvent = _.find($scope.events[email], function(e) {
        //        return e.id == event.id;
        //    });
        //
        //    if(foundEvent){
        //        foundEvent.travel_time = travelTime;
        //    }
        //
        //    $scope.buildInfoEvent(event, travelTime);
        //};

        $scope.buildInfoEvent = function(email, eventType, event, timeDuration, destination) {
            var referenceDate, travelTimeBefore, travelTimeAfter;

            if(!event.lowerEdgeBusy) {
                referenceDate = event.start;
                travelTimeBefore = timeDuration;

                if(travelTimeBefore > event.lowerEdgeMaxTimeDisplay)
                    travelTimeBefore = event.lowerEdgeMaxTimeDisplay;

                $scope.createInfoEvent(email, eventType, 'before', (referenceDate.dateTime || referenceDate.date), timeDuration, travelTimeBefore, destination);
            }

            if(!event.upperEdgeBusy) {
                referenceDate = event.end;
                travelTimeAfter = timeDuration;

                if(travelTimeAfter > event.upperEdgeMaxTimeDisplay)
                    travelTimeAfter = event.upperEdgeMaxTimeDisplay;


                $scope.createInfoEvent(email, eventType, 'after', (referenceDate.dateTime || referenceDate.date), timeDuration, travelTimeAfter, destination);
            }
        };

        $scope.createInfoEvent = function(email, eventType, type, referenceDate, realTravelTime, displayedTravelTime, destination) {
            var infoEvent = {travelTime: realTravelTime};

            var startDate, originalStartDate, endDate, originalEndDate;

            if(type == 'before') {
                startDate = moment(referenceDate).add(-displayedTravelTime, 'm');
                originalStartDate = moment(referenceDate).add(-realTravelTime, 'm');
                endDate = moment(referenceDate);
                originalEndDate = moment(referenceDate);
            }else if(type == 'after') {
                startDate = moment(referenceDate);
                originalStartDate = moment(referenceDate);
                endDate = moment(referenceDate).add(displayedTravelTime, 'm');
                originalEndDate = moment(referenceDate).add(realTravelTime, 'm');
            }

            infoEvent.originalStart = {dateTime: originalStartDate};
            infoEvent.originalEnd = {dateTime: originalEndDate};
            infoEvent.start = {dateTime: startDate};
            infoEvent.end  = {dateTime: endDate};
            infoEvent.eventInfoType = type;
            // We store the destination in the location field so it can be accessed later to be displayed in the travel time tile, opened when clicking a travel time event
            infoEvent.location = destination;
            // In the case where the travel time would overlap the following or predecessing event
            // We compress it to fit and display it in red
            infoEvent.isWarning = displayedTravelTime != realTravelTime;

            if(eventType == 'travelTime') {
                infoEvent.isTravelTime = true;
                infoEvent.travelTimeGoogleDestinationUrl = 'https://www.google.com/maps/dir/' + $scope.originCoordinates.lat() + ',' + $scope.originCoordinates.lng() + '/' + encodeURIComponent(destination);

                $scope.travelTimeEvents[email].push(infoEvent);
            }else if(eventType == 'defaultDelay') {
                infoEvent.isDefaultDelay = true;
                $scope.defaultDelayEvents[email].push(infoEvent);
            }
        };

        $scope.addTravelTimeEventsToCalendar = function(email) {
            if(window.currentCalendar) {
                // The console.log used here strangely allows to fix a display error of the travel time events on the calendar.
                // In the case of multiple clients, the travel time events sometimes does not display correctly (some are missing)
                // Using console.log seems to fix that (maybe it refresh something in background)
                //console.log(email, $scope.travelTimeEvents[email]);
                // The setTimeout heere is used for display purpose, without it when multi clients are present the travel events for each one sometimes does not display properly
                //setTimeout(function() {
                window.currentCalendar.addCal($scope.travelTimeEvents[email]);
                //}, 100);
            }
        };

        $scope.computeDefaultAppointmentDelay = function(email) {
            // We retrieve the events for which we didn't had to calculate the travelTime
            //var events = _.filter($scope.events[email], function(event) { return !event.calculateTravelTime });
            var allEvents = $scope.events[email].concat($scope.travelTimeEvents[email]);
            allEvents = _.compact(allEvents);

            var startDateSortedEventsAsc = $scope.sortEventsStartDate(allEvents);

            var startDateSortedEventsDesc = Array.prototype.slice.call(startDateSortedEventsAsc).reverse();

            var timeDuration = $scope.defaultDelayByClient[email];

            _.each(allEvents, function(e) {

                // We don't compute default appointment delay for holiday + unavailable events + already computed travel times events + events having a travel time
                if(!e.isTravelTime && !e.calculateTravelTime && !e.isNotAvailableEvent && !e.is_meeting_room) {

                    $scope.detectAvailableEdges(email, e, {
                        startDateSortedEventsDesc: startDateSortedEventsDesc,
                        startDateSortedEventsAsc: startDateSortedEventsAsc
                    });

                    e.displayDefaultDelay = !e.lowerEdgeBusy || !e.upperEdgeBusy;

                    if(e.displayDefaultDelay) {
                        $scope.buildInfoEvent(email, 'defaultDelay', e, timeDuration, null);
                    }
                }

            });

            $scope.addDefaultDelayEventsToCalendar(email);
        };

        $scope.addDefaultDelayEventsToCalendar = function(email) {
            if(window.currentCalendar) {
                window.currentCalendar.addCal($scope.defaultDelayEvents[email]);
            }
        };

        $scope.init()
    }]);
})();