(function(){
    var app = angular.module('attendees-manager', ['attendees-manager-directives', 'attendees-manager-services', 'attendees-manager-controllers', 'attendees-manager-filters']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("attendees_manager_app"),['attendees-manager']);
    });
})();