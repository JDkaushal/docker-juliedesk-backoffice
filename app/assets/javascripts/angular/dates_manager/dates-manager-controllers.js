(function() {

    var app = angular.module('dates-manager-controllers', []);

    app.controller('datesSuggestionsManager', ['$scope', 'attendeesService', function($scope, attendeesService) {
        $scope.timeSlotsSuggestions = {};
        $scope.usedTimezones = undefined;
        $scope.allUsedTimezones = undefined;
        $scope.outBoundSuggestionsCount = 0;
        $scope.displayDatesSuggestionManager = false;

        $scope.init = function() {
            $scope.attachEventsToDom();
        };

        $scope.onMainTimezoneChange = function(selection) {
            window.threadComputedData.timezone = selection.value;
            $('#event_creation_timezone').val(window.threadComputedData.timezone);
            $scope.addTimezoneToCurrentCalendar(selection.value);
            $scope.setSuggestions();
        };

        $scope.nextButtonClickAction = function(e) {
            $(".calendar-container").addClass("minimized");
            $('.email.extended').removeClass('extended');
            $(".left-column").animate({scrollTop: $(".reply-box").position().top + 30}, 300);
        };

        $scope.attachEventsToDom = function() {
            $('#dates_suggestion_timezone').timezonePicker({
                onSelectCallback: $scope.onMainTimezoneChange
            });

            $(".time-slots-to-suggest-list-container").on('click', '.suggest-dates-next-button', $scope.nextButtonClickAction);
        };

        $scope.getTimeSlotsSuggestionsForTemplate = function() {
            var result = [];
            var tmpResult = [];
            var subResult = {};
            var clientTimezoneGroupedDates = {};
            var clientTimezoneDates = _.map($scope.timeSlotsSuggestions[window.threadComputedData.timezone], function(timeSlot) { return timeSlot.value ; });

            clientTimezoneGroupedDates = _.groupBy(clientTimezoneDates, function(timeSlot) {
                return timeSlot.format('YYYY-MM-DD');
            });

            var currentIndex, currentSlot;
            _.each(clientTimezoneGroupedDates, function(timeSlots, date) {
                subResult = {};
                _.each(timeSlots, function(timeSlot) {
                    currentIndex = clientTimezoneDates.indexOf(timeSlot);

                    _.each($scope.allUsedTimezones, function(timezone) {

                        currentSlot = $scope.timeSlotsSuggestions[timezone][currentIndex].value;
                        if(!subResult[timezone]) {
                            subResult[timezone] = [currentSlot];
                        } else {
                            subResult[timezone].push(currentSlot);
                        }

                    });
                });
                tmpResult.push(subResult);
            });

            var currentDay;
            subResult = {};
            var indexTouched = [];
            // Timezone choosen to act as a default timezone
            // Used to for example get the number of propositions done in general (as it is the same for all timezones
            // Choosen arbitrary (the first one)
            var referenceTimezone = $scope.allUsedTimezones[0];
            var tmpSlotProp = {};
            var resultToAdd = {};
            var indexToSlice;
            //console.log(tmpResult);

            _.each(tmpResult, function(slotProposition) {
                // Allow destructive manipulation without affecting the main object (we are using slice)
                tmpSlotProp = $.extend(true, {}, slotProposition);
                // Get the number of slots for this proposition
                // Each timezone will have the same number of propositions
                var slotsNumber = slotProposition[referenceTimezone].length;

                _.each($scope.allUsedTimezones, function(timezone) {
                    var propositionInTimezone = slotProposition[timezone];
                    //previousDay = null;
                    currentDay = moment(propositionInTimezone[0]);

                    for(var i=0; i<slotsNumber; i++) {

                        //console.log(currentDay.format());
                        if(indexTouched.indexOf(i) == -1){
                            if(!moment(propositionInTimezone[i]).isSame(currentDay, 'day')) {
                                //console.log(propositionInTimezone[i]);
                                subResult = {};
                                _.each($scope.allUsedTimezones, function(timezone) {
                                    // We remove the slot from each timezone and add it to the subResult
                                    indexToSlice = tmpSlotProp[timezone].indexOf(slotProposition[timezone][i]);
                                    tmpSlotProp[timezone].splice(indexToSlice, 1);
                                    subResult[timezone] = [slotProposition[timezone][i]];
                                });
                                resultToAdd[i] = subResult;
                                indexTouched.push(i);
                            }
                        }

                        //previousDay = currentDay;
                    }

                    //console.log('---');
                });

                if(tmpSlotProp[referenceTimezone].length > 0) {
                    result.push(tmpSlotProp);
                }

                //console.log(resultToAdd);
                resultToAdd  = _.compact(_.flatten(_.map(resultToAdd, function(v, _){ return v})));
                //console.log(resultToAdd);

                result = result.concat(resultToAdd);
                resultToAdd = [];
                indexTouched = [];
            });
            //console.log(result);
            return result;
        };

        $scope.addTimezoneToCurrentCalendar = function(timezone) {
            currentCalendar.initialData.additional_timezone_ids.push(timezone);
            currentCalendar.redrawTimeZoneSelector();
            currentCalendar.selectTimezone(timezone, true);
        };

        $scope.clearPreviousSuggestions = function() {
            $scope.timeSlotsSuggestions = {};
            $scope.outBoundSuggestionsCount = 0;
        };

        $scope.displayOutBoundCount = function() {
            return $scope.outBoundSuggestionsCount > 0;
        };

        $scope.setSuggestions = function() {
            $scope.clearPreviousSuggestions();

            var suggestions = window.timeSlotsToSuggest.slice(0);

            if(suggestions.length > 0) {
                $scope.displayDatesSuggestionManager = true;

                var timezones = $scope.getUsedTimezones();

                _.each(timezones, function(timezone) {
                    $scope.timeSlotsSuggestions[timezone] = [];
                    _.each(suggestions, function(suggestion) {
                        $scope.timeSlotsSuggestions[timezone].push( $scope.addTimeSlotSuggestion(timezone, suggestion) );
                    });
                });
            } else {
                $scope.displayDatesSuggestionManager = false;
            }

            if(!$scope.$$phase)
                $scope.$apply();
        };

        $scope.addTimeSlotSuggestion = function(timezone, suggestion) {
            suggestion = moment(suggestion).tz(timezone);

            var suggestionDisplayText = window.helpers.capitalize(suggestion.locale(window.threadComputedData.locale).format(localize("email_templates.common.full_date_format")));

            var suggestionData = {
                value: suggestion,
                displayText: suggestionDisplayText,
                isOutBound: false
            };

            if($scope.checkSuggestionTimeOutBound(suggestion)) {
                suggestionData.isOutBound = true;
                $scope.outBoundSuggestionsCount += 1;
            }

            return suggestionData;
        };

       $scope.getAppointmentWorkingHours = function() {
         return {
             start: [8, 0],
             end: [21, 0]
         }
       };

        $scope.checkSuggestionTimeOutBound = function(suggestion) {
            var hour = suggestion.hour();
            var minutes = suggestion.minute();
            var timeBoundaries = $scope.getAppointmentWorkingHours();

            var lowerOutBound = hour < timeBoundaries.start[0] || (hour == timeBoundaries.start[0] && minutes < timeBoundaries.start[1]);
            var higherOutBound = hour > timeBoundaries.end[0] || (hour == timeBoundaries.end[0] && minutes > timeBoundaries.end[1]);

            return lowerOutBound || higherOutBound;
        };

        $scope.getUsedTimezones = function() {
             //Allow to refresh the thread timezone if it was updated
            //$scope.allUsedTimezones = [window.threadComputedData.timezone];
            //
            //if(window.threadComputedData.is_virtual_appointment) {
            //    if(!$scope.usedTimezones) {
            //        $scope.usedTimezones = attendeesService.getUsedTimezones().allUsedTimezones;
            //    }
            //
            //    if($scope.usedTimezones.length > 0) {
            //        $scope.allUsedTimezones = _.uniq($scope.allUsedTimezones.concat($scope.usedTimezones));
            //    }
            //}else {
            //    $scope.usedTimezones = [];
            //}
            //
            //return $scope.allUsedTimezones;
            var result = attendeesService.getUsedTimezones();

            if(result) {
                $scope.usedTimezones = result.usedTimezones;
                $scope.allUsedTimezones = result.allUsedTimezones;
            }


            return $scope.allUsedTimezones;
        };

        $scope.getAttendeesApp = function() {
            return attendeesService.getAttendeesApp();
        };

        $scope.init();
    }]);

    app.controller('datesIdentificationsManager', ['$scope', 'attendeesService', 'messageInterpretationsService', function($scope, attendeesService, messageInterpretationsService) {
        $scope.datesToIdentify = [];
        $scope.usedTimezones = [];
        $scope.selectedTimezone = undefined;
        $scope.showAlreadySuggestedArea = true;
        $scope.showDetectedDatesArea = false;
        $scope.loading = false;

        $scope.aiDatesToCheck = [];

        $scope.init = function() {
            $scope.getUsedTimezones();
            $scope.selectCorrectTimezone();
            $scope.setAiDatesToCheck();
            $scope.getDatesToIdentify();

            $scope.loading = false;
            if(!$scope.$$phase)
                $scope.$apply();

            if(window.datesIdentificationManageInitiatedCallback) {
                window.datesIdentificationManageInitiatedCallback();
            }
        };

        $scope.setAiDatesToCheck = function() {
            var mainInterpretation = messageInterpretationsService.getMainInterpretation();

            if(mainInterpretation) {
                $scope.aiDatesToCheck = _.map(mainInterpretation.dates_to_check, function(date) {
                    return moment(date);
                });
            }
        };

        $scope.showAlreadySuggestedDates = function() {
            $scope.showAlreadySuggestedArea = true;
            $scope.showDetectedDatesArea = false;
        };

        $scope.showDetectedDates = function() {
            $scope.showAlreadySuggestedArea = false;
            $scope.showDetectedDatesArea = true;
            $(".detected-dates-container").show();
        };

        $scope.getDatesToIdentify = function() {

            if(!!$scope.selectedTimezone) {

                var data = $('#dates-identifications-manager').data('dates-to-identify');

                $scope.datesToIdentify = [];
                _.each(data, function(date) {
                    // Create a clone of the object so modifications on it does not affect the original
                    $scope.datesToIdentify.push($.extend({}, date));
                });

                $scope.datesToIdentify = _.uniq($scope.datesToIdentify, function(date) {
                    return date.date;
                });

                $scope.computeDataOnDatesToIdentify();
            }
        };

        $scope.computeDataOnDatesToIdentify = function() {
            var currentTimezonedDate;

            _.each($scope.datesToIdentify, function(date) {
                currentTimezonedDate = moment(date.date).tz($scope.selectedTimezone);

                date['displayText'] = currentTimezonedDate.locale(window.threadComputedData.locale).format(localize("email_templates.common.full_date_format"));
                date['timezone'] = $scope.selectedTimezone;

                _.every($scope.aiDatesToCheck, function(dateToCheck) {
                    if(currentTimezonedDate.isSame(dateToCheck)) {
                        // We trigger the change event to undisable the "Oui" button in the suggestion date pannel
                        date['selected'] = true;
                        return false;
                    }
                    return true;
                });
            });
        };

        $scope.selectCorrectTimezone = function() {
            if(window.emailSender) {
                var emailSender = window.emailSender();

                if(emailSender) {
                    emailSender = emailSender.name;
                }

                var emailSenderAttendee = attendeesService.getAttendeeByEmail(emailSender);
                if(emailSenderAttendee) {
                    var selectedTimezone = emailSenderAttendee.timezone;

                    if(emailSenderAttendee.isThreadOwner) {
                        // We do it because the default timezone of the thread owner can be different from the one set for the Thread,
                        // we assume that the timezone of the thread is the timezone of the client for this appointment
                        selectedTimezone = window.threadComputedData.timezone;
                    } else if(emailSenderAttendee.isAssistant) {
                        // When the attendee is an assistant we are gonna take the timezone of the person he is assisting
                        var assisted = attendeesService.getAssisted(emailSenderAttendee);

                        if(assisted) {
                            selectedTimezone = assisted.timezone;
                        }
                    }

                    $scope.selectedTimezone = selectedTimezone;

                    //$scope.setTimezoneOnAppointment();
                }

            }
        };

        $scope.getUsedTimezones = function() {
            $scope.usedTimezones = attendeesService.getUsedTimezones().allUsedTimezones;
        };

        $scope.getSelectedDatesToIdentify = function() {
            var selectedDates = _.filter($scope.datesToIdentify, function(date) {
                return date.selected;
            });

            var timezone = window.threadComputedData.timezone;
            var currentLocale = window.threadComputedData.locale;
            var currentTimezonedDate;

            selectedDates = _.each(selectedDates, function(date) {
                date.timezone = timezone;
                currentTimezonedDate = moment(date.date).tz(timezone);
                date.date_with_timezone = currentTimezonedDate;
                //date.displayText = currentTimezonedDate.locale(currentLocale).format(localize("email_templates.common.full_date_format"));
            });

            return selectedDates;
        };

        $scope.nextButtonDisabled = function() {
          var selectedDates = $scope.getSelectedDatesToIdentify();

          return selectedDates && selectedDates.length == 0;
        };

        $scope.setTimezoneOnAppointment = function() {
            $('#timezone').val($scope.selectedTimezone);
        };

        $scope.listenToAttendeesAppEvents = function() {
            $scope.loading = true;
            $scope.$apply();

            var attendeesApp = attendeesService.getAttendeesApp();

            if(!!attendeesApp) {
                attendeesApp.$on('attendeesFetched', function(event, args) {
                    $scope.init();
                });
            }
        };

        angular.element(document).ready(function() {
            $scope.listenToAttendeesAppEvents();
        });

    }])
})();