(function(){

    var app = angular.module('meeting-rooms-manager-controllers', ['templates']);

    app.directive('meetingRoomsManager', function() {
        return {
            restrict: 'E',
            templateUrl: 'meeting-rooms-manager.html',
            controller: ['$scope', '$element' , function($scope, $element){
                $scope.displayForm = false;
                //$scope.displayAttendeesCountSelect = false;
                $scope.displayCustomSelectionFilters = false;
                $scope.roomsList = [];
                $scope.availableRooms = [];
                $scope.selectedRoom = {id: 'auto_room_selection', summary: 'Sélection Auto Par Filtres'};
                $scope.attendeesManagerCtrl = $scope.attendeesManagerCtrl || angular.element($('#attendeesCtrl')).scope();
                $scope.datesVerificationManagerCtrl = $scope.datesVerificationManagerCtrl || angular.element($('#datesVerificationsManager')).scope();
                $scope.selectedAttendeesNb = "2";
                $scope.formDisabled = !window.threadDataIsEditable;

                $scope.unavailableMessageDisplayed = false;

                $scope.computedDataSelectedRoom;

                $scope.overrideAttendeesCount = true;

                $scope.usingMeetingRoom;

                $scope.locationBase = window.threadComputedData.location;

                $scope.utilitiesHelper = $('#events_availabilities_methods').scope();

                var createEventMeetingRoomContainerSelect = $('.create-event-meeting-rooms-container .selection-area');
                var createEventMeetingRoomContainer = $('.create-event-meeting-rooms-container');
                var createEventRoomSelectionSelect = $('.create_event_room_selection_select');
                var locationInputs = $("input#location, input#event_location");

                var meetingRoomsReFr = new RegExp("-" + localize("events.notes.meeting_rooms.boundary", {locale: 'fr'}) + "-------------------.+?(?:----------------------------------------)");
                var meetingRoomsReEn = new RegExp("-" + localize("events.notes.meeting_rooms.boundary", {locale: 'en'}) + "-------------------.+?(?:----------------------------------------)");

                $scope.attendeesManagerCtrl.$on('attendeesRefreshed', function(event, args) {
                    // We only update the attendees count accordindly of adding or deleting them when we havent saved the count yet
                    if($scope.usingMeetingRoom && ( !window.threadComputedData.meeting_room_details || ( window.threadComputedData.meeting_room_details && !window.threadComputedData.meeting_room_details.attendees_count_for_meeting_room ) ) )
                        $scope.updateAttendeesCountSelect(args.attendees.slice());
                });

                if($scope.datesVerificationManagerCtrl) {
                    $scope.datesVerificationManagerCtrl.$on('datesVerifNewSelectedDate', function(event, args) {
                        $scope.checkMeetingRoomAvailability(false, args);
                    });
                }

                //$scope.$watch('selectedRoom', function(newVal, oldVal) {
                //    $scope.displayAttendeesCountSelect = newVal && newVal.id == 'attendees_count';
                //});

                $scope.$watch('selectedRoom', function(newVal, oldVal) {
                    if(newVal) {
                        $scope.displayCustomSelectionFilters = newVal.id == 'auto_room_selection';

                        var currentAppointment = window.getCurrentAppointment();
                        if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
                            updateNotesCallingInfos();
                        }
                    }

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
                        $scope.setAddressValue();
                        createEventMeetingRoomContainerSelect.show();
                    } else {
                        $scope.setAddressValue();
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

                $('#location_nature, #location_nature_event').change(function(e) {
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
                    $scope.setLocationOnEvent();
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
                    var currentAppointment = window.getCurrentAppointment();

                    if(currentAppointment && currentAppointment.meeting_room_used && address && address.meeting_rooms_enabled) {
                        $scope.usingMeetingRoom = true;
                        // $scope.availableRooms = address.available_meeting_rooms;
                        // $scope.setRoomsList();
                        // $scope.setDefaultSelectedRoom();
                        //$scope.setSelectedRoom();
                    } else {
                        $scope.usingMeetingRoom = false;
                    }

                    if(currentAppointment && currentAppointment.meeting_room_used || address && address.meeting_rooms_enabled) {
                        $scope.displayForm = true;
                        $scope.availableRooms = address.available_meeting_rooms;
                        $scope.setRoomsList();
                        $scope.setDefaultSelectedRoom();
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
                    $scope.roomsList = [{id: 'auto_room_selection', summary: 'Sélection Auto Par Filtres'}];

                    _.each($scope.availableRooms, function(meetingRoom) {
                        $scope.roomsList.push({id: meetingRoom.id, summary: meetingRoom.summary, calendar_login_username: meetingRoom.calendar_login_username});
                    });
                };

                $scope.setDefaultSelectedRoom = function() {
                    var currentAddress = window.getCurrentAddressObject();
                    var currentAppointment = window.getCurrentAppointment();

                    $scope.selectedRoom = undefined;

                    if(currentAddress) {

                        $scope.usingMeetingRoom = currentAddress.meeting_rooms_enabled && currentAppointment.meeting_room_used;

                        if($scope.usingMeetingRoom) {
                            var selectedMeetingRoom = currentAppointment.selected_meeting_room;

                            if(selectedMeetingRoom.indexOf('auto_room_selection') > -1) {
                                $scope.setDefaultFilters(selectedMeetingRoom);
                                selectedMeetingRoom = 'auto_room_selection';
                            }

                            $scope.selectedRoom = _.find($scope.roomsList, function(room) {
                                return room.id == selectedMeetingRoom;
                            });
                        }
                    }
                };

                $scope.setDefaultFilters = function(selectedRoomStr) {
                    $scope.useAttendeesCountFilter = selectedRoomStr.indexOf('attendees_count') > -1;
                    $scope.useCanConfCallFilter = selectedRoomStr.indexOf('can_confcall') > -1;
                    $scope.useCanVisioFilter = selectedRoomStr.indexOf('can_visio') > -1;
                };

                $scope.setSelectedRoom = function() {
                    var address = window.getCurrentAddressObject();

                    $scope.displayForm = address && address.meeting_rooms_enabled;
                    $scope.usingMeetingRoom = window.threadComputedData.using_meeting_room;
                    if(!$.isEmptyObject(window.threadComputedData.meeting_room_details)) {

                        if(window.threadComputedData.meeting_room_details.selected_meeting_room.id.indexOf('auto_room_selection') > -1) {
                            $scope.setDefaultFilters(window.threadComputedData.meeting_room_details.selected_meeting_room.id);
                            $scope.selectedRoom = angular.copy(window.threadComputedData.meeting_room_details.selected_meeting_room);
                            $scope.computedDataSelectedRoom = angular.copy(window.threadComputedData.meeting_room_details.selected_meeting_room);

                            $scope.selectedRoom.id = 'auto_room_selection';
                            $scope.computedDataSelectedRoom.id = 'auto_room_selection';
                        } else {
                            $scope.selectedRoom = window.threadComputedData.meeting_room_details.selected_meeting_room;
                            $scope.computedDataSelectedRoom = window.threadComputedData.meeting_room_details.selected_meeting_room;
                        }

                        if(window.threadComputedData.meeting_room_details.attendees_count_for_meeting_room) {
                            //$scope.displayAttendeesCountSelect = true;
                            $scope.selectedAttendeesNb = window.threadComputedData.meeting_room_details.attendees_count_for_meeting_room;
                        }
                    }
                };

                $scope.updateAttendeesCountSelect = function(attendees) {

                    if(attendees){
                        // TODO When in a vitual Appointment, only take into account attendees from the same company than the threadOwner
                        var currentAppointment = window.getCurrentAppointment();
                        var presentAttendeesCount;
                        // When in a virtual appointment, we take into account only the attendees from the same company than the Thread Owner
                        if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
                            if(window.threadAccount.company_hash && window.threadAccount.company_hash.name.length > 0) {
                                var threadOwnerCompany = window.threadAccount.company_hash.name;

                                presentAttendeesCount = _.countBy(attendees, function (a) {
                                    return a.isPresent && a.company == threadOwnerCompany;
                                })[true];
                            } else {
                                // If the threadOwner does not have a company we set the attendees count to 1
                                presentAttendeesCount = 1;
                            }

                        } else {
                            presentAttendeesCount = _.countBy(attendees, function (a) {
                                return a.isPresent;
                            })[true];
                        }

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
                        if(result.selected_meeting_room.id == 'auto_room_selection') {
                            result.selected_meeting_room.id += '|' + $scope.getActiveFilters().join(';');
                            if($scope.useAttendeesCountFilter)
                                $.extend(result, {attendees_count_for_meeting_room: $scope.selectedAttendeesNb});
                        }
                    }

                    return result;
                };

                $scope.getActiveFilters = function() {
                    var activeFilters = [];

                    if($scope.useAttendeesCountFilter) {
                        activeFilters.push('attendees_count');
                    }
                    if($scope.useCanConfCallFilter) {
                        activeFilters.push('can_confcall');
                    }
                    if($scope.useCanVisioFilter) {
                        activeFilters.push('can_visio');
                    }

                    return activeFilters;
                };

                $scope.getMeetingRoomsToDisplay = function() {
                    var result = [];

                    if($scope.computedDataSelectedRoom && $scope.computedDataSelectedRoom.id == 'auto_room_selection') {
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

                        if($scope.applyFilterOnRoom(room, {attendeesCount: attendeesCount})) {
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

                $scope.applyFilterOnRoom = function(room, params) {
                    var toBeFiltered = true;

                    if($scope.useAttendeesCountFilter) {
                        toBeFiltered = toBeFiltered && $scope.attendeesCountFilter(room.capacity, params.attendeesCount);
                    }
                    if($scope.useCanConfCallFilter) {
                        toBeFiltered = toBeFiltered && $scope.canConfCallFilter(room.can_confcall);
                    }
                    if($scope.useCanVisioFilter) {
                        toBeFiltered = toBeFiltered && $scope.canVisioFilter(room.can_visio);
                    }

                    return toBeFiltered;
                };

                $scope.attendeesCountFilter = function(roomCapacity, attendeesCount) {
                    return roomCapacity === undefined || roomCapacity >= attendeesCount;
                };

                $scope.canConfCallFilter = function(roomCanConfCall) {
                    return roomCanConfCall == 'true';
                };

                $scope.canVisioFilter = function(roomCanVisio) {
                    return roomCanVisio == 'true';
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
                    if(window.currentCalendar && !$.isEmptyObject(window.currentCalendar.meetingRoomsEvents) &&
                        (window.julie_action_nature == 'check_availabilities' || window.classification == 'update_event')) {

                        if (window.classification == 'update_event') {
                            var selectedDateStartTime = window.currentEventTile.getEditedEvent().start;
                            var selectedDateEndTime = window.currentEventTile.getEditedEvent().end;
                            var currentEventStartTime = window.currentEventTile.event.start;
                            var currentEventEndTime = window.currentEventTile.event.end;
                            var updateEventClassification = true;
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
                                        var isOverlapping;

                                        // In an update, the current event has been booked, so the related time period will be marked as busy for the selected
                                        // meeting room
                                        // As we don't want to display that the room is not available anymore on this period, we will ignore this particular period when checking for
                                        // the meeting room availability
                                        if(updateEventClassification && window.threadComputedData.meeting_room_details.selected_meeting_room.id == meetingRoom.id) {
                                            if(moment(currentEventStartTime).isSame(currentStartDate) && moment(currentEventEndTime).isSame(currentEndDate)) {
                                                isOverlapping = false;
                                            } else {
                                                isOverlapping = $scope.eventIsOverlapping(selectedDateStartTime, selectedDateEndTime, currentStartDate, currentEndDate);
                                            }
                                        } else {
                                            isOverlapping = $scope.eventIsOverlapping(selectedDateStartTime, selectedDateEndTime, currentStartDate, currentEndDate);
                                        }

                                        return isOverlapping;
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
                    return $scope.utilitiesHelper.eventIsOverlapping(firstEventDateStartTime, firstEventDateEndTime, secondEventDateStartTime, secondEventDateEndTime);
                    //return (
                    //    firstEventDateStartTime.isSame(secondEventDateStartTime) || firstEventDateEndTime.isSame(secondEventDateEndTime) ||
                    //    firstEventDateStartTime.isBetween(secondEventDateStartTime, secondEventDateEndTime, 'minute', '()') ||
                    //    firstEventDateEndTime.isBetween(secondEventDateStartTime, secondEventDateEndTime, 'minute', '()') ||
                    //    secondEventDateStartTime.isBetween(firstEventDateStartTime, firstEventDateEndTime, 'minute', '()') ||
                    //    secondEventDateEndTime.isBetween(firstEventDateStartTime, firstEventDateEndTime, 'minute', '()')
                    //);
                };

                $scope.selectRoom = function(room) {
                    $scope.selectedRoom = _.find($scope.roomsList, function(mR) {
                        return mR.id == room.id;
                    });

                    if($scope.selectedRoom && $scope.selectedRoom.id != "auto_room_selection") {
                        $('.create_event_room_selection_select option[value="' + $scope.selectedRoom.id + '"]').prop('selected', 'selected');
                        $scope.setAddressValue();
                    }
                };

                $scope.setLocationOnEvent = function() {
                    var location = [];
                    if($scope.usingMeetingRoom && $scope.selectedRoom && $scope.selectedRoom.id != 'auto_room_selection') {
                        location.push($scope.selectedRoom.summary);
                    }

                    location.push(window.threadComputedData.location);

                    $('#event_location').val(_.without(location, '').join(', '));
                };

                $scope.setAddressValue = function() {
                    //if(window.threadComputedData.location) {
                    //    window.setAddressFromComputedData();
                    //} else {
                    //    window.setAddressValues();
                    //}
                    //var currentAppointment = window.getCurrentAppointment();
                    //
                    //if($scope.selectedRoom && $scope.selectedRoom.id != "auto_room_selection" && currentAppointment && !currentAppointment.appointment_kind_hash.is_virtual) {
                    //    var newLocationArray = [locationInputs.val()];
                    //
                    //    if($scope.usingMeetingRoom) {
                    //        newLocationArray.unshift($scope.selectedRoom.summary);
                    //    }
                    //
                    //    var newLocation = newLocationArray.join(', ');
                    //    locationInputs.val(newLocation);
                    //    window.threadComputedData.location = newLocation;
                    //}
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
                     if(!$scope.usingMeetingRoom) {
                         return
                    }

                    if($('#event-cancel-button').css('display') == 'block') {

                        var virtualMeetingHelperUsed = $('#event_update_virtual_meetings_helper').length > 0;

                        var currentHeightContainer = '650px';
                        var currentHeightPanel = '635px';

                        if(virtualMeetingHelperUsed) {
                            currentHeightContainer = '810px';
                            currentHeightPanel = '790px';
                        }

                        if($scope.unavailableMessageDisplayed) {
                            currentHeightContainer = '695px';
                            currentHeightPanel = '680px';

                            if(virtualMeetingHelperUsed) {
                                currentHeightContainer = '855px';
                                currentHeightPanel = '840px';
                            }
                        }

                        $('.event-tile-container.editing').css('height', currentHeightContainer);
                        $('.created-event-panel').css('height', currentHeightPanel);
                    }
                };

                $scope.getFreeSlotsByRooms = function(eventsByMeetingRooms) {
                    var result = {};

                    _.each(eventsByMeetingRooms, function(events, room) {
                        var subResult = [];
                        result[room] = [];

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

                            if(nextEvent && !moment(currentEvent.end).isSame(nextEvent.start)) {
                                result[room].push({start: currentEvent.end, end: nextEvent.start});
                            }
                        }
                    });

                    //_.each(result, function(events, room) {
                    //    var currentLength = events.length;
                    //    if(currentLength > 0) {
                    //        events.unshift({start: "1970-01-01T00:00:00+00:00", end: events[0].start});
                    //        // We added a new item in the array with the unshift so we the new last item is one item further than then previous length of the array
                    //        events.push({start: events[currentLength].end, end: "2999-01-01T00:00:00+00:00"});
                    //    }
                    //});

                    return result;
                };

                $scope.getOverlappingEvents = function(eventsByMeetingRooms) {

                    return $('#events_availabilities_methods').scope().getOverlappingEvents(eventsByMeetingRooms, {isMeetingRoom: true});

                    //var isOneRoomEmpty = _.find(eventsByMeetingRooms, function(events, room) {
                    //    return events.length == 0;
                    //});
                    //
                    //var busyResult = [];
                    //
                    //if(!isOneRoomEmpty) {
                    //    var freeSlotsByRooms = $scope.getFreeSlotsByRooms(eventsByMeetingRooms);
                    //    var freeSlotsFlattened = _.flatten(_.map(freeSlotsByRooms), function(events, _) { return events; });
                    //    var sortedFlattened = _.sortBy(freeSlotsFlattened, function(event) {
                    //        return moment(event.start);
                    //    });
                    //
                    //    var freeResult = [];
                    //
                    //    for(var i=0; i<sortedFlattened.length ; i++) {
                    //        var currentEvent = $.extend({}, sortedFlattened[i]);
                    //        var cont = true;
                    //
                    //        while(cont) {
                    //            var nextEvent = sortedFlattened[i + 1];
                    //
                    //            if(nextEvent) {
                    //                if (moment(nextEvent.start).isBefore(currentEvent.end)) {
                    //                    if(moment(nextEvent.end).isAfter(currentEvent.end)) {
                    //                        currentEvent.end = nextEvent.end;
                    //                    }
                    //                    i += 1;
                    //                }
                    //                else {
                    //                    freeResult.push(currentEvent);
                    //                    cont = false;
                    //                }
                    //            }else {
                    //                freeResult.push(currentEvent);
                    //                cont = false;
                    //            }
                    //        }
                    //    }
                    //
                    //    for(var j=0; j<freeResult.length ; j++) {
                    //        currentEvent = freeResult[j];
                    //        nextEvent = freeResult[j + 1];
                    //
                    //        if(nextEvent) {
                    //            busyResult.push({start: currentEvent.end, end: nextEvent.start, isMeetingRoom: true});
                    //        }
                    //    }
                    //}

                    //var busy_times = {};
                    //_.each(allEvents, function(event) {
                    //    if(event.start in busy_times) {
                    //        busy_times[event.start].busy_meeting_rooms_count += 1;
                    //    }
                    //    else {
                    //        busy_times[event.start] = {event: event, busy_meeting_rooms_count: 1}
                    //    }
                    //});
                    //
                    //return _.map(_.filter(busy_times, function(busyTime) {
                    //    return busyTime.busy_meeting_rooms_count == eventsByMeetingRooms.length
                    //}), function(busyTime) {
                    //    return busyTime.event;
                    //});

                    //return busyResult;
                };

                $scope.getOverlappingEventsOld = function(eventsByMeetingRooms) {
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

                $scope.setMeetingRoomInfosInNotes = function() {
                    if($scope.selectedRoom && $scope.selectedRoom.id != 'auto_room_selection' && $scope.selectedRoom.summary && $scope.attendeesManagerCtrl) {
                        var notesNode = $('#notes');
                        var notes = notesNode.val();
                        var meetingRoomInfos = '';

                        meetingRoomInfos += "-" + localize("events.notes.meeting_rooms.boundary", {locale: window.currentLocale}) + "-------------------";
                        meetingRoomInfos += "\n " + localize("events.notes.meeting_rooms.sentence", {locale: window.currentLocale, company_name: $scope.attendeesManagerCtrl.getThreadOwner().company, meeting_room_name: $scope.selectedRoom.summary});
                        meetingRoomInfos += "\n----------------------------------------";

                        var tmpNotes = notes.replace(/\n/g,'');
                        var regexFrResult = meetingRoomsReFr.exec(tmpNotes);
                        var regexEnResult = meetingRoomsReEn.exec(tmpNotes);

                        if(regexFrResult == null && regexEnResult == null){
                            if(notes.replace(/\n/g,'').length > 0)
                                notes += "\n\n";
                            notes += meetingRoomInfos;
                        }else{
                            // Maybe use contactInfosReFr and contactInfosReEn in place of regexFrResult and regexEnResult
                            var usedRegex = regexFrResult != null ? meetingRoomsReFr : meetingRoomsReEn;
                            notes = notes.replace(/\n/g,'__n').replace(usedRegex, meetingRoomInfos).replace(/(__n){2,}/g, '\n\n').replace(/__n/g, "\n");
                        }

                        notesNode.val(notes);
                    }
                };

                $scope.init();
            }],
            controllerAs: 'meetingRoomsCtrl'
        }
    });
})();
