(function() {

    var app = angular.module('AI-manager', ['AI-manager-services', 'AI-manager-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("AI_manager"),['AI-manager']);
    });
})();