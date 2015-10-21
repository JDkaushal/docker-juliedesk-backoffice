(function(){

    var app = angular.module('virtual-meetings-helper', ['virtual-meetings-helper-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("virtual-meetings-helper"),['virtual-meetings-helper']);
    });
})();