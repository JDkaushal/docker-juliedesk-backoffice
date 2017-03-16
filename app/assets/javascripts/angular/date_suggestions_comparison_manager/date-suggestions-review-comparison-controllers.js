(function () {

    var app = angular.module('date-suggestions-comparison-manager-controllers', ['angularMoment', 'commonDirectives', 'commonServices']);


    app.directive('constraintTile', function () {
        function link(scope, element, attrs) {
            new ConstraintTile(
                $(element),
                {
                    data: scope.constraint,
                    readOnly: true
                }
            );
        }

        return {
            restrict: 'A',
            link: link
        }
    });

    app.controller("date-suggestions-errors-list-controller", ['$scope', 'moment', '$http', 'conscienceApi', function ($scope, moment, $http, conscienceApi) {
        $scope.now = moment();
        $scope.start = $scope.now.clone().startOf('isoWeek');
        $scope.eventType = "call";


        $scope.previousWeekStart = function() {
            return $scope.start.clone().add(-7, 'd');
        };

        $scope.nextWeekStart = function() {
            return $scope.start.clone().add(7, 'd').startOf('isoWeek');
        };
        $scope.shouldShowNextWeek = function() {
            return $scope.end() < $scope.now.clone();
        };

        $scope.goToWeek = function(mDate) {
            $scope.start = mDate;
            $scope.fetch();
        };

        $scope.end = function(mDate) {
            if(!mDate) {
                mDate = $scope.start;
            }
            var end = mDate.clone().endOf("isoWeek");
            return end > $scope.now ? $scope.now : end;
        };


        $scope.fetch = function() {
            $scope.loading = true;
            conscienceApi.suggestedDatesListErrorsRequest({
                start: $scope.start.format(),
                end: $scope.end().format(),
                event_type: $scope.eventType
            }).then(function(response) {
                $scope.loading = false;
                $scope.errors = response.data.data.suggested_dates;
                $scope.totalCount = response.data.data.total_count;
                $scope.errorsCount = response.data.data.errors_count;
                _.each($scope.errors, function(error) {
                   error.date = moment(error.date);
                });
            });
        };

        $scope.fetch();
    }]);

    app.controller("date-suggestions-comparison-controller", ['$scope', 'moment', '$http', 'conscienceApi', function ($scope, moment, $http, conscienceApi) {


        $scope.fetchFromConscience = function() {
            $scope.loading['conscience'] = true;
            conscienceApi.suggestedDatesDetailsRequest({
                julie_action_id: $scope.julieActionId
            }).then(function(response) {
                delete $scope.loading['conscience'];
                $scope.conscienceDateSuggestions = _.map(response.data.data.suggested_date.status, function(status) {
                    var dateStringKey = _.keys(status)[0];
                    return {
                        date: moment(dateStringKey),
                        status: status[dateStringKey]
                    }
                });
                $scope.activateCalendarIfReady();
            });
        };

        $scope.suggestedDatesOther = function() {
            return _.filter($scope.suggestedDates, function(suggestionDate) {
                return !_.find($scope.conscienceDateSuggestions, function(conscienceDateSuggestion) {
                    return conscienceDateSuggestion.date.format() == suggestionDate.date.format();
                });
            });
        };

        $scope.correctConscienceDateSuggestions = function() {
            return _.filter($scope.conscienceDateSuggestions, function(dateSuggestionHash) {
               return dateSuggestionHash.status == true;
            });
        };

        $scope.notCorrectConscienceDateSuggestions = function() {
            return _.filter($scope.conscienceDateSuggestions, function(dateSuggestionHash) {
                return dateSuggestionHash.status != true;
            });
        };

        $scope.init = function(params) {
            $scope.julieActionId = params.julie_action_id;
            $scope.saving = false;
            $scope.loading = {};
            $scope.fetchData();
            $scope.fetchFromConscience();

        };
        $scope.activateCalendarWithParams = function (calendarParams) {
            calendarParams.height = $(".calendar-container").height();
            calendarParams.default_calendar_login_username = calendarParams.email;
            calendarParams.default_calendar_login_type = "google";

            calendarParams.forcedInitialStartDate = calendarParams.forcedInitialStartDate;
            calendarParams.mode = "review";
            calendarParams.dontTrackRequests = true;

            window.currentCalendar = new Calendar($(".calendar-container"), calendarParams);
            $(".calendar-container").addClass("visible");
        };


        $scope.fetchData = function () {
            $scope.loading['backoffice'] = true;
            $http.get("/review/julie_actions/" + $scope.julieActionId + "/compare_date_suggestions.json").then(function (response) {
                delete $scope.loading['backoffice'];

                data = response.data.data;

                $scope.dateSuggestionsSetErrors = data.set_errors;


                $scope.accountEmail = data.account_email;
                $scope.otherAccountEmails = data.other_account_emails;
                $scope.currentNotes = data.other_notes;
                $scope.duration = data.duration;
                $scope.eventType = data.event_type;
                $scope.location = data.location;
                $scope.constraints = data.constraints_data;
                $scope.date = data.date;


                window.otherAttendeesWithAccount = _.filter($scope.attendees, function (attendee) {
                    return attendee.isPresent && attendee.isClient && attendee.accountEmail && attendee.accountEmail != threadAccountEmail;
                });

                $scope.suggestedDates = _.map(data.date_suggestions, function(dateSuggestion) {
                    errors = [];
                    customError = "";
                    var dateFormattedForRuby =moment(dateSuggestion.date).utc().format("YYYY-MM-DDTHH:mm:ss") + ".000Z";
                    if(data.items_errors && data.items_errors[dateFormattedForRuby] && data.items_errors[dateFormattedForRuby].errors) {
                        errors = data.items_errors[dateFormattedForRuby].errors;
                        customError = data.items_errors[dateFormattedForRuby].custom_error;
                    }
                  return {
                      date: moment(dateSuggestion.date),
                      timezone: dateSuggestion.timezone
                  }
                });

                $scope.allTimezones = _.uniq(_.map(data.date_suggestions, function(dateSuggestion) {
                    return dateSuggestion.timezone;
                }));
                $scope.mainTimezone = $scope.allTimezones[0];





                $scope.activateCalendarIfReady();
            }, function(response) {
                if(response.status == 404) {
                    $scope.loading = false;
                    $scope.error = true;
                }
            });
        };

        $scope.isLoading = function() {
            return !_.isEmpty($scope.loading);
        };

        $scope.activateCalendarIfReady = function() {
            if(_.isEmpty($scope.loading)) {
                var firstDate = _.min(_.map($scope.suggestedDates, function(dateSuggestion) {
                    return dateSuggestion.date;
                }));
                $scope.activateCalendarWithParams({
                    email: $scope.accountEmail,
                    date_times: $scope.generateDateTimesForCalendar(),
                    dontShowMinimizeButton: true,
                    duration: $scope.duration,
                    default_timezone_id: $scope.mainTimezone,
                    additional_timezone_ids: $scope.allTimezones,
                    as_at_date: $scope.date,
                    forcedInitialStartDate: firstDate,
                    now: $scope.date,
                    constraintsData: _.groupBy($scope.constraints, function(constraint) {
                        return constraint.attendee_email;
                    }),
                    computeConstraintsViaBackend: true,
                    other_emails: $scope.otherAccountEmails
                });
            }

        };



        $scope.reloadCalendarSuggestionsColors = function () {
            window.currentCalendar.initialData.date_times = $scope.generateDateTimesForCalendar();
            window.currentCalendar.reloadEventsToCheck();
        };

        $scope.generateDateTimesForCalendar = function () {

            var datesFromConscience = _.map($scope.conscienceDateSuggestions, function(dateSuggestion) {
                var color;
                var textColor;
                if(dateSuggestion.status == true) {
                    color = "#9013FE";
                    textColor = "#fff";
                }
                else if(dateSuggestion.status == "moved" || dateSuggestion.status == "removed") {
                    color = "rgba(144, 19, 254, 0.4)";
                    textColor = "#000";
                }
                else if(dateSuggestion.status == false) {
                    color = "rgba(144, 19, 254, 0.2)";
                    textColor = "#000";
                }
                return {
                    date: dateSuggestion.date.format(),
                    color: color,
                    textColor: textColor,
                    customHtml: document.getElementById("event-to-check-for-calendar-html-in-review").innerHTML
                };
            });
            var datesFromOperator = _.map($scope.suggestedDatesOther(), function (dateSuggestion) {

                return {
                    date: dateSuggestion.date.format(),
                    color: "#0099CC",
                    textColor: "#fff",
                    customHtml: document.getElementById("event-to-check-for-calendar-html-in-review").innerHTML
                };
            });

            return datesFromOperator.concat(datesFromConscience);
        };
    }]);


    app.filter('capitalize', function () {
        return function (input) {
            return (!!input) ? input.charAt(0).toUpperCase() + input.substr(1).toLowerCase() : '';
        }
    });
})();