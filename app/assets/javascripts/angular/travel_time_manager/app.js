(function(){

    var app = angular.module('travel-time-manager', ['travel-time-manager-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("travel_time_manager"),['travel-time-manager']);
    });
})();