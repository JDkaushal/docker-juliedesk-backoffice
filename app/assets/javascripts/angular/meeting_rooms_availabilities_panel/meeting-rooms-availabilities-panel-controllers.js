(function(){

    var app = angular.module('meeting-rooms-availabilities-panel-controllers', ['templates']);

    app.directive('meetingRoomsAvailabilitiesPanel', function() {
        return {
            restrict: 'E',
            templateUrl: 'meeting-rooms-availabilities-panel-widget.html',
            controller: ['$scope', '$element' , function($scope, $element){

                $scope.meetingRoomsAvailabilities = [];
                $scope.displayWidget = false;

                // Used for general purpose initialization (called at instanciation)
                $scope.init = function() {
                };

                $scope.displayMeetingRoomsAvailabilities = function(roomsAvailabilities) {
                    $scope.noMeetingRoomsAvailable = false;

                    $scope.meetingRoomsAvailabilities = roomsAvailabilities;

                    $scope.displayWidget = $scope.meetingRoomsAvailabilities && $scope.meetingRoomsAvailabilities.length > 0;

                    if($scope.displayWidget && _.any($scope.meetingRoomsAvailabilities, function(availabilitiesDetails) {
                            return availabilitiesDetails.isAvailable !== undefined && !availabilitiesDetails.isAvailable;
                        })) {
                        $scope.noMeetingRoomsAvailable = true;
                    }
                };

                $scope.init();
            }],
            controllerAs: 'meetingRoomsAvailabilitiesPanelCtrl'
        }
    });

})();