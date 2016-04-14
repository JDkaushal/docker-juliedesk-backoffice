//= require angular_AI_manager_app

/* WARNING
    When using a 'beforeEach' make sure it is not empty like:
        beforeEach() or
        beforeEach(console.log('test'))

    Always use a function inside like:
        beforeEach(function(){console.log('test')})

    Except for module:
        beforeEach(module('AI-manager-services'));
 */

(function() {

    'use strict';

    function setWindowsVariables(){
        window.messageInterpretations = [
            {
                created_at: "2016-03-21T17:09:48.572Z",
                error: false,
                id: 17,
                message_id: 88450,
                question: "main",
                raw_response: "{\"body\": \"Merci !\\n\", \"email_id\": 278000, \"request_classif\": \"unknown\", \"request_threshold\": null, \"appointment_classif\": \"appointment\", \"dates_to_check\": {}, \"language_detected\": \"fr\", \"request_proba\": null, \"appointment_threshold\": 0.78, \"algo_duration\": [6, 3, 0, 3], \"appointment_proba\": 0.94}",
                updated_at: "2016-03-21T17:10:01.063Z"
            }
        ];

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

    describe('AI manager App', function() {
        var $messageInterpretationService, $attendeesService, $scopeAM, AttendeesCtrl, $controller, $http, $rootScope, $httpBackend;

        beforeEach(module('AI-manager-services'));
        beforeEach(module('AI-manager-controllers'));
        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_messageInterpretationsService_){
            $messageInterpretationService = _messageInterpretationsService_;
        }));

        beforeEach(inject(function(_attendeesService_){
            $attendeesService = _attendeesService_;
        }));

        beforeEach(inject(function($injector) {
            setWindowsVariables();

            $rootScope = $injector.get('$rootScope');
            $scopeAM = $rootScope.$new();
            $controller = $injector.get('$controller');

            $http = $injector.get('$http');

            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scopeAM, $http: $http});

            $httpBackend = $injector.get('$httpBackend');
            $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com').respond({contacts: [], aliases: {}, companies: {}});

            spyOn($attendeesService, 'getAttendeesApp').and.returnValue($scopeAM);
            $attendeesService.listenToAttendeesAppEvents();
        }));

        describe('messageInterpretationsService', function() {

            it('should retrieve the main interpretation', function() {
                var expectedResult = JSON.parse(window.messageInterpretations[0].raw_response);

                expect(angular.equals($messageInterpretationService.getMainInterpretation(), expectedResult)).toBe(true);
            });

        });

        describe('attendeesService', function() {

            it('broadcast the right events when the attendees have been fetched', function() {
                spyOn($rootScope, '$broadcast').and.callThrough();

                $httpBackend.flush();

                expect($rootScope.$broadcast.calls.all()[2].args).toEqual(["callNumbersFetched", {callNumbers: { '617-216-2881': { type: 'mobile', ownerGuid: -1 }, 'confcall instructions': { type: 'confCallInstructions', ownerGuid: -1 }}}]);
                expect($rootScope.$broadcast.calls.all()[3].args[0]).toEqual("clientsFetched");

                expect(angular.equals($rootScope.$broadcast.calls.all()[3].args[1],{clients: $attendeesService.getAttendeesClients()})).toBe(true);
            });

            it('should retrieve the attendees without the clients', function() {
                $httpBackend.flush();

                expect($attendeesService.getAttendeesWithoutClients()).toEqual($scopeAM.getAttendeesWithoutClients());
            });

            it('should retrieve the attendees who are clients', function() {
                $httpBackend.flush();

                expect($attendeesService.getAttendeesClients()).toEqual($scopeAM.getAttendeesOnlyClients());
            });

            it('should trigger the $apply method on the attendeesApp scope', function() {
                spyOn($scopeAM, '$apply');

                $attendeesService.applyScope();
                expect($scopeAM.$apply).toHaveBeenCalled();
            });
        });

        describe('localeManager', function() {
            var localeManager, $rootScope, $scope;

            beforeEach(inject(function($injector) {
                setWindowsVariables();
                $controller = $injector.get('$controller');
                $rootScope = $injector.get('$rootScope');
                $scope = $rootScope.$new();
            }));

            describe('Initialization', function() {

                describe('First time filling the form', function() {

                    beforeEach(function(){
                        window.threadComputedData = {appointment_nature: null};
                    });

                    it('should get the main interpretation', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation');
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($messageInterpretationService.getMainInterpretation).toHaveBeenCalled();
                    });

                    it('should set the correct scope variable to hold the currentLocale', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($scope.currentLocale).toEqual('fr');
                    });

                    it('should not set the currentLocale scope variable', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: null});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($scope.currentLocale).toBe(undefined);
                    });

                    it('should check the correct checkbox depending on the locale found', function() {
                        var html = '<input id="locale_fr" name="locale" type="radio" value="fr"><input id="locale_en" name="locale" type="radio" value="en">';
                        angular.element(document.body).append(html);
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($('#locale_fr').prop('checked')).toBe(true);
                    });

                    it('should call the correct method to go to the next form step', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        spyOn(window, 'askNextLinearFormEntry');
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect(window.askNextLinearFormEntry).toHaveBeenCalled();
                    });

                });

                describe('Form has already be initialized', function() {

                    beforeEach(function(){
                        window.threadComputedData = {appointment_nature: 'appointment'};
                    });

                    it('should get the main interpretation', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation');
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($messageInterpretationService.getMainInterpretation).toHaveBeenCalled();
                    });

                    it('should set the correct scope variable to hold the currentLocale', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($scope.currentLocale).toEqual('fr');
                    });

                    it('should not set the currentLocale scope variable', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: null});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($scope.currentLocale).toBe(undefined);
                    });

                    it('no locale radio button chould be checked', function() {
                        $("input[name='locale']").remove();
                        var html = '<input id="locale_fr" name="locale" type="radio" value="fr"><input id="locale_en" name="locale" type="radio" value="en">';
                        angular.element(document.body).append(html);
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect($('#locale_fr').prop('checked')).toBe(false);
                        expect($('#locale_en').prop('checked')).toBe(false);
                    });

                    it('should not call the method to go to the next form step', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        spyOn(window, 'askNextLinearFormEntry');
                        localeManager = $controller('localeManager', {$scope: $scope});
                        expect(window.askNextLinearFormEntry).not.toHaveBeenCalled();
                    });

                    it('should call the correct method to go to the next form step', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({language_detected: 'fr'});
                        localeManager = $controller('localeManager', {$scope: $scope});
                        // We must recall the init function manually because it is normally called on the controller initialization and we cannot attach a spy to the function beforehand
                        spyOn($scope, 'checkLocaleConsistency');
                        $scope.init();
                        expect($scope.checkLocaleConsistency).toHaveBeenCalled();
                    });

                });

            });

            describe('checkLocaleConsistency', function() {
                beforeEach(function(){
                    localeManager = $controller('localeManager', {$scope: $scope});
                });

                describe('the specified locale is different form the AI suggested locale', function() {

                    beforeEach(function() {
                       $scope.currentLocale = 'fr';
                    });

                    it('should call the correct methods', function() {
                        spyOn($scope, 'displayLocaleDiscrepancyMessage');
                        spyOn($scope, 'getLocaleDiscrepancyMessage');

                        $scope.checkLocaleConsistency('wrong');
                        expect($scope.displayLocaleDiscrepancyMessage).toHaveBeenCalledWith(true);
                        expect($scope.getLocaleDiscrepancyMessage).toHaveBeenCalled();
                    });

                    it('should set the correct discrepancy message', function() {
                        var html = '<div class="locale-discrepancy-message"><span id="locale_discrepancy_text"></span></div>';
                        angular.element(document.body).append(html);
                        localeManager = $controller('localeManager', {$scope: $scope});
                        $scope.checkLocaleConsistency('wrong');
                        expect($('#locale_discrepancy_text').html()).toEqual('Attention - Français détecté');
                    });

                });

                describe('the specified locale is the same than the AI suggested locale', function() {

                    beforeEach(function() {
                        $scope.currentLocale = 'fr';
                    });

                    it('should call the correct methods', function() {
                        spyOn($scope, 'displayLocaleDiscrepancyMessage');
                        spyOn($scope, 'getLocaleDiscrepancyMessage');

                        $scope.checkLocaleConsistency('fr');
                        expect($scope.displayLocaleDiscrepancyMessage).toHaveBeenCalledWith(false);
                    });

                });

            });

            describe('displayLocaleDiscrepancyMessage', function() {

                beforeEach(function(){
                    localeManager = $controller('localeManager', {$scope: $scope});
                });

                it('should hide the message', function() {
                    spyOn($.fn, 'hide');
                    $scope.displayLocaleDiscrepancyMessage(false);

                    expect($.fn.hide).toHaveBeenCalled();
                    expect($.fn.hide.calls.mostRecent().object.selector).toEqual('.locale-discrepancy-message');
                });

                it('should show the message', function() {
                    spyOn($.fn, 'show');
                    $scope.displayLocaleDiscrepancyMessage(true);

                    expect($.fn.show).toHaveBeenCalled();
                    expect($.fn.show.calls.mostRecent().object.selector).toEqual('.locale-discrepancy-message');
                });

            });

            describe('getLocaleDiscrepancyMessage', function() {

                beforeEach(function(){
                    localeManager = $controller('localeManager', {$scope: $scope});
                });

                describe('French', function() {
                    beforeEach(function(){
                        $scope.currentLocale = 'fr';
                    });

                    it('should generate the correct message', function() {
                        expect($scope.getLocaleDiscrepancyMessage()).toEqual('Attention - Français détecté');
                    });

                });

                describe('English', function() {
                    beforeEach(function(){
                        $scope.currentLocale = 'en';
                    });

                    it('should generate the correct message', function() {
                        expect($scope.getLocaleDiscrepancyMessage()).toEqual('Attention - Anglais détecté');
                    });

                });

                describe('Not supported locale', function() {
                    beforeEach(function(){
                        $scope.currentLocale = 'not supported';
                    });

                    it('should generate the correct message', function() {
                        expect($scope.getLocaleDiscrepancyMessage()).toEqual('Attention - Locale non supportée : not supported');
                    });

                });

            });
        });

        describe('appointmentTypeManager', function() {
            var appointmentTypeManager, $rootScope, $scope;

            beforeEach(inject(function($injector) {
                $controller = $injector.get('$controller');
                $rootScope = $injector.get('$rootScope');
                $scope = $rootScope.$new();
            }));

            describe('Initialization', function() {

                describe('First time filling the form', function() {

                    beforeEach(function(){
                        window.threadComputedData = {appointment_nature: null};
                    });

                    it('should get the main interpretation', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation');
                        appointmentTypeManager = $controller('appointmentTypeManager', {$scope: $scope});
                        expect($messageInterpretationService.getMainInterpretation).toHaveBeenCalled();
                    });

                    it('should set the currentAppointmentType scope variable when the proba is > 0.50', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({appointment_classif: 'appointment', appointment_proba: 0.90});
                        appointmentTypeManager = $controller('appointmentTypeManager', {$scope: $scope});
                        expect($scope.currentAppointmentType).toEqual('appointment');
                    });

                    it('should not set the currentAppointmentType scope variable when the proba is < 0.50', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({appointment_classif: 'appointment', appointment_proba: 0.49});
                        appointmentTypeManager = $controller('appointmentTypeManager', {$scope: $scope});
                        expect($scope.currentAppointmentType).toBe(undefined);
                    });

                    it('should have called the right method', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({appointment_classif: 'appointment', appointment_proba: 0.90});
                        appointmentTypeManager = $controller('appointmentTypeManager', {$scope: $scope});
                        spyOn($scope, 'setAppointmentType');
                        $scope.init();
                        expect($scope.setAppointmentType).toHaveBeenCalled();
                    });

                    it('should not have called the method to set the appointment type if the confidence is not high enough', function() {
                        spyOn($messageInterpretationService, 'getMainInterpretation').and.returnValue({appointment_classif: 'appointment', appointment_proba: 0.49});
                        appointmentTypeManager = $controller('appointmentTypeManager', {$scope: $scope});
                        spyOn($scope, 'setAppointmentType');
                        $scope.init();
                        expect($scope.setAppointmentType).not.toHaveBeenCalled();
                    });

                });

            });

        });

        describe('phoneSkypeEntitiesManager', function() {
            var $rootScope, $scope, template;

            beforeEach(inject(function($injector, $compile) {
                $('phone-skype-entities-manager').remove();
                if($scope) {
                    $scope.$destroy();
                }

                var html = '<div id="messages_container" data-operator-id="12" data-messages-thread-id="333"></div>';
                angular.element(document.body).append(html);

                $controller = $injector.get('$controller');
                $rootScope = $injector.get('$rootScope');
                $scope = $rootScope.$new();

                var element = angular.element("<phone-skype-entities-manager/>");
                template = $compile(element)($scope);

                angular.element(document.body).append(template);

                angular.element(document.body).append('<div class="juliedesk-entity skype">skypeidss</div>');
                angular.element(document.body).append('<div class="juliedesk-entity phone">9998888777</div>');

                $scope.$digest();
            }));

            describe('Angular Events listeners', function() {

               it('should listen to the callNumbersFetched event and process it accordingly', function() {
                   spyOn($scope, 'validateAlreadyFetchedEntities');
                   var args = {callNumbers: {'1233': {type: 'mobile', ownerGuid: 123}}};
                   $rootScope.$broadcast('callNumbersFetched', args);

                   expect($scope.validateAlreadyFetchedEntities).toHaveBeenCalledWith(args);
               });

                it('should listen to the clientsFetched event and process it accordingly', function() {
                    spyOn($scope, 'validateClientRelatedEntities');
                    var args = {clients: [{email: 'email1'}, {email: 'email2'}]};
                    $rootScope.$broadcast('clientsFetched', args);

                    expect($scope.validateClientRelatedEntities).toHaveBeenCalledWith(args.clients);
                });
            });

            describe('DOM event listeners', function() {

                beforeEach(function() {
                    $scope.possibleAttributes = [{name: 'Mobile', value: 'mobile'}, {name: 'Landline', value: 'landline'}, {name: 'confCall', value: 'confcall'}];
                    $scope.attendees = [{guid: 1, displayNormalizedName: function(){return 'name';}}];

                    $scope.$digest();
                });

                it('should listen to the click event on a .attendee node', function() {
                    spyOn($scope, 'goToAttendeeEditionPanel');
                    template.find('.attendee').trigger('click');

                    expect($scope.goToAttendeeEditionPanel).toHaveBeenCalled();
                });

                it('should listen to the click event on a .type node', function() {
                    spyOn($scope, 'saveSelectedAttribute');
                    template.find('.type').trigger('click');

                    expect($scope.saveSelectedAttribute).toHaveBeenCalled();
                });

                it('should listen to the click event on the #go_to_attendees_list node', function() {
                    spyOn($scope, 'goToAttendeesListPanel');
                    template.find('#go_to_attendees_list').trigger('click');

                    expect($scope.goToAttendeesListPanel).toHaveBeenCalled();
                });

                it('should listen to the click event on a .juliedesk-entity.skype node', function() {
                    spyOn($scope, 'displayFormAction');
                    $('.juliedesk-entity.skype').first().trigger('click');

                    expect($scope.displayFormAction).toHaveBeenCalled();
                    expect($scope.displayFormAction.calls.mostRecent().args[0]).toEqual('skype');
                });

                it('should listen to the click event on a .juliedesk-entity.phone node', function() {
                    spyOn($scope, 'displayFormAction');
                    $('.juliedesk-entity.phone').first().trigger('click');

                    expect($scope.displayFormAction).toHaveBeenCalled();
                    expect($scope.displayFormAction.calls.mostRecent().args[0]).toEqual('phone');
                });

                describe('should listen to the click event when the user click outside the form', function() {
                    describe('Form is displayed', function() {

                        it('should close the form', function() {
                            $scope.displayForm = true;

                            spyOn($scope, 'closeForm');
                            $('body').trigger('mouseup');

                            expect($scope.closeForm).toHaveBeenCalled();
                        });

                    });

                });
            });

            describe('displayFormAction', function() {

                it('should call the right methods', function() {
                    spyOn($scope, 'setParametersExtractedFromEntity');
                    spyOn($scope, 'attachFormToClickedNode');
                    spyOn($scope, 'highlightClickedEntityNode');
                    spyOn($scope, 'setSelectedAttendeeIfPossible');
                    spyOn($scope, 'highlightAttributeToModify');
                    spyOn($scope, 'checkDisplayAttendeeEditMode');
                    spyOn($scope, 'determinePossibleAttributes');
                    spyOn($scope, 'trackOpenEvent');
                    spyOn($attendeesService, 'getAttendeesWithoutClients');

                    $scope.displayFormAction('phone', $('.juliedesk-entity.phone').first());

                    expect($attendeesService.getAttendeesWithoutClients).toHaveBeenCalled();
                    expect($scope.setParametersExtractedFromEntity).toHaveBeenCalled();
                    expect($scope.attachFormToClickedNode).toHaveBeenCalled();
                    expect($scope.highlightClickedEntityNode).toHaveBeenCalled();
                    expect($scope.setSelectedAttendeeIfPossible).toHaveBeenCalled();
                    expect($scope.highlightAttributeToModify).toHaveBeenCalled();
                    expect($scope.checkDisplayAttendeeEditMode).toHaveBeenCalled();
                    expect($scope.determinePossibleAttributes).toHaveBeenCalled();
                    expect($scope.trackOpenEvent).toHaveBeenCalled();
                });

                it('should populate the right scope variables', function() {
                    var node = $('.juliedesk-entity.phone').first();
                    spyOn($attendeesService, 'getAttendeesWithoutClients').and.returnValue([{guid: 1}, {guid: 2}]);
                    $scope.displayFormAction('phone', node);

                    expect($scope.attendees).toEqual([{guid: 1}, {guid: 2}]);
                    expect($scope.currentDetectedSupport).toEqual('phone');
                    expect($scope.currentClickedEntityNode).toEqual(node);
                    expect($scope.currentSelectedAttendee).toBe(undefined);
                    expect($scope.displayForm).toBe(true);
                })

            });

            describe('saveSelectedAttribute', function() {

                it('should call the right methods', function() {
                    spyOn($scope, 'saveCurrentSelectedAttendee');
                    spyOn($scope, 'closeForm');

                    $scope.saveSelectedAttribute({currentTarget: {dataset: {attributeValue: 'mobile'}}});

                    expect($scope.saveCurrentSelectedAttendee).toHaveBeenCalled();
                    expect($scope.closeForm).toHaveBeenCalled();
                });

                it('should populate the right scope variables', function() {
                    spyOn($scope, 'saveCurrentSelectedAttendee');
                    spyOn($scope, 'closeForm');

                    $scope.saveSelectedAttribute({currentTarget: {dataset: {attributeValue: 'mobile'}}});

                    expect($scope.attributeToModify).toEqual('mobile');
                });


            });

            describe('goToAttendeeEditionPanel', function() {

                it('should populate the right scope variables', function() {
                    $scope.attendees = [{id: '12233'}];

                    $scope.goToAttendeeEditionPanel({currentTarget: {dataset: {id: '12233'}}});

                    expect($scope.currentSelectedAttendee).toEqual({id: '12233'});
                    expect($scope.attributeToModify).toEqual('');
                });
            });

            describe('validateAlreadyFetchedEntities', function() {

                it('should add the right class and attributes to the right nodes', function() {
                    $scope.attendees = [{id: '12233'}];
                    var node = $('<div class="juliedesk-entity phone" value="1223455">1223455</div>');
                    angular.element(document.body).append(node);

                    $scope.validateAlreadyFetchedEntities({callNumbers: {'1223455': {ownerGuid: '22', type: 'mobile'}}});

                    expect(node.hasClass('validated')).toBe(true);
                    expect(node.attr('new-owner')).toEqual('22');
                    expect(node.attr('attribute-to-modify')).toEqual('mobile');
                });
            });

            describe('closeFormAction', function() {

                it('should remove the right class and attributes to the right nodes and hide the form', function() {
                    $scope.displayForm = true;
                    $scope.currentClickedEntityNode = $('.juliedesk-entity.phone').first();
                    $scope.currentClickedEntityNode.addClass('highlighted');
                    var interactionAreaNode = $('.interaction-area');
                    var types = template.find('.type');

                    interactionAreaNode.addClass('slide-to-left');

                    types.addClass('highlighted');

                    $scope.closeFormAction();

                    expect($scope.currentClickedEntityNode.hasClass('highlighted')).toBe(false);
                    expect(interactionAreaNode.hasClass('slide-to-left')).toBe(false);
                    expect(types.hasClass('highlighted')).toBe(false);
                    expect($scope.displayForm).toBe(false);
                });
            });

            describe('closeForm', function() {

                describe('The form is not displayed', function() {

                    it('should not call the action method', function() {
                        $scope.displayForm = false;
                        spyOn($scope, 'closeFormAction');

                        $scope.closeForm();

                        expect($scope.closeFormAction).not.toHaveBeenCalled();
                    });

                });

                describe('The form is displayed', function() {

                    it('should call the action method', function() {
                        $scope.displayForm = true;
                        spyOn($scope, 'closeFormAction');

                        $scope.closeForm();

                        expect($scope.closeFormAction).toHaveBeenCalled();
                    });

                });
            });

            describe('saveCurrentSelectedAttendee', function() {

                it('should call the right methods', function() {
                    spyOn($scope, 'trackSaveEvent');
                    spyOn($scope, 'updateCurrentAttendeeAttribute');

                    $scope.saveCurrentSelectedAttendee();

                    expect($scope.trackSaveEvent).toHaveBeenCalled();
                    expect($scope.updateCurrentAttendeeAttribute).toHaveBeenCalled();
                });

                it('should remove the right classes on the right nodes', function() {
                    $scope.attributeToModify = 'mobile';
                    $scope.possibleAttributes = [
                        {name: 'Mobile', value: 'mobile'},
                        {name: 'Téléphone Fix', value: 'landline'},
                        {name: 'Confcall', value: 'confCallInstructions'}
                    ];

                    $scope.$digest();

                    var attributeNode = $('.type[data-attribute-value="landline"]').addClass('highlighted');
                    var mobileAttributeNode = $('.type[data-attribute-value="mobile"]').removeClass('highlighted');
                    var editionPanel = $('.edition-panel');

                    editionPanel.addClass('slide-to-left');
                    editionPanel.addClass('slide-to-right');

                    spyOn($scope, 'trackSaveEvent');
                    spyOn($scope, 'updateCurrentAttendeeAttribute').and.returnValue(true);

                    $scope.saveCurrentSelectedAttendee();

                    expect(editionPanel.hasClass('slide-to-left')).toBe(false);
                    expect(editionPanel.hasClass('slide-to-right')).toBe(false);
                    expect(attributeNode.hasClass('highlighted')).toBe(false);
                    expect(mobileAttributeNode.hasClass('highlighted')).toBe(true);
                });
            });

            describe('setParametersExtractedFromEntity', function() {

                describe('First time interacting with the node, no data has been added by the app tp the node', function() {

                    it('read the right attributes from the node to populate the scope variables', function() {
                        var node = $('<div class="juliedesk-entity phone" value="1223455" owner="ownerEmail@email.com" position-in-text="[10, 20]">1223455</div>');
                        angular.element(document.body).append(node);

                        $scope.currentClickedEntityNode = node;

                        $scope.setParametersExtractedFromEntity();

                        expect($scope.currentDetectedOwner).toEqual("ownerEmail@email.com");
                        expect($scope.attributeToModify).toBe(undefined);
                        expect($scope.currentDetectedNewOwner).toBe(undefined);
                        expect($scope.value).toEqual("1223455");
                        expect($scope.currentPositionInText).toEqual([10, 20]);
                    });

                });

                describe('Not the First time interacting with the node, some data has been added by the app tp the node', function() {

                    it('read the right attributes from the node to populate the scope variables', function() {
                        var node = $('<div class="juliedesk-entity phone" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="landline" position-in-text="[10, 20]">1223455</div>');
                        angular.element(document.body).append(node);

                        $scope.currentClickedEntityNode = node;

                        $scope.setParametersExtractedFromEntity();

                        expect($scope.currentDetectedOwner).toEqual("ownerEmail@email.com");
                        expect($scope.attributeToModify).toEqual("landline");
                        expect($scope.currentDetectedNewOwner).toEqual("newOwnerEmail@email.com");
                        expect($scope.value).toEqual("newValue");
                        expect($scope.currentPositionInText).toEqual([10, 20]);
                    });

                });

            });

            describe('highlightClickedEntityNode', function() {

                it('should add the right class and attributes to the right node', function() {
                    var node = $('<div class="juliedesk-entity phone" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="landline" position-in-text="[10, 20]">1223455</div>');
                    angular.element(document.body).append(node);

                    $scope.currentClickedEntityNode = node;

                    $scope.highlightClickedEntityNode();

                    expect(node.hasClass('highlighted')).toBe(true);
                });
            });

            describe('setSelectedAttendeeIfPossible', function() {

                describe('a owner has been detected by the AI', function() {

                    it('should find the right attendee', function() {
                        $scope.currentDetectedOwner = 'email@email.com';
                        $scope.attendees = [{email: 'email@email.com'}, {email: 'email2@email.com'}, {email: 'email3@email.com'}]

                        $scope.setSelectedAttendeeIfPossible();

                        expect($scope.currentSelectedAttendee).toEqual({email: 'email@email.com'});
                    });

                });

                describe('a owner has been set with the form', function() {

                    it('should find the right attendee', function() {
                        $scope.currentDetectedNewOwner = 2;
                        $scope.attendees = [{guid: 1, email: 'email@email.com'}, {guid: 2, email: 'newOwneremail@email.com'}, {guid: 3, email: 'email3@email.com'}];

                        $scope.setSelectedAttendeeIfPossible();

                        expect($scope.currentSelectedAttendee).toEqual({guid: 2, email: 'newOwneremail@email.com'});
                    });

                });
            });

            describe('attachFormToClickedNode', function() {

                it('should attach the form to the clicked node', function() {
                    spyOn($.fn, 'detach');
                    spyOn($.fn, 'after');

                    var node = $('<div class="juliedesk-entity phone" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="landline" position-in-text="[10, 20]">1223455</div>');
                    angular.element(document.body).append(node);

                    $scope.currentClickedEntityNode = node;

                    $scope.attachFormToClickedNode();

                    expect($.fn.detach).toHaveBeenCalled();
                    expect($.fn.after).toHaveBeenCalled();
                    expect(parseInt($('.phone-skype-entities-form').last().css('left'))).toEqual(node.position().left);
                });
            });

            describe('highlightAttributeToModify', function() {

                it('should highlight the right node', function() {
                    $scope.attributeToModify = 'mobile';
                    $scope.possibleAttributes = [
                        {name: 'Mobile', value: 'mobile'},
                        {name: 'Téléphone Fix', value: 'landline'},
                        {name: 'Confcall', value: 'confCallInstructions'}
                    ];

                    $scope.$digest();

                    $('.type[data-attribute-value="mobile"]').removeClass('highlighted');

                    $scope.highlightAttributeToModify();

                    expect($('.type[data-attribute-value="mobile"]').hasClass('highlighted')).toBe(true);
                });
            });

            describe('checkDisplayAttendeeEditMode', function() {

                it('should slide in the attendee edition panel', function() {
                    $scope.currentSelectedAttendee = {name: 'ok'};
                    var interactionAreaNode = $('.interaction-area');
                    interactionAreaNode.removeClass('slide-to-left');

                    $scope.checkDisplayAttendeeEditMode();

                    expect(interactionAreaNode.hasClass('slide-to-left')).toBe(true);
                });
            });

            describe('determinePossibleAttributes', function() {

                describe('Detected support is a Phone', function() {

                    it('should return set the right attributes list in the right scope variable', function() {
                        $scope.currentDetectedSupport = 'phone';

                        $scope.determinePossibleAttributes();

                        expect($scope.possibleAttributes).toEqual([
                            {name: 'Mobile', value: 'mobile'},
                            {name: 'Téléphone Fix', value: 'landline'},
                            {name: 'Confcall', value: 'confCallInstructions'}
                        ]);

                    });

                });

                describe('Detected support is a Skype', function() {

                    it('should return set the right attributes list in the right scope variable', function() {
                        $scope.currentDetectedSupport = 'skype';

                        $scope.determinePossibleAttributes();

                        expect($scope.possibleAttributes).toEqual([
                            {name: 'Skype', value: 'skypeId'}
                        ]);

                    });

                });
            });

            describe('updateCurrentAttendeeAttribute', function() {

                it('should call the correct methods and return true', function() {
                    spyOn($scope, 'setEntityTypeNodeValidated');
                    spyOn($attendeesService, 'applyScope');
                    $scope.currentSelectedAttendee = {name: 'ok'};
                    $scope.attributeToModify = 'mobile';

                    expect($scope.updateCurrentAttendeeAttribute()).toBe(true);

                    expect($scope.setEntityTypeNodeValidated).toHaveBeenCalled();
                    expect($attendeesService.applyScope).toHaveBeenCalled();

                });

                it('should set the correct attribute on the currentSelectedAttendee', function() {
                    spyOn($scope, 'setEntityTypeNodeValidated');
                    spyOn($attendeesService, 'applyScope');
                    $scope.currentSelectedAttendee = {name: 'ok'};
                    $scope.attributeToModify = 'mobile';
                    $scope.value = '123444';

                    expect($scope.updateCurrentAttendeeAttribute()).toBe(true);

                    expect($scope.currentSelectedAttendee.mobile).toEqual('123444');

                });
            });

            describe('setEntityTypeNodeValidated', function() {

                it('should set the currentClickedEntityNode validated and add to it the correct attributes', function() {
                    var node = $('<div class="juliedesk-entity phone" entity-id="1" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="mobile" position-in-text="[10, 20]">1223455</div>');
                    angular.element(document.body).append(node);

                    $scope.currentSelectedAttendee = {guid: '123frfre'};
                    $scope.attributeToModify = 'landline';
                    $scope.value = '888999';

                    $scope.currentClickedEntityNode = node;

                    $scope.setEntityTypeNodeValidated();

                    expect(node.hasClass('validated')).toBe(true);
                    expect(node.attr('new-owner')).toEqual("123frfre");
                    expect(node.attr('attribute-to-modify')).toEqual("landline");
                    expect(node.attr('new-value')).toEqual("888999");
                });
            });

            describe('setEntityTypeNodeUnvalidated', function() {

                it('should set the currentClickedEntityNode validated and remove from it the correct attributes', function() {
                    var node = $('<div class="juliedesk-entity phone validated" entity-id="1" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="mobile" position-in-text="[10, 20]">1223455</div>');
                    angular.element(document.body).append(node);

                    $scope.currentClickedEntityNode = node;

                    $scope.setEntityTypeNodeUnvalidated();

                    expect(node.hasClass('validated')).toBe(false);
                    expect(node.attr('new-owner')).toBe(undefined);
                    expect(node.attr('attribute-to-modify')).toBe(undefined);
                });
            });

            describe('trackOpenEvent', function() {

                it('should send a tracking report with the right data', function() {
                    var messagesContainerNode = $('#messages_container');
                    var messagesThreadId = messagesContainerNode.data('messages-thread-id');
                    var trackingId = messagesContainerNode.data('operator-id').toString() + '-' + messagesThreadId.toString();

                    var node = $('<div class="email" data-message-id="messageId"><div class="juliedesk-entity phone validated" entity-id="1" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="mobile" position-in-text="[10, 20]">1223455</div>');
                    angular.element(document.body).append(node);

                    $scope.currentClickedEntityNode = node;
                    $scope.value = 'value';
                    $scope.currentDetectedSupport = 'phone';
                    $scope.currentDetectedOwner = 'owner@email.com';
                    $scope.currentPositionInText = [1, 2];

                    spyOn(window, 'trackEvent');

                    $scope.trackOpenEvent();

                    expect(window.trackEvent).toHaveBeenCalledWith("click_on_contact_recognition", {
                        distinct_id: trackingId,
                        interpreted_text: 'value',
                        support_detected: 'phone',
                        participant_detected: 'owner@email.com',
                        index_in_text: [1, 2],
                        message_id: 'messageId',
                        thread_id: messagesThreadId
                    });
                });
            });

            describe('trackSaveEvent', function() {

                it('should send a tracking report with the right data', function() {
                    var messagesContainerNode = $('#messages_container');
                    var messagesThreadId = messagesContainerNode.data('messages-thread-id');
                    var trackingId = messagesContainerNode.data('operator-id').toString() + '-' + messagesThreadId.toString();

                    var node = $('<div class="juliedesk-entity phone validated" entity-id="1" value="1223455" new-value="newValue" owner="ownerEmail@email.com" new-owner="newOwnerEmail@email.com" attribute-to-modify="mobile" position-in-text="[10, 20]">1223455</div>');
                    var container = $('<div class="email" data-message-id="messageId"></div>');

                    container.append(node);
                    angular.element(document.body).append(container);

                    $scope.currentClickedEntityNode = node;
                    $scope.currentSelectedAttendee = {email: 'attendee@email.com'};
                    $scope.value = 'value';
                    $scope.currentDetectedSupport = 'phone';
                    $scope.currentDetectedOwner = 'owner@email.com';
                    $scope.attributeToModify = 'mobile';
                    $scope.currentPositionInText = [1, 2];

                    spyOn(window, 'trackEvent');

                    $scope.trackSaveEvent();

                    expect(window.trackEvent).toHaveBeenCalledWith("save_contact_recognition", {
                        distinct_id: trackingId,
                        interpreted_text: '1223455',
                        saved_text: 'value',
                        support_detected: 'phone',
                        participant_detected: 'owner@email.com',
                        support_saved: 'mobile',
                        participant_saved: 'attendee@email.com',
                        index_in_text: [1, 2],
                        message_id: "messageId",
                        thread_id: messagesThreadId
                    });
                });
            });

        });

    });

})();