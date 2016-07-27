//= require angular_dates_manager_app

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
    }

    describe('Dates Manager App', function() {
        var $rootScope, $scope, $scopeIdentificationMng, $scopeAM, $attendeesService, DatesSuggestionsCtrl, DatesIdentificationsCtrl, AttendeesCtrl, $httpBackend, $http;

        beforeEach(module('dates-manager-services'));
        beforeEach(module('dates-manager-controllers'));
        beforeEach(module('attendees-manager-controllers'));
        beforeEach(module('attendees-manager-services'));

        beforeEach(inject(function(_attendeesService_){
            $attendeesService = _attendeesService_;
        }));

        beforeEach(inject(function($injector) {
            setWindowVariables();

            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();
            $scopeAM = $rootScope.$new();
            $scopeIdentificationMng = $rootScope.$new();

            var $controller = $injector.get('$controller');
            $http = $injector.get('$http');
            DatesSuggestionsCtrl = $controller('datesSuggestionsManager', {$scope: $scope});
            DatesIdentificationsCtrl = $controller('datesIdentificationsManager', {$scope: $scopeIdentificationMng});
            AttendeesCtrl = $controller('AttendeesCtrl', {$scope: $scopeAM, $http: $http});

            $httpBackend = $injector.get('$httpBackend');
            $httpBackend.when('GET', '/client_contacts/fetch?client_email=blake@aceable.com&contacts_emails%5B%5D=test@test1.com&contacts_emails%5B%5D=test@test2.com').respond({contacts: [], aliases: {}, companies: {}});

            spyOn($attendeesService, 'getAttendeesApp').and.returnValue($scopeAM);

            $attendeesService.setup();
        }));

        describe('attendeesService', function() {

            it('should call the correct methods when in the setup phase', function() {
                $attendeesService.setup();

                expect($attendeesService.getAttendeesApp).toHaveBeenCalled();
            });

            describe('getUsedTimezones', function() {

                describe('When the appointment is virtual', function() {

                    it('should return the correct timezones', function() {
                        spyOn($scopeAM, 'getUsedTimezones').and.returnValue(['Asia/Calcutta', 'America/New_York']);

                        window.threadComputedData.is_virtual_appointment = true;
                        window.threadComputedData.timezone = 'Europe/Paris';

                        expect($attendeesService.getUsedTimezones()).toEqual({ usedTimezones: [ 'America/New_York', 'Asia/Calcutta' ], allUsedTimezones: [ 'America/New_York', 'Europe/Paris', 'Asia/Calcutta' ] });
                    });
                });

                describe('When the appointment is not virtual', function() {

                    it('should return the correct timezones', function() {
                        spyOn($scopeAM, 'getUsedTimezones').and.returnValue(['Asia/Calcutta', 'America/New_York']);

                        window.threadComputedData.is_virtual_appointment = false;
                        window.threadComputedData.timezone = 'Europe/Paris';

                        expect($scope.getUsedTimezones()).toEqual([ 'Europe/Paris' ]);
                    });
                });

            });

        });

        describe('datesSuggestionsManager', function() {

            describe('Init', function() {

                it('should call the right methods', function() {
                    spyOn($scope, 'attachEventsToDom');

                    $scope.init();

                    expect($scope.attachEventsToDom).toHaveBeenCalled();
                });

            });

            describe('onMainTimezoneChange', function() {

                it('should execute the right actions', function() {

                    spyOn($scope, 'addTimezoneToCurrentCalendar');
                    spyOn($scope, 'setSuggestions');
                    window.threadComputedData.timezone = 'timezone';

                    $scope.onMainTimezoneChange({value: 'Europe/Paris'});

                    expect(window.threadComputedData.timezone).toEqual('Europe/Paris');
                    expect($scope.addTimezoneToCurrentCalendar).toHaveBeenCalledWith('Europe/Paris');
                    expect($scope.setSuggestions).toHaveBeenCalled();
                });


            });

            describe('attachEventsToDom', function() {

                it('should attach the right methods to the right nodes', function() {
                    spyOn($.fn, 'timezonePicker');
                    spyOn($.fn, 'on');

                    $scope.attachEventsToDom();

                    expect($.fn.timezonePicker).toHaveBeenCalledWith({ onSelectCallback: $scope.onMainTimezoneChange });
                    expect($.fn.on).toHaveBeenCalledWith('click', '.suggest-dates-next-button', $scope.nextButtonClickAction);
                });
            });

            describe('addTimezoneToCurrentCalendar', function() {

                it('should call the right methods', function() {
                    window.currentCalendar = {
                        initialData: {additional_timezone_ids: []},
                        redrawTimeZoneSelector: function() {},
                        selectTimezone: function(p, v) {}
                    };

                    spyOn(window.currentCalendar, 'redrawTimeZoneSelector');
                    spyOn(window.currentCalendar, 'selectTimezone');

                    $scope.addTimezoneToCurrentCalendar('Europe/Paris');

                    expect(window.currentCalendar.redrawTimeZoneSelector).toHaveBeenCalled();
                    expect(window.currentCalendar.selectTimezone).toHaveBeenCalledWith('Europe/Paris', true);
                    expect(window.currentCalendar.initialData.additional_timezone_ids).toEqual(['Europe/Paris'])
                });
            });

            describe('getTimeSlotsSuggestionsForTemplate', function() {

                it('should return the correct object', function() {
                    window.threadComputedData.timezone = 'Europe/Paris';
                    var referenceDay = moment("2016-04-28T12:00:00+00:00");

                    var suggestions = {
                        'Europe/Paris':
                            [
                                { value: referenceDay.clone() },
                                { value: referenceDay.clone().add('h', 3) },
                                { value: referenceDay.clone().add('d', 1) },
                                { value: referenceDay.clone().add('d', 2) },
                                { value: referenceDay.clone().add('d', 3) },
                                { value: referenceDay.clone().add('d', 3).add('h', 1) },
                                { value: referenceDay.clone().add('d', 3).add('h', 2) },
                                { value: referenceDay.clone().add('d', 3).add('h', 3) }
                            ],
                        'America/New_York':
                            [
                                { value: referenceDay.clone() },
                                { value: referenceDay.clone().add('h', 2) },
                                { value: referenceDay.clone().add('d', 1) },
                                { value: referenceDay.clone().add('d', 2) },
                                { value: referenceDay.clone().add('d', 3) },
                                { value: referenceDay.clone().add('d', 3).add('h', 2) },
                                { value: referenceDay.clone().add('d', 4) },
                                { value: referenceDay.clone().add('d', 4).add('h', 3) }
                            ],
                        'Asia/Calcutta':
                            [
                                { value: referenceDay.clone() },
                                { value: referenceDay.clone().add('h', 6) },
                                { value: referenceDay.clone().add('d', 1) },
                                { value: referenceDay.clone().add('d', 2) },
                                { value: referenceDay.clone().add('d', 3) },
                                { value: referenceDay.clone().add('d', 3).add('h', 1) },
                                { value: referenceDay.clone().add('d', 3).add('h', 3) },
                                { value: referenceDay.clone().add('d', 3).add('h', 6) }
                            ]
                    };
                    $scope.timeSlotsSuggestions = suggestions;
                    $scope.allUsedTimezones = ['Europe/Paris', 'America/New_York', 'Asia/Calcutta'];

                    var result = $scope.getTimeSlotsSuggestionsForTemplate();

                    console.log(result);

                    expect(result.length).toEqual(6);
                    expect(Object.keys(result[0])).toEqual([ 'Europe/Paris', 'America/New_York', 'Asia/Calcutta' ]);

                    expect(result[0]['Europe/Paris'][0].isSame(suggestions['Europe/Paris'][0].value)).toBe(true);
                    expect(result[0]['Europe/Paris'][1].isSame(suggestions['Europe/Paris'][1].value)).toBe(true);
                    expect(result[1]['Europe/Paris'][0].isSame(suggestions['Europe/Paris'][2].value)).toBe(true);
                    expect(result[2]['Europe/Paris'][0].isSame(suggestions['Europe/Paris'][3].value)).toBe(true);
                    expect(result[3]['Europe/Paris'][0].isSame(suggestions['Europe/Paris'][4].value)).toBe(true);
                    expect(result[3]['Europe/Paris'][1].isSame(suggestions['Europe/Paris'][5].value)).toBe(true);
                    expect(result[4]['Europe/Paris'][0].isSame(suggestions['Europe/Paris'][6].value)).toBe(true);
                    expect(result[5]['Europe/Paris'][0].isSame(suggestions['Europe/Paris'][7].value)).toBe(true);

                    expect(result[0]['America/New_York'][0].isSame(suggestions['America/New_York'][0].value)).toBe(true);
                    expect(result[0]['America/New_York'][1].isSame(suggestions['America/New_York'][1].value)).toBe(true);
                    expect(result[1]['America/New_York'][0].isSame(suggestions['America/New_York'][2].value)).toBe(true);
                    expect(result[2]['America/New_York'][0].isSame(suggestions['America/New_York'][3].value)).toBe(true);
                    expect(result[3]['America/New_York'][0].isSame(suggestions['America/New_York'][4].value)).toBe(true);
                    expect(result[3]['America/New_York'][1].isSame(suggestions['America/New_York'][5].value)).toBe(true);
                    expect(result[4]['America/New_York'][0].isSame(suggestions['America/New_York'][6].value)).toBe(true);
                    expect(result[5]['America/New_York'][0].isSame(suggestions['America/New_York'][7].value)).toBe(true);

                    expect(result[0]['Asia/Calcutta'][0].isSame(suggestions['Asia/Calcutta'][0].value)).toBe(true);
                    expect(result[0]['Asia/Calcutta'][1].isSame(suggestions['Asia/Calcutta'][1].value)).toBe(true);
                    expect(result[1]['Asia/Calcutta'][0].isSame(suggestions['Asia/Calcutta'][2].value)).toBe(true);
                    expect(result[2]['Asia/Calcutta'][0].isSame(suggestions['Asia/Calcutta'][3].value)).toBe(true);
                    expect(result[3]['Asia/Calcutta'][0].isSame(suggestions['Asia/Calcutta'][4].value)).toBe(true);
                    expect(result[3]['Asia/Calcutta'][1].isSame(suggestions['Asia/Calcutta'][5].value)).toBe(true);
                    expect(result[4]['Asia/Calcutta'][0].isSame(suggestions['Asia/Calcutta'][6].value)).toBe(true);
                    expect(result[5]['Asia/Calcutta'][0].isSame(suggestions['Asia/Calcutta'][7].value)).toBe(true);

                });


            });

            describe('clearPreviousSuggestions', function() {

                it('should clear the correct variables', function() {
                    $scope.timeSlotsSuggestions = {x: 1, y: 2};
                    $scope.outBoundSuggestionsCount = 3;

                    $scope.clearPreviousSuggestions();

                    expect($scope.timeSlotsSuggestions).toEqual({});
                    expect($scope.outBoundSuggestionsCount).toEqual(0);
                });

            });

            describe('displayOutBoundCount', function() {

                it('should return true', function() {
                    $scope.outBoundSuggestionsCount = 1;
                    expect($scope.displayOutBoundCount()).toBe(true);
                });

                it('should return false', function() {
                    $scope.outBoundSuggestionsCount = 0;
                    expect($scope.displayOutBoundCount()).toBe(false);
                });

            });

            describe('setSuggestions', function() {


                it('should clear the previous suggestions', function() {
                    window.timeSlotsToSuggest = [];
                    spyOn($scope, 'clearPreviousSuggestions');

                    $scope.setSuggestions();

                    expect($scope.clearPreviousSuggestions).toHaveBeenCalled();

                });

                it('it should set the displayDatesSuggestionManager to false', function() {
                    $scope.displayDatesSuggestionManager = true;

                    window.timeSlotsToSuggest = [];
                    spyOn($scope, 'clearPreviousSuggestions');

                    $scope.setSuggestions();

                    expect($scope.displayDatesSuggestionManager).toBe(false);
                });

                it('it should set the displayDatesSuggestionManager to true', function() {
                    $scope.displayDatesSuggestionManager = false;

                    window.timeSlotsToSuggest = ["frf"];
                    spyOn($scope, 'clearPreviousSuggestions');
                    spyOn($scope, 'getUsedTimezones').and.returnValue(['Europe/Paris']);
                    spyOn($scope, 'addTimeSlotSuggestion').and.returnValue({x: 1});

                    $scope.setSuggestions();

                    expect($scope.displayDatesSuggestionManager).toBe(true);
                });

                it('should set the correct timeSlotsSuggestions', function() {
                    window.timeSlotsToSuggest = ["2016-04-08T10:00:00+02:00", "2016-04-08T11:30:00+02:00", "2016-04-08T13:30:00+02:00"];

                    spyOn($scope, 'getUsedTimezones').and.returnValue(['Europe/Paris', 'Asia/Calcutta']);
                    spyOn($scope, 'addTimeSlotSuggestion').and.returnValue({x: 1});

                    $scope.setSuggestions();

                    expect($scope.timeSlotsSuggestions).toEqual({'Europe/Paris': [{ x: 1 }, { x: 1 }, { x: 1 }], 'Asia/Calcutta': [{ x: 1 }, { x: 1 }, { x: 1 }]})

                });
            });

            describe('addTimeSlotSuggestion', function() {


                describe('The suggestion is within the working hours bounds', function() {

                    beforeEach(function() {
                        spyOn($scope, 'checkSuggestionTimeOutBound').and.returnValue(false);
                    });

                    it('should return the correct object', function() {
                        window.threadComputedData.locale = 'fr';
                        var result = $scope.addTimeSlotSuggestion("Europe/Paris", "2016-04-08T10:00:00+02:00");

                        expect(result.value.format()).toEqual('2016-04-08T10:00:00+02:00');
                        expect(result.displayText).toEqual('Vendredi 8 avril 2016 10:00am');
                        expect(result.isOutBound).toBe(false);
                    });

                });

                describe('The suggestion is outside the working hours bounds', function() {

                    beforeEach(function() {
                        spyOn($scope, 'checkSuggestionTimeOutBound').and.returnValue(true);
                    });

                    it('should return the correct object', function() {
                        window.threadComputedData.locale = 'fr';
                        var result = $scope.addTimeSlotSuggestion("Europe/Paris", "2016-04-08T10:00:00+02:00");

                        expect(result.value.format()).toEqual('2016-04-08T10:00:00+02:00');
                        expect(result.displayText).toEqual('Vendredi 8 avril 2016 10:00am');
                        expect(result.isOutBound).toBe(true);
                    });

                });
            });

            describe('getAppointmentWorkingHours', function() {

                it('should return the correct hours', function() {

                    expect($scope.getAppointmentWorkingHours()).toEqual({
                        start: [8, 0],
                        end: [21, 0]
                    });

                });
            });

            describe('checkSuggestionTimeOutBound', function() {
                var date;

                beforeEach(function() {
                    spyOn($scope, "getAppointmentWorkingHours").and.returnValue({
                        start: [8, 30],
                        end: [21, 0]
                    });

                    date = moment();
                });

                it('should return true', function() {
                    date.hour(7);
                    date.minute(0);
                    expect($scope.checkSuggestionTimeOutBound(date)).toBe(true);
                });

                it('should return false', function() {
                    date.hour(9);
                    date.minute(0);
                    expect($scope.checkSuggestionTimeOutBound(date)).toBe(false);
                });
            });

            describe('getUsedTimezones', function() {

                it('should call the right method', function() {
                    spyOn($attendeesService, 'getUsedTimezones');

                    $scope.getUsedTimezones();

                    expect($attendeesService.getUsedTimezones).toHaveBeenCalled();
                });

                it('should set the correct scope variables', function() {
                    spyOn($attendeesService, 'getUsedTimezones').and.returnValue({usedTimezones: ['Asia/Calcutta', 'America/New_York'], allUsedTimezones: ['Europe/Paris', 'Asia/Calcutta', 'America/New_York']});

                    $scope.getUsedTimezones();

                    expect($scope.usedTimezones).toEqual(['Asia/Calcutta', 'America/New_York']);
                    expect($scope.allUsedTimezones).toEqual(['Europe/Paris', 'Asia/Calcutta', 'America/New_York']);
                });

                it('should return the correct value', function() {
                    spyOn($attendeesService, 'getUsedTimezones').and.returnValue({usedTimezones: ['Asia/Calcutta', 'America/New_York'], allUsedTimezones: ['Europe/Paris', 'Asia/Calcutta', 'America/New_York']});

                    expect($scope.getUsedTimezones()).toEqual(['Europe/Paris', 'Asia/Calcutta', 'America/New_York']);
                });

            });

        });

        describe('datesIdentificationsManager', function() {

            describe('Init', function() {

                it('should call the right methods', function() {
                    spyOn($scopeIdentificationMng, 'getUsedTimezones');
                    spyOn($scopeIdentificationMng, 'selectCorrectTimezone');
                    spyOn($scopeIdentificationMng, 'getDatesToIdentify');

                    $scopeIdentificationMng.init();

                    expect($scopeIdentificationMng.getUsedTimezones).toHaveBeenCalled();
                    expect($scopeIdentificationMng.selectCorrectTimezone).toHaveBeenCalled();
                    expect($scopeIdentificationMng.getDatesToIdentify).toHaveBeenCalled();
                });

            });

            describe('getUsedTimezones', function() {

                it('should call the correct method', function() {
                    spyOn($attendeesService, 'getUsedTimezones').and.returnValue({allUsedTimezones: ['timezone']});

                    $scopeIdentificationMng.getUsedTimezones();

                    expect($attendeesService.getUsedTimezones).toHaveBeenCalled();
                });

                it('should set the correct scope variable', function() {
                    spyOn($attendeesService, 'getUsedTimezones').and.returnValue({allUsedTimezones: ['timezone']});

                    $scopeIdentificationMng.getUsedTimezones();

                    expect($scopeIdentificationMng.usedTimezones).toEqual(['timezone']);
                });

            });

            describe('getSelectedDatesToIdentify', function() {

                it('should return the selected dates', function() {
                    window.threadComputedData.timezone = 'Europe/Paris';

                    var date = moment();
                    $scopeIdentificationMng.datesToIdentify = [{selected: true, date: date}, {selected: false, date: date}, {selected: true, date: date}];

                    expect($scopeIdentificationMng.getSelectedDatesToIdentify()).toEqual([{ selected: true, date: date, timezone: 'Europe/Paris', date_with_timezone: date.tz('Europe/Paris')}, { selected: true, date: date, timezone: 'Europe/Paris', date_with_timezone: date.tz('Europe/Paris') }]);
                });
            });

            describe('nextButtonDisabled', function() {

                it('should return true', function() {
                    spyOn($scopeIdentificationMng, 'getSelectedDatesToIdentify').and.returnValue([]);

                    expect($scopeIdentificationMng.nextButtonDisabled()).toBe(true)
                });

                it('should return false', function() {
                    spyOn($scopeIdentificationMng, 'getSelectedDatesToIdentify').and.returnValue([1]);

                    expect($scopeIdentificationMng.nextButtonDisabled()).toBe(false)
                });

                it('should return false', function() {
                    spyOn($scopeIdentificationMng, 'getSelectedDatesToIdentify').and.returnValue(undefined);

                    expect($scopeIdentificationMng.nextButtonDisabled()).toBe(undefined)
                });
            });

            describe('setTimezoneOnAppointment', function() {

                it('should set the selected timezone value to the thread timezone', function() {
                    spyOn($.fn, 'val');

                    $scopeIdentificationMng.selectedTimezone = 'timezone';

                    $scopeIdentificationMng.setTimezoneOnAppointment();

                    expect($.fn.val).toHaveBeenCalledWith('timezone');
                });
            });

            describe('listenToAttendeesAppEvents', function() {

                it('should listen to the right event', function() {

                    spyOn($scopeAM, '$on');

                    $scopeIdentificationMng.listenToAttendeesAppEvents();

                    expect($scopeAM.$on).toHaveBeenCalled();
                    expect($scopeAM.$on.calls.mostRecent().args[0]).toEqual('attendeesFetched')
                });

            });

            describe('selectCorrectTimezone', function() {

                describe('no attendee found', function() {

                    it('should not call any method', function() {
                        window.emailSender = function(){
                            return {name: 'aa'};
                        };

                        spyOn($attendeesService, 'getAttendeeByEmail').and.returnValue(undefined);
                        spyOn($scopeIdentificationMng, 'setTimezoneOnAppointment');
                        $scopeIdentificationMng.selectedTimezone = undefined;

                        $scopeIdentificationMng.selectCorrectTimezone();

                        expect($attendeesService.getAttendeeByEmail).toHaveBeenCalledWith('aa');
                        expect($scopeIdentificationMng.setTimezoneOnAppointment).not.toHaveBeenCalled();
                        expect($scopeIdentificationMng.selectedTimezone).toBe(undefined);
                    });

                });

                describe('attendee found', function() {

                    beforeEach(function() {
                        window.getCurrentAppointment = function() {
                            return {};
                        };
                    });

                    describe('thread owner', function() {
                        it('should call the correct methods', function() {
                            window.emailSender = function(){
                                return {name: window.threadAccount.email};
                            };

                            window.threadComputedData.timezone = 'timezoneCOmputed';

                            $httpBackend.flush();

                            spyOn($attendeesService, 'getAttendeeByEmail').and.callThrough();
                            $scopeIdentificationMng.selectedTimezone = undefined;

                            $scopeIdentificationMng.selectCorrectTimezone();

                            expect($attendeesService.getAttendeeByEmail).toHaveBeenCalledWith(window.threadAccount.email);
                            expect($scopeIdentificationMng.selectedTimezone).toBe('timezoneCOmputed');
                        });
                    });

                    describe('normal attendee', function() {
                        it('should call the correct methods', function() {
                            window.emailSender = function(){
                                return {name: "test@test1.com"};
                            };

                            window.threadComputedData.timezone = 'timezoneCOmputed';

                            $httpBackend.flush();

                            spyOn($attendeesService, 'getAttendeeByEmail').and.callThrough();
                            $scopeIdentificationMng.selectedTimezone = undefined;

                            $scopeIdentificationMng.selectCorrectTimezone();

                            expect($attendeesService.getAttendeeByEmail).toHaveBeenCalledWith('test@test1.com');
                            expect($scopeIdentificationMng.selectedTimezone).toBe('America/Chicago');
                        });
                    });

                    describe('assistant', function() {

                        it('should call the correct methods', function() {
                            window.currentAttendees.push({
                                id: 123,
                                email: "test@test3.com",
                                firstName: "fname3",
                                lastName: "lname3",
                                name: "fname3 lname3",
                                usageName: "fname3",
                                gender: 'M',
                                isAssistant: "false",
                                assisted: "true",
                                assistedBy: {guid: 124},
                                company: 'Test Company',
                                timezone: "timezoneOfAssisted",
                                landline: "",
                                mobile: "617-216-2881",
                                skypeId: "",
                                confCallInstructions: '',
                                isPresent: "true",
                                isClient: "true",
                                isThreadOwner: "false"
                            });
                            window.currentAttendees.push({
                                id: 124,
                                email: "test@test4.com",
                                firstName: "fname4",
                                lastName: "",
                                name: "fname4",
                                usageName: "fname4",
                                gender: 'F',
                                isAssistant: "true",
                                assisted: "false",
                                assistedBy: {},
                                company: '',
                                landline: "",
                                mobile: "617-216-2881",
                                skypeId: "",
                                confCallInstructions: '',
                                isPresent: "true",
                                isClient: "false",
                                isThreadOwner: "false"
                            });

                            window.emailSender = function(){
                                return {name: "test@test4.com"};
                            };

                            window.threadComputedData.timezone = 'timezoneCOmputed';

                            $httpBackend.flush();

                            spyOn($attendeesService, 'getAttendeeByEmail').and.callThrough();
                            $scopeIdentificationMng.selectedTimezone = undefined;

                            $scopeIdentificationMng.selectCorrectTimezone();

                            expect($attendeesService.getAttendeeByEmail).toHaveBeenCalledWith("test@test4.com");
                            expect($scopeIdentificationMng.selectedTimezone).toBe('timezoneOfAssisted');
                        });
                    });
                });
            });

            describe('computeDataOnDatesToIdentify', function() {

                it('should compute the data correctly', function() {
                    window.threadComputedData.locale = 'fr';
                    window.currentLocale = 'fr';
                    $scopeIdentificationMng.selectedTimezone = "Asia/Calcutta";

                    $scopeIdentificationMng.datesToIdentify = [
                        {date: "2016-04-14T09:15:00.000+00:00", date_with_timezone: "2016-04-14T14:45:00.000+05:30", timezone: "Asia/Calcutta"},
                        {date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta"},
                        {date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta"}
                    ];

                    $scopeIdentificationMng.computeDataOnDatesToIdentify();

                    expect($scopeIdentificationMng.datesToIdentify[0]).toEqual({ date: '2016-04-14T09:15:00.000+00:00', date_with_timezone: '2016-04-14T14:45:00.000+05:30', timezone: 'Asia/Calcutta', displayText: 'jeudi 14 avril 2016 à 14h45' });
                    expect($scopeIdentificationMng.datesToIdentify[1]).toEqual({ date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta", displayText: 'jeudi 14 avril 2016 à 22h45' });
                    expect($scopeIdentificationMng.datesToIdentify[2]).toEqual({ date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta", displayText: 'vendredi 15 avril 2016 à 14h45' });
                });

            });

            describe('getDatesToIdentify', function() {

                describe('no duplicates', function() {

                    it('should retrieve the dates to identify', function() {

                        spyOn($.fn, 'data').and.returnValue([
                            {date: "2016-04-14T09:15:00.000+00:00", date_with_timezone: "2016-04-14T14:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta"}
                        ]);
                        spyOn($scopeIdentificationMng, 'computeDataOnDatesToIdentify');

                        $scopeIdentificationMng.datesToIdentify = [];
                        $scopeIdentificationMng.selectedTimezone = 'Europe/Paris';

                        $scopeIdentificationMng.getDatesToIdentify();

                        expect($scopeIdentificationMng.computeDataOnDatesToIdentify).toHaveBeenCalled();
                        expect($scopeIdentificationMng.datesToIdentify).toEqual([
                            {date: "2016-04-14T09:15:00.000+00:00", date_with_timezone: "2016-04-14T14:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta"}
                        ]);
                    });
                });

                describe('duplicates', function() {

                    it('should retrieve the dates to identify', function() {

                        spyOn($.fn, 'data').and.returnValue([
                            {date: "2016-04-14T09:15:00.000+00:00", date_with_timezone: "2016-04-14T14:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta"}
                        ]);
                        spyOn($scopeIdentificationMng, 'computeDataOnDatesToIdentify');

                        $scopeIdentificationMng.datesToIdentify = [];
                        $scopeIdentificationMng.selectedTimezone = 'Europe/Paris';

                        $scopeIdentificationMng.getDatesToIdentify();

                        expect($scopeIdentificationMng.computeDataOnDatesToIdentify).toHaveBeenCalled();
                        expect($scopeIdentificationMng.datesToIdentify).toEqual([
                            {date: "2016-04-14T09:15:00.000+00:00", date_with_timezone: "2016-04-14T14:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-14T17:15:00.000+00:00", date_with_timezone: "2016-04-14T22:45:00.000+05:30", timezone: "Asia/Calcutta"},
                            {date: "2016-04-15T09:15:00.000+00:00", date_with_timezone: "2016-04-15T14:45:00.000+05:30", timezone: "Asia/Calcutta"}
                        ]);
                    });
                });


            });

        });
    })


})();