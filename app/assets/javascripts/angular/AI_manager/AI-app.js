(function() {

    var app = angular.module('AI-manager', ['AI-manager-services', 'AI-manager-controllers']);

    angular.element(document).ready(function () {

        // We only activate the AI on threads that can be edited
        // Prevent the confusion of the operators
        if(window.threadDataIsEditable) {
            angular.bootstrap(document.getElementById("AI_manager"),['AI-manager']);
        }
    });
})();