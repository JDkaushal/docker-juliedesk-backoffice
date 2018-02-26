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

    app.service('meetingRoomsPrioritizationService', ['$rootScope', function($rootScope) {
        var meetingRoomsPrioritizationService = this;

        function PrioritizationFlowError(message) {
            this.message = message;
            this.name = "PrioritizationFlowError";
        }

        var PrioritizationRule = function(methods) {
            var klass = function(weight) {
                this.weight = weight;
                this.initialize.apply(this, arguments);
            };

            for (var property in methods) {
                klass.prototype[property] = methods[property];
            }

            if (!klass.prototype.computeRule) throw new Error("Please implement a computeRule method");

            if (!klass.prototype.initialize) klass.prototype.initialize = function(){};

            klass.prototype.applyRule = function(clientDetails, meetingRoom) {
                var result = 0;

                if(this.computeRule(clientDetails, meetingRoom)) {
                    result = this.weight;
                }

                return result;
            };

            return klass;
        };

        // If the current room is among
        var IsAPreferredRoomRule = PrioritizationRule({
            initialize: function() {
                this.type = 'isAPreferredRoomRule'
            },
            computeRule: function(clientDetails, meetingRoom) {
                return clientDetails.preferred_meeting_rooms.indexOf(meetingRoom.id) > -1;
            }
        });

        var IsInMainBuildingRule = PrioritizationRule({
            initialize: function() {
                this.type = 'isInMainBuildingRule'
            },
            computeRule: function(clientDetails, meetingRoom) {
                return meetingRoom.in_main_location;
            }
        });

        var IsInMainBuildingAndFloorRule = PrioritizationRule({
            initialize: function() {
                this.type = 'isInMainBuildingAndFloorRule'
            },
            computeRule: function(clientDetails, meetingRoom) {
                return meetingRoom.in_main_location && meetingRoom.on_default_floor;
            }
        });

        var IsBestChoiceByFloor = PrioritizationRule({
            initialize: function() {
                this.type = 'isBestChoiceByFloor'
            },
            computeRule: function(clientDetails, meetingRoom) {
                return meetingRoom.floor_location_score;
            }
        });

        var rulesMapping = {
            'is_a_preferred_room_rule': IsAPreferredRoomRule,
            'is_in_main_building_rule': IsInMainBuildingRule,
            'is_in_main_building_and_floor_rule': IsInMainBuildingAndFloorRule,
            'is_best_choice_by_floor': IsBestChoiceByFloor
        };

        var PrioritizationFlow = function (clientDetails) {
            this.rules = [];
            this.clientAccount = clientDetails;
        };

        PrioritizationFlow.prototype = {
            prioritize: function(meetingRooms) {
                var that = this;
                var rulesDetails = this.clientAccount && this.clientAccount.company_hash && this.clientAccount.company_hash.meeting_rooms_prioritization_rules;

                if(!rulesDetails) {
                    throw new PrioritizationFlowError('Could not prioritize the meeting rooms with rules => ' + rulesDetails);
                }

                this.buildRules(rulesDetails);

                _.each(meetingRooms, function(room) {
                    room.prioritizationScore = that.computePrioritizationScore(room);
                });
                console.log('Meeting rooms prioritized following rules => ' + JSON.stringify(rulesDetails));

                return _.sortBy(meetingRooms, function(room) {
                    return -room.prioritizationScore;
                });
            },
            buildRules: function(rulesDetails) {
                var that = this;

                _.each(rulesDetails, function(ruleDetails) {
                    that.addRule(new rulesMapping[ruleDetails.type](ruleDetails.weight));
                })
            },
            addRule: function(newRule) {
                var added = false;

                var existingRule = _.find(this.rules, function(rule) {
                    return rule.type === newRule.type;
                });

                if(!existingRule) {
                    this.rules.push(newRule);
                    added = true;
                }

                return added;
            },
            removeRule: function(type) {
                for (var rule, i = 0; rule = this.getRule(i); i++) {
                    if (type === ruleToRemove.type) {
                        this.rules.splice(i, 1);
                        return true;
                    }
                }

                return false;
            },
            getRule: function(index) {
                return this.rules[index];
            },
            computePrioritizationScore: function(meetingRoom) {
                if(!meetingRoom) {
                    throw new Error('Please specify a meeting room in order to compute the current prioritization rule');
                }
                var that = this;

                return _.reduce(this.rules, function(total, rule){ return total + rule.applyRule(that.clientAccount, meetingRoom); }, 0);
            }
        };

        this.prioritizeRoomsActions = function(clientDetails, meetingRooms) {
            var flow = new PrioritizationFlow(clientDetails);
            return flow.prioritize(meetingRooms);
        };

        return {
            prioritizeRooms: function(clientDetails, meetingRooms) {
                return meetingRoomsPrioritizationService.prioritizeRoomsActions(clientDetails, meetingRooms);
            }
        }
    }]);
})();