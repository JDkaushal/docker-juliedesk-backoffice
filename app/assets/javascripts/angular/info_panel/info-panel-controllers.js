(function() {

    var app = angular.module('info-panel-app');

    app.controller('blankInfoPanelController', ['$scope', function ($scope) {
        $scope.currentAppointmentIsVirtual = function() {
            var currentAppointment = window.getCurrentAppointment();
            return currentAppointment && currentAppointment.appointment_kind_hash.is_virtual;
        };
        $scope.fetch = function() {
            $scope.threadComputedData = window.threadComputedData;
        };
        $scope.fetch();
    }]);
})();