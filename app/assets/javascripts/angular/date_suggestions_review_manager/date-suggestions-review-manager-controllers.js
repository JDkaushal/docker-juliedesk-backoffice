(function () {

    var app = angular.module('date-suggestions-review-manager-controllers', ['angularMoment', 'commonDirectives']);


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

    app.controller("date-suggestions-review-manager-controller", ['$scope', 'moment', '$http', function ($scope, moment, $http) {

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
            $http.get(window.dateSuggestionReviewId + ".json").then(function (response) {

                $scope.loading = false;
                data = response.data.data;

                $scope.dateSuggestionsSetErrors = data.set_errors;


                $scope.accountEmail = data.account_email;
                $scope.currentNotes = data.other_notes;
                $scope.duration = data.duration;
                $scope.eventType = data.event_type;
                $scope.location = data.location;
                $scope.constraints = data.constraints_data;
                $scope.date = data.date;
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
                      errors: errors,
                      customError: customError
                  }
                });

                $scope.allTimezones = _.uniq(_.map(data.date_suggestions, function(dateSuggestion) {
                    return dateSuggestion.timezone;
                }));
                $scope.mainTimezone = $scope.allTimezones[0];

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
                    forcedInitialStartDate: firstDate
                });
            }, function(response) {
                if(response.status == 404) {
                    $scope.loading = false;
                    $scope.error = true;
                }
            });
        };


        $scope.possibleDateSuggestionsSetErrors = {
            days_repartition: {
                label: "Mauvaise répartition des jours"
            },
            morning_afternoon_repartition: {
                label: "Mauvaise répartition matin/après midi"
            },
            hours_repartition: {
                label: "Mauvaise répartition des heures"
            },
            wrong_time_for_event_type: {
                label: "Horaire dédié à cet event type non utilisé"
            },
            current_notes: {
                label: "Non prise en compte des notes"
            },
            other: {
                label: "Autre"
            }
        };


        $scope.possibleDateSuggestionErrors = {
            conflict_none_all_day: {
                label: "Conflit - none all-day"
            },
            conflict_all_day: {
                label: "Conflit - all-day"
            },
            constraints: {
                label: "Non respect des contraintes"
            },
            delays: {
                label: "Non respect des délais entre events"
            },
            wrong_time_for_event_type: {
                label: "Horaire non conforme au type d’event"
            },
            timezones: {
                label: "Problème de timezones"
            },
            other: {
                label: "Autre"
            }
        };

        $scope.dateSuggestionsSetErrors = [];
        $scope.addDateSuggestionsSetError = function (errorId) {
            if ($scope.dateSuggestionsSetErrors.indexOf(errorId) == -1) {
                $scope.dateSuggestionsSetErrors.push(errorId);
            }
        };
        $scope.removeDateSuggestionsSetErrors = function (errorId) {
            $scope.dateSuggestionsSetErrors.splice($scope.dateSuggestionsSetErrors.indexOf(errorId), 1);
        };

        $scope.addDateSuggestionError = function (errorId, date) {
            if (date.errors.indexOf(errorId) == -1) {
                date.errors.push(errorId);
            }
            $scope.reloadCalendarSuggestionsColors();
        };

        $scope.removeDateSuggestionError = function (errorId, date) {
            date.errors.splice(date.errors.indexOf(errorId), 1);
            $scope.reloadCalendarSuggestionsColors();
        };

        $scope.anyError = function () {
            return _.find($scope.suggestedDates, function (dateSuggestion) {
                return dateSuggestion.errors.length > 0;
            });
        };

        $scope.reloadCalendarSuggestionsColors = function () {
            window.currentCalendar.initialData.date_times = $scope.generateDateTimesForCalendar();
            window.currentCalendar.reloadEventsToCheck();
        };

        $scope.generateDateTimesForCalendar = function () {
            return _.map($scope.suggestedDates, function (dateSuggestion) {
                return {
                    date: dateSuggestion.date.format(),
                    color: dateSuggestion.errors.length > 0 ? "#F15B5B" : "#93D8C7",
                    customHtml: document.getElementById("event-to-check-for-calendar-html-in-review").innerHTML
                };
            });
        };

        $scope.validateReview = function() {
            $scope.saving = true;
            $http.post("" + window.dateSuggestionReviewId, {
                set_errors: $scope.dateSuggestionsSetErrors,
                items_errors: $scope.suggestedDates
            }).then(function(response) {
                window.location = window.location.href;
            }, function(response) {
                $scope.saving = false;
            });
        };

        document.addEventListener("clickOnDateSuggestionAddErrorButtonInReviewMode", function (e) {
            var selectedDateSuggestion = _.find($scope.suggestedDates, function (dateSuggestion) {
                return dateSuggestion.date.format() == e.detail.start;
            });
            angular.element(document.getElementById("date-suggestion-" + selectedDateSuggestion.date.format())).scope().$broadcast("SHOW_DROPDOWN");
        });
        $scope.saving = false;
        $scope.loading = true;
        $scope.fetchData();
    }]);


    app.filter('capitalize', function () {
        return function (input) {
            return (!!input) ? input.charAt(0).toUpperCase() + input.substr(1).toLowerCase() : '';
        }
    });
})();