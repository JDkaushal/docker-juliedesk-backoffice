(function(){

    angular.module('info-panel-app', ['commonDirectives', 'commonServices', 'templates', 'angucomplete-alt']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("info-panel-app-container-1"),['info-panel-app']);
    });
})();