(function(){

    var app = angular.module('utilities-controllers', []);

    app.controller('eventsAvailabilitiesMethods', ['$scope', function($scope) {

        $scope.getFreeSlotsByRooms = function(groupedEvents) {
            var result = {};

            _.each(groupedEvents, function(events, group) {
                var subResult = [];
                result[group] = [];

                var sortedEvents = _.sortBy(events, function(e) {
                    return e.start;
                });

                for(var i=0; i<sortedEvents.length;i++) {
                    var currentEvent = $.extend({}, sortedEvents[i]);
                    var cont = true;

                    // We continue to iterate on next array elements until we find one which overlap with the current one but end later
                    while(cont) {
                        var nextEvent = sortedEvents[i + 1];

                        if(nextEvent) {
                            if (moment(nextEvent.start).isBefore(currentEvent.end) && moment(nextEvent.end).isAfter(currentEvent.end)) {
                                currentEvent.end = nextEvent.end;
                                i += 1;
                            } else {
                                subResult.push(currentEvent);
                                cont = false;
                            }
                        } else {
                            subResult.push(currentEvent);
                            cont = false;
                        }
                    }
                }

                for(var j = 0; j<subResult.length;j++) {
                    currentEvent = subResult[j];
                    nextEvent = subResult[j+1];

                    // On the first iteration add the first infinite event starting from a very old date
                    if(j == 0) {
                        result[group].push({start: "1970-01-01T00:00:00+00:00", end: currentEvent.start})
                    }

                    if(nextEvent) {
                        if(!moment(currentEvent.end).isSame(nextEvent.start)) {
                            result[group].push({start: currentEvent.end, end: nextEvent.start});
                        }
                    } else {
                        // On the last event, we add the second infinite event starting from the last event end date end ending in the far future
                        result[group].push({start: currentEvent.end, end: "2099-12-31T23:59:59+00:00"})
                    }
                }
            });

            return result;
        };

        $scope.getOverlappingEvents = function(groupedEvents, extraEventsParams) {

            var isOneGroupEmpty = _.find(groupedEvents, function(events,_) {
                return events.length == 0;
            });

            var busyResult = [];

            if(!isOneGroupEmpty) {
                var freeSlotsByGroups = $scope.getFreeSlotsByRooms(groupedEvents);
                var freeSlotsFlattened = _.flatten(_.map(freeSlotsByGroups), function(events,_) { return events; });
                var sortedFlattened = _.sortBy(freeSlotsFlattened, function(event) {
                    return moment(event.start);
                });

                var freeResult = [];

                for(var i=0; i<sortedFlattened.length ; i++) {
                    var currentEvent = $.extend({}, sortedFlattened[i]);
                    var cont = true;

                    while(cont) {
                        var nextEvent = sortedFlattened[i + 1];

                        if(nextEvent) {
                            if (moment(nextEvent.start).isBefore(currentEvent.end)) {
                                if(moment(nextEvent.end).isAfter(currentEvent.end)) {
                                    currentEvent.end = nextEvent.end;
                                }
                                i += 1;
                            }
                            else {
                                freeResult.push(currentEvent);
                                cont = false;
                            }
                        }else {
                            freeResult.push(currentEvent);
                            cont = false;
                        }
                    }
                }

                // We now convert back to the busy events
                if(freeResult.length == 1) {

                } else {

                    for(var j=0; j<freeResult.length ; j++) {
                        currentEvent = freeResult[j];
                        nextEvent = freeResult[j + 1];

                        if(nextEvent) {
                            busyResult.push($.extend({start: currentEvent.end, end: nextEvent.start}, extraEventsParams));
                        }
                    }
                }
            }
            return busyResult;
        };

        $scope.eventIsOverlapping = function(firstEventDateStartTime, firstEventDateEndTime, secondEventDateStartTime, secondEventDateEndTime) {
            return (
                firstEventDateStartTime.isSame(secondEventDateStartTime) || firstEventDateEndTime.isSame(secondEventDateEndTime) ||
                firstEventDateStartTime.isBetween(secondEventDateStartTime, secondEventDateEndTime, 'minute', '()') ||
                firstEventDateEndTime.isBetween(secondEventDateStartTime, secondEventDateEndTime, 'minute', '()') ||
                secondEventDateStartTime.isBetween(firstEventDateStartTime, firstEventDateEndTime, 'minute', '()') ||
                secondEventDateEndTime.isBetween(firstEventDateStartTime, firstEventDateEndTime, 'minute', '()')
            );
        };

    }]);
})();