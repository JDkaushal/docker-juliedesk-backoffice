(function(){

    var app = angular.module('dates-manager', ['dates-manager-services', 'dates-manager-controllers']);

    angular.element(document).ready(function () {
        angular.bootstrap(document.getElementById("thread-header-other-entries-container"),['dates-manager']);
    });
})();