(function() {

    var app = angular.module('info-panel-app');

    app.directive("infoPanelField", function() {
        return {
            restrict : "E",
            scope: {
                "value": "=",
                "label": "@"
            },
            template: "<div class='data-entry linear-form-entry'>" +
            "<div class='data-entry-name'>{{ label }}</div>" +
            "<input class='data-entry form-control' ng-model='value'/>" +
            "<div class='validate-linear-form-entry-button btn btn-success btn-sm'>Validate</div>" +
            "</div>"
        }
    });

    app.directive("infoPanelClientOnTripField", function() {
        return {
            restrict : "E",
            scope: {
                "value": "=",
                "label": "@"
            },
            controller: ['$scope', function ($scope) {
                $scope.knownZones = 'other';
                $scope.availableKnownZones = [
                    {
                        value: "other",
                        label: "Other"
                    }
                ];

                $scope.localizedLabel = window.localize("info_panel." + $scope.label + ".label", {locale: 'fr'});

                $scope.activated = $scope.value !== null;
                $scope.cachedValue = $scope.value;

                $scope.selectZone = function(zone) {
                    $scope.cachedValue = {
                        kind: zone.originalObject.kind,
                        label: zone.originalObject.label,
                        country_code: zone.originalObject.country_code,
                        title: zone.title
                    };
                    $scope.value = $scope.cachedValue;
                };

                $scope.$watch("activated", function(newValue, oldValue) {
                    if(!newValue) {
                        $scope.value = null;
                    }
                    else {
                        $scope.value = $scope.cachedValue;
                    }
                });
            }],
            templateUrl: "info-panel-client-on-trip-field.html"
        }
    });
})();