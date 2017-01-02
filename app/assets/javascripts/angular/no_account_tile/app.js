(function(){

    var app = angular.module('no-account-tile', ['no-account-tile-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("no_account_tile"),['no-account-tile']);
        window.noAccountTilesScope = angular.element(document.getElementById("no_account_tile")).scope();
    });
})();