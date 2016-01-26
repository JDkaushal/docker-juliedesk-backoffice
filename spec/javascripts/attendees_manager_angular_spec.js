//= require angular_attendees_app

(function(){

    'use strict';

    describe('AttendeesCtrl', function(){
        var $scope, $rootScope, $httpBackend, $http, fetchClientsGET, controller, AttendeesCtrl, SharedProperties, Attendee;

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
            $http = $injector.get('$http');
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
                    isPresent: "false",
                    isClient: "false",
                    isThreadOwner: "false"
                }];

            window.currentToCC = ["test@test2.com", "test@test1.com"];

            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scope, $http: $http});

            fetchClientsGET = $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com');
            fetchClientsGET.respond({userId: 'userX', aliases: {}, companies: {}}, {'A-Token': 'xxx'});

            //spyOn( $scope, 'guid' ).and.returnValue(0);

        }));

        describe('Missing Informations', function(){

            beforeEach(function(){
                window.generateEmailTemplate = function(){};
                window.currentLocale = 'fr';
            });

            describe('no appointments select is present in the DOM', function(){

                it('should return an empty string', function(){
                    window.getCurrentAppointment = function(){
                        return {required_additional_informations: 'empty'}
                    };

                    spyOn( window, 'updateNotesCallingInfos' );
                    spyOn( window, 'getCurrentAppointment' );
                    $httpBackend.flush();

                    expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
                    expect( window.getCurrentAppointment ).not.toHaveBeenCalled();

                    expect($scope.checkMissingInformations()).toEqual('');
                });
            });

            describe('appointments select is present in the DOM', function(){

                beforeEach(function(){
                    var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout">hangout</option><option value="confcall">confcall</option></select>';
                    angular.element(document.body).append(html);
                });

                afterEach(function() {
                    $('#appointment_nature').remove();
                });

                describe('should generate the correct message when no additional informations are required', function(){
                    beforeEach(function(){

                    });

                    it('when no required additional informations are specified', function(){
                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'empty'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();

                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        expect($scope.checkMissingInformations()).toEqual('');
                    });

                    it('when the current virtual appointment configuration is targeting an interlocutor', function(){
                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'mobile_only'}
                        };
                        $scope.virtualAppointmentsHelper = {
                            currentConf:{target: "interlocutor"}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();

                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        expect($scope.checkMissingInformations()).toEqual('');
                    });

                    it('when the current virtual appointment configuration is targeting a client and we want to ask early', function(){
                        window.currentAttendees.push({
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'mobile_only'}
                        };
                        $scope.virtualAppointmentsHelper = {
                            currentConf:{target: "client"}
                        };

                        window.presentAttendees = function(){
                            return _.filter($scope.attendees, function(attendee) {
                                return attendee.isPresent;
                            });
                        };

                        window.threadComputedData.locale = 'fr';
                        spyOn( window, 'generateEmailTemplate' );

                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();

                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations({ask_early_call: true});
                        expect( window.generateEmailTemplate ).not.toHaveBeenCalled();
                    });

                });

                describe('should generate the correct message when informations are missing', function(){

                    beforeEach(function(){
                        window.presentAttendees = function(){
                            return _.filter($scope.attendees, function(attendee) {
                                return attendee.isPresent;
                            });
                        };

                        window.threadComputedData.locale = 'fr';
                        spyOn( window, 'generateEmailTemplate' );
                    });

                    it('mobile_only informations are missing on one attendee with multiple other attendees on a virtual appointment', function(){
                        window.currentAttendees.push({
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'mobile_only'}
                        };

                        $scope.virtualAppointmentsHelper = {
                            currentConf:{target: "client"}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );
                        $httpBackend.flush();

                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations();
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'mobile_only', assisted: false, attendees: [ 'Fname3' ], multipleAttendees: true, redundantCourtesy: false, locale: 'fr' });
                    });

                    it('landline_or_mobile informations are missing on multiple attendees with multiple other attendees on a virtual appointment', function(){
                        window.currentAttendees.push({
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test4.com",
                            firstName: "fname4",
                            lastName: "lname4",
                            name: "fname4 lname4",
                            usageName: "fname4",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 3',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test5.com",
                            firstName: "fname5",
                            lastName: "lname5",
                            name: "fname5 lname5",
                            usageName: "fname5",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 4',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'landline_or_mobile'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations();
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'landline_or_mobile', assisted: false, attendees: ["Fname3", "Fname4", "Fname5"], multipleAttendees: true, redundantCourtesy: false, locale: 'fr' });
                    });

                    it('skype_only informations are missing on one attendee with no other attendees on a non virtual appointment', function(){
                        window.currentAttendees = [{
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        }];

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'skype_only'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations();
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'skype_only', assisted: false, attendees: [ 'Fname3' ], multipleAttendees: false, redundantCourtesy: false, locale: 'fr' });
                    });

                    it('skype_only informations are missing on one attendee who is assisted with no other attendees on a non virtual appointment', function(){
                        window.currentAttendees = [{
                            email: "test@test1.com",
                            firstName: "fname1",
                            lastName: "lname1",
                            name: "fname1 lname1",
                            usageName: "fname1",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "true",
                            assistedBy: {email: "test@test2.com", name: "fname2 lname2", guid: 3},
                            id: 2,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },
                        {
                            email: "test@test2.com",
                            firstName: "fname2",
                            lastName: "lname2",
                            name: "fname2 lname2",
                            usageName: "fname2",
                            gender: 'M',
                            isAssistant: "true",
                            assisted: "false",
                            assistedBy: null,
                            id: 3,
                            company: 'Test Company 3',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        }];

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'skype_only'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations();
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'skype_only', assisted: true, attendees: [ 'Fname1' ], multipleAttendees: false, redundantCourtesy: false, locale: 'fr' });
                    });

                    it('skype_only informations are missing on one attendee with no other attendees on a non virtual appointment with redundant courtesy used', function(){
                        window.currentAttendees.push({
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test4.com",
                            firstName: "fname4",
                            lastName: "lname4",
                            name: "fname4 lname4",
                            usageName: "fname4",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 3',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test5.com",
                            firstName: "fname5",
                            lastName: "lname5",
                            name: "fname5 lname5",
                            usageName: "fname5",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 4',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test6.com",
                            firstName: "fname6",
                            lastName: "lname6",
                            name: "fname6 lname6",
                            usageName: "fname6",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 5',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'skype_only'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations({redundantCourtesy: true});
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'skype_only', assisted: false, attendees: ["Fname3", "Fname4", "Fname5", "Fname6"], multipleAttendees: true, redundantCourtesy: true, locale: 'fr' });
                    });

                    it('skype is missing on multiple attendees but some of them have no emails and are not assisted', function(){

                        window.currentAttendees.push({
                            email: "",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "",
                            firstName: "fname4",
                            lastName: "lname4",
                            name: "fname4 lname4",
                            usageName: "fname4",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 3',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "",
                            firstName: "fname5",
                            lastName: "lname5",
                            name: "fname5 lname5",
                            usageName: "fname5",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 4',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test6.com",
                            firstName: "fname6",
                            lastName: "lname6",
                            name: "fname6 lname6",
                            usageName: "fname6",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 5',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'skype_only'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations({redundantCourtesy: true});
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'skype_only', assisted: false, attendees: ["Fname6"], multipleAttendees: true, redundantCourtesy: true, locale: 'fr' });
                    });
                    it('skype is missing on multiple attendees but some of them have no emails but they are assisted', function(){

                        window.currentAttendees.push({
                            email: "",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "true",
                            assistedBy: {test: '123'},
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "",
                            firstName: "fname4",
                            lastName: "lname4",
                            name: "fname4 lname4",
                            usageName: "fname4",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "true",
                            assistedBy: {guid: '123'},
                            company: 'Test Company 3',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "",
                            firstName: "fname5",
                            lastName: "lname5",
                            name: "fname5 lname5",
                            usageName: "fname5",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 4',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test6.com",
                            firstName: "fname6",
                            lastName: "lname6",
                            name: "fname6 lname6",
                            usageName: "fname6",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 5',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        console.log(window.currentAttendees);
                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'skype_only'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        console.log(window.currentAttendees);

                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations({redundantCourtesy: true});
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'skype_only', assisted: false, attendees: ["Fname3", "Fname4", "Fname6"], multipleAttendees: true, redundantCourtesy: true, locale: 'fr' });
                    });

                    it('skype is missing on multiple attendees but one of them from the same company has its informations', function(){

                        window.currentAttendees.push({
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test4.com",
                            firstName: "fname4",
                            lastName: "lname4",
                            name: "fname4 lname4",
                            usageName: "fname4",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test5.com",
                            firstName: "fname5",
                            lastName: "lname5",
                            name: "fname5 lname5",
                            usageName: "fname5",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test6.com",
                            firstName: "fname6",
                            lastName: "lname6",
                            name: "fname6 lname6",
                            usageName: "fname6",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "skypeid",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'skype_only'}
                        };
                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();

                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations({redundantCourtesy: true});
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'skype_only', assisted: false, attendees: [], multipleAttendees: true, redundantCourtesy: true, locale: 'fr' });
                    });

                    it('when the current virtual appointment configuration is targeting an interlocutor and we want to ask early', function(){
                        window.currentAttendees.push({
                            email: "test@test3.com",
                            firstName: "fname3",
                            lastName: "lname3",
                            name: "fname3 lname3",
                            usageName: "fname3",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 2',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test4.com",
                            firstName: "fname4",
                            lastName: "lname4",
                            name: "fname4 lname4",
                            usageName: "fname4",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 3',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test5.com",
                            firstName: "fname5",
                            lastName: "lname5",
                            name: "fname5 lname5",
                            usageName: "fname5",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 4',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        },{
                            email: "test@test6.com",
                            firstName: "fname6",
                            lastName: "lname6",
                            name: "fname6 lname6",
                            usageName: "fname6",
                            gender: 'M',
                            isAssistant: "false",
                            assisted: "false",
                            assistedBy: null,
                            company: 'Test Company 5',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "",
                            skypeId: "",
                            confCallInstructions: '',
                            isPresent: "true",
                            isClient: "false",
                            isThreadOwner: "false"
                        });

                        window.getCurrentAppointment = function(){
                            return {required_additional_informations: 'mobile_only'}
                        };
                        $scope.virtualAppointmentsHelper = {
                            currentConf:{target: "interlocutor"}
                        };

                        spyOn( window, 'updateNotesCallingInfos' );

                        $httpBackend.flush();
                        expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                        $scope.checkMissingInformations({redundantCourtesy: true, ask_early_skype: true});
                        expect( window.generateEmailTemplate ).toHaveBeenCalledWith({ action: 'ask_additional_informations', requiredAdditionalInformations: 'mobile_only', assisted: false, attendees: ["Fname3", "Fname4", "Fname5", "Fname6"], multipleAttendees: true, redundantCourtesy: true, locale: 'fr' });
                    });

                });

            });

            describe('missingInformationAttendeesFilter', function(){

                describe('attendee has an email', function(){
                    it('should return true', function(){
                        var attendee = new Attendee({
                            email: "test@test2.com",
                            firstName: "fname2",
                            lastName: "",
                            usageName: "fname2",
                            name: "fname2",
                            gender: 'F',
                            guid: 0,
                            hasMissingInformations: false,
                            missingInformationsTemp: {},
                            isAssistant: false,
                            assisted: true,
                            assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                            company: '',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "617-216-2881",
                            skypeId: "",
                            confCallInstructions: "",
                            isPresent: undefined,
                            isClient: false,
                            isThreadOwner: false
                        });

                        spyOn($scope, 'getAttendeesOnPresence' ).and.returnValue([attendee]);

                        expect($scope.missingInformationAttendeesFilter(attendee)).toBe(true);
                    });

                    it('should return false', function(){
                        var attendee = new Attendee({
                            email: "",
                            firstName: "fname2",
                            lastName: "",
                            usageName: "fname2",
                            name: "fname2",
                            gender: 'F',
                            guid: 0,
                            hasMissingInformations: false,
                            missingInformationsTemp: {},
                            isAssistant: false,
                            assisted: true,
                            assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                            company: '',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "617-216-2881",
                            skypeId: "",
                            confCallInstructions: "",
                            isPresent: undefined,
                            isClient: false,
                            isThreadOwner: false
                        });
                        spyOn($scope, 'getAttendeesOnPresence' ).and.returnValue([attendee]);

                        expect($scope.missingInformationAttendeesFilter(attendee)).toBe(false);
                    });
                });

                describe('attendee has no email and is not assisted', function(){
                    it('it should return false', function(){
                        var attendee = new Attendee({
                            email: "",
                            firstName: "fname2",
                            lastName: "",
                            usageName: "fname2",
                            name: "fname2",
                            gender: 'F',
                            guid: 0,
                            hasMissingInformations: false,
                            missingInformationsTemp: {},
                            isAssistant: false,
                            assisted: false,
                            assistedBy: null,
                            company: '',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "617-216-2881",
                            skypeId: "",
                            confCallInstructions: "",
                            isPresent: undefined,
                            isClient: false,
                            isThreadOwner: false
                        });
                        spyOn($scope, 'getAttendeesOnPresence' ).and.returnValue([attendee]);

                        expect($scope.missingInformationAttendeesFilter(attendee)).toBe(false);
                    });
                });

                describe('attendee has no email but is assisted', function(){
                    it('it should return true', function(){
                        var attendee = new Attendee({
                            email: "",
                            firstName: "fname2",
                            lastName: "",
                            usageName: "fname2",
                            name: "fname2",
                            gender: 'F',
                            guid: 0,
                            hasMissingInformations: false,
                            missingInformationsTemp: {},
                            isAssistant: false,
                            assisted: true,
                            assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk', guid: '123'},
                            company: '',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "617-216-2881",
                            skypeId: "",
                            confCallInstructions: "",
                            isPresent: undefined,
                            isClient: false,
                            isThreadOwner: false
                        });
                        spyOn($scope, 'getAttendeesOnPresence' ).and.returnValue([attendee]);

                        expect($scope.missingInformationAttendeesFilter(attendee)).toBe(true);
                    });
                });

                describe('attendee has an email but another attendee from same company has its informations', function(){
                    it('should return false', function(){
                        var attendee1 = new Attendee({
                            email: "email2@gmail.com",
                            firstName: "fname2",
                            lastName: "",
                            usageName: "fname2",
                            name: "fname2",
                            gender: 'F',
                            guid: 1,
                            hasMissingInformations: true,
                            missingInformationsTemp: {},
                            isAssistant: false,
                            assisted: false,
                            assistedBy: null,
                            company: 'company1',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "617-216-2881",
                            skypeId: "",
                            confCallInstructions: "",
                            isPresent: undefined,
                            isClient: false,
                            isThreadOwner: false
                        });

                        var attendee2 = new Attendee({
                            email: "email3@gmail.com",
                            firstName: "fname3",
                            lastName: "",
                            usageName: "fname3",
                            name: "fname3",
                            gender: 'F',
                            guid: 2,
                            hasMissingInformations: false,
                            missingInformationsTemp: {},
                            isAssistant: false,
                            assisted: false,
                            assistedBy: null,
                            company: 'company1',
                            timezone: "America/Chicago",
                            landline: "",
                            mobile: "617-216-2881",
                            skypeId: "skypous",
                            confCallInstructions: "",
                            isPresent: undefined,
                            isClient: false,
                            isThreadOwner: false
                        });

                        spyOn($scope, 'getAttendeesOnPresence' ).and.returnValue([attendee1, attendee2]);

                        expect($scope.missingInformationAttendeesFilter(attendee1)).toBe(false);
                    });
                });
            });

        });

        describe('Attendees', function(){
            beforeEach(function(){
                spyOn( $scope, 'guid' ).and.returnValue(0);
            });


            it('should have a method to format its informations', function(){
                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect($scope.attendees[0].displayNormalizedName()).toEqual('fname1 lname1');
                expect($scope.attendees[1].displayNormalizedName()).toEqual('fname2');
            });

            it("should have a method to format the attendee's calling informations", function(){
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
                        landline: "000-8765-321",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "false",
                        isClient: "false",
                        isThreadOwner: "false"
                    }];


                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect($scope.attendees[0].displayPhoneInformations()).toEqual('617-216-2881');
                expect($scope.attendees[1].displayPhoneInformations()).toEqual('617-216-2881 / 000-8765-321');
            });

            it("should have a method to format all it's informations", function(){
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
                        landline: "000-8765-321",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "false",
                        isClient: "false",
                        isThreadOwner: "false"
                    }];

                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect($scope.attendees[0].computeContactNotes()).toEqual("\nfname1 lname1\nTéléphone : 617-216-2881");
                expect($scope.attendees[1].computeContactNotes()).toEqual("\nfname2\nTéléphone : 617-216-2881 / 000-8765-321");
            });

            it("should have a method to display it's assistedBy informations", function(){
                window.currentAttendees = [{
                    email: "test@test1.com",
                    firstName: "fname1",
                    lastName: "lname1",
                    name: "fname1 lname1",
                    usageName: "fname1",
                    gender: 'M',
                    isAssistant: "false",
                    assisted: "false",
                    assistedBy: {displayName: "Julie Desk", email:"julie@juliedesk.com"},
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
                        landline: "000-8765-321",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "false",
                        isClient: "false",
                        isThreadOwner: "false"
                    }];

                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect($scope.attendees[0].assistantDisplayText()).toEqual("Julie Desk (julie@juliedesk.com)");
            });

            it('should have an attendee variable set to the correct attendees', function(){

                var expectedAttendees = [
                    new Attendee({
                        email: "test@test1.com",
                        firstName: "fname1",
                        lastName: "lname1",
                        usageName: "fname1",
                        name: "fname1 lname1",
                        gender: 'M',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: false,
                        assistedBy: null,
                        company: 'Test Company',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: true,
                        isClient: true,
                        isThreadOwner: false
                    }),
                    new Attendee({
                        email: "test@test2.com",
                        firstName: "fname2",
                        lastName: "",
                        usageName: "fname2",
                        name: "fname2",
                        gender: 'F',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: true,
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: undefined,
                        isClient: false,
                        isThreadOwner: false
                    })
                ];

                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });

                // We do this to bypass this methode since there is no DOM, it raise an exception when trying to replace the value of a DOM element
                spyOn( window, 'updateNotesCallingInfos' );
                expectedAttendees.push(threadOwner);
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
                expect(angular.equals($scope.attendees, expectedAttendees)).toBe(true);
            });

            it('should return the correct assistant', function(){
                window.currentAttendees = [{
                    email: "test@test1.com",
                    firstName: "fname1",
                    lastName: "lname1",
                    name: "fname1 lname1",
                    usageName: "fname1",
                    gender: 'M',
                    isAssistant: "false",
                    assisted: "false",
                    assistedBy: {displayName: "fname2", email:"test@test2.com", guid:3},
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
                        id: 3,
                        isAssistant: "false",
                        assisted: "true",
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        landline: "000-8765-321",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "false",
                        isClient: "false",
                        isThreadOwner: "false"
                    }];

                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect(angular.equals($scope.getAssistant($scope.attendees[0]), $scope.attendees[1])).toBe(true);
            });

            it('should return the correct Assistant by email', function(){
                window.currentAttendees = [{
                    email: "test@test1.com",
                    firstName: "fname1",
                    lastName: "lname1",
                    name: "fname1 lname1",
                    usageName: "fname1",
                    gender: 'M',
                    isAssistant: "false",
                    assisted: "false",
                    assistedBy: {displayName: "fname2", email:"test@test2.com", guid:3},
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
                        id: 3,
                        isAssistant: "false",
                        assisted: "true",
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        landline: "000-8765-321",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "false",
                        isClient: "false",
                        isThreadOwner: "false"
                    }];

                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect(angular.equals($scope.getAssistedByEmail($scope.attendees[1]), $scope.attendees[0])).toBe(true);
            });

            it('should return the correct Assisted', function(){
                window.currentAttendees = [{
                    email: "test@test1.com",
                    firstName: "fname1",
                    lastName: "lname1",
                    name: "fname1 lname1",
                    usageName: "fname1",
                    gender: 'M',
                    isAssistant: "false",
                    assisted: "false",
                    assistedBy: {displayName: "fname2", email:"test@test2.com", guid:3},
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
                        id: 3,
                        isAssistant: "false",
                        assisted: "true",
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        landline: "000-8765-321",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "false",
                        isClient: "false",
                        isThreadOwner: "false"
                    }];

                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect(angular.equals($scope.getAssisted($scope.attendees[1]), $scope.attendees[0])).toBe(true);
            });

            it('should return the correct companies names', function(){
                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
                expect(AttendeesCtrl.getCompaniesNames()).toEqual(['Test Company']);
            });

            it('should call the displayAttendeeForm Method of the sharedProperties Service when opening a new form', function(){
                AttendeesCtrl.displayAttendeeNewForm();
                expect(SharedProperties.displayAttendeeForm).toHaveBeenCalledWith({attendee: { timezone: 'America/Chicago', isPresent: true }, action: 'new'});
            });

            it('should call the displayAttendeeForm Method of the sharedProperties Service when opening an update form', function(){
                var attendee = new Attendee({email: 'test'});
                AttendeesCtrl.displayAttendeeUpdateForm(attendee);
                expect(SharedProperties.displayAttendeeForm).toHaveBeenCalledWith({attendee: attendee, action: 'update'});
            });

            it('should send the currentThreadOwner to the sharedProperties service', function(){
                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });
                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
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
                var attendeesLength = $scope.attendees.length;
                $rootScope.$broadcast('attendeeAdded', {attendee: attendee});
                expect($scope.attendees.length).toEqual(attendeesLength + 1);
            });

            it('should return the current Thread Owner', function(){
                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });
                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect(angular.equals($scope.getThreadOwner(), threadOwner)).toBe(true);
            });

            it('should get the current ThreadOwner emails', function(){
                expect($scope.getThreadOwnerEmails()).toEqual([ 'blake@aceable.com', 'threadOwnerAlias1@alias.com' ]);
            });

            it('should get the current contacts infos from the notes in EN', function(){
                var notes = '';

                notes += '-Contacts-Infos-------------------';
                notes += 'Blablalblrfrefrefe';
                notes += "\n----------------------------------------";

                expect(AttendeesCtrl.getCurrentContactsInfosEn(notes.replace(/\n/g, ''))[0]).toEqual('-Contacts-Infos-------------------Blablalblrfrefrefe----------------------------------------');
            });

            it('should get the current contacts infos from the notes in FR', function(){
                var notes = '';

                notes += '-Informations-de-contacts-------------------';
                notes += 'Blablalblrfrefrefe';
                notes += "\n----------------------------------------";

                expect(AttendeesCtrl.getCurrentContactsInfosFr(notes.replace(/\n/g, ''))[0]).toEqual('-Informations-de-contacts-------------------Blablalblrfrefrefe----------------------------------------');
            });

            it('should call updateNotes every time the attendees are updated', function(){
                spyOn( window, 'updateNotesCallingInfos' );
                $httpBackend.flush();
                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                $scope.attendees[0].email = 'newEmail@frefe.com';
                expect( window.updateNotesCallingInfos ).toHaveBeenCalledWith();
            });

            it('should trigger the attendeesRefreshed event when an attendee is updated', function(){
                spyOn( window, 'updateNotesCallingInfos' );
                spyOn( $rootScope, '$broadcast').and.callThrough();

                $httpBackend.flush();

                $scope.attendees[0].email = 'newEmail@frefe.com';
                expect($rootScope.$broadcast).toHaveBeenCalled();
                expect(angular.equals($rootScope.$broadcast.calls.mostRecent().args[1].attendees, $scope.attendees)).toBe(true);

            });

            it('should update correctly the notes in EN', function(){
                window.currentLocale = 'en';
                var html = '<textarea class="data-entry form-control" id="notes" name="notes" disabled="">-Contacts-Infos-------------------\
                Frederic GRAIS\
            Téléphone: hythtyhy / hythtyhhyhtyhty\
            ----------------------------------------</textarea>';
                angular.element(document.body).append(html);

                $httpBackend.flush();
                $scope.updateNotes();

                var expectedNotes = '-Contacts-Infos-------------------fname1 lname1Téléphone : 617-216-2881----------------------------------------';

                expect($('#notes').val().replace(/\n/g, '')).toEqual(expectedNotes);

                $('#notes').remove();
            });

            it('should update correctly the notes in FR', function(){
                window.currentLocale = 'en';
                var html = '<textarea class="data-entry form-control" id="notes" name="notes" disabled="">-Contacts-Infos-------------------\
                Frederic GRAIS\
            Téléphone: hythtyhy / hythtyhhyhtyhty\
            ----------------------------------------</textarea>';
                angular.element(document.body).append(html);

                $httpBackend.flush();
                $scope.updateNotes();

                var expectedNotes = '-Contacts-Infos-------------------fname1 lname1Téléphone : 617-216-2881----------------------------------------';

                expect($('#notes').val().replace(/\n/g, '')).toEqual(expectedNotes);

                $('#notes').remove();
            });

            it('should override the attendees details with the ones retrieved from the contact network', function(){
                fetchClientsGET.respond({contacts: [{
                    email: "test@test1.com",
                    firstName: "overriden firstName",
                    lastName: "overriden lastName",
                    name: "fname1 lname1",
                    usageName: "fname1",
                    gender: 'M',
                    id: 1,
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
                }], aliases: {}, companies: {}}, {'A-Token': 'xxx'});

                var expectedAttendees = [
                    new Attendee({
                        email: "test@test1.com",
                        firstName: "overriden firstName",
                        lastName: "overriden lastName",
                        usageName: "fname1",
                        name: "overriden firstName overriden lastName",
                        gender: 'M',
                        guid: 1,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: false,
                        assistedBy: null,
                        company: 'Test Company',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: true,
                        isClient: true,
                        isThreadOwner: false
                    }),
                    new Attendee({
                        email: "test@test2.com",
                        firstName: "fname2",
                        lastName: "",
                        usageName: "fname2",
                        name: "fname2",
                        gender: 'F',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: true,
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: undefined,
                        isClient: false,
                        isThreadOwner: false
                    })
                ];

                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });

                // We do this to bypass this methode since there is no DOM, it raise an exception when trying to replace the value of a DOM element
                spyOn( window, 'updateNotesCallingInfos' );
                expectedAttendees.push(threadOwner);
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
                expect(angular.equals($scope.attendees, expectedAttendees)).toBe(true);
            });

            it('should only keep the main email when it is in the current recipient even if there is an alias present', function(){
                fetchClientsGET.respond({contacts: [], aliases: {"test@test1.com": ["testalias@test1.com"]}, companies: {'test@test1.com': 'Test Company'}}, {'A-Token': 'xxx'});

                window.currentAttendees.push({
                    email: "testalias@test1.com",
                    firstName: "aliasfname1",
                    lastName: "aliaslname1",
                    name: "aliasfname1 aliaslname1",
                    usageName: "aliasfname1",
                    gender: 'M',
                    guid: 0,
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
                });

                var expectedAttendees = [
                    new Attendee({
                        email: "test@test1.com",
                        firstName: "fname1",
                        lastName: "lname1",
                        usageName: "fname1",
                        name: "fname1 lname1",
                        gender: 'M',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: false,
                        assistedBy: null,
                        company: 'Test Company',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: true,
                        isClient: true,
                        isThreadOwner: false
                    }),
                    new Attendee({
                        email: "test@test2.com",
                        firstName: "fname2",
                        lastName: "",
                        usageName: "fname2",
                        name: "fname2",
                        gender: 'F',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: true,
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: undefined,
                        isClient: false,
                        isThreadOwner: false
                    })
                ];

                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });

                spyOn( window, 'updateNotesCallingInfos' );
                expectedAttendees.push(threadOwner);
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();

                expect(angular.equals($scope.attendees, expectedAttendees)).toBe(true);

            });

            it('should keep the alias if it is in the recipient and the main email is not', function(){

                fetchClientsGET.respond({contacts: [], aliases: {"test@test1.com": ["testalias@test1.com"]}, companies: {'test@test1.com': 'Test Company'}}, {'A-Token': 'xxx'});

                window.currentToCC = ["test@test2.com", "testalias@test1.com"];

                window.currentAttendees.push({
                    email: "testalias@test1.com",
                    firstName: "aliasfname1",
                    lastName: "aliaslname1",
                    name: "aliasfname1 aliaslname1",
                    usageName: "aliasfname1",
                    gender: 'M',
                    guid: 0,
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
                });

                var expectedAttendees = [
                    new Attendee({
                        email: "test@test2.com",
                        firstName: "fname2",
                        lastName: "",
                        usageName: "fname2",
                        name: "fname2",
                        gender: 'F',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: true,
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: undefined,
                        isClient: false,
                        isThreadOwner: false
                    }),
                    new Attendee({
                        email: "testalias@test1.com",
                        firstName: "aliasfname1",
                        lastName: "aliaslname1",
                        name: "aliasfname1 aliaslname1",
                        usageName: "aliasfname1",
                        gender: 'M',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
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
                    })
                ];

                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });

                spyOn( window, 'updateNotesCallingInfos' );
                expectedAttendees.push(threadOwner);
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
                expect(angular.equals($scope.attendees, expectedAttendees)).toBe(true);
            });

            it('should set the correct company when retrieved from the contact network', function(){
                fetchClientsGET.respond({contacts: [], aliases: {}, companies: {"test@test1.com": "Retrieved Company"}}, {'A-Token': 'xxx'});

                var expectedAttendees = [
                    new Attendee({
                        email: "test@test1.com",
                        firstName: "fname1",
                        lastName: "lname1",
                        usageName: "fname1",
                        name: "fname1 lname1",
                        gender: 'M',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: false,
                        assistedBy: null,
                        company: 'Retrieved Company',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: true,
                        isClient: true,
                        isThreadOwner: false
                    }),
                    new Attendee({
                        email: "test@test2.com",
                        firstName: "fname2",
                        lastName: "",
                        usageName: "fname2",
                        name: "fname2",
                        gender: 'F',
                        guid: 0,
                        hasMissingInformations: false,
                        missingInformationsTemp: {},
                        isAssistant: false,
                        assisted: true,
                        assistedBy: {email: 'Julie2@juliedesk.com', displayName: 'Julie2 Desk'},
                        company: '',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "617-216-2881",
                        skypeId: "",
                        confCallInstructions: "",
                        isPresent: undefined,
                        isClient: false,
                        isThreadOwner: false
                    })
                ];

                var threadOwner = new Attendee({
                    email: "blake@aceable.com",
                    firstName: "Blake",
                    lastName: "Garrett",
                    usageName: "Blake",
                    name: "Blake Garrett",
                    gender: '?',
                    guid: -1,
                    isAssistant: false,
                    assisted: true,
                    assistedBy: {email: 'Julie@juliedesk.com', displayName: 'Julie Desk'},
                    company: '',
                    timezone: "America/Chicago",
                    landline: "",
                    mobile: "617-216-2881",
                    skypeId: "",
                    confCallInstructions: undefined,
                    isPresent: true,
                    isClient: true,
                    isThreadOwner: true
                });

                spyOn( window, 'updateNotesCallingInfos' );
                expectedAttendees.push(threadOwner);
                $httpBackend.flush();

                expect( window.updateNotesCallingInfos ).toHaveBeenCalled();
                expect(angular.equals($scope.attendees, expectedAttendees)).toBe(true);

            });

            it('should fetch the contacts emails besed beginning with a substring', function(){
                spyOn($http, 'get').and.callThrough();
                AttendeesCtrl.getEmailsSuggestions('test');
                expect($http.get).toHaveBeenCalledWith("/client_contacts/emails_suggestions?sub_string=test");
            });
        });
    });

    describe('Form Controller Directive', function(){
        var $scope, $rootScope, $httpBackend, template, FormCtrl, SharedProperties, Attendee;

        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_sharedProperties_){
            SharedProperties = _sharedProperties_;
        }));

        beforeEach(inject(function($injector, $compile){
            // The injector unwraps the underscores (_) from around the parameter names when matching
            $rootScope = $injector.get('$rootScope');
            $httpBackend = $injector.get('$httpBackend');
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
                guid: 0,
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

        it('should retrieve a contact infos by making an http call to a specific URL', function(){
            FormCtrl.getThreadOwner = jasmine.createSpy("getThreadOwner() spy").and.callFake(function(){
                return {email: 'client@mail.com'};
            });

            $httpBackend.when('GET', '/client_contacts/fetch_one?client_email=client@mail.com&email=test@email.fr').respond({email: 'retrievedEmail@email.com', firstName: 'retrievedFN', lastName: 'retrievedLN', gender: 'retrievedGender'});
            spyOn(FormCtrl, 'setAttendeeInFormDetails');
            FormCtrl.attendeeInForm.email = 'test@email.fr';
            FormCtrl.importContactInfos();
            $httpBackend.flush();
            expect(FormCtrl.setAttendeeInFormDetails).toHaveBeenCalledWith({ email: 'retrievedEmail@email.com', firstName: 'retrievedFN', lastName: 'retrievedLN', gender: 'retrievedGender' });
        });

        it('should set the current attendeeInForm details', function(){
            FormCtrl.setAttendeeInFormDetails({firstName: 'OverridenFName', lastName: 'OverridenLName', gender: 'OverridenGender'});
            expect(FormCtrl.attendeeInForm.firstName).toEqual('OverridenFName');
            expect(FormCtrl.attendeeInForm.lastName).toEqual('OverridenLName');
            expect(FormCtrl.attendeeInForm.gender).toEqual('OverridenGender');
        });

        it('should set the current attendeeInForm details in full', function(){
            FormCtrl.setAttendeeInFormDetails({firstName: 'OverridenFName', lastName: 'OverridenLName', gender: 'OverridenGender',usageName: 'OverridenFName OverridenLName', isAssistant: true, assisted: false, assistedBy: "{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}", timezone: "America/Chicago", landline: '0102030404', mobile: '0646646464', skypeId: 'Skype ID', confCallInstructions: 'conf call'});

            expect(FormCtrl.attendeeInForm.firstName).toEqual('OverridenFName');
            expect(FormCtrl.attendeeInForm.lastName).toEqual('OverridenLName');
            expect(FormCtrl.attendeeInForm.gender).toEqual('OverridenGender');
            expect(FormCtrl.attendeeInForm.usageName).toEqual('OverridenFName OverridenLName');
            expect(FormCtrl.attendeeInForm.isAssistant).toEqual(true);
            expect(FormCtrl.attendeeInForm.assistedBy).toEqual({ email: 'julie@juliedesk.com', displayName: 'Julie Desk' });
            expect(FormCtrl.attendeeInForm.timezone).toEqual("America/Chicago");
            expect(FormCtrl.attendeeInForm.landline).toEqual('0102030404');
            expect(FormCtrl.attendeeInForm.mobile).toEqual('0646646464');
            expect(FormCtrl.attendeeInForm.skypeId).toEqual('Skype ID');
            expect(FormCtrl.attendeeInForm.confCallInstructions).toEqual('conf call');
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