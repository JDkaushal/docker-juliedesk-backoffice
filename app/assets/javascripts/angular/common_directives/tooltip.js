angular.module('commonDirectives').directive('tooltip', function () {


    return {
        restrict: 'A',
        link: function (scope, element, attr, ctrl) {

            scope.message = attr['tooltip'];
            scope.displayClasses = {
                top: attr['tooltipTop'] != null,
                right: attr['tooltipRight'] != null
            };

            scope.showDelay = 0;
            if (attr['tooltipDelay'] != null) {
                scope.showDelay = 600;
            }


            element.on('mouseenter', function () {
                scope.$apply(function () {
                    ctrl.showHover(true);
                });
            });
            element.on('mouseleave', function () {
                scope.$apply(function () {
                    ctrl.showHover(false);
                });
            });

        },
        controller: ["$scope", "$element", "$timeout", function ($scope, $element, $timeout) {
            $scope.isShown = false;
            $scope.shouldShow = false;

            this.showHover = function (shouldShow) {
                if (shouldShow) {
                    $scope.shouldShow = true;
                    $timeout(function () {
                        if ($scope.shouldShow) {
                            $scope.isShown = true;
                        }
                    }, $scope.showDelay);
                }
                else {
                    $scope.shouldShow = false;
                    $scope.isShown = false;
                }
            }

        }],
        transclude: {
            'tooltipHtml': '?tooltipHtml'
        },
        replace: false,
        template: function (element, attr) {
            var htmlTemplate =
                '<div class="custom-tooltip-container" ng-show="isShown">' +
                '<div class="custom-tooltip" ng-class="displayClasses"><div ng-transclude="tooltipHtml"></div>{{ message }}<div class="custom-tooltip-arrow"></div></div>' +
                '</div>';
            if (attr['tooltipTop'] != null) {
                return htmlTemplate + "<div ng-transclude></div>";
            }
            else {
                return "<div ng-transclude></div>" + htmlTemplate;
            }
        }


    }
});