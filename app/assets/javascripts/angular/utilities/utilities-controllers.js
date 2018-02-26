(function(){

    var app = angular.module('utilities-controllers', []);

    app.controller('appointmentsTimesConstraintsHelper', ['$scope', function($scope) {

        $scope.getTimesConstraintsEventsForCurrentAppointment = function(start, end) {
           return window.currentCalendar.computeConstraintsDataEvents($scope.getGroupedTimesConstraintsForCurrentAppointment(), start, end);
        };

        $scope.getGroupedTimesConstraintsForCurrentAppointment = function() {
            return _.groupBy($scope.getTimesConstraintsForCurrentAppointment(), function(data) {
               return data.attendee_email;
            });
        };

        $scope.getTimesConstraintsForCurrentAppointment = function() {
            return $scope.timesConstraintsForAppointmentType(window.threadComputedData.appointment_nature);
        };

        $scope.timesConstraintsForAppointmentType = function(appointmentType) {
            var constraints = [];

            var functionToExecute = $scope[appointmentType + 'Constraints'];

            if(functionToExecute) {
                constraints = functionToExecute();
            } else {
                constraints = $scope.defaultAppointmentsConstraints();
            }

            return _.map(constraints, function(constraint) {
                return $scope.generateConstraintForCurrentClient(constraint);
            });

            //return constraints;
        };

        $scope.breakfastConstraints = function() {
            return [$scope.generateTimeHash('08:00', '09:30')];
        };

        $scope.lunchConstraints = function() {
            var constraints = [];

            if(window.threadAccount.locale == 'fr'){
                constraints = [$scope.generateTimeHash('12:30', '14:00')];
            } else {
                constraints = [$scope.generateTimeHash('12:00', '13:30')];
            }

            return constraints;
        };

        $scope.coffeeConstraints = function() {
            return [$scope.generateTimeHash('09:00', '12:00'), $scope.generateTimeHash('14:00', '18:00')];
        };

        $scope.drinkConstraints = function() {
            return [$scope.generateTimeHash('18:00', '21:00')];
        };

        $scope.dinnerConstraints = function() {
            var constraints = [];

            if(window.threadAccount.locale == 'fr'){
                constraints = [$scope.generateTimeHash('19:30', '21:30')];
            } else {
                constraints = [$scope.generateTimeHash('18:30', '20:30')];
            }

            return constraints;
        };

        $scope.defaultAppointmentsConstraints = function() {
            return [$scope.generateTimeHash('08:00', '12:00'), $scope.generateTimeHash('14:30', '19:30')];
        };



        $scope.generateTimeHash = function(start, end) {
          return {
              startTime: start,
              endTime: end
          };
        };

        $scope.generateConstraintForCurrentClient = function(params) {
            return {
                attendee_email: window.threadAccount.email,
                constraint_nature: 'can',
                constraint_when_nature: 'always',
                days_of_weeks: ["0", "1", "2", "3", "4", "5", "6"],
                start_time: params.startTime,
                end_time: params.endTime,
                timezone: window.threadComputedData.timezone
            }
        };
    }]);

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
                            // We don't add the gap between two events if they are bonded
                            if(!moment(currentEvent.end).isSame(moment(nextEvent.start)))
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

    app.controller('locationsClusterController', ['$scope', function($scope) {
        $scope.currentAddress = window.getCurrentAddress();
        $scope.clusterizedLocations = [];

        $scope.getClusterizedLocations = function() {
            var clusterizedTeamAddressIds = $scope.currentAddress.child_team_addresses_ids;
            $scope.clusterizedLocations = _.filter(window.threadAccount.addresses, function(addr) {
               return clusterizedTeamAddressIds.indexOf(addr.team_address_id) > -1;
            });
        };

        $scope.determineLocation = function() {
            $scope.getClusterizedLocations();
            return $scope.determineFromMeetingRoom() || $scope.determineFromMainClientDefaultLocation() || $scope.determineFromSecondaryClientDefaultLocation() || $scope.fallbackOnLocationsCluster();
        };

        $scope.determineFromMeetingRoom = function() {
            var meetingRoomsManager = $('#meeting-rooms-manager').scope();
            var result = undefined;

            // Only for physical appointments we will check the meeting room
            if(!window.isCurrentAppointmentVirtual() && meetingRoomsManager) {
                var meetingRoomsWidget = _.find(meetingRoomsManager.widgets, function(widget) {
                    return widget.roomLocation.address == $scope.currentAddress.address;
                });

                if(meetingRoomsWidget && meetingRoomsWidget.reservationData && meetingRoomsWidget.reservationData.used) {
                    var selectedRoomId = meetingRoomsWidget.reservationData.selected.id;

                    var firstSuitableLocation = _.find($scope.clusterizedLocations, function(location) {
                        var availableMeetingRoomsIds = _.map(location.available_meeting_rooms, function(room) {
                            return room.id
                        });

                       return availableMeetingRoomsIds.indexOf(selectedRoomId) > -1;
                    });

                    if(firstSuitableLocation) {
                        result = firstSuitableLocation;
                    }
                }
            }

            return result;
        };

        $scope.determineFromMainClientDefaultLocation = function() {
            var result = undefined;
            var mainClientDefaultLocation = window.threadAccount.main_address;

            if($scope.currentAddress.child_team_addresses_ids.indexOf(mainClientDefaultLocation.team_address_id) > -1) {
                result = mainClientDefaultLocation;
            }

            return result;
        };

        $scope.determineFromSecondaryClientDefaultLocation = function() {
            var addressInCluster = undefined;
            var accounts = $('#accounts-list-section').scope().accounts;
            var secondaryClients = _.filter(accounts, function(acc) {
                return acc.email != window.threadAccount.email;
            });

            var secondaryClientsMainAddresses = _.flatten(_.map(secondaryClients, function(client) {
               return client.main_address;
            }));

            addressInCluster = _.find(secondaryClientsMainAddresses, function(addr) {
               return $scope.currentAddress.child_team_addresses_ids.indexOf(addr.team_address_id) > -1
            });

            return addressInCluster;
        };

        $scope.fallbackOnLocationsCluster = function() {
            return $scope.clusterizedLocations[0] || $scope.currentAddress;
        };

    }]);
})();