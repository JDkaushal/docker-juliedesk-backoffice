(function(){

    var app = angular.module('virtual-meetings-helper-controllers', ['templates']);

    app.directive('virtualMeetingsHelper', function(){
        return{
            restrict: 'E',
            templateUrl: 'virtual-meetings-helper.html',
            controller: ['$scope,' , function($scope){




            }],
            controllerAs: 'virtualMeetingsHelperCtrl'
        }
    });
})();