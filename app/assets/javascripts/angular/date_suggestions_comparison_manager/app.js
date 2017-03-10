(function(){

    var app = angular.module('date-suggestions-comparison-manager', ['date-suggestions-comparison-manager-controllers', 'angularMoment']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("date-suggestions-comparison-manager"),['date-suggestions-comparison-manager']);
    });
})();