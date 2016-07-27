//= require angular_restaurant_booking_manager_app

(function(){

    'use strict';

    function setWindowVariables(){
        window.threadDataIsEditable = true;

        window.threadComputedData = {call_instructions: {}, attendees: []};

        window.currentToCC = ["test@gmail.com"];

        window.threadAccount = {
            addresses: Array[4],
            appointments: Array[13],
            awaiting_current_notes: "",
            block_until_preferences_change: false,
            calendar_logins: Array[1],
            company_hash: null,
            complaints_count: 0,
            confcall_instructions: "confcall instructions",
            contacts_from_same_company: Array[0],
            created_at: "2015-03-17T23:30:24.000+00:00",
            current_notes: "",
            default_timezone_id: "America/Chicago",
            email: "blake@aceable.com",
            email_aliases: ["threadOwnerAlias1@alias.com"],
            full_name: "Blake Garrett",
            is_pro: false,
            landline_number: "",
            locale: "en",
            means_of_transport: "Walk",
            mobile_number: "617-216-2881",
            office_365_refresh_token_expired: false,
            only_admin_can_process: false,
            raw_preferences: "",
            skype: "",
            usage_name: "Blake"
        };

        window.currentJulieAlias = {
            email: 'Julie@juliedesk.com',
            name: 'Julie Desk'
        };

        window.currentAttendees = [{
            email: "test@test1.com",
            firstName: "fname1",
            lastName: "lname1",
            name: "fname1 lname1",
            usageName: "fname1",
            gender: 'M',
            isAssistant: "false",
            assisted: "false",
            assistedBy: null,
            company: 'Test Company',
            timezone: "America/Chicago",
            landline: "",
            mobile: "617-216-2881",
            skypeId: "",
            confCallInstructions: '',
            isPresent: "true",
            isClient: "true",
            isThreadOwner: "false"
        },
        {
            email: "test@test2.com",
            firstName: "fname2",
            lastName: "",
            name: "fname2",
            usageName: "fname2",
            gender: 'F',
            isAssistant: "false",
            assisted: "true",
            assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
            company: '',
            landline: "",
            mobile: "617-216-2881",
            skypeId: "",
            confCallInstructions: '',
            isPresent: "true",
            isClient: "false",
            isThreadOwner: "false"
        }];
    };

    describe('Restaurant booking App', function() {
        var $rootScope, $scopeAM, $scope, template, $httpBackend, fetchClientsGET, AttendeesCtrl;

        beforeEach(module('restaurant-booking-controllers'));
        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function($injector, $compile) {

            setWindowVariables();
            window.getCurrentAppointment = function() {
            };
            window.getCurrentAddressObject = function() {
            };

            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();
            $scopeAM = $rootScope.$new();

            var $controller = $injector.get('$controller');
            $httpBackend = $injector.get('$httpBackend');
            fetchClientsGET = $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com');
            fetchClientsGET.respond({userId: 'userX', aliases: {}, companies: {}}, {'A-Token': 'xxx'});

            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scopeAM});

            var element = angular.element("<restaurant-booking-manager/>");
            template = $compile(element)($scope);
            $scope.attendeesManagerCtrl = $scopeAM;
            $scope.$digest();

            fetchClientsGET = $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com');
            fetchClientsGET.respond({contacts: [], aliases: {}, companies: {}});
            $httpBackend.flush();
        }));

        describe('watchers', function() {

           it('should hide the attendees count select when the checkbox is not checked', function() {
               $scope.displayAttendeesCountSelect = false;
               $scope.usingRestaurantBooking = true;
               $scope.$apply();
               expect($scope.displayAttendeesCountSelect).toBe(true);
           });

        });

        describe('event listeners', function() {

            it('should listen to the attendees refreshed event', function() {
                var args = {attendees: [{id: 1}]};
                spyOn($scope, 'updateAttendeesCountSelect');
                $rootScope.$broadcast('attendeesRefreshed', args);

                expect($scope.updateAttendeesCountSelect).toHaveBeenCalledWith([{id: 1}]);
            });
        });

        describe('Methods', function() {

            describe('updateAttendeesCountSelect', function() {
                it('should set the correct selectedAttendeesNb variable', function() {
                    $scope.updateAttendeesCountSelect([{isPresent: true}, {isPresent: true}, {isPresent: true}, {isPresent: true}])
                    expect($scope.selectedAttendeesNb).toEqual('4');
                });
            });

            describe('checkFeatureState', function() {

                it('should set the displayForm variable to the correct value', function() {
                    spyOn($scope, 'functionnalityActive').and.returnValue(true);
                    $scope.displayForm = false;

                    $scope.checkFeatureState();

                    expect($scope.displayForm).toBe(true);
                });

                describe('functionnality inactive', function() {
                    beforeEach(function() {
                        spyOn($scope, 'functionnalityActive').and.returnValue(false);
                    });

                    it('should let the variable usingRestaurantBooking as is', function() {
                        $scope.usingRestaurantBooking = false;
                        $scope.checkFeatureState();

                        expect($scope.usingRestaurantBooking).toBe(false);
                    });
                });

                describe('functionnality active', function() {
                    beforeEach(function() {
                        spyOn($scope, 'functionnalityActive').and.returnValue(true);
                    });

                    it('should set the variable usingRestaurantBooking to true', function() {
                        $scope.usingRestaurantBooking = false;
                        $scope.checkFeatureState();
                        expect($scope.usingRestaurantBooking).toBe(true);
                    });

                    it('should set the variable usingRestaurantBooking to false', function() {
                        spyOn(window, 'getCurrentAddressObject').and.returnValue({
                            kind: 'client_will_define'
                        });
                        $scope.usingRestaurantBooking = false;
                        $scope.checkFeatureState();
                        expect($scope.usingRestaurantBooking).toBe(false);
                    });
                });
            });

            describe('getUsingRestaurantBooking', function() {
                describe('the feature is not used', function() {
                    beforeEach(function() {
                        $scope.usingRestaurantBooking = false;
                    });

                    it('should return the correct value', function() {
                        expect($scope.getUsingRestaurantBooking()).toBe(false)
                    });
                });

                describe('the feature is used', function() {
                    beforeEach(function() {
                        $scope.usingRestaurantBooking = true;
                    });

                    it('should return the correct value', function() {
                        expect($scope.getUsingRestaurantBooking()).toBe(true)
                    });
                });
            });

            describe('getRestaurantBookingDetails', function() {
                describe('the feature is not used', function() {
                   beforeEach(function() {
                       $scope.usingRestaurantBooking = false;
                   });

                    it('should return the correct data object', function() {
                        $scope.selectedAttendeesNb = '4';

                        expect($scope.getRestaurantBookingDetails()).toEqual(null)
                    });
                });

                describe('the feature is used', function() {
                    beforeEach(function() {
                        $scope.usingRestaurantBooking = true;
                    });

                    it('should return the correct data object', function() {
                        $scope.selectedAttendeesNb = '4';

                        expect($scope.getRestaurantBookingDetails()).toEqual({
                            attendees_count_for_restaurant_booking: '4'
                        })
                    });
                });
            });

            describe('functionnalityActive', function() {
                it('should be based on correct scope variables', function() {
                    expect($scope.allowedAppointmentType).toEqual(['breakfast', 'lunch', 'dinner']);
                    expect($scope.allowedAddressType).toEqual(['restaurant']);
                });


                describe('should return true', function(){
                    beforeEach(function() {
                        window.threadAccount.restaurant_booking_enabled = true;

                        window.getCurrentAddressObject = function(){};
                    });

                    describe('dinner', function() {
                        beforeEach(function() {
                            window.getCurrentAppointment = function() {
                                return {
                                    kind: 'dinner'
                                }
                            };
                        });

                        it('should be true', function() {
                            expect($scope.functionnalityActive()).toBe(true);
                        });
                    });

                    describe('lunch', function() {
                        beforeEach(function() {
                            window.getCurrentAppointment = function() {
                                return {
                                    kind: 'lunch'
                                }
                            };
                        });

                        it('should be true', function() {
                            expect($scope.functionnalityActive()).toBe(true);
                        });
                    });

                    describe('breakfast', function() {
                        beforeEach(function() {
                            window.getCurrentAppointment = function() {
                                return {
                                    kind: 'breakfast'
                                }
                            };
                        });

                        it('should be true', function() {
                            expect($scope.functionnalityActive()).toBe(true);
                        });
                    });

                    describe('address is a restaurant', function() {
                        beforeEach(function() {
                            spyOn(window, 'getCurrentAddressObject').and.returnValue({
                               kind: 'restaurant'
                            });
                        });

                        it('should be true', function() {
                            expect($scope.functionnalityActive()).toBe(true);
                        });
                    });
                });

                describe('should return false', function() {

                    describe('functionality deactivated', function() {
                        beforeEach(function() {
                            window.threadAccount.restaurant_booking_enabled = false;
                        });

                        it('should return false', function() {
                            expect($scope.functionnalityActive()).toBe(false);
                        });
                    });

                    describe('functionality activated', function() {
                        beforeEach(function() {
                            window.threadAccount.restaurant_booking_enabled = true;
                        });

                        describe('wrong appointment type', function() {

                            beforeEach(function() {
                                spyOn(window, 'getCurrentAppointment').and.returnValue({
                                    kind: 'meeting'
                                });
                            });

                            it('should return false', function() {
                                expect($scope.functionnalityActive()).toBe(false);
                            });
                        });

                        describe('wrong address type', function() {

                            beforeEach(function() {
                                spyOn(window, 'getCurrentAddressObject').and.returnValue({
                                    kind: 'office'
                                });
                            });

                            it('should return false', function() {
                                expect($scope.functionnalityActive()).toBe(false);
                            });
                        });
                    });


                });

            });

        });

    });

})();