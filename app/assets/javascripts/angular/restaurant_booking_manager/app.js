(function(){

    var app = angular.module('restaurant-booking-manager', ['restaurant-booking-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("restaurant-booking-manager"),['restaurant-booking-manager']);
    });
})();