(function(){

    var app = angular.module('meeting-rooms-manager-controllers', ['templates']);

    app.directive('meetingRoomsManager', function() {
        return {
            restrict: 'E',
            templateUrl: 'meeting-rooms-manager.html',
            controller: ['$scope', '$element' , function($scope, $element){

                var autoRoomMode = {id: 'auto_room_selection', summary: 'Sélection Auto Par Filtres'};
                var autoRoomModeWithFilters = {id: 'auto_room_selection|attendees_count', summary: 'Sélection Auto Par Filtres'};

                $scope.displayForm = false;
                //$scope.displayAttendeesCountSelect = false;
                $scope.displayCustomSelectionFilters = false;
                $scope.roomsList = [];
                $scope.availableRooms = [];
                $scope.roomsSelectionMode = autoRoomMode;
                $scope.selectedRoom = undefined;
                $scope.attendeesManagerCtrl = $scope.attendeesManagerCtrl || angular.element($('#attendeesCtrl')).scope();
                $scope.datesVerificationManagerCtrl = $scope.datesVerificationManagerCtrl || angular.element($('#datesVerificationsManager')).scope();
                $scope.selectedAttendeesNb = "2";
                $scope.formDisabled = !window.threadDataIsEditable;

                $scope.noFittingRooms = false;

                $scope.unavailableMessageDisplayed = false;

                $scope.computedDataSelectedRoom;
                $scope.computedDataRoomsSelectionMode;

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

                $scope.$watch('selectedRoom', function(newVal, oldVal) {
                    var currentAppointment = window.getCurrentAppointment();
                    if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
                        updateNotesCallingInfos();
                    }
                });

                $scope.$watch('roomsSelectionMode', function(newVal, oldVal) {
                    $scope.displayCustomSelectionFilters = newVal.id == 'auto_room_selection';
                    newVal = newVal || {};
                    oldVal = oldVal || {};

                    if(newVal && newVal.id != oldVal.id  && !window.julie_action_nature) {
                        if(newVal.id == 'auto_room_selection') {
                            $scope.selectedRoom = undefined;
                        } else {
                            $scope.selectedRoom = angular.copy(newVal);
                        }
                    }
                });

                $scope.$watchGroup(['useAttendeesCountFilter', 'useCanConfCallFilter', 'useCanVisioFilter'], function(newValues, oldValues, scope) {
                    $scope.determineFittingMeetingRooms();
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

                $('#location_nature, #location_nature_event').change(function(e) {
                    $scope.refreshRoomsList();
                    $scope.determineFittingMeetingRooms();
                    $scope.$apply();
                });

                $('#appointment_nature').change(function(e) {
                    $scope.setDefaultSelectedRoom();
                    $scope.determineFittingMeetingRooms();
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
                        createEventRoomSelectionSelect.append('<option value="no_room_selected">No room selected</option>');

                        $scope.availableRooms = [];

                        _.each($('#calendars-list-popup').find('.calendar-item.is-meeting-room input[type="checkbox"]:checked'), function(node) {
                            var containerNode = $(node).closest('.calendar-item');
                            var currentCalendarId = containerNode.data('calendar-id');
                            var currentCalendarSummary = containerNode.data('calendar-summary');
                            var currentRoomCapacity = containerNode.data('room-capacity');
                            var currentCanVisio = containerNode.data('room-can-visio');
                            var currentCanConfcall = containerNode.data('room-can-confcall');

                            if(currentRoomCapacity)
                                currentRoomCapacity = parseInt(currentRoomCapacity);

                            $scope.availableRooms.push({calendar_login_username: containerNode.data('calendar-login-username'), id: currentCalendarId, summary: currentCalendarSummary, capacity: currentRoomCapacity, can_visio: currentCanVisio, can_confcall: currentCanConfcall});

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
                    $scope.roomsList = [autoRoomMode];

                    _.each($scope.availableRooms, function(meetingRoom) {
                        // Fix when some capacity are equal to '', should not happen anymore, was a bug from the admin panel on the user edit page where the capacity was set to null instead of undefined
                        meetingRoom.capacity = meetingRoom.capacity || undefined;
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
                            var appointmentSelectedMeetingRoom = currentAppointment.selected_meeting_room;
                            var selectedMeetingRoom = undefined;

                            if(appointmentSelectedMeetingRoom.indexOf('auto_room_selection') > -1) {
                                $scope.setDefaultFilters(appointmentSelectedMeetingRoom);
                            } else {
                                selectedMeetingRoom = appointmentSelectedMeetingRoom;
                            }

                            if(selectedMeetingRoom) {
                                $scope.selectedRoom = _.find($scope.roomsList, function(room) {
                                    return room.id == selectedMeetingRoom;
                                });
                            }
                        }
                    } else {
                        $scope.usingMeetingRoom = false;
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
                        var threadDataRoomsDetails = angular.copy(window.threadComputedData.meeting_room_details);

                        // Backward compatibility
                        if($.isEmptyObject(threadDataRoomsDetails.room_selection_mode)) {
                            threadDataRoomsDetails.room_selection_mode = autoRoomModeWithFilters;
                        }

                        if(threadDataRoomsDetails.room_selection_mode.id.indexOf('auto_room_selection') > -1) {
                            $scope.setDefaultFilters(threadDataRoomsDetails.room_selection_mode.id);
                            $scope.selectedRoom = angular.copy(threadDataRoomsDetails.selected_meeting_room);
                            $scope.computedDataSelectedRoom = angular.copy(threadDataRoomsDetails.selected_meeting_room);

                            $scope.roomsSelectionMode = angular.copy(threadDataRoomsDetails.room_selection_mode);
                            $scope.computedDataRoomsSelectionMode = angular.copy(threadDataRoomsDetails.room_selection_mode);

                            $scope.roomsSelectionMode.id = 'auto_room_selection';
                            $scope.computedDataRoomsSelectionMode.id = 'auto_room_selection';
                        } else {
                            $scope.selectedRoom = angular.copy(threadDataRoomsDetails.selected_meeting_room);
                            $scope.computedDataSelectedRoom = angular.copy(threadDataRoomsDetails.selected_meeting_room);

                            $scope.roomsSelectionMode = angular.copy(threadDataRoomsDetails.room_selection_mode);
                            $scope.computedDataRoomsSelectionMode = angular.copy(threadDataRoomsDetails.room_selection_mode);
                        }

                        if(threadDataRoomsDetails.attendees_count_for_meeting_room) {
                            //$scope.displayAttendeesCountSelect = true;
                            $scope.selectedAttendeesNb = threadDataRoomsDetails.attendees_count_for_meeting_room;
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

                $scope.getEventMeetingRoomDetails = function() {
                    var result = {used: false};

                    if(!$.isEmptyObject($scope.selectedRoom)) {
                        result.used = true;
                        result.selected = $scope.selectedRoom;
                    }

                    return result
                };

                $scope.getUsingMeetingRoom = function() {
                    return $scope.usingMeetingRoom;
                };

                $scope.getMeetingRoomDetails = function() {
                    var result = null;

                    if($scope.usingMeetingRoom) {
                        result = {selected_meeting_room: $scope.selectedRoom, room_selection_mode: $scope.roomsSelectionMode};
                        if(result.room_selection_mode.id == 'auto_room_selection') {
                            result.room_selection_mode.id += '|' + $scope.getActiveFilters().join(';');
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

                // Used in AI verify dates call in ask_availabilities.js
                $scope.getCurrentMeetingRoomsToDisplay = function() {
                    var result = [];

                    if($scope.roomsSelectionMode && $scope.roomsSelectionMode.id.indexOf('auto_room_selection') > -1) {
                        result = $scope.determineFittingMeetingRooms();
                    }else {
                        if($scope.selectedRoom)
                            result.push($scope.selectedRoom);
                    }

                    return result;
                };

                $scope.getMeetingRoomsToDisplay = function() {
                    var result = [];

                    if($scope.computedDataRoomsSelectionMode && $scope.computedDataRoomsSelectionMode.id.indexOf('auto_room_selection') > -1) {
                        result = $scope.determineFittingMeetingRooms();
                    }else {
                        if($scope.selectedRoom)
                            result.push($scope.selectedRoom);
                    }

                    // randomize meeting room order
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

                    $scope.noFittingRooms = filteredAvailableRooms.length == 0;
                    if(!$scope.$$phase)
                        $scope.$apply();


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

                    if(!$.isEmptyObject($scope.selectedRoom)) {
                        $scope.checkMeetingRoomAvailability(true);
                    }
                };

                $scope.checkIfDetectAvailabilities = function() {
                    if($scope.selectedRoom && $scope.selectedRoom.id) {
                        $scope.checkMeetingRoomAvailability(true);
                    } else {
                        $scope.checkMeetingRoomAvailability();
                    }
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
                                var selectedDateEndTime = selectedDateStartTime.clone().add(window.currentCalendar.getCurrentDuration(), 'm');
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
                                        if(updateEventClassification && window.threadComputedData.meeting_room_details.selected_meeting_room && window.threadComputedData.meeting_room_details.selected_meeting_room.id == meetingRoom.id) {
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
                            
                            available = _.sortBy(available, function(_) { return Math.random()  });

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
                };

                $scope.selectRoom = function(room) {
                    $scope.selectedRoom = _.find($scope.roomsList, function(mR) {
                        return mR.id == room.id;
                    });

                    if($scope.selectedRoom && $scope.selectedRoom.id != "auto_room_selection") {
                        $('.create_event_room_selection_select option[value="' + $scope.selectedRoom.id + '"]').prop('selected', 'selected');
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

                    return result;
                };

                $scope.getOverlappingEvents = function(eventsByMeetingRooms) {
                    var scop = $('#events_availabilities_methods').scope();

                    // - - - - - - - DIRTY FIX DUE TO CHROME VERSION 57 BUG - - - - - //
                    // - TO REMOVE WHEN CHROM V.58 IS PUBLIC  - - - - - - - - - - - - //
                    if(!scop.getOverlappingEvents) {
                        console.log("Scope error due to Chrome v57.");
                        scop = scop.$$childHead;
                    }
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -//

                    return scop.getOverlappingEvents(eventsByMeetingRooms, {isMeetingRoom: true});
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
                    var notesNode = $('#notes');
                    var notes = notesNode.val();
                    var meetingRoomInfos = '';

                    if($scope.selectedRoom && $scope.selectedRoom.summary && $scope.attendeesManagerCtrl) {
                        meetingRoomInfos += "-" + localize("events.notes.meeting_rooms.boundary", {locale: window.currentLocale}) + "-------------------";
                        meetingRoomInfos += "\n " + localize("events.notes.meeting_rooms.sentence", {locale: window.currentLocale, company_name: $scope.attendeesManagerCtrl.getThreadOwner().company, meeting_room_name: $scope.selectedRoom.summary});
                        meetingRoomInfos += "\n----------------------------------------";
                    }

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
                };

                // $scope.setMeetingRoomInfosInNotes = function() {
                //     if($scope.selectedRoom && $scope.selectedRoom.id != 'auto_room_selection' && $scope.selectedRoom.summary && $scope.attendeesManagerCtrl) {
                //         var notesNode = $('#notes');
                //         var notes = notesNode.val();
                //         var meetingRoomInfos = '';
                //
                //         meetingRoomInfos += "-" + localize("events.notes.meeting_rooms.boundary", {locale: window.currentLocale}) + "-------------------";
                //         meetingRoomInfos += "\n " + localize("events.notes.meeting_rooms.sentence", {locale: window.currentLocale, company_name: $scope.attendeesManagerCtrl.getThreadOwner().company, meeting_room_name: $scope.selectedRoom.summary});
                //         meetingRoomInfos += "\n----------------------------------------";
                //
                //         var tmpNotes = notes.replace(/\n/g,'');
                //         var regexFrResult = meetingRoomsReFr.exec(tmpNotes);
                //         var regexEnResult = meetingRoomsReEn.exec(tmpNotes);
                //
                //         if(regexFrResult == null && regexEnResult == null){
                //             if(notes.replace(/\n/g,'').length > 0)
                //                 notes += "\n\n";
                //             notes += meetingRoomInfos;
                //         }else{
                //             // Maybe use contactInfosReFr and contactInfosReEn in place of regexFrResult and regexEnResult
                //             var usedRegex = regexFrResult != null ? meetingRoomsReFr : meetingRoomsReEn;
                //             notes = notes.replace(/\n/g,'__n').replace(usedRegex, meetingRoomInfos).replace(/(__n){2,}/g, '\n\n').replace(/__n/g, "\n");
                //         }
                //
                //         notesNode.val(notes);
                //     }
                // };

                $scope.init();
            }],
            controllerAs: 'meetingRoomsCtrl'
        }
    });
})();
