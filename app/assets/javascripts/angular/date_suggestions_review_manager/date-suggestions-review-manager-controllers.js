(function () {

    var app = angular.module('date-suggestions-review-manager-controllers', ['angularMoment', 'commonDirectives', 'commonPipes']);

    app.controller("date-suggestions-review-manager-controller", ['$scope', 'moment', '$http', function ($scope, moment, $http) {

        $scope.init = function(params) {
            $scope.dateSuggestionsReviewId = params.date_suggestions_review_id;
            $scope.loading = {};
            $scope.saving = false;
            $scope.fetchData().then($scope.activateCalendarIfReady);
            $scope.listenToDocumentForInteractions();
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

        $scope.populateErrors = function(dateSuggestions) {
            _.each(dateSuggestions, function(dateSuggestion) {
                var errors = [];
                var customError = "";
                var dateFormattedForRuby = dateSuggestion.date.utc().format("YYYY-MM-DDTHH:mm:ss") + ".000Z";
                if($scope.itemsErrorsData && $scope.itemsErrorsData[dateFormattedForRuby] && $scope.itemsErrorsData[dateFormattedForRuby].errors) {
                    errors = $scope.itemsErrorsData[dateFormattedForRuby].errors;
                    customError = $scope.itemsErrorsData[dateFormattedForRuby].custom_error;
                }
                dateSuggestion.errors = errors;
                dateSuggestion.customError = customError;
            });
        };

        $scope.handleDateSuggestionsData = function(data) {
            $scope.julieActionId = data.julie_action_id;

            $scope.dateSuggestionsSetErrors = data.set_errors;


            $scope.accountEmail = data.account_email;
            $scope.otherAccountEmails = data.other_account_emails;
            $scope.currentNotes = data.other_notes;
            $scope.duration = data.duration;
            $scope.eventType = data.event_type;
            $scope.location = data.location;
            $scope.constraints = data.constraints_data;
            $scope.date = data.date;

            $scope.itemsErrorsData = data.items_errors;
            $scope.fullAutoErrors = data.full_auto_errors;
            $scope.fullAutoCustomError = data.full_auto_custom_error;
            $scope.comment = data.comment;

            window.otherAttendeesWithAccount = _.filter($scope.attendees, function (attendee) {
                return attendee.isPresent && attendee.isClient && attendee.accountEmail && attendee.accountEmail != threadAccountEmail;
            });

            $scope.suggestedDates = _.map(data.date_suggestions, function(dateSuggestion) {
                return {
                    date: moment(dateSuggestion.date)
                }
            });

            $scope.populateErrors($scope.suggestedDates);

            $scope.allTimezones = _.uniq(_.map(data.date_suggestions, function(dateSuggestion) {
                return dateSuggestion.timezone;
            }));
            $scope.mainTimezone = $scope.allTimezones[0];
        };

        $scope.activateCalendarIfReady = function() {
            if($scope.isLoading()) {
                return;
            }
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
        };

        $scope.fetchData = function () {
            $scope.startLoading('backoffice');
            return $http.get("/review/date_suggestions_reviews/" + $scope.dateSuggestionsReviewId, {
                params: {},
                headers: {'Accept': 'application/json'}
            }).then(function (response) {
                $scope.endLoading('backoffice');
                data = response.data.data;
                $scope.handleDateSuggestionsData(data);
            }, function(response) {
                $scope.endLoading('backoffice');
                if(response.status == 404) {
                    $scope.loading = false;
                    $scope.error = true;
                }
            });
        };

        $scope.startLoading = function(source) {
            $scope.loading[source] = true;
        };

        $scope.endLoading = function(source) {
            delete $scope.loading[source];
        };

        $scope.isLoading = function() {
            !_.isEmpty($scope.loading);
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
            if(!date.errors) {
                date.errors = [];
            }
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

        $scope.itemsErrors = function() {
            return $scope.suggestedDates;
        };

        $scope.validateReview = function() {
            $scope.saving = true;
            $http.post("/review/date_suggestions_reviews/" + $scope.dateSuggestionsReviewId, {
                set_errors: $scope.dateSuggestionsSetErrors,
                items_errors: $scope.itemsErrors(),
                full_auto_errors: $scope.fullAutoErrors,
                full_auto_custom_error: $scope.fullAutoCustomError,
                comment: $scope.comment
            }).then(function(response) {
                window.location = window.location.href;
            }, function(response) {
                $scope.saving = false;
            });
        };

        $scope.findDateSuggestionByDate = function(date) {
            return _.find($scope.suggestedDates, function (dateSuggestion) {
                return dateSuggestion.date.format() == date;
            });
        };

        $scope.listenToDocumentForInteractions = function() {
            document.addEventListener("clickOnDateSuggestionAddErrorButtonInReviewMode", function (e) {
                var selectedDateSuggestion = $scope.findDateSuggestionByDate(e.detail.start);
                angular.element(document.getElementById("date-suggestion-" + selectedDateSuggestion.date.format())).scope().$broadcast("SHOW_DROPDOWN");

            });
            document.addEventListener("mouseEnterOnDateSuggestionInReviewMode", function (e) {
                var selectedDateSuggestion = $scope.findDateSuggestionByDate(e.detail.start);
                selectedDateSuggestion.highlighted = true;
                $scope.$apply()
            });
            document.addEventListener("mouseLeaveOnDateSuggestionInReviewMode", function (e) {
                var selectedDateSuggestion = $scope.findDateSuggestionByDate(e.detail.start);
                selectedDateSuggestion.highlighted = false;
                $scope.$apply()
            });
        };

    }]);

    app.controller("date-suggestions-full-auto-review-manager-controller", ['$scope', '$controller', 'moment', '$http', 'conscienceApi', function ($scope, $controller, moment, $http, conscienceApi) {
        $controller('date-suggestions-review-manager-controller', {$scope: $scope});

        $scope.init = function(params) {
            $scope.dateSuggestionsReviewId = params.date_suggestions_review_id;
            $scope.loading = {};
            $scope.saving = false;
            $scope.fullAutoErrors = [];
            $scope.fetchData().then(function() {
                return $scope.fetchFromConscience()
            }).then($scope.activateCalendarIfReady);
            $scope.listenToDocumentForInteractions();

            $scope.possibleFullAutoErrorsFiltered = {};
        };

        $scope.possibleFullAutoErrors = {
            should_have_changed: {
                label: "Dates should have been changed",
                when_no_force: true
            },
            unjustified_change: {
                label: "Unjustified change",
                when_force: true
            },
            time_constraints: {
                label: "Wrong time constraints",
                when_force: true
            },
            timezone: {
                label: "Wrong Timezone",
                when_force: true
            },
            flow: {
                label: "Wrong flow",
                when_force: true
            },
            other: {
                label: "Other",
                when_force: true,
                when_no_force: true
            }
        };



        $scope.addFullAutoError = function (errorId) {
            if ($scope.fullAutoErrors.indexOf(errorId) == -1) {
                $scope.fullAutoErrors.push(errorId);
            }
        };

        $scope.removeFullAutoError = function (errorId) {
            $scope.fullAutoErrors.splice($scope.fullAutoErrors.indexOf(errorId), 1);
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

        $scope.fetchFromConscience = function() {
            $scope.startLoading('conscience');
            return conscienceApi.suggestedDatesDetailsRequest({
                julie_action_id: $scope.julieActionId
            }).then(function(response) {
                //console.log("fetched from conscience");
                $scope.endLoading('conscience');
                $scope.forceHumanReason = response.data.data.suggested_date.auto_process_force_human_reason;
                if(response.data.data.suggested_date.auto_process_force_human_reason_details) {
                    $scope.forceHumanReason = response.data.data.suggested_date.auto_process_force_human_reason_details;
                }
                $scope.conscienceDateSuggestions = _.map(response.data.data.suggested_date.status, function(status) {
                    var dateStringKey = _.keys(status)[0];
                    return {
                        date: moment(dateStringKey),
                        status: status[dateStringKey]
                    }
                });


                _.each($scope.possibleFullAutoErrors, function(v, k) {
                    if(($scope.notCorrectConscienceDateSuggestions().length > 0 && v.when_force) ||
                        ($scope.notCorrectConscienceDateSuggestions().length == 0 && v.when_no_force)) {
                        $scope.possibleFullAutoErrorsFiltered[k] = v;
                    }
                });

                console.log($scope.possibleFullAutoErrorsFiltered);

                $scope.populateErrors($scope.conscienceDateSuggestions);
            });
        };

        $scope.suggestedDatesOther = function() {
            return _.filter($scope.suggestedDates, function(suggestionDate) {
                return !_.find($scope.conscienceDateSuggestions, function(conscienceDateSuggestion) {
                    return conscienceDateSuggestion.date.format() == suggestionDate.date.format();
                });
            });
        };


        $scope.itemsErrors = function() {
            return _.flatten([$scope.correctConscienceDateSuggestions(), $scope.suggestedDatesOther(), $scope.notCorrectConscienceDateSuggestions()]);
        };

        $scope.correctConscienceDateSuggestions = function() {
            return $scope.correctOrIncorrectConscienceDateSuggestions(true);
        };

        $scope.notCorrectConscienceDateSuggestions = function() {
            return $scope.correctOrIncorrectConscienceDateSuggestions(false);
        };

        $scope.correctOrIncorrectConscienceDateSuggestions = function(correctOrIncorrect) {
            return _.filter($scope.conscienceDateSuggestions, function(dateSuggestionHash) {
                var isCorrect = dateSuggestionHash.status == true || _.find($scope.suggestedDates, function(suggestionDate) {
                        return dateSuggestionHash.date.format() == suggestionDate.date.format();
                    }) != undefined;
                return isCorrect == correctOrIncorrect;
            });
        };

        $scope.findDateSuggestionByDate = function(date) {
            return _.find(_.flatten([$scope.conscienceDateSuggestions, $scope.suggestedDates]), function (dateSuggestion) {
                return dateSuggestion.date.utc().format() == moment(date).utc().format();
            });
        };
    }]);
})();