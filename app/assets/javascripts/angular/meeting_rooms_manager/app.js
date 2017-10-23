(function(){

    var app = angular.module('meeting-rooms-manager', ['meeting-rooms-manager-services', 'meeting-rooms-manager-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("meeting-rooms-manager"),['meeting-rooms-manager']);
    });
})();