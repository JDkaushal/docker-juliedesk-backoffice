angular.module('commonDirectives').directive('eventTimeLine', ['moment', 'calendarServerApi', function (moment, calendarServerApi) {

    return {
        restrict: 'E',
        link: function (scope, element, attrs, ctrl) {
            attrs.$observe('eventId', function(eventId) {
                scope.eventId = eventId;
                scope.fetch();
            });
        },
        scope: {

        },
        controller: ['$scope', function ($scope) {
            $scope.loading = false;

            $scope.fetch = function() {
                if(!$scope.eventId) {
                    window.histories = [];
                    $scope.cleanHistories(histories);
                    $scope.loading = false;
                    return;
                }
                $scope.loading = true;
                calendarServerApi.eventHistoriesListRequest({event_id: $scope.eventId}).then(function(response) {

                    var histories = response.data.data.event_histories;
                    window.histories = histories;

                    $scope.cleanHistories(histories);
                    $scope.loading = false;

                });
            };

            $scope.formatRange = function(datesRanges) {
                if(datesRanges && datesRanges.start && datesRanges.end) {
                    return CommonHelpers.formatDateTimeRangeInText(datesRanges.start, datesRanges.end, "en", "UTC", false);
                }
                return "";

            };

            $scope.cleanHistories = function(histories) {
                $scope.deletedAt = null;
                $scope.cleanedHistories = [];

                var result =_.sortBy(histories, function(history) {
                    return history.validity_start;
                });


                var currentAttributes = {};
                var globalChanges = [];
                _.each(result, function(history) {
                    var cleanHistory = {
                        dates: {
                            start: moment(history.start.date),
                            end: moment(history.end.date)
                        },
                        summary: history.summary
                    };

                    var changedAttributeKeys = _.filter(_.keys(cleanHistory), function(k) {
                        return JSON.stringify(currentAttributes[k]) != JSON.stringify(cleanHistory[k]);
                    });
                    var changes = {};
                    _.each(changedAttributeKeys, function(attributeKey) {
                        changes[attributeKey] = {
                            old: currentAttributes[attributeKey],
                            new: cleanHistory[attributeKey]
                        }
                    });

                    if(changedAttributeKeys.length > 0) {
                        globalChanges.push({
                            date: moment(history.validity_start),
                            changes: changes
                        });
                        currentAttributes = cleanHistory;
                    }
                });

                if(result.length > 0 && result[result.length - 1].validity_end) {
                    $scope.deletedAt = moment(result[result.length - 1].validity_end);
                }
                if(globalChanges.length > 0) {
                    globalChanges[0].is_creation = true;
                }

                $scope.history_changes = globalChanges;
            };
        }],
        template: function (element, attr) {
            var htmlTemplate =
                '<div class="event-time-line-container">' +
                '<div class="no-event" ng-show="history_changes.length == 0 && !loading">No event</div>' +
                '<div class="no-event" ng-show="loading">Loading..</div>' +
                '<div class="event-time-line" ng-show="history_changes.length > 0 && !loading">' +
                '<div class="history-change" ng-class="{creation: history_change.is_creation}" ng-repeat="history_change in history_changes">' +
                '<div class="history-change-date">{{ history_change.date | amTimezone: "UTC" | amDateFormat: "YYYY-MM-DD HH:mm" }}</div>' +
                '<div class="history-change-dot" tooltip>' +
                '<span>X</span>' +
                '<tooltip-html class="history-change-tooltip">' +
                '<div ng-show="history_change.changes.summary">' +
                '<span class="change-old" ng-show="history_change.changes.summary.old">{{ history_change.changes.summary.old }}</span>' +
                '<span class="change-arrow">→</span>' +
                '<span class="change-new">{{ history_change.changes.summary.new }}</span>' +
                '</div>' +

                '<div ng-show="history_change.changes.dates">' +
                '<span class="change-old" ng-show="history_change.changes.dates.old">{{ formatRange(history_change.changes.dates.old) }}</span>' +
                '<span class="change-arrow">→</span>' +
                '<span class="change-new">{{ formatRange(history_change.changes.dates.new) }}</span>' +
                '</div>' +
                '</tooltip-html>' +
                '</div>' +
                '</div>' +
                '<div class="history-change deletion" ng-show="deletedAt">' +
                '<div class="history-change-date">{{ deletedAt | amTimezone: "UTC" | amDateFormat: "YYYY-MM-DD HH:mm" }}</div>' +
                '<div class="history-change-dot" tooltip>' +
                '<span>X</span>' +
                '<tooltip-html class="history-change-tooltip">' +
                '<span class="change-deleted">Deleted</span>' +
                '</div>' +
                '</div>' +
                '</div>' +
                '</div>' +
                '</div>' +
                '</div>';

            return htmlTemplate;
        }
    }
}]);