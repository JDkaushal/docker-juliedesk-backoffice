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
                "label": "@",
                "shouldShow": "=",
                "accountEmail": "="
            },
            controller: ['$scope', '$http', function ($scope, $http) {
                CommonHelpers.externalRequest({
                    action: "list_future_location_indications",
                    email: $scope.accountEmail
                }, function (locationIndications) {

                    $http.get("/geo_zones?" + _.map(locationIndications, function(locationIndication) {
                        return "zones[]=" + locationIndication;
                    }).join("&")).then(function(response) {

                        $scope.availableKnownZones = _.map(response.data.data, function(availableKnownZone) {
                            return {
                                kind: availableKnownZone.kind,
                                label: availableKnownZone.label,
                                country_code: availableKnownZone.country_code,
                                title: availableKnownZone.label_and_country
                            }
                        });

                        $scope.availableKnownZones.push({
                            label: "other",
                            title: "Other"
                        });

                        if($scope.value !== null) {
                            $scope.activated = true;
                            if(_.find($scope.availableKnownZones, function(availableKnownZone) {
                                    return availableKnownZone.label === $scope.value.label;
                                })) {
                                $scope.knownZone = $scope.value.label;
                            }
                            else {
                                $scope.knownZone = 'other';
                            }
                        }
                        else {
                            $scope.activated = false;
                        }
                        $scope.cachedValue = $scope.value;

                        $scope.watchAll();
                    })


                })


                $scope.localizedLabel = window.localize("info_panel." + $scope.label + ".label", {locale: 'fr'});



                $scope.selectZone = function(zone) {
                    if(zone) {
                        $scope.cachedValue = {
                            kind: zone.originalObject.kind,
                            label: zone.originalObject.label,
                            country_code: zone.originalObject.country_code,
                            title: zone.title
                        };
                        $scope.value = $scope.cachedValue;
                    }
                };



                $scope.watchAll = function() {

                    $scope.$watch("activated", function(newValue, oldValue) {

                        if(!newValue) {
                            $scope.value = null;
                        }
                        else {
                            $scope.value = $scope.cachedValue;
                        }
                    });

                    $scope.$watch("knownZone", function(newValue, oldValue) {
                        if(newValue && newValue !== oldValue) {
                            if(newValue !== 'other') {
                                $scope.cachedValue = _.find($scope.availableKnownZones, function(availableKnownZone) {
                                    return newValue === availableKnownZone.label;
                                })

                                $scope.value = $scope.cachedValue;
                            }
                        }
                    });
                }

            }],
            templateUrl: "info-panel-client-on-trip-field.html"
        }
    });
})();