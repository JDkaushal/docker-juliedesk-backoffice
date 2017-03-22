(function () {
    var app = angular.module('calendar-viewer-controllers', ['commonServices']);


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
