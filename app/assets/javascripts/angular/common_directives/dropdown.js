angular.module('commonDirectives').directive('dropdown', function() {


    return {
        restrict: 'A',
        link: function(scope, element, attr, ctrl) {
            scope.data_items = JSON.parse(attr['dropdownData']);

            var activationElement = element;
            if(element.find('.dropdown-button').length > 0) {
                activationElement = angular.element(element.find('.dropdown-button')[0]);
            }
            activationElement.on('click', function() {
                scope.showDropDown();
            });

            scope.hideDropdown = function() {
                ctrl.hideHover();
            };
            scope.showDropDown = function() {
                scope.$apply(function() {
                    ctrl.showHover();
                });
            };

        },
        controller: function($scope, $element, $timeout) {
            $scope.isShown = false;

            $scope.$on('SHOW_DROPDOWN', function(event, data) {
                console.log("okok");
                $scope.$apply(function() {
                    $scope.isShown = true;
                });
            });

            this.showHover = function() {
                $scope.isShown = !$scope.isShown;
            };
            this.hideHover = function() {
                $scope.isShown = false;
            };

        },
        transclude: true,
        replace: false,
        scope: {
            'selectItem': '&dropdownSelectItem'
        },
        template: function(element, attr) {
            var htmlTemplate =
'<div class="custom-dropdown-container" ng-show="isShown">' +
'<div class="custom-dropdown">' +
'<div class="custom-dropdown-option" ng-repeat="(data_id, data_item) in data_items" ng-click="hideDropdown(); selectItem({value: data_id})">{{ data_item.label }}</div>' +
'</div>' +
'</div>';

            return "<div ng-transclude></div>" + htmlTemplate;
        }


    }
});