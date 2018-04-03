(function() {

    var app = angular.module('event-creator-controllers', []);

    app.controller('datesVerificationManager', ['$scope', '$timeout', '$rootScope', function($scope, $timeout, $rootScope) {
        $scope.selectedDateRaw = undefined;
        $scope.rawDatesToCheck = [];
        $scope.datesToCheck = [];
        $scope.datesManager = undefined;
        $scope.accountsManager = undefined;
        $scope.selectedDate = undefined;

        $scope.hasDateOutOfBounds = false;

        $scope.doNotAskSuggestionsMode = false;

        $scope.verifiedDatesByAi = angular.copy(window.verifiedDatesByAi);
        $scope.aiDatesVerificationIsActive = window.featuresHelper.isFeatureActive('ai_dates_verification');
        $scope.aiDatesSuggestionsIsActive = window.featuresHelper.isFeatureActive('ai_dates_suggestions');

        $scope.meetingRoomsAvailabilities = [];
        $scope.canDisplayMeetingRoomsAvailabilities = false;

        $scope.attendeesManagerReady = false;
        $scope.accountsManagerReady = false;


        $scope.$watch('selectedDateRaw', function(newVal, oldVal) {
            if(newVal != oldVal) {
                // We will listen to this event in the meeting rooms manager to check for the rooms disponibilities
                $scope.$emit('datesVerifNewSelectedDate', newVal);
            }
        });

        $scope.init = function() {
            $scope.setRawDatesFromData();
            if($scope.rawDatesToCheck.length > 0) {
                $scope.addDatesToCheck();
                $scope.selectedDateRaw = $scope.datesToCheck[0].date;
            }

            if($scope.aiDatesVerificationIsActive && $scope.aiShouldCreateEvent()) {
                $scope.createEventIfNecessary();
            }

            $scope.attachEventsToDom();
        };

        $scope.reset = function() {
            $scope.datesToCheck = [];
            $scope.selectedDateRaw = undefined;
            $scope.rawDatesToCheck = [];
            $scope.selectedDate = undefined;
        };

        $scope.displayMeetingRoomsAvailabilities = function(roomsAvailabilities) {
            $scope.noMeetingRoomsAvailable = false;

            $scope.meetingRoomsAvailabilities = roomsAvailabilities;

            $scope.canDisplayMeetingRoomsAvailabilities = $scope.meetingRoomsAvailabilities && $scope.meetingRoomsAvailabilities.length > 0;

            if($scope.canDisplayMeetingRoomsAvailabilities && _.any($scope.meetingRoomsAvailabilities, function(availabilitiesDetails) {
                return availabilitiesDetails.isAvailable !== undefined && !availabilitiesDetails.isAvailable;
            })) {
                $scope.noMeetingRoomsAvailable = true;
            }
        };

        $scope.showAiNoDatesValidated = function() {
            // It is undefined when no dates where submitted to the AI
          return $scope.aiDatesVerificationIsActive && ($scope.verifiedDatesByAi && ($scope.verifiedDatesByAi.no_suitable_dates || $scope.verifiedDatesByAi.error_response));
        };

        $scope.aiShouldCreateEvent = function() {
            return (!window.currentEventTile &&
                $scope.verifiedDatesByAi &&
                $scope.verifiedDatesByAi.verified_dates &&
                $scope.verifiedDatesByAi.verified_dates.length > 0);
        };

        $scope.createEventIfNecessary = function() {
            var now = moment();
            var filteredDates = _.filter(window.verifiedDatesByAi.verified_dates, function(date) {
               return moment(date).isAfter(now);
            });

            if(filteredDates.length > 0) {
                var selectedDate = filteredDates[0];
                var roomsToBook = [];

                $scope.selectedDateRaw = selectedDate;

                // Retro-compatibility, the parameter used to be called meetingRoomsToBook, but was changed to meeting_rooms_to_book to fit Ruby conventions
                $scope.verifiedDatesByAi.meeting_rooms_to_book = $scope.verifiedDatesByAi.meeting_rooms_to_book || $scope.verifiedDatesByAi.meetingRoomsToBook;

                if($scope.verifiedDatesByAi.meeting_rooms_to_book)
                    roomsToBook = $scope.verifiedDatesByAi.meeting_rooms_to_book[selectedDate];

                if(roomsToBook && roomsToBook.length > 0) {
                    var meetingRoomsManager = $('#meeting-rooms-manager').scope();
                    var meetingRoomsDetails = [];
                    meetingRoomsManager.usingMeetingRoom = true;
                    var accounts = $('#accounts-list-section').scope().accounts
                    var allAddresses = _.flatten(_.map(accounts, function(acc) {
                        var clonedAddrs = JSON.parse(JSON.stringify(acc.addresses))
                        _.each(clonedAddrs, function(addr) { addr.accountEmail = acc.email; })

                        return clonedAddrs
                    }));

                    _.each(roomsToBook, function(roomToBook) {
                        var currentRoom;
                        var currentRoomLocation = _.find(allAddresses, function(addr) {
                            currentRoom = _.find(addr.available_meeting_rooms, function(room) {
                                return room.id == roomToBook;
                            });
                            return currentRoom;
                        });

                        meetingRoomsDetails.push({
                            attendees_count_for_meeting_room: '1',
                            client: currentRoomLocation.accountEmail,
                            location: currentRoomLocation.address,
                            room_selection_mode: $.extend(true, {}, currentRoom),
                            selected_meeting_room: $.extend(true, {}, currentRoom)
                        });
                    });

                    window.threadComputedData.meeting_room_details = meetingRoomsDetails;

                    meetingRoomsManager.initialize(accounts);
                    meetingRoomsManager.$apply();

                    // Manually force the room availability for each widgets to true, so it will be picked up by the formatEventMeetingRoomDetails() method
                    // on the meeting rooms manager
                    _.each(meetingRoomsManager.widgets, function(widget) {
                       widget.roomAvailable = true;
                    });
                }

                window.createEventButtonClickHandler({forceTimezone: window.verifiedDatesByAi.timezone, createdFromAI: true});
            }
        };
        
        $scope.setRawDatesFromData = function() {
            var data = $('.suggested-date-times').data('date-times');

            $scope.rawDatesToCheck = [];
            _.each(data, function(date) {
               $scope.rawDatesToCheck.push($.extend({}, date));
            });
        };

        $scope.addRawDateToCheck = function(date) {
            $scope.setRawDatesFromData();
            $scope.rawDatesToCheck.push(date);
            $scope.rawDatesToCheck = _.uniq($scope.rawDatesToCheck, function(date) {
                return moment(date.date).format();
            });
        };

        $scope.addNewDateToVerify = function(date) {
            $scope.addRawDateToCheck(date);
            $scope.selectedDateRaw = date.date;

            $scope.addDatesToCheck();
        };

        $scope.onMainTimezoneChange = function(selection) {
            window.threadComputedData.timezone = selection.value;
            $('#dates_suggestion_timezone').val(window.threadComputedData.timezone);
            $scope.addTimezoneToCurrentCalendar(selection.value);
            $scope.addDatesToCheck();
            $scope.selectSuggestedDateInCalendar();
        };

        $scope.addTimezoneToCurrentCalendar = function(timezone) {
            window.currentCalendar.initialData.additional_timezone_ids.push(timezone);
            window.currentCalendar.redrawTimeZoneSelector();
            window.currentCalendar.selectTimezone(timezone, true);
        };

        $scope.eventActionsDisabled = function() {
            return $scope.datesToCheck.length == 0;
        };

        $scope.attachEventsToDom = function() {
            $('#event_creation_timezone').timezonePicker({
                onSelectCallback: $scope.onMainTimezoneChange
            });

            $('.suggested-date-times').on('click', '.suggested-date-time', function(e) {
                var dateTime = $(this).data("date");
                if (dateTime) {
                    window.currentCalendar.selectSuggestedEvent(dateTime);
                }
                $scope.selectedDateRaw = dateTime;
            });
        };

        $scope.getUsedTimezones = function() {
            return $scope.datesManager.getUsedTimezones();
        };

        $scope.addDatesToCheck = function() {
            $scope.datesToCheck = [];
            var selectedDateMoment = moment($scope.selectedDateRaw);
            $scope.hasDateOutOfBounds = false;

            var currentDateUtc, currentDate, formattedDate, dateInOtherTimezones, timezones, data;
            _.each($scope.rawDatesToCheck, function(datum) {

                currentDateUtc = moment(datum.date);
                currentDate = moment(datum.date).tz(window.threadComputedData.timezone);
                formattedDate = currentDateUtc.format();
                dateInOtherTimezones = [];

                timezones = $scope.getUsedTimezones();
                var dateIsOutOfBounds = $scope.datesManager.checkSuggestionTimeOutBound(currentDate);

                if(dateIsOutOfBounds) {
                    $scope.hasDateOutOfBounds = true;
                }

                data = {
                    date: formattedDate,
                    timezone: window.threadComputedData.timezone,
                    displayText: currentDate.locale(window.threadComputedData.locale).format(localize("email_templates.common.full_date_format")),
                    isHighlighted: currentDate.isSame(selectedDateMoment),
                    isOutBound: dateIsOutOfBounds,
                    // We may want to hide the date in the list because of reasons (i.e in the do_not_ask_suggestions_mode)
                    hide: datum.hide
                };

                _.each(timezones, function(timezone) {
                    //if(timezone != window.threadComputedData.timezone) {
                    var currentTimezonedDate = currentDate.tz(timezone);
                    var dateIsOutOfBoundsForTimezone = $scope.datesManager.checkSuggestionTimeOutBound(currentTimezonedDate);

                    if(dateIsOutOfBoundsForTimezone) {
                        $scope.hasDateOutOfBounds = true;
                    }

                    dateInOtherTimezones.push({
                        displayText: currentDate.tz(timezone).locale(window.threadComputedData.locale).format(localize("email_templates.common.full_date_format")),
                        timezone: timezone,
                        isOutBound: dateIsOutOfBoundsForTimezone
                    });
                    //}

                });

                data['dateInOtherTimezones'] = dateInOtherTimezones;

                if(data.isHighlighted) {
                    $scope.selectedDate = data;
                }

                $scope.datesToCheck.push(data);
            });

            if(!$scope.$$phase)
                $scope.$apply();

        };

        $scope.selectSuggestedDateInCalendar = function() {
            $timeout( function() {
                window.currentCalendar.selectSuggestedEvent($scope.selectedDateRaw);
            }, 0);
        };

        window.allCalendarEventsFetched = function() {

            if(!window.currentCalendar.firstLoaded) {
                window.currentCalendar.firstLoaded = true;
                $scope.selectSuggestedDateInCalendar();
            }
        };

        $scope.getDatesManagerApp = function() {
            return $('#dates-suggestion-manager').scope();
        };

        $scope.getAccountsApp = function() {
          return $('#accounts-list-section').scope();
        };

        $scope.listenToEvents = function() {
            $scope.datesManager = $scope.getDatesManagerApp();
            $scope.accountsManager = $scope.getAccountsApp();

            if(!!$scope.datesManager) {
                $scope.datesManager.getAttendeesApp().$on('attendeesFetched', function() {
                    $scope.attendeesManagerReady = true;
                    $scope.initApp();
                });
            }
            if(!!$scope.accountsManager) {
                $scope.accountsManager.$on('allAccountsFetched', function() {
                    $scope.accountsManagerReady = true;
                    $scope.initApp();
                });
            }
        };

        $scope.initApp = function() {
            if($scope.accountsManagerReady && $scope.attendeesManagerReady) {
                $scope.init();
                if(!$scope.$$phase)
                    $scope.$apply();
            }
        };

        angular.element(document).ready(function() {
            $scope.listenToEvents();
        });

    }]);

})();