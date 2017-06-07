(function(){

    var app = angular.module('date-suggestions-full-auto-review-manager', ['date-suggestions-full-auto-review-manager-controllers', 'angularMoment']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("date-suggestions-full-auto-review-manager"),['date-suggestions-full-auto-review-manager']);
    });
})();