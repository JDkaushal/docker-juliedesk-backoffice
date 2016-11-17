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
        var eventsToIgnore = ['is_meeting_room', 'is_virtual_resource', 'isNotAvailableEvent'];
        // Allow us to prevent having to recalculate this fixed length every time
        var googleUsedTravelModeForMaxCount = 2;

        $scope.events = {};
        $scope.eventsToCompute = {};
        $scope.eventsWithDefaultCommutingTime = {};
        $scope.eventsWithDefaultTime = {};

        // Used to store the events we will not process ofr time related infos
        // we will only use them to find if they overlapp with the processed ones
        $scope.otherEvents = {};

        $scope.originCoordinates = [];
        $scope.preferedMeanOfTransport = undefined;
        $scope.googleMatrixService = undefined;
        $scope.travelTimeEvents = {};
        $scope.defaultDelayEvents = {};
        $scope.defaultDelayByClient = {};
        $scope.defaultCommutingTimeByClient = {};

        // Used when the window.threadAccount.travel_time_transport_mode is set to 'max'.
        // In this mode we take the longest duration between the driving one and the transit one
        // As these requests are asynchronous, we need to store the intermediate values somewhere
        $scope.maxDistanceTmp = {};

        // Handle the multiple asynchronous requests
        $scope.pendingGoogleMatrixCall = {};
        // -----------------------------------------
        $scope.schedulingEventProperties = {};
        $scope.referenceLocation = {};

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

            $scope.getSchedulingEvent();
        };
        
        $scope.getMainClientMainAddress = function() {
          return $scope.schedulingEventProperties.clientsMainAddresses[window.threadAccount.email].address;
        };

        $scope.schedulingEventLocationMatrix = function(email) {
            return {
                virtual: function() {
                    return $scope.schedulingEventProperties.aiMetadata.sanitized_location || $scope.schedulingEventProperties.location || $scope.schedulingEventProperties.clientsMainAddresses[email].address;
                },
                external: function() {
                    return $scope.schedulingEventProperties.aiMetadata.sanitized_location || $scope.schedulingEventProperties.location || null;
                },
                meeting: function() {
                    return $scope.schedulingEventProperties.aiMetadata.sanitized_location || $scope.schedulingEventProperties.location || $scope.schedulingEventProperties.clientsMainAddresses[email].address;
                }
            };
        };

        $scope.calendarEventLocationMatrix = function(event, mainClientMainAddress) {
            return {
                virtual: function() {
                    return mainClientMainAddress;
                },
                internal: function() {
                    return event.ai_metadata.sanitized_location || mainClientMainAddress;
                },
                external: function() {
                    return event.ai_metadata.sanitized_location || null;
                },
                reminder: function() {
                    return event.ai_metadata.sanitized_location || mainClientMainAddress;
                },
                other: function() {
                    return event.ai_metadata.sanitized_location || null;
                }
            }
        };

        $scope.computeSchedulingEventClientsMainAddresses = function() {
            var allClients = window.currentCalendar.accountPreferences;
            var clientsMainAddresses = {};

            _.each(allClients, function(prefs) {
               clientsMainAddresses[prefs.email] = _.find(prefs.addresses, function(address) {
                   return address.is_main_address;
               })
            });
            $scope.schedulingEventProperties.clientsMainAddresses = clientsMainAddresses;
        };

        $scope.computeCalendarEventLocation = function(event, mainClientMainAddress) {
            // For events coming from the calendar server, the metadata property is called ai_metadata with an underscore
            // If no event type is found returned by the AI, we will consider it as an external event
            var eventType = event.ai_metadata.event_type || 'external';

            var locationMethod = $scope.calendarEventLocationMatrix(event, mainClientMainAddress)[eventType];
            var result = null;
            if(locationMethod) {
                result = locationMethod();
            }
            return  result;
        };

        $scope.computeSchedulingEventLocationForClient = function(email) {
          return  $scope.schedulingEventLocationMatrix(email)[$scope.schedulingEventProperties.event_type]();
        };

        $scope.getSchedulingEvent = function() {
            $scope.schedulingEventProperties.aiMetadata = {};
            $scope.schedulingEventProperties.location = window.threadComputedData.location;
            
            $scope.computeSchedulingEventType();
            $scope.fetchSchedulingEventMetadata();
        };
        
        // We are using less detailled status than those returned by the AI when classifying the scheduling event
        $scope.computeSchedulingEventType = function() {
            if(window.threadComputedData.appointment_nature == 'meeting') {
                $scope.schedulingEventProperties.event_type = 'meeting';
            } else if(window.threadComputedData.is_virtual_appointment) {
                $scope.schedulingEventProperties.event_type = 'virtual';
            } else {
                $scope.schedulingEventProperties.event_type = 'external';
            }
        };

        $scope.fetchSchedulingEventMetadata = function() {
            var aiEventsMetadataManager = $('#ai_events_metadata_manager').scope();

            if(aiEventsMetadataManager) {
                aiEventsMetadataManager.fetchSchedulingEventMetadata().then(function(response) {
                    $scope.schedulingEventProperties.aiMetadata = response.scheduling_event;
                })
            }
        };

        $scope.resetForClient = function(email) {
            $scope.travelTimeEvents[email] = [];
            $scope.defaultDelayEvents[email] = [];
            $scope.eventsToCompute[email] = [];
            $scope.eventsWithDefaultTime[email] = [];
            $scope.eventsWithDefaultCommutingTime[email] = [];
            $scope.otherEvents[email] = [];
            $scope.events[email] = [];
        };

        $scope.computeReferenceLocationForClient = function(email) {
            $scope.referenceLocation[email] = $scope.computeSchedulingEventLocationForClient(email);
        };

        $scope.processForClient = function(clientPrefs, events) {
            var email = clientPrefs.email;

            $scope.defaultDelayByClient[email] = clientPrefs.delay_between_appointments;
            $scope.defaultCommutingTimeByClient[email] = clientPrefs.default_commuting_time;

            $scope.resetForClient(email);
            $scope.setEvents(email, events);

            $scope.selectEventsToCompute(email);
            $scope.computeReferenceLocationForClient(email);

            if(window.threadComputedData.location_coordinates && window.threadComputedData.location_coordinates.length > 0 && $scope.eventsToCompute[email].length > 0) {
                $scope.calculate(email);
            } else {
                // This method is called by subfunctions of 'calculate' at the end of the process to display default time
                // to events for which Google could not calculate a travel time

                // We call it here when we don't calculate travel time (because no location has been set in the thread form or it is invalid)
                $scope.computeDefaultCommutingTime(email);
                $scope.addTravelTimeEventsToCalendar(email);
            }
        };

        $scope.setEvents = function(email, events) {
            // We don't take into account for travel time (and default time):
            //  - All day events
            $scope.events[email] = _.reject(events, function(e) {
                return e.all_day || e.isNotAvailableEvent;
            });
        };

        $scope.shouldComputeEvent = function(e) {
            var ignore = false;

            _.each(eventsToIgnore, function(toIgnoreAttr) {
                if(e[toIgnoreAttr]) {
                    ignore = true;
                }
            });

            return !ignore;
        };

        $scope.selectEventsToCompute = function(email) {
            // If originCoordinates is an array, check that is is not empty, if it is an object (instance of google LatLng class) check that property lat() is not undefined
            // this means that the object is correct
            var canComputeTravelTime = ($scope.originCoordinates && $scope.originCoordinates.length > 0 || (typeof($scope.originCoordinates) == 'object' && $scope.originCoordinates.lat && $scope.originCoordinates.lat()));
            var startDateSortedEventsAsc = $scope.sortEventsStartDate($scope.events[email]);
            // Make a copy of the array so we can safely reverse it then use both later on
            var startDateSortedEventsDesc = Array.prototype.slice.call(startDateSortedEventsAsc).reverse();

            var mainClientMainAddress = $scope.getMainClientMainAddress();

            _.each($scope.events[email], function(e) {
                if($scope.shouldComputeEvent(e)) {
                    e.toProcess = true;

                    $scope.detectAvailableEdges(email, e, {
                        startDateSortedEventsDesc: startDateSortedEventsDesc,
                        startDateSortedEventsAsc: startDateSortedEventsAsc
                    });

                    var shouldComputeTime = !e.lowerEdgeBusy || !e.upperEdgeBusy;
                    e.location = $scope.computeCalendarEventLocation(e, mainClientMainAddress);

                    if(e.ai_metadata.event_type == 'virtual' && $scope.schedulingEventProperties.event_type == 'virtual') {
                        e.calculateTravelTime = true;
                        e.forceTravelTimeDurationValue = 0;
                    } else {
                        if(canComputeTravelTime && e.location) {
                            e.calculateTravelTime = shouldComputeTime;
                        } else {
                            e.displayDefaultTime = shouldComputeTime;
                        }
                    }
                }
            });


            $scope.eventsToCompute[email] = _.filter($scope.events[email], function(e) {
                return e.toProcess && e.calculateTravelTime;
            });

            $scope.eventsWithDefaultCommutingTime[email] = _.filter($scope.events[email], function(e) {
                return e.toProcess && e.displayDefaultTime;
            });

            // $scope.eventsWithDefaultTime[email] = _.filter($scope.events[email], function(e) {
            //     return e.toProcess && e.displayDefaultTime;
            // });
        };

        $scope.sortEventsStartDate = function(events) {
            return _.sortBy(events, function(e) {
                return moment(e.start.date || e.start.dateTime).valueOf();
            });
        };

        $scope.calculate = function(email) {
            var eventsToCompute = angular.copy($scope.eventsToCompute[email]);

            $scope.computeEvents(email, eventsToCompute);
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

            if (status == google.maps.DistanceMatrixStatus.OK) {
                var currentIndex = 0;
                var currentEvent, currentDestination;
                var destinations = response.destinationAddresses;

                _.each(response.rows[0].elements, function(element) {
                    currentEvent = events[currentIndex];
                    currentDestination = destinations[currentIndex];

                    $scope.handleResponseElement(email, element, currentEvent, currentDestination);
                    currentIndex += 1;
                });
            }

            if($scope.pendingGoogleMatrixCall[email] == 0) {
                // We display all the computed events on the calendar after having finished every process
                // It includes:
                //  - Travel time events
                //  - Default Time events (for when Google could not calculate a proper travel time
                $scope.computeDefaultCommutingTime(email);
                $scope.addTravelTimeEventsToCalendar(email);
                $scope.addDefaultDelayEventsToCalendar(email);
            }
        };

        $scope.handleResponseElement = function(email, element, event, destination) {
            var currentDuration = null;
            var currentEventId = event.id;

            if(element.status == google.maps.DistanceMatrixStatus.OK) {
                currentDuration = element.duration;
                if(currentDuration) {
                    currentDuration = Math.floor(currentDuration.value / 60);

                    if(currentDuration > 180) {
                        currentDuration = $scope.defaultCommutingTimeByClient[email];
                    }
                    
                    if(event.forceTravelTimeDurationValue) {
                        currentDuration = event.forceTravelTimeDurationValue;
                    }
                    // Element.duration.value is an integer representing the duration in seconds
                    // We divide it by 60 then floor it to obtain an approximated duration in minutes
                    $scope.addCurrentDurationToMaxTmp(email, currentEventId, currentDuration);
                }
            } else {
                $scope.addCurrentDurationToMaxTmp(email, currentEventId, $scope.defaultCommutingTimeByClient[email]);
            }

            $scope.getMaxDurationForEventThenCompute(email, event, destination);
        };

        $scope.getMaxDurationForEventThenCompute = function(email, event, destination) {
            var eventId = event.id;
            var maxDistanceData = $scope.maxDistanceTmp[email];

            // In the case where we want the max value for the travel time duration, we  don't do anything until we have all the duration data for this event
            if($scope.preferedMeanOfTransport == 'max') {
                if(!maxDistanceData[eventId]) {
                    return;
                }
                if(maxDistanceData[eventId].length != googleUsedTravelModeForMaxCount) {
                    return;
                }
            }

            var max = $scope.getMaxDurationForEvent(email, eventId);

            if(max) {
                $scope.buildInfoEvent(email, 'travelTime', event, max, destination);
            } else {
                // We will display the default appointment time for this event instead of the travel time
                //$scope.eventsWithDefaultCommutingTime[email].push(event);
                $scope.eventsWithDefaultTime[email].push(event);
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

        // Modified it beyond initial expectations, should probably refactor it by splitting logic into separate functions for each event types (travelTime and defaultDelay)
        $scope.buildInfoEvent = function(email, eventType, event, timeDuration, destination) {
            var referenceDate, travelTimeBefore, travelTimeAfter, remainingTime, newRefDate, displayedTime;

            var usedEventType = eventType;
            var usedTravelTimeAfter;

            if(!event.lowerEdgeBusy) {
                referenceDate = (event.start.dateTime || event.start.date);
                travelTimeBefore = timeDuration;

                if(travelTimeBefore > event.lowerEdgeMaxTimeDisplay) {
                    travelTimeBefore = event.lowerEdgeMaxTimeDisplay;
                } else {
                    if(eventType == 'travelTime') {
                        remainingTime = event.lowerEdgeMaxTimeDisplay - travelTimeBefore;
                        newRefDate = moment(referenceDate).clone().add(-travelTimeBefore, 'm');
                        displayedTime = $scope.defaultDelayByClient[email] > remainingTime ? remainingTime : $scope.defaultDelayByClient[email];
                        $scope.createInfoEvent(email, 'defaultDelay', 'before', newRefDate, $scope.defaultDelayByClient[email], displayedTime, destination);
                    }
                }

                $scope.createInfoEvent(email, usedEventType, 'before', referenceDate, timeDuration, travelTimeBefore, destination);
            }

            if(!event.upperEdgeBusy) {
                referenceDate = (event.end.dateTime || event.end.date);
                travelTimeAfter = timeDuration;
                usedTravelTimeAfter = travelTimeAfter;

                if(eventType == 'travelTime') {
                    travelTimeAfter = $scope.defaultDelayByClient[email];
                    timeDuration = travelTimeAfter;
                    usedEventType = 'defaultDelay';
                }

                if(travelTimeAfter > event.upperEdgeMaxTimeDisplay) {
                    travelTimeAfter = event.upperEdgeMaxTimeDisplay;
                } else {
                    if(eventType == 'travelTime') {
                        remainingTime = event.upperEdgeMaxTimeDisplay - travelTimeAfter;
                        newRefDate = moment(referenceDate).clone().add(travelTimeAfter, 'm');
                        displayedTime = usedTravelTimeAfter > remainingTime ? remainingTime : usedTravelTimeAfter;
                        $scope.createInfoEvent(email, 'travelTime', 'after', newRefDate, usedTravelTimeAfter, displayedTime, destination);
                    }
                }

                $scope.createInfoEvent(email, usedEventType, 'after', referenceDate, timeDuration, travelTimeAfter, destination);
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

        $scope.computeDefaultCommutingTime = function(email) {
            if(($scope.defaultCommutingTimeByClient[email] || 0) <= 0 || $scope.defaultCommutingTimeByClient[email].length == 0) {
                return;
            }

            var allEvents = angular.copy($scope.eventsWithDefaultCommutingTime[email]);
            var timeDuration = $scope.defaultCommutingTimeByClient[email];

            _.each(allEvents, function(e) {
                $scope.buildInfoEvent(email, 'travelTime', e, timeDuration, null);
            });
        };

        $scope.computeDefaultAppointmentDelay = function(email) {
            if(($scope.defaultDelayByClient[email] || 0) <= 0 || $scope.eventsWithDefaultTime[email].length == 0) {
                return;
            }

            var allEvents = angular.copy($scope.eventsWithDefaultTime[email]);

            var timeDuration = $scope.defaultDelayByClient[email];

            _.each(allEvents, function(e) {
                $scope.buildInfoEvent(email, 'defaultDelay', e, timeDuration, null);
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