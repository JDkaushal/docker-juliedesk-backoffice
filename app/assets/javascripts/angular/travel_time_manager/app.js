(function(){

    var app = angular.module('travel-time-manager', ['travel-time-manager-controllers']);

    // If there is no account associated with the thread, don't boot this app otherwise it cause errors
    if(window.threadAccount) {
        angular.element(document).ready(function () {
            angular.bootstrap(document.getElementById("travel_time_manager"),['travel-time-manager']);
        });
    }

})();