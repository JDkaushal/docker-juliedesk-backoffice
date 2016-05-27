(function(){
    var app = angular.module('attendees-manager-directives', ['templates']);

    app.directive('attendeeGeneralDetails', ['$timeout', function($timeout){
        return {
            restrict: 'E',
            templateUrl: 'attendee-general-details.html',
            link: function(scope, element, attrs) {
                // Allow us to initialize the timezonePicker on the timezone field exposed in the attendee details thumbnail
                $timeout(function() {
                    $(element[0]).find('.attendee-timezone').timezonePicker();
                });
            }
        };
    }]);

    app.directive('capitalize', function() {
        return {
            require: 'ngModel',
            link: function(scope, element, attrs, modelCtrl) {
                var capitalize = function(inputValue) {
                    if(inputValue == undefined) inputValue = '';
                    var capitalized = inputValue.charAt(0).toUpperCase() + inputValue.slice(1);

                    console.log(capitalized);
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

    app.directive('sanitizeWhitespaces', function() {
        return {
            require: 'ngModel',
            link: function(scope, element, attrs, modelCtrl) {
                var sanitize = function(inputValue) {
                    if(inputValue == undefined) inputValue = '';
                    var sanitized = inputValue.trim();

                    if(sanitized !== inputValue) {
                        modelCtrl.$setViewValue(sanitized);
                        modelCtrl.$render();
                    }
                    return sanitized;
                };
                modelCtrl.$parsers.push(sanitize);
                sanitize(scope[attrs.ngModel]);  // sanitize initial value
            }
        };
    });


})();