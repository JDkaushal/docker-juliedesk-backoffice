(function(){
    var app = angular.module('meeting-rooms-manager-services', []);

    app.service('sharedProperties', ['$rootScope', function($rootScope) {
        var sharedProperties = this;
        this.currentlyChoosenRooms = [];

        this.clearCurrentlyChoosenRoom = function(){
            sharedProperties.currentlyChoosenRooms = [];
        };

        this.addCurrentlyChoosenRoom = function(roomId){
            sharedProperties.currentlyChoosenRooms.push(roomId);
        };

        this.isRoomAlreadyChoosen = function(roomId) {
            return sharedProperties.currentlyChoosenRooms.indexOf(roomId) > -1;
        };

        return {
            clearChoosenRooms: function() {
                sharedProperties.clearCurrentlyChoosenRoom();
            },
            getCurrentlyChoosenRooms: function() {
                return sharedProperties.currentlyChoosenRooms;
            },
            addChoosenRooms: function(roomId){
                sharedProperties.addCurrentlyChoosenRoom(roomId);
            },
            checkRoomAlreadyChoosen: function(roomId) {
                return sharedProperties.isRoomAlreadyChoosen(roomId);
            }
        }
    }]);
})();