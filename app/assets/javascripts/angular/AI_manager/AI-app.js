(function() {

    var app = angular.module('AI-manager', ['AI-manager-services', 'AI-manager-controllers']);

    angular.element(document).ready(function () {
        var aiManagerNode = $('#AI_manager');
        // We only activate the AI on threads that can be edited
        // Prevent the confusion of the operators
        if(window.threadDataIsEditable) {
            aiManagerNode.append($('<div id="locale_manager" ng-controller="localeManager"></div>'));
            aiManagerNode.append($('<div id="appointment_type_manager" ng-controller="appointmentTypeManager"></div>'));
            aiManagerNode.append($('<phone-skype-entities-manager/>'));

            if(window.classification == 'ask_availabilities') {
                aiManagerNode.append($('<div id="ai_dates_verification_manager" ng-controller="datesVerificationManager"></div>'));
            }
        }

        angular.bootstrap(document.getElementById("AI_manager"),['AI-manager']);
    });
})();