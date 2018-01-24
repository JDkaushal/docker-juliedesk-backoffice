(function(){

    var app = angular.module('meeting-rooms-manager-controllers', ['templates']);

    app.controller('meetingRoomsController', ['$scope', '$element', '$timeout', 'sharedProperties', 'defaultInitializationsService' , function($scope, $element, $timeout, sharedProperties, defaultInitializationsService){

        $scope.displayForm = false;
        //$scope.selectedAttendeesNb = "2";
        $scope.formDisabled = !window.threadDataIsEditable;
        $scope.usingMeetingRoom = false;

        $scope.initialized = false;

        // Used to store the currently choosen rooms, in order to prevent duplicate bookings
        $scope.currentlyChoosenRooms = [];
        $scope.allSelectionnableMeetingRooms = [];

        $scope.accountsManager = $('#accounts-list-section').scope();
        $scope.datesVerificationManager = $scope.datesVerificationManager || angular.element($('#datesVerificationsManager')).scope();
        $scope.meetingRoomsAvailabilitiesPanel = $scope.meetingRoomsAvailabilitiesPanel || angular.element($('#meeting-rooms-availabilities-panel')).scope();
        $scope.attendeesManagerCtrl = $scope.attendeesManagerCtrl || angular.element($('#attendeesCtrl')).scope();
        $scope.datesSuggestionManager = $scope.datesSuggestionManager || $('#dates-suggestion-manager').scope();

        $scope.widgets = [];

        var meetingRoomsReFr = new RegExp("-" + localize("events.notes.meeting_rooms.boundary", {locale: 'fr'}) + "-------------------.+?(?:----------------------------------------)");
        var meetingRoomsReEn = new RegExp("-" + localize("events.notes.meeting_rooms.boundary", {locale: 'en'}) + "-------------------.+?(?:----------------------------------------)");

        $scope.$watch('displayForm', function(newVal, oldVal) {
            if(newVal) {
            } else {
                $scope.$broadcast('clearWidgets');
            }
        });

        $scope.$watch('allSelectionnableMeetingRooms', function(newVal, oldVal) {
            if(oldVal && newVal) {
                var sortedOldVal = oldVal.sort();
                var sortedNewVal = newVal.sort();

                if (!_.isEqual(sortedOldVal, sortedNewVal)) {
                    $scope.reloadCalendar();
                }
            }
        });

        $scope.reloadCalendar = function() {
            // Only reload the calendar if we are
            if(window.currentCalendar && window.currentCalendar.dispStart) {
                console.log('Reloading Calendar');
                window.currentCalendar.fetchCalendars(function() {
                    window.currentCalendar.resetMeetingRoomsEvents();
                    window.currentCalendar.refreshEvents();
                });
            }
        };

        if($scope.datesSuggestionManager) {
            $scope.datesSuggestionManager.$on('suggestionAdded', function(event, args) {
                var lastSuggestion = _.last(window.currentCalendar.events);

                if(lastSuggestion) {
                    // To have the date in the correct timezone, otherwise it is offsetted due to UTC
                    var timezonedDate = moment.tz(lastSuggestion.start.format(), currentCalendar.getCalendarTimezone()).format();
                    $scope.checkIfDetectAvailabilities(timezonedDate);
                }
                //$scope.checkMeetingRoomAvailability(false, args);
            });
        }

        if($scope.datesVerificationManager) {
            $scope.datesVerificationManager.$on('datesVerifNewSelectedDate', function(event, dateToCheck) {
                $scope.checkIfDetectAvailabilities(dateToCheck);
                //$scope.checkMeetingRoomAvailability(false, args);
            });
        }

        if($scope.attendeesManagerCtrl) {
            $scope.attendeesManagerCtrl.$on('attendeesInitialized', function(event, args) {
                if($scope.initialized && !window.currentCalendar && window.drawCalendarCallback)
                    window.drawCalendarCallback();
            });
        }

        $scope.accountsManager.$on('allAccountsFetched', function(event, args) {
            $scope.initialize(args.accounts);
            $scope.$apply();
        });

        $scope.usingMeetingRoomOnchange = function() {
            $scope.checkRoomAvailabilities();
        };

        // Used for general purpose initialization (called at instanciation)
        $scope.init = function() {
        };

        // Used to bootstrap the app really (called in listener of the allAccountsFetched event of the client_account_tile app)
        $scope.initialize = function(clientsList) {
            if($scope.initialized) return;

            // Deep Copy of the array;
            $scope.clientsList = JSON.parse(JSON.stringify(clientsList));

            var clientsEmails = _.flatten(_.map($scope.clientsList, function(client) { return client.email_aliases.concat(client.email)}));

            if(window.threadComputedData.meeting_room_details) {
                _.each(window.threadComputedData.meeting_room_details, function(details) {
                    // Only add the widget if the client is still client and is attending the appointment
                    if(clientsEmails.indexOf(details.client) > -1) {
                        $scope.addWidget(details.client, details);
                    }
                });
            }

            $scope.checkMeetingRoomsActivation();

            $scope.initialized = true;

            $scope.$broadcast('meetingRoomsInitialized');
        };

        $scope.addWidget = function(email, initialConfiguration) {
            $scope.widgets.push(new Widget(email, initialConfiguration));
            $scope.usingMeetingRoom = true;
        };

        var busy = false;

        $('.event-tile-panel').on('change', 'input.event-dates', function(e) {
            if(!$scope.usingMeetingRoom) return;

            if(!busy) {
                //$scope.checkMeetingRoomAvailability(false);
                var dateToCheck = undefined;

                if(window.currentEventTile && window.currentEventTile.getEditedEvent()) {
                    dateToCheck = window.currentEventTile.getEditedEvent().start;
                }

                $scope.checkIfDetectAvailabilities(dateToCheck);

                busy = true;

                // As the change event is triggered multiple times each time the date is updated, we do this to prevent calling the checkAvailabilities code needlessly
                $timeout(function() {
                    busy = false
                }, 1000);
            }

        });

        //
        $('#location_nature, #location_nature_event').change(function(e) {
            var that = $(this);
            var previousLocation = that.data('prevValue');
            var newLocation = window.getCurrentAddressObject().address;
            that.data('prevValue', newLocation);

            $scope.$broadcast ('locationChanged', {prevValue: previousLocation, newValue: newLocation});

            $scope.addClientsIfNecessary();
            //$scope.checkMeetingRoomsActivation();
            $scope.$apply();
        });
        //
        $('#appointment_nature').change(function(e) {
            $scope.cleanWidgets();
            
            $scope.addClientsIfNecessary();

            $scope.$broadcast ('setDefaults');
            $scope.$broadcast('appointmentTypeChanged');

            //$scope.checkMeetingRoomsActivation();
            $scope.$apply();
        });
        //

        $scope.cleanWidgets = function() {
            $scope.widgets = [];
        };

        $scope.addClientsIfNecessary = function() {
            //if(window.isCurrentAppointmentVirtual()) {
                var currentAppointment = window.getCurrentAppointment();

                var usedLocations = [];

                var currentAppointmentIsVirtual = window.isCurrentAppointmentVirtual();

              _.each($scope.clientsList, function(client) {

                  // Don't open a widget for the client if one is already open
                  if(currentAppointmentIsVirtual || client.email === window.threadAccount.email) {

                      var currentClientAppointment = _.find(client.appointments, function(appointment) {
                          return appointment.kind === currentAppointment.kind
                      });

                      var currentAddress = !currentAppointmentIsVirtual && window.getCurrentAddressObject();

                      if( (currentClientAppointment && currentClientAppointment.meeting_room_used) || (currentAddress && currentAddress.meeting_room_used) ) {
                            var initialConfiguration = {client: client.email, location: currentClientAppointment.default_address.address};

                            var usedRoom = defaultInitializationsService.getMeetingRoomToUse(currentClientAppointment || {}, currentAddress || {});

                          if(usedRoom.indexOf('auto_room_selection') > - 1) {
                              initialConfiguration.roomsSelectionMode = {id: usedRoom, summary: "Sélection Auto Par Filtres"}
                          }

                          var addWidget = true;
                          // When the appointment is virtual,
                          if(currentAppointmentIsVirtual && usedLocations.indexOf(initialConfiguration.location) > -1) {
                              addWidget = false;
                          }

                          if(addWidget) {
                              $scope.addWidget(client.email, initialConfiguration);
                              usedLocations.push(initialConfiguration.location);
                          }
                      }
                  }
              });
            //}
        };

        $scope.checkMeetingRoomsActivation = function() {
            $scope.displayForm = $scope.shouldDisplayForm();
        };

        $scope.shouldDisplayForm = function() {
            //var shouldDisplay = false;

            var shouldDisplay = _.any($scope.clientsList, function(client) {
               return client.has_meeting_rooms;
            });
            // if(currentAppointment) {
            //     var currentAppointmentIsVirtual = currentAppointment.appointment_kind_hash.is_virtual;
            //     var userHasRoomsOnLocations = _.any(window.threadAccount.addresses, function(address) {
            //         return address.meeting_rooms_enabled;
            //     });
            //
            //     var shouldDisplayForPhysicalAppointment = !currentAppointmentIsVirtual && (currentAppointment.meeting_room_used || address && address.meeting_room_used);
            //     var shouldDisplayForVirtualAppointment = currentAppointmentIsVirtual && userHasRoomsOnLocations;
            //
            //     shouldDisplay = shouldDisplayForPhysicalAppointment || shouldDisplayForVirtualAppointment;
            // }

            return shouldDisplay;
        };

        $scope.setMeetingRoomInfosInNotes = function() {
            var notesNode = $('#notes');
            var notes = notesNode.val();
            var meetingRoomInfos = '';

            var bookedRooms = $scope.getBookedRoomsDetails();

            if(bookedRooms && _.keys(bookedRooms).length > 0 && $scope.attendeesManagerCtrl.attendees && $scope.attendeesManagerCtrl.attendees.length > 0) {
                meetingRoomInfos += "-" + localize("events.notes.meeting_rooms.boundary", {locale: window.currentLocale}) + "-------------------";
                _.each(bookedRooms, function(roomDetails) {
                    meetingRoomInfos += "\n " + localize("events.notes.meeting_rooms.sentence", {locale: window.currentLocale, meeting_room_name: roomDetails.summary, meeting_room_location: roomDetails.location});
                });
                meetingRoomInfos += "\n----------------------------------------";
            }

            var tmpNotes = notes.replace(/\n/g,'');
            var regexFrResult = meetingRoomsReFr.exec(tmpNotes);
            var regexEnResult = meetingRoomsReEn.exec(tmpNotes);

            if(regexFrResult == null && regexEnResult == null){
                // if(notes.replace(/\n/g,'').length > 0)
                //     notes += "\n\n";
                notes = meetingRoomInfos + "\n\n" + notes;
                //notes += meetingRoomInfos;
            }else{
                // Maybe use contactInfosReFr and contactInfosReEn in place of regexFrResult and regexEnResult
                var usedRegex = regexFrResult != null ? meetingRoomsReFr : meetingRoomsReEn;
                notes = notes.replace(/\n/g,'__n').replace(usedRegex, meetingRoomInfos).replace(/(__n){2,}/g, '\n\n').replace(/__n/g, "\n");
            }

            notesNode.val(notes);
        };

        $scope.getUsingMeetingRoom = function() {
            return $scope.usingMeetingRoom;
        };

        $scope.getMeetingRoomDetails = function() {
            if(!$scope.usingMeetingRoom) return;

            $scope.$broadcast('computeMeetingRoomsDetails');

            return _.map($scope.widgets, function(widget) {
                return widget.meetingRoomsDetails;
            });
        };

        // Used in AI verify dates call in ask_availabilities.js
        $scope.getCurrentMeetingRoomsToDisplay = function() {
            if(!$scope.usingMeetingRoom) return;

            $scope.$broadcast('getCurrentMeetingRoomsToDisplay');

            return _.uniq(_.flatten(_.map($scope.widgets, function(widget) {
                return widget.currentMeetingRoomsToDisplay;
            })), function(room) {
                return room.id;
            });
        };

        $scope.getMeetingRoomsToDisplayRaw = function() {
            if(!$scope.usingMeetingRoom) return;

            $scope.$broadcast('getMeetingRoomsToDisplay');

            return _.map($scope.widgets, function(widget) {
                return _.map(widget.meetingRoomsToDisplay, function(room) {
                    return room.id;
                });
            });
        };

        $scope.getMeetingRoomsToDisplay = function() {
            if(!$scope.usingMeetingRoom) return;

            $scope.$broadcast('getMeetingRoomsToDisplay');

          return _.uniq(_.flatten(_.map($scope.widgets, function(widget) {
              return widget.meetingRoomsToDisplay;
          })), function(room) {
              return room.id;
          });
        };

        $scope.getWidgets = function() {
            return _.map($element.find('meeting-rooms-widget'), function(directive) {
                return $(directive).scope();
            });
        };

        $scope.getAvailableMeetingRooms = function() {
            if(!$scope.usingMeetingRoom) return;

            var result = {};

            _.each($scope.widgets, function(widget) {
                if(widget.roomLocation) {
                    result[widget.initialConfiguration.client] = result[widget.initialConfiguration.client] || [];
                    result[widget.initialConfiguration.client] = result[widget.initialConfiguration.client].concat(widget.roomLocation.available_meeting_rooms);
                }
            });

            _.each(result, function(rooms, clientEmail) {
               result[clientEmail] = _.uniq(rooms, function(room) {
                   return room.id;
               });
            });

            return result;
        };

        // To know if we have to reload the calendar when the selectable rooms changed
        $scope.computeAllSelectionnableMeetingRooms = function() {

            $scope.allSelectionnableMeetingRooms = _.map(_.flatten(_.values($scope.getCurrentMeetingRoomsToDisplay())), function(room) {
                return room.id;
            });

            $scope.allSelectionnableMeetingRooms = _.uniq($scope.allSelectionnableMeetingRooms);
        };

        $scope.displayRoomsAvailable = function() {
            // Only display the rooms availabilities if the calendar have been initialized (we will then have access to the events)
            if(window.currentCalendar) {
                var roomsAvailabilities = [];

                if($scope.usingMeetingRoom) {
                    roomsAvailabilities = _.map(_.filter($scope.widgets, function(w) {return w.roomAvailable !== undefined}), function(widget) {
                        return {clientUsageName: widget.clientUsageName, location: widget.roomLocation, roomName: widget.roomAvailableName, isAvailable: widget.roomAvailable};
                    });
                }

                if($scope.datesSuggestionManager) {
                    $scope.datesSuggestionManager.displayMeetingRoomsAvailabilities(roomsAvailabilities);
                    $scope.datesSuggestionManager.$apply();
                }

                if($scope.datesVerificationManager) {
                    $scope.datesVerificationManager.displayMeetingRoomsAvailabilities(roomsAvailabilities);
                }

                if($scope.meetingRoomsAvailabilitiesPanel) {
                    $scope.meetingRoomsAvailabilitiesPanel.displayMeetingRoomsAvailabilities(roomsAvailabilities);
                    $scope.meetingRoomsAvailabilitiesPanel.$apply();
                }
            }
        };

        $scope.$on('clientChanged', function() {
            $scope.checkRoomAvailabilities();
        });

        $scope.$on('roomFiltersUpdated', function() {
            $scope.checkRoomAvailabilities();
        });
        
        $scope.$on('widgetAdded', function() {
            $scope.checkRoomAvailabilities();
        });

        $scope.$on('roomChanged', function() {
            $scope.checkRoomAvailabilities();
        });
        
        $scope.$on('availableRoomsChanged', function() {
            $scope.computeAllSelectionnableMeetingRooms();
        });

        $scope.$on('widgetDeleted', function(event, args) {
            $scope.widgets = _.reject($scope.widgets, function(widget) {
                return widget.guid === args.widgetGuid;
            });

            if($scope.widgets.length === 0) {
                $scope.usingMeetingRoom = false;
            }

            $scope.checkRoomAvailabilities();
        });
        
        $scope.checkRoomAvailabilities = function() {
            var dateToCheck = undefined;

            if(window.currentEventTile && window.currentEventTile.getEditedEvent()) {
                dateToCheck = window.currentEventTile.getEditedEvent().start;
            }

            $scope.checkIfDetectAvailabilities(dateToCheck);
        };

        $scope.checkIfDetectAvailabilities = function(dateToCheck) {
            if($scope.usingMeetingRoom) {
                sharedProperties.clearChoosenRooms();

                $scope.$broadcast('checkIfDetectAvailabilities', dateToCheck);
                //$scope.currentlyChoosenRooms = [];
            }
            // We do this to reset the currentlyChoosenRooms property before each calls
            // As it is called from external trigger coming from outside angular, we need to use $applyAsync

            $scope.displayRoomsAvailable();

            if(window.updateNotesCallingInfos)
                window.updateNotesCallingInfos();
        };

        $scope.getBookedRoomsDetails = function() {
            if(!$scope.usingMeetingRoom) return {};

            var result = [];

            $scope.$broadcast('getEventMeetingRoomDetails');

            _.each($scope.widgets, function(widget) {
                if(widget.roomAvailable) {
                    if(widget.reservationData && widget.reservationData.selected) {
                        result.push({summary: widget.reservationData.selected.summary, id: widget.reservationData.selected.id, location: widget.roomLocation.address});
                    }
                }
            });

            return result;
        };

        $scope.getEventMeetingRoomDetails = function() {
            if(!$scope.usingMeetingRoom) return {used: false, booked_rooms: []};

            $scope.$broadcast('getEventMeetingRoomDetails');

            return $scope.formatEventMeetingRoomDetails();
        };

        $scope.formatEventMeetingRoomDetails = function() {
            var result = {used: false, booked_rooms:  new Set};

            _.each($scope.widgets, function(widget) {
                if(widget.roomAvailable) {
                    result.used = true;
                    if(widget.reservationData && widget.reservationData.selected && widget.reservationData.selected.id) {
                        result.booked_rooms.add(widget.reservationData.selected.id);
                    }
                }
            });

            result.booked_rooms = Array.from(result.booked_rooms);

            return result;
        };

        // Returns every meeting rooms associated to any client attendee
        $scope.getEveryPossibleMeetingRooms = function() {

            return _.uniq(_.flatten(_.map($scope.clientsList, function(client) {
                return _.map(client.addresses, function(address) {
                    return address.available_meeting_rooms;
                })
            })), function(room) {
                return room.id;
            })
        };

        $scope.init();
    }]);

    app.controller('meetingRoomsWidgetController', ['$scope', '$element', 'sharedProperties', 'defaultInitializationsService' , function($scope, $element, sharedProperties, defaultInitializationsService){

        var autoRoomMode = {id: 'auto_room_selection', summary: 'Sélection Auto Par Filtres'};
        var autoRoomModeWithFilters = {id: 'auto_room_selection|attendees_count', summary: 'Sélection Auto Par Filtres'};

        $scope.displayCustomSelectionFilters = false;

        $scope.attendeesManagerCtrl = $scope.attendeesManagerCtrl || angular.element($('#attendeesCtrl')).scope();
        $scope.datesVerificationManagerCtrl = $scope.datesVerificationManagerCtrl || angular.element($('#datesVerificationsManager')).scope();
        $scope.utilitiesHelper = $('#events_availabilities_methods').scope();

        $scope.roomsList = [];
        $scope.availableRooms = [];
        $scope.roomsSelectionMode = autoRoomMode;
        $scope.selectedRoom = undefined;
        $scope.noFittingRooms = false;
        $scope.unavailableMessageDisplayed = false;
        $scope.computedDataRoomsSelectionMode;

        $scope.locationDifferentThanAppointment = false;
        
        $scope.attendeesManagerCtrl.$on('attendeesRefreshed', function(event, args) {
            // We only update the attendees count accordindly of adding or deleting them when we havent saved the count yet
            if($scope.usingMeetingRoom && ( !$scope.widgetData.initialConfiguration || ( $scope.widgetData.initialConfiguration && !$scope.widgetData.initialConfiguration.attendees_count_for_meeting_room ) ) )
                $scope.updateAttendeesCountSelect(args.attendees.slice());
        });

        // We don't use watchers, because it is triggered after the $emit events
        // $scope.$watch('roomLocation', function(newVal, oldVal) {
        //    $scope.widgetData.roomLocation = newVal;
        // });

        $scope.$watch('selectedRoom', function(newVal, oldVal) {
            var currentAppointment = window.getCurrentAppointment();
            if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
                updateNotesCallingInfos();
            }
        });

        $scope.$watch('roomsSelectionMode', function(newVal, oldVal) {
            newVal = newVal || {};
            oldVal = oldVal || {};
            $scope.displayCustomSelectionFilters = newVal.id === 'auto_room_selection';

            // if(newVal && newVal.id && newVal.id !== oldVal.id && !window.julie_action_nature) {
            //     if(newVal.id.indexOf('auto_room_selection') > - 1) {
            //         $scope.selectedRoom = undefined;
            //     } else {
            //         $scope.selectedRoom = angular.copy(newVal);
            //     }
            // }
        });

        $scope.$on('appointmentTypeChanged', function() {
            $scope.checkIfLocationDifferentThanAppointment();

        });

        $scope.$on('getEventMeetingRoomDetails', function() {
           $scope.getEventMeetingRoomDetails();
        });

        $scope.$on('checkIfDetectAvailabilities', function(event, dateToCheck) {
            // As the widget will be effectively deleted at the end of the digest cycle, when we click the delete button,
            // It triggers a check of the rooms availabilities on each widgets and if we delete a widget which is not the last,
            // it would lead to problem with the system thinking a room as been booked by a deleted widget when in fact it should not
            if($scope.beingDeleted) return;

           $scope.checkIfDetectAvailabilities(dateToCheck);
        });

        $scope.$on('computeMeetingRoomsDetails', function() {
           $scope.computeMeetingRoomDetails();
        });

        $scope.$on('clearWidgets', function() {
           $scope.clear();
        });

        $scope.$watch('availableRooms', function(newVal, oldVal) {
            $scope.$emit('availableRoomsChanged');
        });

        $scope.$on('locationChanged', function(event, args) {
            // When the appointment is physical and the appointment old address was associated with some meeting rooms,
            // we will change the location to the new one
            // If the new one has no meeting rooms associated to it, or is not present on the concerned user, we will delete
            // the widget
            if(!window.isCurrentAppointmentVirtual()) {
                if($scope.roomLocation.address === args.prevValue) {
                    $scope.roomLocation = _.find($scope.locations, function(location) {
                        return location.address === args.newValue;
                    });

                    if($scope.roomLocation && $scope.roomLocation.meeting_room_used) {
                        $scope.roomLocationChanged();
                    } else {
                        $scope.deleteWidget();
                    }
                }
            }
        });

        $scope.$on('setDefaults', function() {
            $scope.clear();
            $scope.setDefaultRoomLocation();
            $scope.refreshRoomsList();
            if(window.isCurrentAppointmentVirtual() || $scope.client.email === window.threadAccount.email) {
                $scope.setDefaultSelectedRoom();
            }
            $scope.determineFittingMeetingRooms();
        });

        $scope.$on('clearWidgets', function() {
           $scope.clear();
        });

        // Used in AI verify dates call in ask_availabilities.js
        $scope.$on('getCurrentMeetingRoomsToDisplay', function() {
            $scope.widgetData.currentMeetingRoomsToDisplay = $scope.getCurrentMeetingRoomsToDisplay();
        });

        $scope.$on('getMeetingRoomsToDisplay', function() {
           $scope.widgetData.meetingRoomsToDisplay = $scope.getMeetingRoomsToDisplay();
        });

        $scope.$watchGroup(['useAttendeesCountFilter', 'useCanConfCallFilter', 'useCanVisioFilter'], function(newValues, oldValues, scope) {
            $scope.determineFittingMeetingRooms();
            //$scope.checkIfDetectAvailabilities();

            $scope.$emit('roomFiltersUpdated');
            $scope.$emit('availableRoomsChanged');
        });

        $scope.deleteWidget = function() {
            $scope.beingDeleted = true;
            $scope.$emit('widgetDeleted', {widgetGuid: $scope.widgetData.guid});
        };

        $scope.setDefaultRoomLocation = function() {
            $scope.roomLocation = $scope.getCurrentLocationForClient();
            $scope.widgetData.roomLocation = $scope.roomLocation;
        };

        $scope.getCurrentLocationForClient = function() {
            var currentAddress = (window.getCurrentAddressObject() || $scope.getDefaultAddressForCurrentAppointment() || {}).address;

            return $scope.getLocationForClient(currentAddress);
        };

        $scope.getLocationForClient = function(address) {
            return _.find($scope.client.addresses, function(addr) {
                return addr.address === address;
            });
        };

        $scope.getDefaultAddressForCurrentAppointment = function() {
            var currentAppointmentKind = window.getCurrentAppointment().kind;
            
            var currentAppointmentForClient = _.find($scope.client.appointments, function(appointment) {
                return appointment.kind === currentAppointmentKind;
            });

            return currentAppointmentForClient.default_address;
        };

        $scope.selectedAttendeesNbChanged = function() {
            $scope.determineFittingMeetingRooms();
        };

        $scope.init = function() {
            // Initializations are done when the client variable is changed (watcher)

            // In case we did not specify a client when creating the widget, we preselect the first one
            var targetEmail = $scope.widgetData.targetEmail || window.threadAccount.email;

            $scope.client = _.find($scope.clientsList, function(clientData) {
               return clientData.email === targetEmail;
            });

            if(!$scope.widgetData.initialConfiguration || !$scope.widgetData.initialConfiguration.client) {
                $scope.widgetData.initialConfiguration = $scope.widgetData.initialConfiguration || {};
                $scope.widgetData.initialConfiguration.client = targetEmail;
            }

            $scope.initialClientConfiguration();
            //$scope.clientChanged();
            $scope.$emit('widgetAdded');
        };

        $scope.resetLocation = function() {
          $scope.roomLocation = undefined;
          $scope.widgetData.roomLocation = undefined;
        };

        $scope.initialClientConfiguration = function() {
            $scope.initLocations();
            $scope.resetLocation();

            if($scope.widgetData.initialConfiguration && $scope.widgetData.initialConfiguration.location) {
                $scope.setMeetingRoomManagerDefaultState($scope.widgetData.initialConfiguration.location);
            }

            // // Don't preselect an address if one was already set in a previous form filling for the current client
            if(!$scope.roomLocation) {
                $scope.preselectAddress();
            }

            $scope.widgetData.clientUsageName = $scope.client.usage_name;
            $scope.widgetData.targetEmail = $scope.client.email;
        };

        $scope.clientChanged = function() {
            $scope.initLocations();
            $scope.resetLocation();

            // // Don't preselect an address if one was already set in a previous form filling for the current client
            if(!$scope.roomLocation) {
                $scope.preselectAddress();
            }
            
            $scope.widgetData.clientUsageName = $scope.client.usage_name;
            $scope.widgetData.targetEmail = $scope.client.email;

            $scope.$emit('clientChanged');
        };

        $scope.setMeetingRoomManagerDefaultState = function(location) {
            var address = _.find($scope.client.addresses, function(address) {
                    return address.address === location;
                });

            if(address) {
                $scope.setAvailableRooms(address);
                $scope.setSelectedRoom();
                $scope.roomLocation = address;
                $scope.widgetData.roomLocation = $scope.roomLocation;
            }
        };

        $scope.getClient = function(clientEmail) {
          return _.find($scope.clientsList, function(client) {
              return client.email === clientEmail;
          })
        };

        $scope.getRoomLocation = function(location) {
            return _.find($scope.locations, function(loc) {
                return loc.address === location;
            });
        };

        $scope.initLocations = function() {
            $scope.locations = $.extend(true, [], _.filter($scope.client.addresses, function(address) {
                return address.meeting_rooms_enabled;
            }));

            _.each($scope.locations, function(location) {
                if(location.kind == 'locations_cluster') {
                    location.label = location.label + ' (Campus)';
                }
            });
        };

        $scope.shouldDisplayFields = function() {
          return $scope.client && $scope.client.email && $scope.client.email.length > 0;
        };

        $scope.roomLocationChanged = function() {
            if($scope.roomLocation) {
                var usableRooms = $scope.roomLocation.available_meeting_rooms;
                var currentAppointment = $scope.getCurrentAppointmentForClient();

                $scope.roomsList = [autoRoomMode];

                _.each(usableRooms, function(meetingRoom) {
                    meetingRoom.capacity = meetingRoom.capacity || undefined;
                    $scope.roomsList.push({id: meetingRoom.id, summary: meetingRoom.summary, calendar_login_username: meetingRoom.calendar_login_username});
                });

                $scope.setAvailableRooms($scope.roomLocation);

                //var usedRoom = $scope.determineUsedMeetingRoom((currentAppointment && currentAppointment.meeting_room_used && currentAppointment.selected_meeting_room) || '', ($scope.roomLocation.meeting_room_used && $scope.roomLocation.selected_meeting_room) || '');
                var usedRoom = defaultInitializationsService.determineMeetingRoomToUse((currentAppointment && currentAppointment.meeting_room_used && currentAppointment.selected_meeting_room) || '', ($scope.roomLocation.meeting_room_used && $scope.roomLocation.selected_meeting_room) || '');

                if(usedRoom.indexOf('auto_room_selection') > -1) {
                    $scope.setDefaultFilters($scope.roomLocation.selected_meeting_room);
                    $scope.setRoom('auto_room_selection');
                    $scope.determineFittingMeetingRooms();
                } else {
                    $scope.setRoom(usedRoom);
                    $scope.noFittingRooms = false;
                }

                $scope.widgetData.roomLocation = $scope.roomLocation;

                $scope.checkIfLocationDifferentThanAppointment();
            }
        };

        $scope.checkIfLocationDifferentThanAppointment = function() {
            // When the current Appointment is physical
            $scope.locationDifferentThanAppointment = !window.isCurrentAppointmentVirtual() && ((window.getCurrentAddressObject() || {}).address !== ($scope.roomLocation || {}).address);
        };

        $scope.getMainAddressForCurrentAppointment = function() {
            var clientCurrentAppointment = $scope.getCurrentAppointmentForClient();
            var mainAddress = undefined;

            // Try to get the default location for the appointment type if it uses some meeting rooms
            // Otherwise we will try to get the client general default address (if it is present in the $scope.locations variable)
            // which would mean that is owns some meeting rooms
            if(clientCurrentAppointment.meeting_room_used && clientCurrentAppointment.default_address) {
                mainAddress = $scope.getRoomLocation(clientCurrentAppointment.default_address.address);
            } else {
                mainAddress = _.find($scope.locations, function(location) {
                    return location.is_main_address;
                });
            }

            return mainAddress;
        };

        $scope.preselectAddress = function() {
            $scope.roomLocation = $scope.getMainAddressForCurrentAppointment();

            if(!$scope.roomLocation) {
                $scope.roomLocation = $scope.locations[0];
            }

            $scope.widgetData.roomLocation = $scope.roomLocation;

            if($scope.roomLocation) {
                $scope.roomLocationChanged();
            }
        };

        $scope.setRoom = function(roomId) {
            var room = _.find($scope.roomsList, function(room) {
                return room.id === roomId;
            });

            if(room) {
                $scope.roomsSelectionMode = room;
                $scope.selectedRoom = room;
            }
        };

        $scope.setAvailableRooms = function(address) {
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

        $scope.roomSelectionModeChanged = function() {


          // Clear the no fitting rooms for used filters message if necessary
          if($scope.roomsSelectionMode.id.indexOf('auto_room_selection') > -1) {
              $scope.determineFittingMeetingRooms();
          } else {
              $scope.noFittingRooms = false;
          }

            if($scope.roomsSelectionMode && $scope.roomsSelectionMode.id && !window.julie_action_nature) {
                if($scope.roomsSelectionMode.id.indexOf('auto_room_selection') > - 1) {
                    $scope.selectedRoom = undefined;
                } else {
                    $scope.selectedRoom = angular.copy($scope.roomsSelectionMode);
                }
            }

            $scope.$emit('roomChanged');
        };

        $scope.shouldDisplayLocationfield = function() {
            return window.getCurrentAppointment().appointment_kind_hash.is_virtual;
        };

        $scope.getUsedLocation = function() {
            return $scope.roomLocation.address;
        };

        $scope.refreshRoomsList = function(skipDefaultRoom) {
            //skipDefaultRoom  = skipDefaultRoom || false;

            var address = $scope.getCurrentLocationForClient();

            // if(!address && $scope.widgetData.initialConfiguration && $scope.widgetData.initialConfiguration.location && $scope.widgetData.initialConfiguration.client === $scope.client.email) {
            //     address = _.find($scope.client.addresses, function(address) {
            //         return address.address === $scope.widgetData.initialConfiguration.location;
            //     });
            // }
            if(address) {
                $scope.availableRooms = address.available_meeting_rooms;
                $scope.setRoomsList();

                // if(!skipDefaultRoom) {
                //     $scope.setDefaultSelectedRoom();
                // }
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

        // $scope.computeDefaultFilters = function(appointmentSelectedMeetingRoom, addressSelectedMeetingRoom) {
        //     var filtersFromAppointments = appointmentSelectedMeetingRoom.split('|')[1].split(';');
        //     var filtersFromAddress = addressSelectedMeetingRoom.split('|')[1].split(';');
        //
        //     var summedFilters = _.uniq(filtersFromAppointments.concat(filtersFromAddress));
        //
        //     return 'auto_room_selection|' + summedFilters.join(';');
        // };

        $scope.getUsedMeetingRoom = function(currentAppointment, currentAddress) {
            // var appointmentSelectedMeetingRoom = currentAppointment.selected_meeting_room || '';
            // var addressSelectedMeetingRoom = currentAddress.selected_meeting_room || '';
            //
            // return $scope.determineUsedMeetingRoom(appointmentSelectedMeetingRoom, addressSelectedMeetingRoom);

            return defaultInitializationsService.getMeetingRoomToUse(currentAppointment, currentAddress);
        };

        // $scope.determineUsedMeetingRoom = function(appointmentMeetingRoomConfig, addressMeetingRoomConfig) {
        //     var usedMeetingRoom = appointmentMeetingRoomConfig;
        //
        //     if(appointmentMeetingRoomConfig.indexOf('auto_room_selection') === -1) {
        //         usedMeetingRoom = appointmentMeetingRoomConfig;
        //     } else if(addressMeetingRoomConfig.indexOf('auto_room_selection') === -1) {
        //         usedMeetingRoom = addressMeetingRoomConfig;
        //     } else {
        //         usedMeetingRoom = $scope.computeDefaultFilters(appointmentMeetingRoomConfig, addressMeetingRoomConfig)
        //     }
        //
        //     return usedMeetingRoom;
        // };

        $scope.getCurrentAppointmentForClient = function() {
            var currentAppointmentKind = window.getCurrentAppointment().kind;

            return _.find($scope.client.appointments, function(appointment) {
                return appointment.kind === currentAppointmentKind;
            });
        };

        $scope.setDefaultSelectedRoom = function() {
            var currentAddress = $scope.getCurrentLocationForClient();
            var currentAppointment = $scope.getCurrentAppointmentForClient();

            $scope.selectRoom(undefined);

            // if(!currentAddress && currentAppointment.appointment_kind_hash.is_virtual && $scope.widgetData.initialConfiguration && $scope.widgetData.initialConfiguration.location) {
            //     currentAddress = _.find($scope.client.addresses, function(address) {
            //         return address.address === $scope.widgetData.initialConfiguration.location;
            //     });
            // }

            if(currentAddress) {

                //$scope.usingMeetingRoom = currentAddress.meeting_room_used || currentAppointment.meeting_room_used;

                //if($scope.usingMeetingRoom) {
                    var selectedMeetingRoom = undefined;

                    var usedMeetingRoom = $scope.getUsedMeetingRoom(currentAppointment, currentAddress);

                    if(usedMeetingRoom.indexOf('auto_room_selection') > -1) {
                        $scope.setDefaultFilters(usedMeetingRoom);
                        selectedMeetingRoom = autoRoomMode.id;
                    } else {
                        selectedMeetingRoom = usedMeetingRoom;
                    }

                    if(selectedMeetingRoom) {
                        var selectedRoom = _.find($scope.roomsList, function(room) {
                            return room.id === selectedMeetingRoom;
                        });

                        $scope.selectedRoom = selectedRoom;
                        $scope.roomsSelectionMode = selectedRoom;
                    }
                //}
            }
            // else {
            //     $scope.usingMeetingRoom = false;
            // }
        };

        $scope.setDefaultFilters = function(selectedRoomStr) {
            $scope.useAttendeesCountFilter = selectedRoomStr.indexOf('attendees_count') > -1;
            $scope.useCanConfCallFilter = selectedRoomStr.indexOf('can_confcall') > -1;
            $scope.useCanVisioFilter = selectedRoomStr.indexOf('can_visio') > -1;

            if($scope.useAttendeesCountFilter) {
                $scope.updateAttendeesCountSelect($scope.attendeesManagerCtrl.attendees);
            }
        };

        $scope.setSelectedRoom = function() {

            if(!$.isEmptyObject($scope.widgetData.initialConfiguration)) {
                 var threadDataRoomsDetails = angular.copy($scope.widgetData.initialConfiguration);
            //
            //     // Backward compatibility
                if($.isEmptyObject(threadDataRoomsDetails.room_selection_mode)) {
                    threadDataRoomsDetails.room_selection_mode = autoRoomModeWithFilters;
                }
            //
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

             if(attendees && attendees.length > 0){
            //     // TODO When in a vitual Appointment, only take into account attendees from the same company than the threadOwner
                var currentAppointment = window.getCurrentAppointment();
                var presentAttendeesCount;
            //     // When in a virtual appointment, we take into account only the attendees from the same company than the current client
                 if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
                     if($scope.client.company_hash && $scope.client.company_hash.name.length > 0) {
                        var clientCompany = $scope.client.company_hash.name;

                        presentAttendeesCount = _.countBy(attendees, function (a) {
                            return a.isPresent && a.company == clientCompany;
                        })[true];
                    } else {
                        presentAttendeesCount = 1;
                    }
            //
                 } else {
                    presentAttendeesCount = _.countBy(attendees, function (a) {
                        return a.isPresent;
                    })[true];
                 }
            //
                 $scope.selectedAttendeesNb = String(presentAttendeesCount);
            //
            //     if(!$scope.$$phase)
            //         $scope.$apply();
            }
        };

        $scope.getEventMeetingRoomDetails = function() {
            var result = {used: false};

            if(!$.isEmptyObject($scope.selectedRoom)) {
                result.used = true;
                result.selected = $scope.selectedRoom;
            }

            $scope.widgetData.reservationData = result;

            return result
        };

        $scope.computeMeetingRoomDetails = function() {
            var result = null;

            result = {selected_meeting_room: $scope.selectedRoom, room_selection_mode: $scope.roomsSelectionMode, location: $scope.getUsedLocation(), client: $scope.client.email};
            if(result.room_selection_mode.id === 'auto_room_selection') {
                result.room_selection_mode.id += '|' + $scope.getActiveFilters().join(';');
                if($scope.useAttendeesCountFilter)
                    $.extend(result, {attendees_count_for_meeting_room: $scope.selectedAttendeesNb});
            }

            $scope.widgetData.meetingRoomsDetails = result;
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

            if($scope.roomsSelectionMode && $scope.roomsSelectionMode.id.indexOf('auto_room_selection') > -1) {
                result = $scope.determineFittingMeetingRooms();
            }else {
                if($scope.selectedRoom)
                    result.push($scope.selectedRoom);
            }

            // randomize meeting room order
            return result;
        };

        $scope.getFilteredRooms = function() {
            // This allow us to reject the current selected Room from the available rooms, in order to put it first
            // in the array so it will be checked first
            var filteredAvailableRooms = [];

            if($scope.roomsSelectionMode && $scope.roomsSelectionMode.id && $scope.roomsSelectionMode.id.indexOf('auto_room_selection') > -1) {
                var attendeesCount = parseInt($scope.selectedAttendeesNb);
                var selectedRoomId = ($scope.selectedRoom && $scope.selectedRoom.id) || null;
                var selectedRoomToUnshift = false;
                filteredAvailableRooms = _.filter($scope.availableRooms, function(room) {
                    var toFilter = false;

                    if($scope.applyFilterOnRoom(room, {attendeesCount: attendeesCount})) {
                        if(room.id === selectedRoomId) {
                            selectedRoomToUnshift = true;
                        } else {
                            toFilter = true;
                        }
                    }
                    return toFilter;
                });

                if(selectedRoomToUnshift) {
                    filteredAvailableRooms.unshift($scope.selectedRoom);
                }
            } else {
                filteredAvailableRooms = $scope.availableRooms;
            }

            return filteredAvailableRooms;
        };

        $scope.determineFittingMeetingRooms = function() {

            var filteredAvailableRooms = $scope.getFilteredRooms();

            $scope.noFittingRooms = filteredAvailableRooms.length === 0;

            if($scope.noFittingRooms) {
                $scope.selectRoom(undefined);
            }

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
            return roomCanConfCall === 'true';
        };

        $scope.canVisioFilter = function(roomCanVisio) {
            return roomCanVisio === 'true';
        };

        // $scope.setNewSelectedRoom = function(roomId) {
        //     $scope.selectedRoom = _.find($scope.availableRooms, function(room) {
        //         return room.id === roomId;
        //     });
        //
        //     if(!$.isEmptyObject($scope.selectedRoom)) {
        //         $scope.checkMeetingRoomAvailability(true);
        //     }
        // };

        $scope.checkIfDetectAvailabilities = function(dateToCheck) {
            if($scope.roomsSelectionMode && $scope.roomsSelectionMode.id.indexOf('auto_room_selection') === -1) {
                $scope.checkMeetingRoomAvailability(true, dateToCheck);
            } else {
                $scope.checkMeetingRoomAvailability(false, dateToCheck);
            }
        };

        $scope.checkMeetingRoomAvailability = function(checkSelectedRoom, specifiedDate) {
            if(window.currentCalendar && !$.isEmptyObject(window.currentCalendar.meetingRoomsEvents) &&
                (['check_availabilities', 'suggest_dates'].indexOf(window.julie_action_nature) > -1 || window.classification === 'update_event')) {

                if (window.classification === 'update_event') {
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

                var meetingRoomsAvailable = $scope.getFilteredRooms();

                // We reject the already booked rooms from previous widgets in the available rooms list to prevent duplicates
                meetingRoomsAvailable = _.reject(meetingRoomsAvailable, function(room) {
                    //return $scope.currentlyChoosenRooms.indexOf(room.id) > -1;
                    return sharedProperties.checkRoomAlreadyChoosen(room.id);
                });

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
                                if(updateEventClassification && $scope.widgetData.initialConfiguration && $scope.widgetData.initialConfiguration.selected_meeting_room && $scope.widgetData.initialConfiguration.selected_meeting_room.id === meetingRoom.id) {
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

                    // We place the currently selected Room at the top of the availabilities so it get taken first if we check a new timeslot
                    var selectedRoomId = ($scope.selectedRoom && $scope.selectedRoom.id) || null;
                    var currentlySelectedRoom = undefined;
                    if(selectedRoomId && available[0].id === selectedRoomId) {
                        currentlySelectedRoom = available.shift();
                    }

                    available = _.sortBy(available, function(_) { return Math.random(); });

                    if(currentlySelectedRoom) {
                        available.unshift(currentlySelectedRoom);
                    }

                    // Whenever we check for the currently selected room availability, we will not select automatically
                    // an available room if any (case when we changed the room in the select, this way the operator can
                    // have the current availability state of the selected Room
                    if (checkSelectedRoom) {
                        var selectedRoomAvailability = _.find(available, function(hash) {
                            return hash.id === $scope.selectedRoom.id;
                        });

                        if(selectedRoomAvailability && selectedRoomAvailability.isAvailable) {
                            $scope.widgetData.roomAvailable = true;
                            $scope.widgetData.roomAvailableName = $scope.roomsSelectionMode.summary;
                            sharedProperties.addChoosenRooms($scope.roomsSelectionMode.id);
                            //$scope.currentlyChoosenRooms.push($scope.roomsSelectionMode.id);
                            $scope.hideNonAvailableMessage();
                        } else {
                            $scope.widgetData.roomAvailable = false;
                            $scope.widgetData.roomAvailableName = undefined;
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
                            $scope.widgetData.roomAvailable = true;
                            $scope.widgetData.roomAvailableName = $scope.selectedRoom.summary;
                            //$scope.currentlyChoosenRooms.push($scope.selectedRoom.id);
                            sharedProperties.addChoosenRooms($scope.selectedRoom.id);
                        } else {
                            $scope.widgetData.roomAvailable = false;
                            $scope.widgetData.roomAvailableName = undefined;
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
            if(room === undefined) {
                $scope.selectedRoom = undefined;
            } else {
                $scope.selectedRoom = _.find($scope.roomsList, function(mR) {
                    return mR.id == room.id;
                });
            }

            //if($scope.selectedRoom && $scope.selectedRoom.id != "auto_room_selection") {
                //$('.create_event_room_selection_select option[value="' + $scope.selectedRoom.id + '"]').prop('selected', 'selected');
                //$('#room_selection_select')
            //}
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

        $scope.setMeetingRoomInfosInNotes = function() {
            var notesNode = $('#notes');
            var notes = notesNode.val();
            var meetingRoomInfos = '';

            if($scope.selectedRoom && $scope.selectedRoom.summary && $scope.attendeesManagerCtrl && $scope.attendeesManagerCtrl.attendees && $scope.attendeesManagerCtrl.attendees.length > 0) {
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

        $scope.init();
    }]);

    app.directive('meetingRoomsManager', function() {
        return {
            restrict: 'E',
            templateUrl: 'meeting-rooms-manager.html',
            controller: 'meetingRoomsController',
            controllerAs: 'meetingRoomsCtrl'
        }
    });

    app.directive('meetingRoomsWidget', function() {
        return {
            restrict: 'E',
            templateUrl: 'meeting-rooms-widget.html',
            scope: {
                widgetData: '=',
                clientsList: '=',
                currentlyChoosenRooms: '=',
                formDisabled: '='
            },
            controller: 'meetingRoomsWidgetController',
            controllerAs: 'meetingRoomsWidgetCtrl'
        }
    });

    function generateGuid() {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }
        return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
            s4() + '-' + s4() + s4() + s4();
    }


    var Class = function(methods) {
        var klass = function() {
            this.initialize.apply(this, arguments);
        };

        for (var property in methods) {
            klass.prototype[property] = methods[property];
        }

        if (!klass.prototype.initialize) klass.prototype.initialize = function(){};

        return klass;
    };

    var Widget = Class({
        initialize: function(targetEmail, initialConfiguration){
            var that = this;

            that.guid = generateGuid();
            that.targetEmail = targetEmail;
            // initialConfiguration is populated with the saved meeting_rooms_details from a previous form save
            that.initialConfiguration = initialConfiguration;
        }
    });
})();
