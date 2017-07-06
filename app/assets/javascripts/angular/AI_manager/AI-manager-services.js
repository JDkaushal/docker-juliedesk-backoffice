(function(){

    var app = angular.module('AI-manager-services', []);

    app.service('aIDatesSuggestionService', ['$http','$q', function($http, $q) {
        this.fetch = function(params) {
            return $http({
                url: '/ai/dates_suggestions/fetch',
                method: "POST",
                data: params
            }).then(
                function(response) {
                    var result = {};

                    // In case of error, we reject the deferred object
                    if(response.data.error) {
                        result = $q.reject(response.data);
                    } else {
                        result = { data: response.data };
                    }

                    return result;
                }, function(httpError) {
                    console.log(httpError);
                    return $q.reject(httpError);
                });
        };

        this.datesSuggestionsAutoProcessUpdate = function (params) {
            return $http({
                url: '/ai/dates_suggestions/dates_suggestions_auto_process_update',
                method: "POST",
                data: params
            }).then(
                function (response) {
                    return {
                        data: response.data
                    };
                }, function (httpError) {
                    console.log(httpError);
                });
        };

        this.sendLearningData = function(params) {
            return $http({
                url: '/ai/dates_suggestions/send_learning_data',
                method: "POST",
                data: params
            }).then(
                function(response) {
                    return {
                        data: response.data
                    };
                }, function(httpError) {
                    console.log(httpError);
                });

        };
    }]);

    app.service('aIDatesVerificationService', ['$http','$q', function($http, $q) {
        this.verifyDates = function(params) {
            return $http({
                url: '/ai/dates_verification/verify_dates',
                method: "POST",
                data: params,
                timeout: 10000
            }).then(function(response) {
                return response.data;
            }, function(httpError) {
                console.log(httpError);
                return {error: true, details: httpError};
            });
        };

        this.verifyDatesV2 = function(params) {
            return $http({
                url: '/ai/dates_verification/verify_dates_v2',
                method: "POST",
                data: params,
                timeout: 10000
            }).then(function(response) {
                return response.data;
            }, function(httpError) {
                console.log(httpError);
                return {error: true, details: httpError};
            });
        };
    }]);

    app.service('messageInterpretationsService', function(){
        this.getMainInterpretation = function(){
            var mainInterpretation = _.find(window.messageInterpretations, function(mI) {
                return mI.question == "main";
            });
            var result = undefined;

            if(mainInterpretation && !mainInterpretation.error && !!mainInterpretation.raw_response) {
                result = JSON.parse(mainInterpretation.raw_response);
            }

            return result;
        };
    });

    app.service('eventsMetadataService', ['$http', '$q', function($http, $q){
        this.fetch = function(params){
            return $http({
                url: '/ai/events_metadata/fetch',
                method: "POST",
                timeout: 3000,
                data: params
            }).then(
                function(response) {
                    var result = {};

                    if(response.data.error) {
                        console.log(response.data);
                        result = $q.reject(response.data);
                    } else {
                        result = { data: response.data };
                    }

                    return result;
                }, function(httpError) {
                    console.log(httpError);
                    return $q.reject()
                }
            );
        };
    }]);

    app.service('attendeesService', ['$rootScope', function($rootScope){
        var attendeesApp;
        var that = this;

        function getAllAttendeesCallNumbers(attendees) {
            var result = {};

            _.each(attendees, function(a) {
                if(!!a.mobile) {
                    result[a.mobile] = {
                        type: 'mobile',
                        ownerGuid: a.guid
                    }
                }
                if(!!a.landline) {
                    result[a.landline] = {
                        type: 'landline',
                        ownerGuid: a.guid
                    }
                }
                if(!!a.confCallInstructions) {
                    result[a.confCallInstructions] = {
                        type: 'confCallInstructions',
                        ownerGuid: a.guid
                    }
                }
                if(!!a.skypeId) {
                    result[a.skypeId] = {
                        type: 'skypeId',
                        ownerGuid: a.guid
                    }
                }
            });

            return result;
        };

        this.getAttendeesWithoutClients = function(){
            return attendeesApp.getAttendeesWithoutClients();
        };

        this.getAttendeesClients = function() {
            return attendeesApp.getAttendeesOnlyClients();
        };

        this.applyScope = function() {
            if(!attendeesApp.$$phase)
                attendeesApp.$apply();
        };

        this.getAttendeesApp = function() {
            return angular.element($('#attendeesCtrl')).scope();
        };

        this.listenToAttendeesAppEvents = function() {
            attendeesApp = that.getAttendeesApp();

            if(!!attendeesApp) {
                attendeesApp.$on('attendeesFetched', function(event, args) {
                    $rootScope.$broadcast('callNumbersFetched', {callNumbers: getAllAttendeesCallNumbers(args.attendees.slice())});
                    $rootScope.$broadcast('clientsFetched', {clients: that.getAttendeesClients()});
                });
            }
        };

        angular.element(document).ready(function() {
            that.listenToAttendeesAppEvents();
        });
    }]);

})();