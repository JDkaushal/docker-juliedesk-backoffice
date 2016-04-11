(function(){

    var app = angular.module('AI-manager-services', []);

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