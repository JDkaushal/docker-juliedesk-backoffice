
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

        beforeEach(inject(function($injector, $compile){
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

            window.threadComputedData = {call_instructions: {}};

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

        describe('Watchers', function(){
            it('should watch the current conf details and update the notes when it has changed', function(){
                spyOn(window, 'updateNotesCallingInfos');

                $scopeVM.$apply(function(){$scopeVM.currentConf.details = 'new value';});
                expect(window.updateNotesCallingInfos).toHaveBeenCalled();
            });

            it('should watch the current conf target Infos and cache the interlocutor and compute the new details when it has changed', function(){
                spyOn($scopeVM, 'cacheCurrentInterlocutor');
                spyOn($scopeVM, 'computeCallDetails');

                $scopeVM.$apply(function(){$scopeVM.currentConf.targetInfos = 'new value';});
                expect($scopeVM.cacheCurrentInterlocutor).toHaveBeenCalled();
                expect($scopeVM.computeCallDetails).toHaveBeenCalled();
            });

            it('should watch the current conf support and update VA config accordingly when it has changed and the target is the client', function(){
                spyOn($scopeVM, 'changeCurrentVAConfig');

                $scopeVM.$apply(function(){$scopeVM.currentConf = {target: 'client', support: 'mobile'};});
                expect($scopeVM.changeCurrentVAConfig).toHaveBeenCalledWith('mobile');

            });

            it('should watch the current conf support and don\'t update VA config accordingly when it has changed and the target is not the client', function(){
                spyOn($scopeVM, 'changeCurrentVAConfig');

                $scopeVM.$apply(function(){$scopeVM.currentConf = {target: 'interlocutor', support: 'mobile'};});
                expect($scopeVM.changeCurrentVAConfig).not.toHaveBeenCalled();
            });

            it('should watch the current conf and don\'t update the targetInfos select of the other form if it doesn\'t exists', function(){
                spyOn($scopeVM, 'updateTargetInfosSelect');

                $scopeVM.$apply(function(){$scopeVM.currentConf = {target: 'client', support: 'mobile'};});
                expect($scopeVM.updateTargetInfosSelect).not.toHaveBeenCalled();
            });

            it('should watch the current conf and update the targetInfos select of the other form if it exists', function(){
                spyOn($scopeVM, 'updateTargetInfosSelect');

                $scopeVM.otherForm = {
                    $apply: function(){},
                    $$phase: false,
                    currentConf:{}
                };

                $scopeVM.$apply(function(){$scopeVM.currentConf = {target: 'client', support: 'mobile'};});
                expect($scopeVM.updateTargetInfosSelect).toHaveBeenCalled();
                expect(angular.equals($scopeVM.otherForm.currentConf, {target: 'client', support: 'mobile'})).toBe(true);
            });

            it('should watch the current VA config and reflect the changes on the other form and update the notes if it is present when it has changed', function(){
                spyOn(window, 'updateNotesCallingInfos');

                $scopeVM.otherForm = {
                    $apply: function(){},
                    $$phase: false,
                    currentConf:{},
                    setVAConfig: function(val){}
                };


                $scopeVM.$apply(function(){$scopeVM.currentConf.details = 'new value';});
                expect(window.updateNotesCallingInfos).toHaveBeenCalled();
            });
        });

        it('should set the scope variable after initialization', function(){
            expect(angular.equals($scopeVM.currentConf, {})).toBe(true);

            expect(angular.equals($scopeVM.attendeesManagerCtrl, $scopeAM)).toBe(true);

            expect($scopeVM.formEditMode).toBe(true);

            expect($scopeVM.showHeader).toBe(true);
            expect($scopeVM.displayForm).toBe(true);

            expect($scopeVM.forceCurrentConfig).toBe(false);

            expect($scopeVM.lastTargetInfos, '').toEqual('');

            expect($scopeVM.detailsFrozenBecauseClient).toBe(false);
            expect($scopeVM.forcedDetailsFrozen).toBe(false);
            expect($scopeVM.cachedInterlocutor).toBe(undefined);
            expect(angular.equals($scopeVM.cachedCurrentConf, {})).toBe(true);
            expect($scopeVM.configLoaded).toBe(false);
            expect($scopeVM.otherForm).toBe(undefined);
        });

        it('should display the correct text for the interlocutor drop list', function(){
            expect($scopeVM.computeOptionText({name: 'name', email: 'email'})).toEqual('name (email)');
        });

        it('should populate correctly the call target infos', function(){
            $httpBackend.flush();
            expect(angular.equals(JSON.parse(angular.toJson($scopeVM.callTargetsInfos)), [{displayName: "fname1 lname1 (test@test1.com)", email: "test@test1.com", name: "fname1 lname1", guid: $scopeAM.attendees[0].guid}, {displayName: "fname2 (test@test2.com)", email: "test@test2.com", name: "fname2", guid: $scopeAM.attendees[1].guid}])).toBe(true);
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

        describe('should load the correct default config', function(){

            afterEach(function() {
                $('#appointment_nature').remove();
            });

            it('call config', function(){
                var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call" selected>call</option><option value="hangout">hangout</option><option value="confcall">confcall</option></select>';
                angular.element(document.body).append(html);

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

                $httpBackend.flush();
                expect(angular.equals($scopeVM.getCurrentAppointment(), window.threadAccount.appointments[0])).toBe(true);
                expect(angular.equals($scopeVM.getCurrentVAConfig(), window.threadAccount.appointments[0].support_config_hash)).toBe(true);
                expect(angular.equals($scopeVM.getCurrentBehaviour(), window.threadAccount.appointments[0].behaviour)).toBe(true);

                expect(angular.equals(angular.toJson($scopeVM.currentConf), '{"target":"client","targetInfos":{"name":"Blake Garrett","email":"blake@aceable.com","guid":-1},"support":"mobile","details":"617-216-2881"}')).toBe(true);
            });

            it('confcall config propose', function(){
                var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout">hangout</option><option value="confcall" selected>confcall</option></select>';
                angular.element(document.body).append(html);

                window.threadComputedData.appointment_nature = 'confcall';

                window.threadAccount.appointments = [
                    {
                        kind: 'confcall',
                        support_config_hash: {
                            confcall_in_note: true,
                            label: "Confcall",
                            landline_in_note: true,
                            mobile_in_note: false,
                            rescue_with_confcall: false,
                            rescue_with_landline: false,
                            rescue_with_mobile: false,
                            rescue_with_skype: false,
                            skype_in_note: false
                        },
                        behaviour: 'propose'
                    }
                ];

                $httpBackend.flush();
                expect(angular.equals($scopeVM.getCurrentAppointment(), window.threadAccount.appointments[0])).toBe(true);
                expect(angular.equals($scopeVM.getCurrentVAConfig(), window.threadAccount.appointments[0].support_config_hash)).toBe(true);
                expect(angular.equals($scopeVM.getCurrentBehaviour(), window.threadAccount.appointments[0].behaviour)).toBe(true);

                expect(angular.equals(angular.toJson($scopeVM.currentConf), '{"target":"client","targetInfos":{"name":"Blake Garrett","email":"blake@aceable.com","guid":-1},"support":"confcall","details":"confcall instructions"}')).toBe(true);
            });

            it('confcall config ask interlocutor', function(){
                var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout">hangout</option><option value="confcall" selected>confcall</option></select>';
                angular.element(document.body).append(html);

                window.threadComputedData.appointment_nature = 'confcall';

                window.threadAccount.appointments = [
                    {
                        kind: 'confcall',
                        support_config_hash: {
                            confcall_in_note: true,
                            label: "Confcall",
                            landline_in_note: true,
                            mobile_in_note: false,
                            rescue_with_confcall: false,
                            rescue_with_landline: false,
                            rescue_with_mobile: false,
                            rescue_with_skype: false,
                            skype_in_note: false
                        },
                        behaviour: 'ask_interlocutor'
                    }
                ];
                spyOn($scopeVM, 'setDefaultSupportManually');

                $httpBackend.flush();
                expect($scopeVM.setDefaultSupportManually).toHaveBeenCalled();
                expect(angular.equals($scopeVM.getCurrentAppointment(), window.threadAccount.appointments[0])).toBe(true);
                expect(angular.equals($scopeVM.getCurrentVAConfig(), window.threadAccount.appointments[0].support_config_hash)).toBe(true);
                expect(angular.equals($scopeVM.getCurrentBehaviour(), window.threadAccount.appointments[0].behaviour)).toBe(true);

                expect(angular.equals(angular.toJson($scopeVM.currentConf), '{"target":"interlocutor","targetInfos":{},"support":"","details":""}')).toBe(true);
            });

            it('call config ask interlocutor with one attendee', function(){
                var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call" selected>call</option><option value="hangout">hangout</option><option value="confcall">confcall</option></select>';
                angular.element(document.body).append(html);

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
                }];

                window.threadComputedData.appointment_nature = null;

                window.threadAccount.appointments = [
                    {
                        kind: 'call',
                        support_config_hash: {
                            confcall_in_note: true,
                            label: "Mobile",
                            landline_in_note: true,
                            mobile_in_note: false,
                            rescue_with_confcall: false,
                            rescue_with_landline: false,
                            rescue_with_mobile: false,
                            rescue_with_skype: false,
                            skype_in_note: false
                        },
                        behaviour: 'ask_interlocutor'
                    }
                ];

                spyOn($scopeVM, 'setDefaultSupportManually');

                $httpBackend.flush();

                expect($scopeVM.setDefaultSupportManually).toHaveBeenCalled();
                expect(angular.equals($scopeVM.getCurrentAppointment(), window.threadAccount.appointments[0])).toBe(true);
                expect(angular.equals($scopeVM.getCurrentVAConfig(), window.threadAccount.appointments[0].support_config_hash)).toBe(true);
                expect(angular.equals($scopeVM.getCurrentBehaviour(), window.threadAccount.appointments[0].behaviour)).toBe(true);

                expect(angular.equals(angular.toJson($scopeVM.currentConf), '{"target":"interlocutor","targetInfos":' + JSON.stringify({email: $scopeVM.callTargetsInfos[0].email, name: $scopeVM.callTargetsInfos[0].name, guid: $scopeVM.callTargetsInfos[0].guid, displayName: $scopeVM.callTargetsInfos[0].displayName}) + ',"support":"mobile","details":"617-216-2881"}')).toBe(true);
            });

            it('hangout config later', function(){
                var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout" selected>hangout</option><option value="confcall">confcall</option></select>';
                angular.element(document.body).append(html);

                window.threadComputedData.appointment_nature = 'hangout';

                window.threadAccount.appointments = [
                    {
                        kind: 'hangout',
                        support_config_hash: {
                            confcall_in_note: true,
                            label: "Vide",
                            landline_in_note: true,
                            mobile_in_note: true,
                            rescue_with_confcall: false,
                            rescue_with_landline: false,
                            rescue_with_mobile: false,
                            rescue_with_skype: false,
                            skype_in_note: true
                        },
                        behaviour: 'later'
                    }
                ];

                $httpBackend.flush();
                expect(angular.equals($scopeVM.getCurrentAppointment(), window.threadAccount.appointments[0])).toBe(true);
                expect(angular.equals($scopeVM.getCurrentVAConfig(), window.threadAccount.appointments[0].support_config_hash)).toBe(true);
                expect(angular.equals($scopeVM.getCurrentBehaviour(), window.threadAccount.appointments[0].behaviour)).toBe(true);

                expect(angular.equals(angular.toJson($scopeVM.currentConf), '{"target":"later","targetInfos":{},"support":"","details":""}')).toBe(true);
            });
        });

        describe('determineDefaultSupport', function(){
            it('should determine the correct default support for the provided target: mobile', function(){
                var target = {
                    mobile: '123',
                    landline: '456'
                };

                expect($scopeVM.determineDefaultSupport(target)).toEqual('mobile');
            });

            it('should determine the correct default support for the provided target: landline', function(){
                var target = {
                    mobile: '',
                    landline: '456'
                };

                expect($scopeVM.determineDefaultSupport(target)).toEqual('landline');
            });

            it('should determine the correct default support for the provided target: empty', function(){
                var target = {
                    mobile: '',
                    landline: ''
                };

                expect($scopeVM.determineDefaultSupport(target)).toEqual('');
            });
        });

        describe('setDefaultSupportManually', function(){
            describe('confcall', function(){
                it('should determine the correct default support for the provided target: confcall', function(){
                    var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout">hangout</option><option value="confcall" selected>confcall</option></select>';
                    angular.element(document.body).append(html);

                    var target = {
                        confCallInstructions: 'ok',
                        mobile: '123',
                        landline: '345'
                    };

                    spyOn($scopeVM, 'computeCallDetails');

                    $scopeVM.setDefaultSupportManually(target);
                    expect($scopeVM.computeCallDetails).toHaveBeenCalled();
                    expect($scopeVM.currentConf.support).toEqual('confcall');
                });

                it('should determine the correct default support for the provided target: mobile', function(){
                    var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout">hangout</option><option value="confcall" selected>confcall</option></select>';
                    angular.element(document.body).append(html);

                    var target = {
                        confCallInstructions: '',
                        mobile: '123',
                        landline: '345'
                    };

                    spyOn($scopeVM, 'computeCallDetails');

                    $scopeVM.setDefaultSupportManually(target);
                    expect($scopeVM.computeCallDetails).toHaveBeenCalled();
                    expect($scopeVM.currentConf.support).toEqual('mobile');
                });

                it('should determine the correct default support for the provided target: landline', function(){
                    var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call">call</option><option value="hangout">hangout</option><option value="confcall" selected>confcall</option></select>';
                    angular.element(document.body).append(html);

                    var target = {
                        confCallInstructions: '',
                        mobile: '',
                        landline: '345'
                    };

                    spyOn($scopeVM, 'computeCallDetails');

                    $scopeVM.setDefaultSupportManually(target);
                    expect($scopeVM.computeCallDetails).toHaveBeenCalled();
                    expect($scopeVM.currentConf.support).toEqual('landline');
                });
            });

            describe('call', function(){
                it('should determine the correct default support for the provided target: mobile', function(){
                    var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call" selected>call</option><option value="hangout">hangout</option><option value="confcall">confcall</option></select>';
                    angular.element(document.body).append(html);

                    var target = {
                        confCallInstructions: '',
                        mobile: '123',
                        landline: '345'
                    };

                    spyOn($scopeVM, 'computeCallDetails');

                    $scopeVM.setDefaultSupportManually(target);
                    expect($scopeVM.computeCallDetails).toHaveBeenCalled();
                    expect($scopeVM.currentConf.support).toEqual('mobile');
                });

                it('should determine the correct default support for the provided target: landline', function(){
                    var html = '<select class="data-entry form-control" id="appointment_nature" name="appointment_nature" disabled=""><option value="lunch">lunch</option><option value="meeting">meeting</option><option value="webex">webex</option><option value="breakfast">breakfast</option><option value="skype">skype</option><option value="coffee">coffee</option><option value="dinner">dinner</option><option value="drink">drink</option><option value="appointment">appointment</option><option value="work_session">work_session</option><option value="call" selected>call</option><option value="hangout">hangout</option><option value="confcall">confcall</option></select>';
                    angular.element(document.body).append(html);

                    var target = {
                        confCallInstructions: '',
                        mobile: '',
                        landline: '345'
                    };

                    spyOn($scopeVM, 'computeCallDetails');

                    $scopeVM.setDefaultSupportManually(target);
                    expect($scopeVM.computeCallDetails).toHaveBeenCalled();
                    expect($scopeVM.currentConf.support).toEqual('landline');
                });
            });
        });

        it('should change the current VA config', function(){

            window.threadAccount.virtual_appointments_support_config = [
                {
                    confcall_in_note: false,
                    label: "Mobile",
                    landline_in_note: true,
                    mobile_in_note: true,
                    rescue_with_confcall: false,
                    rescue_with_landline: false,
                    rescue_with_mobile: false,
                    rescue_with_skype: false,
                    skype_in_note: false
                }
            ];

            spyOn(window, 'updateNotesCallingInfos');

            $scopeVM.changeCurrentVAConfig('mobile');

            expect(window.updateNotesCallingInfos).toHaveBeenCalled();
            expect($scopeVM.getCurrentVAConfig())
            expect(angular.equals($scopeVM.getCurrentVAConfig(), window.threadAccount.virtual_appointments_support_config[0])).toBe(true);
        });
    });
})();