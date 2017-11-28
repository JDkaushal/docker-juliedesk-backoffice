(function(){
    var app = angular.module('meeting-rooms-manager-services', []);

    app.service('defaultInitializationsService', ['$rootScope', function($rootScope) {
        var defaultInitializationsService = this;

        this.getUsedMeetingRoom = function(currentAppointment, currentAddress) {
            var appointmentSelectedMeetingRoom = currentAppointment.selected_meeting_room || '';
            var addressSelectedMeetingRoom = currentAddress.selected_meeting_room || '';

            return this.determineUsedMeetingRoom(appointmentSelectedMeetingRoom, addressSelectedMeetingRoom);
        };

        this.determineUsedMeetingRoom = function(appointmentMeetingRoomConfig, addressMeetingRoomConfig) {
            var usedMeetingRoom = appointmentMeetingRoomConfig;

            if(appointmentMeetingRoomConfig.indexOf('auto_room_selection') === -1) {
                usedMeetingRoom = appointmentMeetingRoomConfig;
            } else if(addressMeetingRoomConfig.indexOf('auto_room_selection') === -1) {
                usedMeetingRoom = addressMeetingRoomConfig;
            } else {
                usedMeetingRoom = this.computeDefaultFilters(appointmentMeetingRoomConfig, addressMeetingRoomConfig)
            }

            return usedMeetingRoom;
        };

        this.computeDefaultFilters = function(appointmentSelectedMeetingRoom, addressSelectedMeetingRoom) {
            var filtersFromAppointments = appointmentSelectedMeetingRoom.split('|')[1].split(';');
            var filtersFromAddress = addressSelectedMeetingRoom.split('|')[1].split(';');

            var summedFilters = _.uniq(filtersFromAppointments.concat(filtersFromAddress));

            return 'auto_room_selection|' + summedFilters.join(';');
        };

        return {
            getMeetingRoomToUse: function(appointmentMeetingRoomConfig, addressMeetingRoomConfig) {
               return defaultInitializationsService.getUsedMeetingRoom(appointmentMeetingRoomConfig, addressMeetingRoomConfig);
            },
            determineMeetingRoomToUse: function(appointmentMeetingRoomConfig, addressMeetingRoomConfig) {
                return defaultInitializationsService.determineUsedMeetingRoom(appointmentMeetingRoomConfig, addressMeetingRoomConfig);
            }
        }
    }]);

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