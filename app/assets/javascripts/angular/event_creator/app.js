(function(){

    var app = angular.module('event-creator', ['event-creator-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("create-event-panel"),['event-creator']);
    });
})();