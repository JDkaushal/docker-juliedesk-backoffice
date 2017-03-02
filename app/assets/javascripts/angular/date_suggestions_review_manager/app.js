(function(){

    var app = angular.module('date-suggestions-review-manager', ['date-suggestions-review-manager-controllers', 'angularMoment']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("date-suggestions-review-manager"),['date-suggestions-review-manager']);
    });
})();