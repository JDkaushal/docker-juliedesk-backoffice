(function(){
    var app = angular.module('calendar-viewer', ['calendar-viewer-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("calendar-viewer"),['calendar-viewer']);
    });
})();