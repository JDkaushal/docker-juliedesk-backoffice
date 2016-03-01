//= require angular_reply_box_app

(function(){

    'use strict';

    function setWindowVariables(){
        window.threadAccount = {
            addresses: [],
            appointments: [],
            awaiting_current_notes: "",
            block_until_preferences_change: false,
            calendar_logins: [],
            company_hash: null,
            complaints_count: 0,
            confcall_instructions: "confcall instructions",
            contacts_from_same_company: [],
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

        console.log(window.threadAccount.email_aliases.length);

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
        window.currentToCC = ["test@test2.com", "test@test1.com"];

        window.currentJulieAlias = {
            email: 'Julie@juliedesk.com',
            name: 'Julie Desk'
        };

        window.threadComputedData = {};
    };

    describe('Reply Box App', function() {
        var $rootScope, $httpBackend, $http, $scope, $scopeAM, replyBoxCtrl, AttendeesCtrl, fetchClientsGET;

        beforeEach(module('reply-box-controllers'));
        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));


        beforeEach(inject(function($injector) {
            setWindowVariables();

            var html = '<input id="recipients-to-input"/><input id="recipients-cc-input"/>';
            angular.element(document.body).append(html);

            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();
            $scopeAM = $rootScope.$new();
            var $controller = $injector.get('$controller');
            $http = $injector.get('$http');

            $scope.attendeesApp = $scopeAM;

            replyBoxCtrl = $controller('recipientsManager', {$scope: $scope});
            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scopeAM, $http: $http});

            $httpBackend = $injector.get('$httpBackend');

            fetchClientsGET = $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com');
            fetchClientsGET.respond({contacts: [], aliases: {}, companies: {}});
        }));

        describe('Initialization', function() {
            it('should be initialized when the attendees have been fetched', function() {
                spyOn($scope, 'init');

                $rootScope.$broadcast('attendeesFetched');

                expect($scope.init).toHaveBeenCalled();
            })
        });

        describe('Recipients', function() {

            describe('Other action than ask_availabilities or ask_date_suggestions', function() {

                it('should populate the right ccs and tos fields', function() {
                    window.initialToRecipients =  function(){
                        return [{name: 'recipientTo1'}, {name: 'recipientTo2'}];
                    };

                    window.initialCcRecipients = function(){
                        return [{name: 'recipientCc1'}, {name: 'recipientCc2'}];
                    };

                    window.emailSender = function(){
                        return {name: 'emailSender'};
                    };

                    $httpBackend.flush();

                    $scope.setReplyRecipients();

                    var tos = _.map($('#recipients-to-input').tokenInput('get'), function(r) {
                        return r.name;
                    });

                    var ccs = _.map($('#recipients-cc-input').tokenInput('get'), function(r) {
                        return r.name;
                    });

                    expect(tos).toEqual(['emailSender']);
                    expect(ccs).toEqual([window.threadAccount.email, 'recipientTo1', 'recipientTo2', 'recipientCc1', 'recipientCc2']);
                });

            });

            describe('action is ask_date_suggestions', function() {
                beforeEach(function(){
                    $scope.actionNature = 'ask_date_suggestions';
                });

                it('should populate the ccs and tos fields right', function() {

                    window.initialToRecipients =  function(){
                        return [{name: 'recipientTo1'}, {name: 'recipientTo2'}, {name: 'tESt@TeSt6.com'}];
                    };

                    window.initialCcRecipients = function(){
                        return [{name: 'recipientCc1'}, {name: 'recipientCc2'}, {name: 'TEST@TeSt6.com'}];
                    };

                    window.emailSender = function(){
                        return {name: 'emailSender'};
                    };

                    window.currentAttendees.push({
                        email: "assistant1@gmail.com",
                        firstName: "assistant1",
                        lastName: "assistant1",
                        name: "assistant1 assistant1",
                        usageName: "assistant1",
                        gender: 'M',
                        isAssistant: "true",
                        assisted: "false",
                        assistedBy: null,
                        company: 'Test Company',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "637-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "true",
                        isClient: "false",
                        isThreadOwner: "false"
                    });

                    window.currentAttendees.push({
                        email: "test@test3.com",
                        firstName: "fname3",
                        lastName: "lname3",
                        name: "fname3 lname3",
                        usageName: "fname3",
                        gender: 'M',
                        isAssistant: "false",
                        assisted: "true",
                        assistedBy: {email: 'assistant1@gmail.com'},
                        company: 'Test Company',
                        timezone: "America/Chicago",
                        landline: "",
                        mobile: "637-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "true",
                        isClient: "false",
                        isThreadOwner: "false"
                    });

                    window.currentAttendees.push({
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
                        mobile: "637-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "true",
                        isClient: "true",
                        isThreadOwner: "false"
                    });

                    window.currentAttendees.push({
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
                        mobile: "637-216-2881",
                        skypeId: "",
                        confCallInstructions: '',
                        isPresent: "true",
                        isClient: "false",
                        isThreadOwner: "false"
                    });

                    $httpBackend.flush();

                    $scope.setReplyRecipients();

                    var tos = _.map($('#recipients-to-input').tokenInput('get'), function(r) {
                        return r.name;
                    });

                    var ccs = _.map($('#recipients-cc-input').tokenInput('get'), function(r) {
                        return r.name;
                    });

                    expect(tos).toEqual(['assistant1@gmail.com', 'test@test6.com', 'julie2@juliedesk.com']);
                    expect(ccs).toEqual(['test@test1.com', 'test@test5.com', 'emailsender', 'recipientto1', 'recipientto2', 'recipientcc1', 'recipientcc2', window.threadAccount.email]);

                });

            });

        });

    });


})();