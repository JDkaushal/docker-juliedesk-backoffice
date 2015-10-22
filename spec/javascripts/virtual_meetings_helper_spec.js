
//= require angular_virtual_meetings_helper_app

(function(){

    'use strict';

    describe('virtualMeetingsHelperController', function(){
        var $scopeAM, $scopeVM, $rootScope, $httpBackend, template, fetchClientsGET, AttendeesCtrl, SharedProperties;

        beforeEach(module('virtual-meetings-helper-controllers'));
        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_sharedProperties_){
            SharedProperties = _sharedProperties_;

            spyOn(SharedProperties, 'displayAttendeeForm').and.callThrough();
            spyOn(SharedProperties, 'setThreadOwner').and.callThrough();
        }));

        beforeEach(inject(function($injector, $compile) {
            setWindowVariables();

            // The injector unwraps the underscores (_) from around the parameter names when matching
            //var html = '<div class="data-entry linear-form-entry attendees-manager" ng-app="attendees-manager" id="attendeesManager"><div id="attendeesCtrl" ng-controller="AttendeesCtrl as attendees_manager"></div></div>';
            var html = '<textarea class="data-entry form-control" id="notes" name="notes" disabled="">-Contacts-Infos-------------------\
                Frederic GRAIS\
            Téléphone: hythtyhy / hythtyhhyhtyhty\
            ----------------------------------</textarea>';
            angular.element(document.body).append(html);

            $rootScope = $injector.get('$rootScope');

            $scopeVM = $rootScope.$new();
            $scopeAM = $rootScope.$new();
            var $controller = $injector.get('$controller');
            $httpBackend = $injector.get('$httpBackend');
            fetchClientsGET = $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com');
            fetchClientsGET.respond({userId: 'userX', aliases: {}, companies: {}}, {'A-Token': 'xxx'});

            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scopeAM});

            var element = angular.element("<virtual-meetings-helper/>");
            template = $compile(element)($scopeVM);
            $scopeVM.attendeesManagerCtrl = $scopeAM;
            $scopeVM.$digest();

            fetchClientsGET = $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com');
            fetchClientsGET.respond({contacts: [], aliases: {}, companies: {}});
        }));

        function setWindowVariables(){
            window.threadDataIsEditable = true;

            window.threadComputedData.call_instructions = {};

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
                isPresent: "true",
                isClient: "false",
                isThreadOwner: "false"
            }];
        };

        it('should set the scope variable after initialization', function(){
            expect(angular.equals($scopeVM.currentConf, {})).toBe(true);

            expect($scopeVM.formEditMode).toBe(true);

            expect($scopeVM.showHeader).toBe(true);

            expect($scopeVM.forceCurrentConfig).toBe(false);

            expect($scopeVM.lastTargetInfos, '').toEqual('');

            expect($scopeVM.detailsFrozen).toBe(false);

            expect($scopeVM.configLoaded).toBe(false);
        });

        it('should display the correct text for the interlocutor drop list', function(){
            expect($scopeVM.computeOptionText({name: 'name', email: 'email'})).toEqual('name (email)');
        });

        it('should trigger a refresh action with the correct parameters when the attendees list is updated', function(){
            spyOn($scopeVM, 'refresh');
            $httpBackend.flush();
            $scopeAM.attendees[0].email = 'updated';
            expect(angular.equals($scopeVM.refresh.calls.mostRecent().args[0], $scopeAM.attendees)).toBe(true);
        });

        it('should not load the defaultConfig if we can not determine which type of appointments we are dealing with', function(){
            $scopeVM.loadDefaultConfig();
            expect($scopeVM.currentConf).toEqual({});
        });

        it('should load the correct defaultConfig', function(){
            window.threadComputedData.appointment_nature = 'call';

            window.threadAccount.appointments = [
                {
                    kind: 'call',
                    support_config_hash: {
                        confcall_in_note: false,
                        label: "Mobile",
                        landline_in_note: true,
                        mobile_in_note: true,
                        rescue_with_confcall: false,
                        rescue_with_landline: false,
                        rescue_with_mobile: false,
                        rescue_with_skype: false,
                        skype_in_note: false
                    },
                    behaviour: 'propose'
                }
            ];

            expect(angular.equals($scopeVM.callTargets, $scopeAM.attendees)).toBe(true);

        });

    });
})();