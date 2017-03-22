(function () {
    var app = angular.module('calendar-viewer-controllers', ['angularMoment', 'commonServices']);


    app.controller("event-histories-viewer-controller", ['$scope', 'moment', 'calendarServerApi', function ($scope, moment, calendarServerApi) {

      $scope.event_id = 6716180;

      $scope.fetch = function() {
          calendarServerApi.eventHistoriesListRequest({event_id: $scope.event_id}).then(function(response) {

              var histories = response.data.data.event_histories;
              window.histories = histories;

              $scope.cleanHistories(histories);

          });
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
                      validity_start: moment(history.validity_start),
                      changes: changes
                  });
                  currentAttributes = cleanHistory;
              }
          });

          if(result.length > 0 && result[result.length - 1].validity_end) {
              $scope.deletedAt = moment(result[result.length - 1].validity_end);
          }

          //$scope.$watch("event_id", $scope.fetch);

          $scope.cleanedHistories = globalChanges;
      };

      $scope.formatRange = function(datesRanges) {
          if(datesRanges && datesRanges.start && datesRanges.end) {
              return CommonHelpers.formatDateTimeRangeInText(datesRanges.start, datesRanges.end, "en", "UTC", false);
          }
          return "";

      };
      $scope.fetch();
    }]);
    app.controller("calendar-viewer-controller", ['$scope', 'backofficeApi', function ($scope, backofficeApi) {


        $scope.account_email = function() {
            return $("#calendar-viewer-client-email").val();
        };

        $scope.addressHasMeetingRooms = function (address) {
            return address.available_meeting_rooms && address.available_meeting_rooms.length > 0;
        };

        $scope.$on('account_email_changed', function(event, args) {
            backofficeApi.accountDetailsRequest({email: $scope.account_email()}).then(function(response) {
                $scope.account = response.data.data.account;
            });
        });

        $scope.selectedMeetingRooms = function() {
            return _.filter(_.flatten(_.map($scope.account.addresses, function(address) { return address.available_meeting_rooms; } )), function(address) {
                return address && address.selected;
            });
        };

        $scope.selectedMeetingRoomsByUsername = function() {
            result = {}
            _.each($("#calendar-viewer").scope().selectedMeetingRooms(), function(meeting_room) {
                if(!(meeting_room.calendar_login_username in result)) {
                    result[meeting_room.calendar_login_username] = [];
                }
                result[meeting_room.calendar_login_username].push(meeting_room.id)
            });
            return result;
        };

        $scope.$watch(function() {
            return $scope.account;
        }, function() {
            document.dispatchEvent(new CustomEvent('calendarSettingsChanged'));
        }, true);

    }]);
})();
