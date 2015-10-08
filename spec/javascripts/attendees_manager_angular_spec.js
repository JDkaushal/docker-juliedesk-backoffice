
//= require jquery
//= require angular_attendees_app

(function(){

    'use strict';

    describe('AttendeesCtrl', function(){
        var $scope, $rootScope, $httpBackend, controller, AttendeesCtrl, SharedProperties, Attendee;

        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_sharedProperties_){
            SharedProperties = _sharedProperties_;

            spyOn(SharedProperties, 'displayAttendeeForm').and.callThrough();
            spyOn(SharedProperties, 'setThreadOwner').and.callThrough();

        }));

        var $controller;

        beforeEach(inject(function($injector){
            // The injector unwraps the underscores (_) from around the parameter names when matching
            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();
            $httpBackend = $injector.get('$httpBackend');
            var $controller = $injector.get('$controller');

            var Class = function(methods) {
                var klass = function() {
                    this.initialize.apply(this, arguments);
                };

                for (var property in methods) {
                    klass.prototype[property] = methods[property];
                }

                if (!klass.prototype.initialize) klass.prototype.initialize = function(){};

                return klass;
            };

            Attendee = Class({
                initialize: function(params){
                    var that = this;
                    $.each( params, function( key, value ) {
                        that[key] = value;
                    });
                },
                assistantDisplayText: function(){
                    return this.assistedBy.usageName + ' (' + this.assistedBy.email + ')';
                }
            });

            window.threadComputedData = {};

            window.threadAccount = {
                addresses: Array[4],
                appointments: Array[13],
                awaiting_current_notes: "",
                block_until_preferences_change: false,
                calendar_logins: Array[1],
                company_hash: null,
                complaints_count: 0,
                contacts_from_same_company: Array[0],
                created_at: "2015-03-17T23:30:24.000+00:00",
                current_notes: "",
                default_timezone_id: "America/Chicago",
                email: "blake@aceable.com",
                email_aliases: Array[0],
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
                    lastName: "lname2",
                    name: "fname2 lname2",
                    usageName: "fname2",
                    gender: 'F',
                    isAssistant: "false",
                    assisted: "true",
                    assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                    company: '',
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: '',
                    isPresent: "false",
                    isClient: "false",
                    isThreadOwner: "false"
                }];

            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scope});

            $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com').respond({userId: 'userX'}, {'A-Token': 'xxx'});
        }));

        it('should have an attendee variable set to the correct attendees', function(){

            var expectedAttendees = [
                new Attendee({
                    email: "test@test1.com",
                    firstName: "fname1",
                    lastName: "lname1",
                    usageName: "fname1",
                    gender: 'M',
                    isAssistant: false,
                    assisted: false,
                    assistedBy: null,
                    company: 'Test Company',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: '',
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: false
                }),
                new Attendee({
                    email: "test@test2.com",
                    firstName: "fname2",
                    lastName: "lname2",
                    usageName: "fname2",
                    gender: 'F',
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: '',
                    isPresent: false,
                    isClient: false,
                    isThreadOwner: false
                })
            ];

            var threadOwner = new Attendee({
                email: "blake@aceable.com",
                firstName: "Blake",
                lastName: "Garrett",
                usageName: "Blake",
                gender: '?',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: 'Julie@juliedesk.com', usageName: 'Julie Desk'},
                company: '',
                timezone: "America/Chicago",
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: true,
                isClient: true,
                isThreadOwner: true
            });

            expectedAttendees.push(threadOwner);
            $httpBackend.flush();
            console.log(AttendeesCtrl.attendees, expectedAttendees);
            expect(angular.equals(AttendeesCtrl.attendees, expectedAttendees)).toBe(true);
        });

        it('should return the correct companies names', function(){
            $httpBackend.flush();
            expect(AttendeesCtrl.getCompaniesNames()).toEqual(['Test Company']);
        });

        it('should call the displayAttendeeForm Method of the sharedProperties Service when opening a new form', function(){
            AttendeesCtrl.displayAttendeeNewForm();
            expect(SharedProperties.displayAttendeeForm).toHaveBeenCalledWith({attendee: {}, action: 'new'});
        });

        it('should call the displayAttendeeForm Method of the sharedProperties Service when opening an update form', function(){
            var attendee = new Attendee({email: 'test'});
            AttendeesCtrl.displayAttendeeUpdateForm(attendee);
            expect(SharedProperties.displayAttendeeForm).toHaveBeenCalledWith({attendee: attendee, action: 'update'});
        });

        it('should send the currentThreadOwner to he sharedProperties service', function(){
            var threadOwner = new Attendee({
                email: "blake@aceable.com",
                firstName: "Blake",
                lastName: "Garrett",
                usageName: "Blake",
                gender: '?',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: 'Julie@juliedesk.com', usageName: 'Julie Desk'},
                company: '',
                timezone: "America/Chicago",
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: true,
                isClient: true,
                isThreadOwner: true
            });
            $httpBackend.flush();
            console.log(SharedProperties.setThreadOwner.calls.mostRecent().args[0]);
            expect(angular.equals(SharedProperties.setThreadOwner.calls.mostRecent().args[0], threadOwner)).toBe(true);
        });

        it('should listen to the attendeeAdded event', function(){

            var attendee = new Attendee({
                email: "test@testfff.com",
                firstName: "fname2",
                lastName: "lname2",
                name: "fname2 lname2",
                usageName: "fname2",
                gender: 'F',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                company: '',
                timezone: "America/Chicago",
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: false,
                isClient: false,
                isThreadOwner: false
            });
            var attendeesLength = AttendeesCtrl.attendees.length;
            $rootScope.$broadcast('attendeeAdded', {attendee: attendee});
            expect(AttendeesCtrl.attendees.length).toEqual(attendeesLength + 1);
        });

    });

    describe('Form Controller Directive', function(){
        var $scope, $rootScope, template, FormCtrl, SharedProperties, Attendee;

        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_sharedProperties_){
            SharedProperties = _sharedProperties_;

        }));

        var $controller;

        beforeEach(inject(function($injector, $compile){
            // The injector unwraps the underscores (_) from around the parameter names when matching
            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();
            var element = angular.element("<attendees-form></attendees-form>");
            template = $compile(element)($scope);
            $scope.$digest();

            FormCtrl = element.controller('attendeesForm');


            var Class = function(methods) {
                var klass = function() {
                    this.initialize.apply(this, arguments);
                };

                for (var property in methods) {
                    klass.prototype[property] = methods[property];
                }

                if (!klass.prototype.initialize) klass.prototype.initialize = function(){};

                return klass;
            };

            Attendee = Class({
                initialize: function(params){
                    var that = this;
                    $.each( params, function( key, value ) {
                        that[key] = value;
                    });
                },
                assistantDisplayText: function(){
                    return this.assistedBy.usageName + ' (' + this.assistedBy.email + ')';
                }
            });

            window.threadAccount = {
                addresses: Array[4],
                appointments: Array[13],
                awaiting_current_notes: "",
                block_until_preferences_change: false,
                calendar_logins: Array[1],
                company_hash: null,
                complaints_count: 0,
                contacts_from_same_company: Array[0],
                created_at: "2015-03-17T23:30:24.000+00:00",
                current_notes: "",
                default_timezone_id: "America/Chicago",
                email: "blake@aceable.com",
                email_aliases: Array[0],
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
                    lastName: "lname2",
                    name: "fname2 lname2",
                    usageName: "fname2",
                    gender: 'F',
                    isAssistant: "false",
                    assisted: "true",
                    assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                    company: '',
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: '',
                    isPresent: "false",
                    isClient: "false",
                    isThreadOwner: "false"
                }];
        }));

        it('should set the correct Attendee in the form and make a copy of it', function(){
            var attendee = new Attendee({
                email: "test@testfff.com",
                firstName: "fname2",
                lastName: "lname2",
                name: "fname2 lname2",
                usageName: "fname2",
                gender: 'F',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                company: '',
                timezone: "America/Chicago",
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: false,
                isClient: false,
                isThreadOwner: false
            });

            FormCtrl.setAttendeeInForm(attendee);

            expect(angular.equals(FormCtrl.attendeeInForm, attendee)).toBe(true);
            expect(angular.equals(FormCtrl.getOriginalAttendee(), attendee)).toBe(true);
        });

        it('should cancel the form, restore the object to its previous state and hide the form', function(){
            var attendee = new Attendee({
                email: "test@testfff.com",
                firstName: "fname2",
                lastName: "lname2",
                name: "fname2 lname2",
                usageName: "fname2",
                gender: 'F',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                company: '',
                timezone: "America/Chicago",
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: false,
                isClient: false,
                isThreadOwner: false
            });

            FormCtrl.setAttendeeInForm(attendee);
            FormCtrl.attendeeInForm.email = 'toto';
            expect(FormCtrl.attendeeInForm.email).toEqual('toto');

            FormCtrl.cancelAttendeeForm();
            expect(FormCtrl.attendeeInForm.email).toEqual('test@testfff.com');

            expect(FormCtrl.isVisible).toBe(false);
        });

        it('should correctly manage the isAssisted and isAssistant checkboxes accessibility', function(){
            FormCtrl.attendeeInForm.isAssistant = true;
            FormCtrl.attendeeInForm.email = 'test';
            FormCtrl.setAssistant();
            expect(FormCtrl.attendeeInForm.isAssistant).toBe(false);

            FormCtrl.attendeeInForm.assisted = true;
            FormCtrl.checkAssistantConditions({email: {$error : []}});
            expect(FormCtrl.attendeeInForm.assisted).toBe(false);
        });

        it('should display an error message if the user click on the isAssistant checkbox and no email has been specified', function(){
            FormCtrl.attendeeInForm.email = '';
            FormCtrl.checkAssistantConditions({email: {$error : {}}});
            expect(FormCtrl.attendeeInForm.isAssistant).toBe(false);
            expect(FormCtrl.displayAssistantEmailError).toBe(true);

            FormCtrl.displayAssistantEmailError = false;
            FormCtrl.attendeeInForm.email = 'test';
            FormCtrl.checkAssistantConditions({email: {$error : {"required": true}}});
            expect(FormCtrl.attendeeInForm.isAssistant).toBe(false);
            expect(FormCtrl.displayAssistantEmailError).toBe(true);

            FormCtrl.displayAssistantEmailError = false;
            FormCtrl.attendeeInForm.email = undefined;
            FormCtrl.checkAssistantConditions({email: {$error : {}}});
            expect(FormCtrl.attendeeInForm.isAssistant).toBe(false);
            expect(FormCtrl.displayAssistantEmailError).toBe(true);
        });

        it ('should return is it the provided mode is the current one', function(){
            FormCtrl.currentMode = 'new';
            expect(FormCtrl.isCurrentMode('new')).toBe(true);
        });

        it('should listen to the attendeeFormDisplayed', function(){
            spyOn(FormCtrl, 'setAttendeeInForm').and.callThrough();
            spyOn(FormCtrl, 'checkIfTimezoneNeeded').and.callThrough();

            $rootScope.$broadcast('attendeeFormDisplayed', {attendee: {}, action: 'new'});

            expect(FormCtrl.currentMode).toEqual('new');
            expect(FormCtrl.setAttendeeInForm).toHaveBeenCalledWith({});

            expect(FormCtrl.isVisible).toBe(true);

        });

        it('should add a new Attendee', function(){
            spyOn(SharedProperties, 'notifyAttendeeAdded').and.callThrough();

            var attendee = {
                email: "test@testfff.com",
                firstName: "fname2",
                lastName: "lname2",
                name: "fname2 lname2",
                usageName: "fname2",
                gender: 'F',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                company: '',
                timezone: "America/Chicago",
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: false,
                isClient: false,
                isThreadOwner: false
            };

            FormCtrl.setAttendeeInForm(attendee);
            FormCtrl.addAttendee();

            expect(angular.equals(SharedProperties.notifyAttendeeAdded.calls.mostRecent().args[0], new Attendee(attendee))).toBe(true);

            expect(FormCtrl.isVisible).toBe(false);
        });

        it('should find if a timezone field is needed in the form', function(){
            FormCtrl.checkIfTimezoneNeeded('skype');
            expect(FormCtrl.timezoneNeeded).toBe(true);

            FormCtrl.checkIfTimezoneNeeded('coffee');
            expect(FormCtrl.timezoneNeeded).toBe(false);
        });

    });

    describe('Attendees Filter group by companies then order by company name', function(){
        var filter, filterGroupBy, filterToArray;

        beforeEach(module('attendees-manager-filters'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_$filter_){
            var $filter = _$filter_;

            filter = $filter('organizeContactArray');
            filterGroupBy = $filter('groupBy');
            filterToArray = $filter('toArray');
        }));


        it('should reorganize the hash by company names', function(){
            //var initialArray = [{$key: 'A',  }]
            var attendees = [{
                email: "test@test1.com",
                firstName: "fname1",
                lastName: "lname1",
                name: "fname1 lname1",
                usageName: "fname1",
                gender: 'M',
                isAssistant: "false",
                assisted: "false",
                assistedBy: null,
                company: 'B',
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
                lastName: "lname2",
                name: "fname2 lname2",
                usageName: "fname2",
                gender: 'F',
                isAssistant: "false",
                assisted: "true",
                assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                company: 'C',
                landline: "",
                mobile: "617-216-2881",
                skypeId: "",
                confCallInstructions: '',
                isPresent: "false",
                isClient: "false",
                isThreadOwner: "false"
            },
                {
                    email: "test@test2.com",
                    firstName: "fname2",
                    lastName: "lname2",
                    name: "fname2 lname2",
                    usageName: "fname2",
                    gender: 'F',
                    isAssistant: "false",
                    assisted: "true",
                    assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                    company: 'A',
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: '',
                    isPresent: "false",
                    isClient: "false",
                    isThreadOwner: "false"
                },
                {
                    email: "test@test2.com",
                    firstName: "fname2",
                    lastName: "lname2",
                    name: "fname2 lname2",
                    usageName: "fname2",
                    gender: 'F',
                    isAssistant: "false",
                    assisted: "true",
                    assistedBy: {email: 'Julie2@juliedesk.com', usageName: 'Julie2 Desk'},
                    company: 'C',
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: '',
                    isPresent: "false",
                    isClient: "false",
                    isThreadOwner: "false"
                }];

            var  x = filterGroupBy(attendees, 'company');
            var y = filterToArray(x, true);
            var z = filter(y);
            var keys = [];
            for(var k in z) keys.push(k);
            expect(keys).toEqual(["A", "B", "C"]);
        });
    });
})();