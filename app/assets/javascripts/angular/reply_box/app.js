(function(){

    var app = angular.module('reply-box', ['reply-box-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("reply-box"),['reply-box']);
    });
})();