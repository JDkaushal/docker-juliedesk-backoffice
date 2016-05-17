//= require angular_event_creator_app

(function(){

    'use strict';

    describe('Event creator app', function() {
        var $rootScope, $scope, $scopeAM, DatesVerificationCtrl, DatesSuggestionsCtrl, $scopeSuggMng, $attendeesService;

        beforeEach(module('event-creator-controllers'));
        beforeEach(module('dates-manager-services'));
        beforeEach(module('dates-manager-controllers'));

        beforeEach(inject(function(_attendeesService_){
            $attendeesService = _attendeesService_;
        }));

        beforeEach(inject(function($injector) {
            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();
            $scopeSuggMng = $rootScope.$new();
            $scopeAM = $rootScope.$new();

            var $controller = $injector.get('$controller');
            DatesVerificationCtrl = $controller('datesVerificationManager', {$scope: $scope});
            DatesSuggestionsCtrl = $controller('datesSuggestionsManager', {$scope: $scopeSuggMng});

            spyOn($scope, 'getDatesManagerApp').and.returnValue($scopeSuggMng);
            spyOn($scopeSuggMng, 'getAttendeesApp').and.returnValue($scopeAM);
        }));

        describe('datesVerificationManager', function() {

            describe('init', function() {

                describe('data are available', function() {

                    it('should call the right methods', function() {
                        $scope.rawDatesToCheck = [{x: 1}];
                        $scope.datesToCheck = [{date: 'date'}];
                        spyOn($scope, 'setRawDatesFromData');
                        spyOn($scope, 'addDatesToCheck');
                        spyOn($scope, 'attachEventsToDom');

                        $scope.init();

                        expect($scope.setRawDatesFromData).toHaveBeenCalled();
                        expect($scope.addDatesToCheck).toHaveBeenCalled();
                        expect($scope.attachEventsToDom).toHaveBeenCalled();
                        expect($scope.selectedDateRaw).toEqual('date');

                    });

                });

                describe('data are not available', function() {

                    it('should call the right methods', function() {
                        $scope.rawDatesToCheck = [];
                        spyOn($scope, 'setRawDatesFromData');
                        spyOn($scope, 'addDatesToCheck');
                        spyOn($scope, 'attachEventsToDom');

                        $scope.init();

                        expect($scope.setRawDatesFromData).toHaveBeenCalled();
                        expect($scope.addDatesToCheck).not.toHaveBeenCalled();
                        expect($scope.attachEventsToDom).toHaveBeenCalled();
                        expect($scope.selectedDate).toBe(undefined);

                    });

                });
            });

            describe('setRawDatesFromData', function() {

                it('should set the correct scope variable', function() {
                    spyOn($.fn, 'data').and.returnValue([{x: 1}, {x:2}, {x: 3}]);

                    $scope.setRawDatesFromData();

                    expect($.fn.data).toHaveBeenCalledWith('date-times');
                    expect($scope.rawDatesToCheck).toEqual([{x: 1}, {x:2}, {x: 3}]);
                });
            });

            describe('addRawDateToCheck', function() {

                it('should call the correct method and set the correct scope variables', function() {
                    spyOn($scope, 'setRawDatesFromData');

                    $scope.rawDatesToCheck = [{date: 1}, {date: 2}];

                    $scope.addRawDateToCheck({date: 2});

                    expect($scope.setRawDatesFromData).toHaveBeenCalled();
                    expect($scope.rawDatesToCheck).toEqual([{date: 1}, {date: 2}]);

                    $scope.addRawDateToCheck({date: 3});
                    expect($scope.rawDatesToCheck).toEqual([{date: 1}, {date: 2}, {date: 3}]);

                });
            });

            describe('addNewDateToVerify', function() {
                it('should call the correct methods and set the correct scope variable', function() {
                    spyOn($scope, 'addRawDateToCheck');
                    spyOn($scope, 'addDatesToCheck');

                    $scope.selectedDateRaw = undefined;

                    $scope.addNewDateToVerify({date: 'date'});

                    expect($scope.addRawDateToCheck).toHaveBeenCalledWith({date: 'date'});
                    expect($scope.addDatesToCheck).toHaveBeenCalled();
                    expect($scope.selectedDateRaw).toEqual('date');
                });


            });

            describe('onMainTimezoneChange', function() {
                it('should call the correct methods and set the correct window variable', function() {
                    window.threadComputedData = {};
                    spyOn($scope, 'addTimezoneToCurrentCalendar');
                    spyOn($scope, 'addDatesToCheck');
                    spyOn($scope, 'selectSuggestedDateInCalendar');
                    spyOn($.fn, 'val');

                    $scope.onMainTimezoneChange({value: 'newTimezone'});

                    expect($scope.addTimezoneToCurrentCalendar).toHaveBeenCalledWith('newTimezone');
                    expect($scope.addDatesToCheck).toHaveBeenCalled();
                    expect($scope.selectSuggestedDateInCalendar).toHaveBeenCalled();
                    expect($.fn.val).toHaveBeenCalledWith('newTimezone');
                    expect(window.threadComputedData.timezone).toEqual('newTimezone');
                })


            });

            describe('addTimezoneToCurrentCalendar', function() {
                it('should call the correct methods and set the correct variables', function() {
                    window.currentCalendar = {
                        initialData: {additional_timezone_ids: []},
                        redrawTimeZoneSelector: function() {},
                        selectTimezone: function(timezone, bool) {}
                    };

                    spyOn(window.currentCalendar, 'redrawTimeZoneSelector');
                    spyOn(window.currentCalendar, 'selectTimezone');

                    $scope.addTimezoneToCurrentCalendar('newTimezone');

                    expect(window.currentCalendar.redrawTimeZoneSelector).toHaveBeenCalled();
                    expect(window.currentCalendar.selectTimezone).toHaveBeenCalledWith('newTimezone', true);
                    expect(window.currentCalendar.initialData.additional_timezone_ids).toEqual(['newTimezone']);
                });
            });

            describe('eventActionsDisabled', function() {
                it('should return true', function() {
                    $scope.datesToCheck = [];

                    expect($scope.eventActionsDisabled()).toBe(true);
                });

                it('should return false', function() {
                    $scope.datesToCheck = [1];

                    expect($scope.eventActionsDisabled()).toBe(false);
                });
            });

            describe('attachEventsToDom', function() {
                it('should call the correct methods', function() {
                    spyOn($.fn, 'timezonePicker');
                    spyOn($.fn, 'on');

                    $scope.attachEventsToDom();

                    expect($.fn.timezonePicker).toHaveBeenCalledWith({
                        onSelectCallback: $scope.onMainTimezoneChange
                    });

                    expect($.fn.on).toHaveBeenCalled();
                });
            });

            describe('getUsedTimezones', function() {
                it('should return the correct value', function() {
                    spyOn($scopeSuggMng, 'getUsedTimezones').and.returnValue(['timezone1', 'timezone2']);
                    // Used to set the $scope.datesManager variable
                    $scope.listenToEvents();

                    expect($scope.getUsedTimezones()).toEqual(['timezone1', 'timezone2']);
                });
            });

            describe('addDatesToCheck', function() {

                it('should set the $scope.datesToCheck variable', function() {
                    // Used to set the $scope.datesManager variable
                    $scope.listenToEvents();

                    window.threadComputedData = {};

                    window.threadComputedData.timezone = 'Europe/Paris';
                    window.threadComputedData.locale = 'fr';
                    window.currentLocale = 'fr';

                    $scope.selectedDateRaw = '2016-04-12T12:30:00Z';
                    $scope.rawDatesToCheck = [{date: '2016-04-11T12:30:00Z'}, {date: '2016-04-12T12:30:00Z'}, {date: '2016-04-13T22:30:00Z'}];

                    spyOn($scope, 'getUsedTimezones').and.returnValue(['Asia/Calcutta', 'America/New_York']);

                    $scope.addDatesToCheck();

                    expect($scope.datesToCheck).toEqual([
                        { date: '2016-04-11T14:30:00+02:00', timezone: 'Europe/Paris', displayText: 'lundi 11 avril 2016 à 14h30', isHighlighted: false, isOutBound: false, dateInOtherTimezones: [{ displayText: 'lundi 11 avril 2016 à 18h00', timezone: 'Asia/Calcutta', isOutBound: false }, { displayText: 'lundi 11 avril 2016 à 8h30', timezone: 'America/New_York', isOutBound: false }]},
                        { date: '2016-04-12T14:30:00+02:00', timezone: 'Europe/Paris', displayText: 'mardi 12 avril 2016 à 14h30', isHighlighted: true, isOutBound: false, dateInOtherTimezones: [{ displayText: 'mardi 12 avril 2016 à 18h00', timezone: 'Asia/Calcutta', isOutBound: false }, { displayText: 'mardi 12 avril 2016 à 8h30', timezone: 'America/New_York', isOutBound: false }]},
                        { date: '2016-04-14T00:30:00+02:00', timezone: 'Europe/Paris', displayText: 'jeudi 14 avril 2016 à 0h30', isHighlighted: false, isOutBound: true, dateInOtherTimezones: [{ displayText: 'jeudi 14 avril 2016 à 4h00', timezone: 'Asia/Calcutta', isOutBound: true }, { displayText: 'mercredi 13 avril 2016 à 18h30', timezone: 'America/New_York', isOutBound: false }]}
                    ]);

                });


            });

            describe('window.allCalendarEventsFetched', function() {
                it('should call the correct method', function() {
                    spyOn($scope, 'selectSuggestedDateInCalendar');

                    window.allCalendarEventsFetched();

                    expect($scope.selectSuggestedDateInCalendar).toHaveBeenCalled();
                });

            });

            describe('listenToEvents', function() {
                it('should call the right methods and set the correct scope variables', function() {
                    spyOn($scopeAM, '$on');

                    $scope.listenToEvents();

                    expect($scope.getDatesManagerApp).toHaveBeenCalled();
                    expect($scopeSuggMng.getAttendeesApp).toHaveBeenCalled();
                    expect($scopeAM.$on).toHaveBeenCalledWith('attendeesFetched', $scope.attendeesRefreshedActions);
                });
            });

            describe('attendeesRefreshedActions', function() {
                it('should call the right methods', function() {
                    spyOn($scope, 'init');
                    spyOn($scope, '$apply');

                    $scope.attendeesRefreshedActions();

                    expect($scope.init).toHaveBeenCalled();
                    expect($scope.$apply).toHaveBeenCalled();
                });

            });
        });

    });

})();