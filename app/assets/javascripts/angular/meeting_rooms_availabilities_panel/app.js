(function(){

    var app = angular.module('meeting-rooms-availabilities-panel', ['meeting-rooms-availabilities-panel-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("meeting-rooms-availabilities-panel"),['meeting-rooms-availabilities-panel']);
    });
})();