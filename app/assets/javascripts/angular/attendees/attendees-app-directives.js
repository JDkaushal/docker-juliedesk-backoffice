(function(){
    var app = angular.module('attendees-manager-directives', ['templates']);

    app.directive('attendeeGeneralDetails', function(){
        return {
            restrict: 'E',
            templateUrl: 'attendee-general-details.html'
        };
    });

    app.directive('capitalize', function() {
        return {
            require: 'ngModel',
            link: function(scope, element, attrs, modelCtrl) {
                var capitalize = function(inputValue) {
                    if(inputValue == undefined) inputValue = '';
                    var capitalized = inputValue.charAt(0).toUpperCase() + inputValue.slice(1);
                    if(capitalized !== inputValue) {
                        modelCtrl.$setViewValue(capitalized);
                        modelCtrl.$render();
                    }
                    return capitalized;
                };
                modelCtrl.$parsers.push(capitalize);
                capitalize(scope[attrs.ngModel]);  // capitalize initial value
            }
        };
    });


})();