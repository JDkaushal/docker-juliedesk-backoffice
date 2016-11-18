(function(){
    angular.module('client-account-tile-app', []);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("accounts-list-section"),['client-account-tile-app']);
        window.clientAccountTilesScope = angular.element(document.getElementById("accounts-list-section")).scope();
    });
})();