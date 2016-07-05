(function() {

    var app = angular.module('event-creator-controllers', []);

    app.controller('datesVerificationManager', ['$scope', '$timeout', '$rootScope', function($scope, $timeout, $rootScope) {
        $scope.selectedDateRaw = undefined;
        $scope.rawDatesToCheck = [];
        $scope.datesToCheck = [];
        $scope.datesManager = undefined;
        $scope.selectedDate = undefined;

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

            $scope.attachEventsToDom();
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

            var currentDateUtc, currentDate, formattedDate, dateInOtherTimezones, timezones, data;
            _.each($scope.rawDatesToCheck, function( datum) {

                currentDateUtc = moment(datum.date);
                currentDate = moment(datum.date).tz(window.threadComputedData.timezone);
                formattedDate = currentDateUtc.format();
                dateInOtherTimezones = [];

                timezones = $scope.getUsedTimezones();

                data = {
                    date: formattedDate,
                    timezone: window.threadComputedData.timezone,
                    displayText: currentDate.locale(window.threadComputedData.locale).format(localize("email_templates.common.full_date_format")),
                    isHighlighted: currentDate.isSame(selectedDateMoment),
                    isOutBound: $scope.datesManager.checkSuggestionTimeOutBound(currentDate)
                };

                _.each(timezones, function(timezone) {
                    //if(timezone != window.threadComputedData.timezone) {
                        var currentTimezonedDate = currentDate.tz(timezone);

                        dateInOtherTimezones.push({
                            displayText: currentDate.tz(timezone).locale(window.threadComputedData.locale).format(localize("email_templates.common.full_date_format")),
                            timezone: timezone,
                            isOutBound: $scope.datesManager.checkSuggestionTimeOutBound(currentTimezonedDate)
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

        $scope.listenToEvents = function() {
            $scope.datesManager = $scope.getDatesManagerApp();

            if(!!$scope.datesManager) {
                $scope.datesManager.getAttendeesApp().$on('attendeesFetched', $scope.attendeesRefreshedActions);
            }
        };

        $scope.attendeesRefreshedActions = function() {
            $scope.init();
            if(!$scope.$$phase)
                $scope.$apply();
        };

        angular.element(document).ready(function() {
            $scope.listenToEvents();
        });

    }]);

})();