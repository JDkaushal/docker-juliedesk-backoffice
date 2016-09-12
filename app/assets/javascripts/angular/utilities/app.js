(function(){
    var app = angular.module('utilities', ['utilities-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("angular_utilities"),['utilities']);
    });

})();