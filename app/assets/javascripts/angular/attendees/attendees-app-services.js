(function(){
    var app = angular.module('attendees-manager-services', []);

    app.service('sharedProperties', ['$rootScope', function($rootScope) {
        var sharedProperties = this;
        this.threadOwner = {};

        this.displayAttendeeForm = function(args){
            $rootScope.$broadcast('attendeeFormDisplayed', args);
        };

        this.attendeeAdded = function(attendee){
            $rootScope.$broadcast('attendeeAdded', {attendee: attendee});
        };

        return {
            displayAttendeeForm: function(args) {
                sharedProperties.displayAttendeeForm(args);
            },
            notifyAttendeeAdded: function(attendee){
                sharedProperties.attendeeAdded(attendee);
            },
            setThreadOwner: function(threadOwner) {
                sharedProperties.threadOwner = threadOwner;
            },
            getThreadOwner: function() {
                return sharedProperties.threadOwner;
            }
        }
    }]);
})();