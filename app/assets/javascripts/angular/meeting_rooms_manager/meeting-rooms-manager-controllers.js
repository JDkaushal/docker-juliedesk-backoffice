(function(){

    var app = angular.module('meeting-rooms-manager-controllers', ['templates']);

    app.directive('meetingRoomsManager', function() {
        return {
            restrict: 'E',
            templateUrl: 'meeting-rooms-manager.html',
            controller: ['$scope', '$element' , function($scope, $element){
                $scope.displayForm = true;
                $scope.displayAttendeesCountSelect = false;
                $scope.roomsList = [];
                $scope.availableRooms = [];
                $scope.selectedRoom = {id: 'attendees_count', summary: 'En fonction du nombre de participants'};
                $scope.attendeesManagerCtrl = $scope.attendeesManagerCtrl || angular.element($('#attendeesCtrl')).scope();
                $scope.datesVerificationManagerCtrl = $scope.datesVerificationManagerCtrl || angular.element($('#datesVerificationsManager')).scope();
                $scope.selectedAttendeesNb = "2";
                $scope.formDisabled = !window.threadDataIsEditable;

                $scope.unavailableMessageDisplayed = false;

                $scope.computedDataSelectedRoom;

                $scope.overrideAttendeesCount = true;

                $scope.usingMeetingRoom;

                var createEventMeetingRoomContainerSelect = $('.create-event-meeting-rooms-container .selection-area');
                var createEventMeetingRoomContainer = $('.create-event-meeting-rooms-container');
                var createEventRoomSelectionSelect = $('.create_event_room_selection_select');
                var locationInputs = $("input#location, input#event_location");

                $scope.attendeesManagerCtrl.$on('attendeesRefreshed', function(event, args) {
                    // We only update the attendees count accordindly of adding or deleting them when we havent saved the count yet
                    if($scope.usingMeetingRoom && !window.threadComputedData.meeting_room_details && !window.threadComputedData.meeting_room_details.attendees_count_for_meeting_room)
                        $scope.updateAttendeesCountSelect(args.attendees.slice());
                });

                if($scope.datesVerificationManagerCtrl) {
                    $scope.datesVerificationManagerCtrl.$on('datesVerifNewSelectedDate', function(event, args) {
                        $scope.checkMeetingRoomAvailability(false, args);
                    });
                }

                $scope.$watch('selectedRoom', function(newVal, oldVal) {
                    $scope.displayAttendeesCountSelect = newVal && newVal.id == 'attendees_count';
                });

                $scope.$watch('displayForm', function(newVal, oldVal) {
                    if(newVal) {
                        createEventMeetingRoomContainer.show();
                    } else {
                        createEventMeetingRoomContainer.hide();
                    }
                });

                $scope.$watch('usingMeetingRoom', function(newVal, oldVal) {
                    $('.create-event-meeting-rooms-container input[type="checkbox"]').prop('checked', newVal);
                    if(newVal) {
                        createEventMeetingRoomContainerSelect.show();
                    } else {
                        createEventMeetingRoomContainerSelect.hide();
                    }
                });

                $scope.init = function() {
                    if(!window.formFirstPass || window.julie_action_nature) {
                        $scope.setMeetingRoomManagerDefaultState();
                    }
                };

                $('.event-tile-panel').on('change', 'input.event-dates', function(e) {
                    $scope.checkMeetingRoomAvailability(false);
                });

                $('#location_nature').change(function(e) {
                    $scope.refreshRoomsList();
                    $scope.setAddressValue();
                    $scope.$apply();
                });

                $('#appointment_nature').change(function(e) {
                    $scope.setDefaultSelectedRoom();
                    $scope.$apply();
                });

                $('.create-event-meeting-rooms-container input[type="checkbox"]').change(function(e) {
                    $scope.usingMeetingRoom = $(this).prop('checked');
                    $scope.$apply();
                });

                createEventRoomSelectionSelect.change(function(e) {
                    //$scope.refreshRoomsList();
                    $scope.setNewSelectedRoom($('.create_event_room_selection_select option:selected').val());
                    $scope.$apply();
                    // Allow us to reset the location ( stripping out any eventual meeting room name placed before the
                    // location itself )
                    $scope.setAddressValue();
                });

                $scope.setMeetingRoomManagerDefaultState = function() {
                    $scope.setAvailableRooms();
                    $scope.setSelectedRoom();

                    // We are in a creation event so we have to populate the
                    if(createEventMeetingRoomContainer.length > 0) {
                        createEventMeetingRoomContainer.find('input[type="checkbox"]').prop('checked', $scope.usingMeetingRoom);
                    }
                };

                $scope.populateCreateEventRoomSelect = function() {
                    if(createEventMeetingRoomContainer.length > 0) {
                        createEventRoomSelectionSelect.html('');

                        $scope.availableRooms = [];

                        _.each($('#calendars-list-popup').find('.calendar-item.is-meeting-room input[type="checkbox"]:checked'), function(node) {
                            var containerNode = $(node).closest('.calendar-item');
                            var currentCalendarId = containerNode.data('calendar-id');
                            var currentCalendarSummary = containerNode.data('calendar-summary');
                            var currentRoomCapacity = containerNode.data('room-capacity');

                            if(currentRoomCapacity)
                                currentRoomCapacity = parseInt(currentRoomCapacity);

                            $scope.availableRooms.push({calendar_login_username: containerNode.data('calendar-login-username'), id: currentCalendarId, summary: currentCalendarSummary, capacity: currentRoomCapacity});

                            createEventRoomSelectionSelect.append('<option value="' + currentCalendarId + '">' + currentCalendarSummary + '</option>');
                        });

                        $scope.setRoomsList();

                        if($scope.selectedRoom)
                            $scope.selectRoom($scope.selectedRoom);
                    }
                };

                $scope.setAvailableRooms = function() {
                    var address = window.getCurrentAddressObject();

                    if(address) {
                        $scope.availableRooms = address.available_meeting_rooms;
                    } else {
                        $scope.availableRooms = [];
                    }

                    $scope.setRoomsList();
                };

                $scope.orderAvailableRooms = function() {
                    $scope.availableRooms = _.sortBy($scope.availableRooms, function(room) {
                        return parseInt(room.capacity);
                    });
                };

                $scope.refreshRoomsList = function() {
                    var address = window.getCurrentAddressObject();

                    if(address && address.meeting_rooms_enabled) {
                        $scope.displayForm = true;
                        $scope.usingMeetingRoom = true;
                        $scope.availableRooms = address.available_meeting_rooms;
                        $scope.setRoomsList();
                        $scope.setDefaultSelectedRoom();
                        //$scope.setSelectedRoom();
                    } else {
                        $scope.clear();
                    }
                };

                $scope.clear = function() {
                    $scope.roomsList = [];
                    $scope.availableRooms = [];
                    $scope.selectedRoom = undefined;
                    $scope.displayForm = false;
                    $scope.usingMeetingRoom = false;
                };

                $scope.setRoomsList = function() {
                    $scope.orderAvailableRooms();
                    $scope.roomsList = [{id: 'attendees_count', summary: 'En fonction du nombre de participants'}];

                    _.each($scope.availableRooms, function(meetingRoom) {
                        $scope.roomsList.push({id: meetingRoom.id, summary: meetingRoom.summary, calendar_login_username: meetingRoom.calendar_login_username});
                    });
                };

                $scope.setDefaultSelectedRoom = function() {
                    var currentAddress = window.getCurrentAddressObject();
                    var currentAppointment = window.getCurrentAppointment();

                    $scope.selectedRoom = undefined;

                    if(currentAddress) {

                        $scope.usingMeetingRoom = currentAddress.meeting_rooms_enabled;

                        if($scope.usingMeetingRoom) {
                            $scope.selectedRoom = _.find($scope.roomsList, function(room) {
                                return room.id == currentAppointment.selected_meeting_room;
                            });
                        }
                    }
                };

                $scope.setSelectedRoom = function() {
                    var address = window.getCurrentAddressObject();

                    $scope.displayForm = address && address.meeting_rooms_enabled;
                    $scope.usingMeetingRoom = window.threadComputedData.using_meeting_room;
                    if(window.threadComputedData.meeting_room_details) {
                        $scope.selectedRoom = window.threadComputedData.meeting_room_details.selected_meeting_room;
                        $scope.computedDataSelectedRoom = window.threadComputedData.meeting_room_details.selected_meeting_room;
                        if(window.threadComputedData.meeting_room_details.attendees_count_for_meeting_room) {
                            $scope.displayAttendeesCountSelect = true;
                            $scope.selectedAttendeesNb = window.threadComputedData.meeting_room_details.attendees_count_for_meeting_room;
                        }
                    }
                };

                $scope.updateAttendeesCountSelect = function(attendees) {

                    if(attendees){
                        var presentAttendeesCount = _.countBy(attendees, function (a) {
                            return a.isPresent;
                        })[true];

                        $scope.selectedAttendeesNb = String(presentAttendeesCount);

                        if(!$scope.$$phase)
                            $scope.$apply();
                    }
                };

                $scope.getUsingMeetingRoom = function() {
                    return $scope.usingMeetingRoom;
                };

                $scope.getMeetingRoomDetails = function() {
                    var result = null;

                    if($scope.usingMeetingRoom) {
                        result = {selected_meeting_room: $scope.selectedRoom};
                        if(result.selected_meeting_room.id == 'attendees_count') {
                            $.extend(result, {attendees_count_for_meeting_room: $scope.selectedAttendeesNb})
                        }
                    }

                    return result;
                };

                $scope.getMeetingRoomsToDisplay = function() {
                    var result = [];

                    if($scope.computedDataSelectedRoom && $scope.computedDataSelectedRoom.id == 'attendees_count') {
                        result = $scope.determineFittingMeetingRooms();
                    }else {
                        if($scope.selectedRoom)
                            result.push($scope.selectedRoom);
                    }

                    return result;
                };

                $scope.determineFittingMeetingRooms = function() {
                    var attendeesCount = parseInt($scope.selectedAttendeesNb);
                    var selectedRoomToUnshift = false;

                    // This allow us to reject the current selected Room from the available rooms, in order to put it first
                    // in the array so it will be checked first
                    var selectedRoomId = ($scope.selectedRoom && $scope.selectedRoom.id) || null;

                    var filteredAvailableRooms = _.filter($scope.availableRooms, function(room) {
                        var toFilter = false;

                        if(room.capacity === undefined || room.capacity >= attendeesCount) {
                            if(room.id == selectedRoomId) {
                                selectedRoomToUnshift = true;
                            } else {
                                toFilter = true;
                            }
                        }
                        return toFilter;
                    });

                    if(selectedRoomToUnshift)
                        filteredAvailableRooms.unshift($scope.selectedRoom);

                    return filteredAvailableRooms;
                };

                $scope.setNewSelectedRoom = function(roomId) {
                    $scope.selectedRoom = _.find($scope.availableRooms, function(room) {
                        return room.id == roomId;
                    });

                    $scope.checkMeetingRoomAvailability(true);
                };


                $scope.checkIfDetectAvailabilities = function() {
                        $scope.checkMeetingRoomAvailability();
                    //if(window.classification == 'update_event' && $scope.computedDataSelectedRoom && $scope.computedDataSelectedRoom.id == 'attendees_count') {
                    //    $scope.checkMeetingRoomAvailability();
                    //} else {
                    //    $scope.checkMeetingRoomAvailability(true);
                    //}
                };

                $scope.checkMeetingRoomAvailability = function(checkSelectedRoom, specifiedDate) {
                    if(window.currentCalendar && window.currentCalendar.meetingRoomsEvents &&
                        (window.julie_action_nature == 'check_availabilities' || window.classification == 'update_event')) {

                        if (window.classification == 'update_event') {
                            var selectedDateStartTime = window.currentEventTile.getEditedEvent().start;
                            var selectedDateEndTime = window.currentEventTile.getEditedEvent().end;
                        } else {

                            if(specifiedDate) {
                                var selectedDateStartTime = moment(specifiedDate);
                            }   else if($scope.datesVerificationManagerCtrl.selectedDate) {
                                var selectedDateStartTime = moment($scope.datesVerificationManagerCtrl.selectedDate.date);
                            } else {
                                var selectedDateStartTime = null;
                            }

                            if(selectedDateStartTime)
                                var selectedDateEndTime = selectedDateStartTime.clone().add('m', window.currentCalendar.getCurrentDuration());
                        }

                        var meetingRoomsAvailable = $scope.availableRooms;

                        var available = [];

                        if(selectedDateStartTime) {

                            // TODO: Optimize this algorythm as now we are ordering the rooms by their capacity so
                            // we could stop iterate after the first time we find a room available because it will be
                            // the smallest possible for the current meeting

                            _.each(meetingRoomsAvailable, function (meetingRoom) {
                                var meetingRoomEvents = window.currentCalendar.meetingRoomsEvents[meetingRoom.id];
                                var currentAvailability = {id: meetingRoom.id, isAvailable: true};

                                // We either directly specify the selected date (from the event) or we will fetch it from the datesVerif module

                                if (meetingRoomEvents) {
                                    var eventOnThisSchedule = _.find(meetingRoomEvents, function (event) {
                                        var currentStartDate = moment(event.start);
                                        var currentEndDate = moment(event.end);

                                        return $scope.eventIsOverlapping(selectedDateStartTime, selectedDateEndTime, currentStartDate, currentEndDate);
                                    });

                                    if (eventOnThisSchedule) {
                                        currentAvailability.isAvailable = false;
                                    }
                                }
                                available.push(currentAvailability);
                            });

                            // Whenever we check for the currently selected room availability, we wiil not select automatically
                            // an available room if any (case when we changed the room in the select, this way the operator can
                            // have the current availability state of the selected Room
                            if (checkSelectedRoom) {
                                var selectedRoomAvailability = _.find(available, function(hash) {
                                    return hash.id == $scope.selectedRoom.id;
                                });

                                if(selectedRoomAvailability && selectedRoomAvailability.isAvailable) {
                                    $scope.hideNonAvailableMessage();
                                } else {
                                    $scope.displayNonAvailableMessage('Salle de réunion non disponible');
                                }
                            } else {
                                var firstAvailableRoom = _.find(available, function (hash) {
                                    return hash.isAvailable;
                                });

                                // If there are no first available room, it means every rooms are busy
                                if (firstAvailableRoom) {
                                    $scope.hideNonAvailableMessage();
                                    $scope.selectRoom(firstAvailableRoom);

                                    // To update the form select option if we have triggered this function from the calendar events fetched callback
                                    if(!$scope.$$phase)
                                        $scope.$apply();
                                } else {
                                    // Depending on the number of total rooms, we then display the correct message
                                    if (Object.keys(available).length > 1) {
                                        $scope.displayNonAvailableMessage('Aucune salle de réunion disponible');
                                    } else {
                                        $scope.displayNonAvailableMessage('Salle de réunion non disponible');
                                    }
                                }
                            }
                        }
                    }
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

                $scope.selectRoom = function(room) {
                    $scope.selectedRoom = _.find($scope.roomsList, function(mR) {
                        return mR.id == room.id;
                    });

                    if($scope.selectedRoom && $scope.selectedRoom.id != "attendees_count") {
                        $('.create_event_room_selection_select option[value="' + $scope.selectedRoom.id + '"]').prop('selected', 'selected');
                        $scope.setAddressValue();
                    }
                };

                $scope.setAddressValue = function() {
                    window.setAddressValues();

                    if($scope.selectedRoom) {
                        var newLocation = [$scope.selectedRoom.summary, locationInputs.val()].join(', ');
                        locationInputs.val(newLocation);
                        window.threadComputedData.location = newLocation;
                    }
                };

                $scope.displayNonAvailableMessage = function(msg) {
                    $scope.unavailableMessageDisplayed = true;
                    $('.meeting_room_non_available_msg').html(msg);
                    $('.meeting_room_warning_area').show();

                    $scope.scaleEventTile();
                };

                $scope.hideNonAvailableMessage = function() {
                    $scope.unavailableMessageDisplayed = false;
                    $('.meeting_room_non_available_msg').html('');
                    $('.meeting_room_warning_area').hide();

                    $scope.scaleEventTile();
                };

                $scope.scaleEventTile = function() {
                    if($('#event-cancel-button').css('display') == 'block') {

                        var currentHeightContainer = '650px';
                        var currentWidthPanel = '635px';
                        if($scope.unavailableMessageDisplayed) {
                            currentHeightContainer = '695px';
                            currentWidthPanel = '680px';
                        }

                        $('.event-tile-container.editing').css('height', currentHeightContainer);
                        $('.created-event-panel').css('height', currentWidthPanel);
                    }
                };

                $scope.getOverlappingEvents = function(eventsByMeetingRooms) {
                    eventsByMeetingRooms = _.sortBy(eventsByMeetingRooms, function(val, _) { return val.length ;});

                    var totalEntries = Object.keys(eventsByMeetingRooms).length;
                    var result = [];

                    if(totalEntries == 1) {
                        result = eventsByMeetingRooms[0];
                    } else {
                        _.each(eventsByMeetingRooms[0], function(event) {

                            $scope.exploreNestedEvents(result, 1, totalEntries, eventsByMeetingRooms, [event]);
                        });
                    }

                    return result;
                };

                $scope.exploreNestedEvents = function(result, currentMrIndex, totalEntries, eventsByMeetingRooms, overLappingEvents) {
                    var currentNestedOverLappingEvents = [];

                    _.each(overLappingEvents, function(currentOverLappingEvent) {
                        var cont = true;

                        if(currentMrIndex == totalEntries) {
                            result.push(currentOverLappingEvent);
                        } else {

                            while(cont) {
                                var nestedOverLappingEvents = _.filter(eventsByMeetingRooms[currentMrIndex], function(nestedOverlappingEvent) {
                                    return $scope.eventIsOverlapping(moment(currentOverLappingEvent.start), moment(currentOverLappingEvent.end), moment(nestedOverlappingEvent.start), moment(nestedOverlappingEvent.end));
                                });

                                if(nestedOverLappingEvents.length == 0) {
                                    // No events overlapping, it means the slot is available on at least one room
                                    cont = false;
                                } else {
                                    _.each(nestedOverLappingEvents, function(cEvent) {
                                        // We need to make a copy of the event to prevent altering the start and end dates of
                                        // the original one
                                        var currentNestedOverLappingEvent = $.extend({}, cEvent);
                                        currentNestedOverLappingEvent.start = moment.max(cEvent.start, moment(currentOverLappingEvent.start));
                                        currentNestedOverLappingEvent.end = moment.min(cEvent.end, moment(currentOverLappingEvent.end));
                                        currentNestedOverLappingEvents.push(currentNestedOverLappingEvent);
                                    });

                                    if(currentMrIndex < totalEntries) {
                                        $scope.exploreNestedEvents(result, currentMrIndex + 1, totalEntries, eventsByMeetingRooms, currentNestedOverLappingEvents);
                                        currentMrIndex += 1;
                                    }
                                }

                                if(currentMrIndex >= totalEntries) {
                                    cont = false;
                                }
                            }
                        }

                    });
                };

                $scope.init();
            }],
            controllerAs: 'meetingRoomsCtrl'
        }
    });
})();
