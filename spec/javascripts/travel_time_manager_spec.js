//= require angular_travel_time_manager_app.js

(function(){

    'use strict';

    describe('travelTimeManager', function() {
        var $scope, $rootScope, travelTimeCalculator;

        window.google = false;

        beforeEach(module('travel-time-manager-controllers'));

        beforeEach(inject(function($injector) {
            window.threadComputedData = {location_coordinates:  [1, 2]};
            window.threadAccount = {travel_time_transport_mode: 'driving'};

            $rootScope = $injector.get('$rootScope');
            $scope = $rootScope.$new();

            var $controller = $injector.get('$controller');
            travelTimeCalculator = $controller('travelTimeCalculator', {$scope: $scope});
        }));

        describe('travelTimeCalculator', function() {

            describe('init', function() {

               it('should set the correct scope variables', function() {
                    $scope.originCoordinates = {};
                    $scope.preferedMeanOfTransport = undefined;

                   $scope.init();

                   expect($scope.originCoordinates).toEqual([ 1, 2 ]);
                    expect($scope.preferedMeanOfTransport).toEqual('driving');
               });

            });

            describe('processForClient', function() {

                describe('No coordinates available', function() {
                    beforeEach(function() {

                       window.threadComputedData = {location_coordinates: undefined};
                        window.threadAccount.delay_between_appointments = 10;
                    });

                    it('should still display the default delay for the appointments', function() {
                        spyOn($scope, 'setEvents');
                        spyOn($scope, 'selectEventsToCompute');
                        spyOn($scope, 'calculate');
                        spyOn($scope, 'computeDefaultAppointmentDelay');

                        $scope.processForClient({email: 'email@gmail.com', delay_between_appointments: 10}, []);

                        expect($scope.calculate).not.toHaveBeenCalled();
                        expect($scope.computeDefaultAppointmentDelay).toHaveBeenCalledWith('email@gmail.com');
                    });

                });

                describe('coordinates available', function() {
                    beforeEach(function() {

                        window.threadComputedData = {location_coordinates: [1, 2]}
                    });

                    it('should call the correct methods', function() {
                        spyOn($scope, 'setEvents');
                        spyOn($scope, 'selectEventsToCompute');
                        spyOn($scope, 'calculate');

                        $scope.processForClient({email: 'email@gmail.com'}, []);

                        expect($scope.setEvents).toHaveBeenCalledWith('email@gmail.com', []);
                        expect($scope.selectEventsToCompute).toHaveBeenCalledWith('email@gmail.com');
                        expect($scope.calculate).toHaveBeenCalledWith('email@gmail.com');
                    });
                });

            });

            describe('setEvents', function() {

                it('should set the correct scope variable', function() {
                    $scope.events = {};

                    var events = [
                        {all_day: true, id: 1},
                        {all_day: false, id: 2},
                        {all_day: false, id: 3},
                        {all_day: false, id: 4},
                        {all_day: true, id: 5}
                    ];

                    $scope.setEvents('email@gmail.com', events);

                    expect($scope.events).toEqual({
                        'email@gmail.com':  [
                            {all_day: false, id: 2},
                            {all_day: false, id: 3},
                            {all_day: false, id: 4}
                        ]
                    });
                });


            });

            describe('sortEventsStartDate', function() {
                var events = [
                    {start: {date: "2016-05-05"}, id: 1},
                    {start: {date: "2016-05-02T13:00:00.000+02:00"}, id: 2},
                    {start: {date: "2016-04-02T13:00:00.000+02:00"}, id: 3},
                    {start: {date: "2016-06-05"}, id: 4},
                    {start: {date: "2016-05-02T15:00:00.000+02:00"}, id: 5}
                ];

                it('should set the correct scope variable', function() {
                    $scope.events = {'email@gmail.com': events};

                    var result = $scope.sortEventsStartDate(events);

                    expect(_.map(result, function(e) {return e.id;})).toEqual([ 3, 2, 5, 1, 4 ])
                });
            });

            describe('selectEventsToCompute', function() {

                it('should analyze the events correctly and update them accordingly', function() {

                    $scope.events = {
                        'email@gmail.com': [
                            //{id: 1, location: '', start: {dateTime: "2016-05-05"}, end: {dateTime: "2016-05-06"}},
                            {id: 2, location: '100 rue de la rue', start: {dateTime: "2016-05-05T13:00:00.000+02:00"}, end: {dateTime: "2016-05-05T15:00:00.000+02:00"}},
                            {id: 3, location: "10 avenue de l'avenue", start: {dateTime: "2016-05-05T15:00:00.000+02:00"}, end: {dateTime: "2016-05-05T16:00:00.000+02:00"}},
                            {id: 4, location: '9 boulevard du boulevard', start: {dateTime: "2016-05-06T15:00:00.000+02:00"}, end: {dateTime: "2016-05-06T17:00:00.000+02:00"}},
                            {id: 5, location: '2 sentier du sentier', start: {dateTime: "2016-05-06T17:00:00.000+02:00"}, end: {dateTime: "2016-05-06T19:00:00.000+02:00"}},
                            {id: 6, location: '1 impasse de impasse', start: {dateTime: "2016-05-06T19:00:00.000+02:00"}, end: {dateTime: "2016-05-07T15:00:00.000+02:00"}}
                        ]};

                    $scope.selectEventsToCompute('email@gmail.com');

                    //var result = $scope.events['email@gmail.com'];
                    //var expectation = [
                    //    //{location: '', start: {date: "2016-05-05"}, end: {dateTime: "2016-05-06"}, calculateTravelTime: false},
                    //    {id: 2, location: '100 rue de la rue', start: {dateTime: "2016-05-05T13:00:00.000+02:00"}, end: {dateTime: "2016-05-05T15:00:00.000+02:00"}, lowerEdgeBusy: false, upperEdgeBusy: true, calculateTravelTime: true},
                    //    {id: 3, location: "10 avenue de l'avenue", start: {dateTime: "2016-05-05T15:00:00.000+02:00"}, end: {dateTime: "2016-05-05T16:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: false, calculateTravelTime: true, upperEdgeMaxTimeDisplay: 1380},
                    //    {id: 4, location: '9 boulevard du boulevard', start: {dateTime: "2016-05-06T15:00:00.000+02:00"}, end: {dateTime: "2016-05-06T17:00:00.000+02:00"}, lowerEdgeBusy: false, upperEdgeBusy: true, calculateTravelTime: true, lowerEdgeMaxTimeDisplay: 1380},
                    //    {id: 5, location: '2 sentier du sentier', start: {dateTime: "2016-05-06T17:00:00.000+02:00"}, end: {dateTime: "2016-05-06T19:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: true, calculateTravelTime: false},
                    //    {id: 6, location: '1 impasse de impasse', start: {dateTime: "2016-05-06T19:00:00.000+02:00"}, end: {dateTime: "2016-05-07T15:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: false, calculateTravelTime: true}
                    //];
                    //
                    //expect(result[2]).toEqual(expectation[2]);

                    expect($scope.events['email@gmail.com']).toEqual(
                        [
                            //{location: '', start: {date: "2016-05-05"}, end: {dateTime: "2016-05-06"}, calculateTravelTime: false},
                            {id: 2, location: '100 rue de la rue', start: {dateTime: "2016-05-05T13:00:00.000+02:00"}, end: {dateTime: "2016-05-05T15:00:00.000+02:00"}, lowerEdgeBusy: false, upperEdgeBusy: true, calculateTravelTime: true},
                            {id: 3, location: "10 avenue de l'avenue", start: {dateTime: "2016-05-05T15:00:00.000+02:00"}, end: {dateTime: "2016-05-05T16:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: false, calculateTravelTime: true, upperEdgeMaxTimeDisplay: 1380},
                            {id: 4, location: '9 boulevard du boulevard', start: {dateTime: "2016-05-06T15:00:00.000+02:00"}, end: {dateTime: "2016-05-06T17:00:00.000+02:00"}, lowerEdgeBusy: false, upperEdgeBusy: true, calculateTravelTime: true, lowerEdgeMaxTimeDisplay: 1380},
                            {id: 5, location: '2 sentier du sentier', start: {dateTime: "2016-05-06T17:00:00.000+02:00"}, end: {dateTime: "2016-05-06T19:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: true, calculateTravelTime: false},
                            {id: 6, location: '1 impasse de impasse', start: {dateTime: "2016-05-06T19:00:00.000+02:00"}, end: {dateTime: "2016-05-07T15:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: false, calculateTravelTime: true}
                        ]
                    );

                    //console.log($scope.events['email@gmail.com']);
                    //
                    //console.log(
                    //    [
                    //        //{location: '', start: {date: "2016-05-05"}, end: {dateTime: "2016-05-06"}, calculateTravelTime: false},
                    //        {id: 2, location: '100 rue de la rue', start: {dateTime: "2016-05-05T13:00:00.000+02:00"}, end: {dateTime: "2016-05-05T15:00:00.000+02:00"}, lowerEdgeBusy: false, upperEdgeBusy: true, calculateTravelTime: true},
                    //        {id: 3, location: "10 avenue de l'avenue", start: {dateTime: "2016-05-05T15:00:00.000+02:00"}, end: {dateTime: "2016-05-05T16:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: false, calculateTravelTime: true, upperEdgeMaxTravelTimeDisplay: 1380},
                    //        {id: 4, location: '9 boulevard du boulevard', start: {dateTime: "2016-05-06T15:00:00.000+02:00"}, end: {dateTime: "2016-05-06T17:00:00.000+02:00"}, lowerEdgeBusy: false, upperEdgeBusy: true, calculateTravelTime: true, lowerEdgeMaxTravelTimeDisplay: 1380},
                    //        {id: 5, location: '2 sentier du sentier', start: {dateTime: "2016-05-06T17:00:00.000+02:00"}, end: {dateTime: "2016-05-06T19:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: true, calculateTravelTime: false},
                    //        {id: 6, location: '1 impasse de impasse', start: {dateTime: "2016-05-06T19:00:00.000+02:00"}, end: {dateTime: "2016-05-07T15:00:00.000+02:00"}, lowerEdgeBusy: true, upperEdgeBusy: false, calculateTravelTime: true}
                    //    ]
                    //);
                });
            });

            describe('upperEdgeIsBusyCondition', function() {
                var referenceEvent = {
                    start: {
                        dateTime: '2016-02-10T12:00:000+02:00'
                    },
                    end: {
                        dateTime: '2016-02-10T15:00:000+02:00'
                    }
                };

                it('should return false', function() {
                    expect($scope.upperEdgeIsBusyCondition(moment('2016-02-10T11:00:000+02:00'), referenceEvent)).toBe(false);
                    expect($scope.upperEdgeIsBusyCondition(moment('2016-02-10T15:00:000+02:00'), referenceEvent)).toBe(false);
                    expect($scope.upperEdgeIsBusyCondition(moment('2016-02-10T16:00:000+02:00'), referenceEvent)).toBe(false);
                });

                it('should return true', function() {
                    expect($scope.upperEdgeIsBusyCondition(moment('2016-02-10T12:00:000+02:00'), referenceEvent)).toBe(true);
                    expect($scope.upperEdgeIsBusyCondition(moment('2016-02-10T13:00:000+02:00'), referenceEvent)).toBe(true);
                });

            });

            describe('lowerEdgeIsBusyCondition', function() {
                var referenceEvent = {
                    start: {
                        dateTime: '2016-02-10T12:00:000+02:00'
                    },
                    end: {
                        dateTime: '2016-02-10T15:00:000+02:00'
                    }
                };

                it('should return false', function() {
                    expect($scope.lowerEdgeIsBusyCondition(moment('2016-02-10T11:00:000+02:00'), referenceEvent)).toBe(false);
                    expect($scope.lowerEdgeIsBusyCondition(moment('2016-02-10T12:00:000+02:00'), referenceEvent)).toBe(false);
                    expect($scope.lowerEdgeIsBusyCondition(moment('2016-02-10T16:00:000+02:00'), referenceEvent)).toBe(false);
                });

                it('should return true', function() {
                    expect($scope.lowerEdgeIsBusyCondition(moment('2016-02-10T13:00:000+02:00'), referenceEvent)).toBe(true);
                    expect($scope.lowerEdgeIsBusyCondition(moment('2016-02-10T15:00:000+02:00'), referenceEvent)).toBe(true);
                });

            });

            describe('calculate', function() {

                it('should call the correct method with the right parameters', function() {
                    $scope.events = {
                      'email@gmail.com': [
                          {calculateTravelTime: true, id: 1},
                          {calculateTravelTime: false, id: 2},
                          {calculateTravelTime: true, id: 3},
                          {calculateTravelTime: true, id: 4}
                      ]
                    };

                    spyOn($scope, 'computeEvents');

                    $scope.calculate('email@gmail.com');

                    expect($scope.computeEvents).toHaveBeenCalledWith('email@gmail.com', [
                        {calculateTravelTime: true, id: 1},
                        {calculateTravelTime: true, id: 3},
                        {calculateTravelTime: true, id: 4}
                    ]);
                });

                describe('No events need to have a calculated travel time', function() {

                   beforeEach(function() {
                       window.threadAccount.delay_between_appointments = 10;
                   });

                    it('should call the correct method', function() {
                        $scope.events = {
                            'email@gmail.com': [
                                {calculateTravelTime: false, id: 1},
                                {calculateTravelTime: false, id: 2},
                                {calculateTravelTime: false, id: 3},
                                {calculateTravelTime: false, id: 4}
                            ]
                        };

                        $scope.defaultDelayByClient['email@gmail.com'] = 10;

                        spyOn($scope, 'computeDefaultAppointmentDelay');

                        $scope.calculate('email@gmail.com');

                        expect($scope.computeDefaultAppointmentDelay).toHaveBeenCalledWith('email@gmail.com');
                    });
                });
            });

            describe('computeEvents', function() {
                var events = [{id: 1}, {id: 2}, {id: 3}];

                describe('When Mean of transport != max', function() {

                    beforeEach(function() {
                       $scope.preferedMeanOfTransport = 'driving';
                    });

                    it('should call the right methods with the right parameters', function() {
                        spyOn($scope, 'decomposeEventsIntoFittingGroups').and.returnValue(events);
                        spyOn($scope, 'simpleGoogleMatrixRequest');

                        $scope.computeEvents('email@gmail.com', events);

                        expect($scope.decomposeEventsIntoFittingGroups).toHaveBeenCalledWith(events);
                        expect($scope.simpleGoogleMatrixRequest).toHaveBeenCalledWith('email@gmail.com', events, 'driving');
                    });

                });

                describe('When Mean of transport == max', function() {
                    beforeEach(function() {
                        $scope.preferedMeanOfTransport = 'max';
                    });

                    it('should call the right methods with the right parameters', function() {
                        spyOn($scope, 'decomposeEventsIntoFittingGroups').and.returnValue(events);
                        spyOn($scope, 'simpleGoogleMatrixRequest');

                        $scope.computeEvents('email@gmail.com', events);

                        expect($scope.decomposeEventsIntoFittingGroups).toHaveBeenCalledWith(events);
                        expect($scope.simpleGoogleMatrixRequest.calls.count()).toEqual(2);
                        expect($scope.simpleGoogleMatrixRequest.calls.all()[0].args).toEqual(['email@gmail.com', events, 'driving']);
                        expect($scope.simpleGoogleMatrixRequest.calls.all()[1].args).toEqual(['email@gmail.com', events, 'transit']);
                    });
                });
            });

            describe('simpleGoogleMatrixRequest', function() {

                it('should call the correct methods with the right parameters', function() {
                    spyOn($scope, 'getGoogleTravelMode').and.returnValue('googleMode');
                    spyOn($scope, 'performGoogleRequests');

                    $scope.simpleGoogleMatrixRequest('email@gmail.com', [1, 2, 3], 'travelMode');

                    expect($scope.getGoogleTravelMode).toHaveBeenCalledWith('travelMode');
                    expect($scope.performGoogleRequests).toHaveBeenCalledWith('email@gmail.com', [1, 2, 3], 'googleMode');
                });
            });

            describe('getGoogleTravelMode', function() {
                it('should return the correct value', function() {
                    window.google = {maps: {TravelMode: {DRIVING: 'googleDriving', TRANSIT: 'googleTransit'}}};

                    expect($scope.getGoogleTravelMode('driving')).toEqual('googleDriving');
                    expect($scope.getGoogleTravelMode('transit')).toEqual('googleTransit');

                    window.google = false;
                });
            });

            describe('decomposeEventsIntoFittingGroups', function() {

                it('should return 25-items chunks of the base array', function() {
                    var baseArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52];

                    expect($scope.decomposeEventsIntoFittingGroups(baseArray)).toEqual(
                        [
                            [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 ],
                            [ 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50 ],
                            [ 51, 52 ]
                        ]
                    );

                });
            });

            describe('performGoogleRequests', function() {

                it('should call the correct method with the right parameters', function() {
                    spyOn($scope, 'makeGoogleMatrixRequest');

                    $scope.performGoogleRequests('email@gmail.com', [[{id: 1, location: 'location1'}, {id: 2, location: 'location2'}, {id: 3, location: 'location3'}]], 'driving');

                    expect($scope.makeGoogleMatrixRequest).toHaveBeenCalledWith(
                        'email@gmail.com',
                        'driving',
                        // Normally for the origin parameter we would ahve a Google LatLng Object
                        [[1, 2]],
                        ['location1', 'location2', 'location3'],
                        [{id: 1, location: 'location1'}, {id: 2, location: 'location2'}, {id: 3, location: 'location3'}]
                    )
                });
            });

            describe('handleGoogleMatrixResponse', function() {
                beforeEach(function(){
                    window.google = {maps: {DistanceMatrixStatus: {OK: 'OK'}}};
                });

                afterEach(function() {
                   window.google = false;
                });

                it('should decrement the pendingRequest count for the specified email', function() {
                    $scope.pendingGoogleMatrixCall = {'email@gmail.com': 3};

                    $scope.handleGoogleMatrixResponse({}, 'NOTOK', [], 'email@gmail.com');

                    expect($scope.pendingGoogleMatrixCall['email@gmail.com']).toEqual(2);
                });


                describe('Request failed', function() {

                    it('should not call any methods', function() {
                        $scope.pendingGoogleMatrixCall = {'email@gmail.com': 3};
                        spyOn($scope, 'handleResponseElement');

                        $scope.handleGoogleMatrixResponse({}, 'NOTOK', [], 'email@gmail.com');

                        expect($scope.handleResponseElement).not.toHaveBeenCalled();
                    });

                    //it('should not call any methods', function() {
                    //    $scope.pendingGoogleMatrixCall = {'email@gmail.com': 3};
                    //    spyOn($scope, 'addCurrentDurationToMaxTmp');
                    //    spyOn($scope, 'getMaxDurationForEventThenCompute');
                    //    spyOn($scope, 'addTravelTimeEventsToCalendar');
                    //
                    //    $scope.handleGoogleMatrixResponse({}, 'NOTOK', [], 'email@gmail.com');
                    //
                    //    expect($scope.addCurrentDurationToMaxTmp).not.toHaveBeenCalled();
                    //    expect($scope.getMaxDurationForEventThenCompute).not.toHaveBeenCalled();
                    //    expect($scope.addTravelTimeEventsToCalendar).not.toHaveBeenCalled();
                    //
                    //});
                });

                describe('Request succeed', function() {

                    it('should call the right methods with the right arguments', function() {
                        $scope.pendingGoogleMatrixCall = {'email@gmail.com': 3};

                        var response = {
                            destinationAddresses: ['address1', 'address2', 'address3', 'address4'],
                            rows: [
                                {
                                    elements: [
                                        {status: 'OK', duration: 1200},
                                        {status: 'NOTOK'},
                                        {status: 'OK', duration: 1200},
                                        {status: 'OK', duration: 1200}
                                    ]
                                }
                            ]
                        };

                        spyOn($scope, 'handleResponseElement');

                        $scope.handleGoogleMatrixResponse(response, 'OK', [{id: 1}, {id: 2}, {id: 3}, {id: 4}], 'email@gmail.com');

                        expect($scope.handleResponseElement.calls.count()).toEqual(4);
                        expect($scope.handleResponseElement.calls.all()[0].args).toEqual(['email@gmail.com', {status: 'OK', duration: 1200}, {id: 1}, 'address1']);
                        expect($scope.handleResponseElement.calls.all()[1].args).toEqual(['email@gmail.com', {status: 'NOTOK'}, {id: 2}, 'address2']);
                        expect($scope.handleResponseElement.calls.all()[2].args).toEqual(['email@gmail.com', {status: 'OK', duration: 1200}, {id: 3}, 'address3']);
                        expect($scope.handleResponseElement.calls.all()[3].args).toEqual(['email@gmail.com', {status: 'OK', duration: 1200}, {id: 4}, 'address4']);
                    });

                    //it('should call the right methods with the right arguments', function() {
                    //    $scope.pendingGoogleMatrixCall = {'email@gmail.com': 3};
                    //
                    //    var response = {
                    //        destinationAddresses: ['address1', 'address2', 'address3', 'address4'],
                    //        rows: [
                    //            {
                    //                elements: [
                    //                    {status: 'OK', duration: 1200},
                    //                    {status: 'NOTOK'},
                    //                    {status: 'OK', duration: 1200},
                    //                    {status: 'OK', duration: 1200}
                    //                ]
                    //            }
                    //        ]
                    //    };
                    //
                    //    spyOn($scope, 'addCurrentDurationToMaxTmp');
                    //    spyOn($scope, 'getMaxDurationForEventThenCompute');
                    //    spyOn($scope, 'addTravelTimeEventsToCalendar');
                    //
                    //    $scope.handleGoogleMatrixResponse({}, 'OK', [], 'email@gmail.com');
                    //
                    //    expect($scope.simpleGoogleMatrixRequest.calls.count()).toEqual(2);
                    //    expect($scope.simpleGoogleMatrixRequest.calls.all()[0].args).toEqual(['email@gmail.com', events, 'driving']);
                    //    expect($scope.simpleGoogleMatrixRequest.calls.all()[1].args).toEqual(['email@gmail.com', events, 'transit']);
                    //});


                });

                describe('All pending requests are complete', function() {

                    it('should call the right method', function() {
                        window.threadAccount.delay_between_appointments = 10;
                        $scope.pendingGoogleMatrixCall = {'email@gmail.com': 1};

                        var response = {
                            destinationAddresses: ['address1', 'address2', 'address3', 'address4'],
                            rows: [
                                {
                                    elements: [
                                        {status: 'OK', duration: 1200},
                                        {status: 'NOTOK'},
                                        {status: 'OK', duration: 1200},
                                        {status: 'OK', duration: 1200}
                                    ]
                                }
                            ]
                        };

                        $scope.defaultDelayByClient['email@gmail.com'] = 10;

                        spyOn($scope, 'handleResponseElement');
                        spyOn($scope, 'addTravelTimeEventsToCalendar');
                        spyOn($scope, 'computeDefaultAppointmentDelay');

                        $scope.handleGoogleMatrixResponse(response, 'OK', [{id: 1}, {id: 2}, {id: 3}, {id: 4}], 'email@gmail.com');

                        expect($scope.addTravelTimeEventsToCalendar).toHaveBeenCalledWith('email@gmail.com');
                        expect($scope.computeDefaultAppointmentDelay).toHaveBeenCalledWith('email@gmail.com');
                    })
                });
            });

            describe('handleResponseElement', function() {
                beforeEach(function(){
                    window.google = {maps: {DistanceMatrixStatus: {OK: 'OK'}}};
                });

                afterEach(function() {
                    window.google = false;
                });

                describe('Request is a success', function() {

                    it('should call the right methods with the correct parameters', function() {
                        var element = {
                            status: 'OK',
                            duration: {value: 1200}
                        };

                        spyOn($scope, 'addCurrentDurationToMaxTmp');
                        spyOn($scope, 'getMaxDurationForEventThenCompute');

                        $scope.handleResponseElement('email@gmail.com', element, {id: 1}, 'destination');

                        expect($scope.addCurrentDurationToMaxTmp).toHaveBeenCalledWith('email@gmail.com', 1, 20);
                        expect($scope.getMaxDurationForEventThenCompute).toHaveBeenCalledWith('email@gmail.com', {id: 1}, 'destination');
                    });
                });

                describe('Request is a failure', function() {

                    it('should call the right methods with the correct parameters', function() {
                        var element = {
                            status: 'NOTOK'
                        };

                        spyOn($scope, 'addCurrentDurationToMaxTmp');
                        spyOn($scope, 'getMaxDurationForEventThenCompute');

                        $scope.handleResponseElement('email@gmail.com', element, {id: 1}, 'destination');

                        expect($scope.addCurrentDurationToMaxTmp).toHaveBeenCalledWith('email@gmail.com', 1, null);
                        expect($scope.getMaxDurationForEventThenCompute).toHaveBeenCalledWith('email@gmail.com', {id: 1}, 'destination');
                    });
                });
            });

            describe('getMaxDurationForEventThenCompute', function() {

                beforeEach(function() {
                    $scope.preferedMeanOfTransport = 'driving';

                });

                describe('a max has been found', function() {
                    beforeEach(function() {
                        spyOn($scope, 'getMaxDurationForEvent').and.returnValue(10);
                    });

                    it('should call the right methods with the correct parameters', function() {
                        spyOn($scope, 'buildInfoEvent');

                        $scope.getMaxDurationForEventThenCompute('email@gmail.com', {id: 1}, 'destination');

                        expect($scope.getMaxDurationForEvent).toHaveBeenCalled();
                        expect($scope.buildInfoEvent).toHaveBeenCalledWith('email@gmail.com', 'travelTime', {id: 1}, 10, 'destination');
                    });
                });

                describe('no max has been found', function() {
                    beforeEach(function() {
                        spyOn($scope, 'getMaxDurationForEvent').and.returnValue(null);
                    });

                    it('should call the right methods with the correct parameters', function() {
                        spyOn($scope, 'buildInfoEvent');

                        $scope.getMaxDurationForEventThenCompute('email@gmail.com', {id: 1}, 'destination');

                        expect($scope.getMaxDurationForEvent).toHaveBeenCalled();
                        expect($scope.buildInfoEvent).not.toHaveBeenCalled();
                    });
                });

                describe('preferred mean of transport == max', function() {

                    beforeEach(function() {
                        $scope.preferedMeanOfTransport = 'max';
                    });

                    describe('no duration data are present for the specified event', function() {

                       it('should return from the function immediately', function() {
                           spyOn($scope, 'getMaxDurationForEvent');
                           $scope.maxDistanceTmp = {'email@gmail.com': {}};

                           $scope.getMaxDurationForEventThenCompute('email@gmail.com', {id: 1}, 'destination');

                           expect($scope.getMaxDurationForEvent).not.toHaveBeenCalled();
                       })

                    });

                    describe('all the durations have not yet been all collected', function() {

                        it('should return from the function immediately', function() {
                            spyOn($scope, 'getMaxDurationForEvent');
                            $scope.maxDistanceTmp = {'email@gmail.com': {1: [{duration: 1200}]}};

                            $scope.getMaxDurationForEventThenCompute('email@gmail.com', {id: 1}, 'destination');

                            expect($scope.getMaxDurationForEvent).not.toHaveBeenCalled();
                        })

                    });

                });
            });

            describe('getMaxDurationForEvent', function() {
                it('should return the max duration for the specified event', function() {

                    $scope.maxDistanceTmp = {'email@gmail.com': {1: [{duration: 1200}, {duration: 2400}]}};

                    // 2400 + (0.25 * 2400) because we are manually adding 25% of the duration on top of the actual duration
                    // This is to have some margin in case of bad traffic for example etc...
                    expect($scope.getMaxDurationForEvent('email@gmail.com', 1)).toEqual(Math.ceil(2400 + (0.25 * 2400)));
                });
            });


            describe('addCurrentDurationToMaxTmp', function() {

                describe('no duration yet for the event', function() {

                    it('should create the duration array for the event', function() {
                        $scope.maxDistanceTmp = {'email@gmail.com': {}};

                        $scope.addCurrentDurationToMaxTmp('email@gmail.com', 1, 1200);

                        expect($scope.maxDistanceTmp).toEqual({'email@gmail.com': {1: [{duration: 1200}]}});
                    })
                });

                describe('a duration is already present for the event', function() {

                    it('should update the duration array for the event', function() {
                        $scope.maxDistanceTmp = {'email@gmail.com': {1: [{duration: 1200}]}};

                        $scope.addCurrentDurationToMaxTmp('email@gmail.com', 1, 2400);

                        expect($scope.maxDistanceTmp).toEqual({'email@gmail.com': {1: [{duration: 1200}, {duration: 2400}]}});
                    })
                });
            });

            describe('buildInfoEvent', function() {
                var event;

                describe('the event upper edge is busy', function() {
                    beforeEach(function() {
                        event = {upperEdgeBusy: true};
                    });

                    describe('the lowerEdgeMaxTravelTimeDisplay is lower than the real travel time', function() {

                        it('should call the correct method with the right parameters', function() {
                            spyOn($scope, 'createInfoEvent');

                            event.start = {dateTime: '2016-02-01T13:00:000+0200'};
                            event.lowerEdgeMaxTimeDisplay = 10;

                            $scope.buildInfoEvent('email@gmail.com', 'travelTime', event, 40, 'destination');

                            expect($scope.createInfoEvent).toHaveBeenCalledWith('email@gmail.com', 'travelTime', 'before', '2016-02-01T13:00:000+0200', 40, 10, 'destination');
                        });

                    });

                    describe('the lowerEdgeMaxTravelTimeDisplay is higher than the real travel time', function() {

                        it('should call the correct method with the right parameters', function() {
                            spyOn($scope, 'createInfoEvent');

                            event.start = {dateTime: '2016-02-01T13:00:000+0200'};
                            event.lowerEdgeMaxTimeDisplay = 120;

                            $scope.buildInfoEvent('email@gmail.com', 'travelTime', event, 40, 'destination');

                            expect($scope.createInfoEvent).toHaveBeenCalledWith('email@gmail.com', 'travelTime', 'before', '2016-02-01T13:00:000+0200', 40, 40, 'destination');
                        });

                    });
                });

                describe('the event lower edge is busy', function() {
                    beforeEach(function() {
                        event = {lowerEdgeBusy: true};
                    });

                    describe('the lowerEdgeMaxTravelTimeDisplay is lower than the real travel time', function() {

                        it('should call the correct method with the right parameters', function() {
                            spyOn($scope, 'createInfoEvent');

                            event.end = {dateTime: '2016-02-01T13:00:000+0200'};
                            event.upperEdgeMaxTimeDisplay = 10;

                            $scope.buildInfoEvent('email@gmail.com', 'travelTime', event, 40, 'destination');

                            expect($scope.createInfoEvent).toHaveBeenCalledWith('email@gmail.com', 'travelTime', 'after', '2016-02-01T13:00:000+0200', 40, 10, 'destination');
                        });

                    });

                    describe('the lowerEdgeMaxTravelTimeDisplay is higher than the real travel time', function() {

                        it('should call the correct method with the right parameters', function() {
                            spyOn($scope, 'createInfoEvent');

                            event.end = {dateTime: '2016-02-01T13:00:000+0200'};
                            event.upperEdgeMaxTimeDisplay = 120;

                            $scope.buildInfoEvent('email@gmail.com', 'travelTime', event, 40, 'destination');

                            expect($scope.createInfoEvent).toHaveBeenCalledWith('email@gmail.com', 'travelTime', 'after', '2016-02-01T13:00:000+0200', 40, 40, 'destination');
                        });

                    });
                });
            });

            describe('createInfoEvent', function() {
                beforeEach(function(){
                    $scope.originCoordinates = {
                        lat: function(){return 10;},
                        lng: function(){return 20;}
                    };

                    $scope.travelTimeEvents['email@gmail.com'] = [];
                    $scope.defaultDelayEvents['email@gmail.com'] = [];
                });

                describe('creating an appointment default delay event before the current event', function() {

                    describe('the real travel time is bigger than the displayed one', function() {

                        it('should push to the travelTimeEvents scope variable the right created travelTimeEvent', function() {

                            $scope.createInfoEvent('email@gmail.com', 'defaultDelay', 'before', '2016-02-01T13:00:000+0200', 30, 20, '1 rue du test 74432 Test');

                            var lastDefaultDelayEvent = $scope.defaultDelayEvents['email@gmail.com'][0];

                            expect(lastDefaultDelayEvent.isDefaultDelay).toBe(true);
                            expect(lastDefaultDelayEvent.travelTime).toEqual(30);
                            expect(lastDefaultDelayEvent.travelTimeGoogleDestinationUrl).toEqual(undefined);
                            expect(lastDefaultDelayEvent.originalStart.dateTime.format()).toEqual(moment('2016-02-01T12:30:000+0200').format());
                            expect(lastDefaultDelayEvent.originalEnd.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastDefaultDelayEvent.start.dateTime.format()).toEqual(moment('2016-02-01T12:40:000+0200').format());
                            expect(lastDefaultDelayEvent.end.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastDefaultDelayEvent.eventInfoType).toEqual('before');
                            expect(lastDefaultDelayEvent.location).toEqual('1 rue du test 74432 Test');
                            expect(lastDefaultDelayEvent.isWarning).toBe(true);
                        });
                    });


                });

                describe('creating a travelTimeEvent before the current event', function() {

                    describe('the real travel time is bigger than the displayed one', function() {

                        it('should push to the travelTimeEvents scope variable the right created travelTimeEvent', function() {

                            $scope.createInfoEvent('email@gmail.com', 'travelTime', 'before', '2016-02-01T13:00:000+0200', 30, 20, '1 rue du test 74432 Test');

                            var lastTravelTimeEvent = $scope.travelTimeEvents['email@gmail.com'][0];

                            expect(lastTravelTimeEvent.isTravelTime).toBe(true);
                            expect(lastTravelTimeEvent.travelTime).toEqual(30);
                            expect(lastTravelTimeEvent.travelTimeGoogleDestinationUrl).toEqual('https://www.google.com/maps/dir/10,20/1%20rue%20du%20test%2074432%20Test');
                            expect(lastTravelTimeEvent.originalStart.dateTime.format()).toEqual(moment('2016-02-01T12:30:000+0200').format());
                            expect(lastTravelTimeEvent.originalEnd.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.start.dateTime.format()).toEqual(moment('2016-02-01T12:40:000+0200').format());
                            expect(lastTravelTimeEvent.end.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.eventInfoType).toEqual('before');
                            expect(lastTravelTimeEvent.location).toEqual('1 rue du test 74432 Test');
                            expect(lastTravelTimeEvent.isWarning).toBe(true);
                        });
                    });

                    describe('the real travel time is the same as the displayed one', function() {

                        it('should push to the travelTimeEvents scope variable the right created travelTimeEvent', function() {

                            $scope.createInfoEvent('email@gmail.com', 'travelTime', 'before', '2016-02-01T13:00:000+0200', 30, 30, '1 rue du test 74432 Test');

                            var lastTravelTimeEvent = $scope.travelTimeEvents['email@gmail.com'][0];

                            expect(lastTravelTimeEvent.isTravelTime).toBe(true);
                            expect(lastTravelTimeEvent.travelTime).toEqual(30);
                            expect(lastTravelTimeEvent.travelTimeGoogleDestinationUrl).toEqual('https://www.google.com/maps/dir/10,20/1%20rue%20du%20test%2074432%20Test');
                            expect(lastTravelTimeEvent.originalStart.dateTime.format()).toEqual(moment('2016-02-01T12:30:000+0200').format());
                            expect(lastTravelTimeEvent.originalEnd.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.start.dateTime.format()).toEqual(moment('2016-02-01T12:30:000+0200').format());
                            expect(lastTravelTimeEvent.end.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.eventInfoType).toEqual('before');
                            expect(lastTravelTimeEvent.location).toEqual('1 rue du test 74432 Test');
                            expect(lastTravelTimeEvent.isWarning).toBe(false);
                        });
                    });

                });

                describe('creating an appointment default delay event after the current event', function() {

                    describe('the real travel time is bigger than the displayed one', function() {

                        it('should push to the travelTimeEvents scope variable the right created travelTimeEvent', function() {

                            $scope.createInfoEvent('email@gmail.com', 'defaultDelay', 'after', '2016-02-01T13:00:000+0200', 30, 20, '1 rue du test 74432 Test');

                            var lastDefaultDelayEvent = $scope.defaultDelayEvents['email@gmail.com'][0];

                            expect(lastDefaultDelayEvent.isDefaultDelay).toBe(true);
                            expect(lastDefaultDelayEvent.travelTime).toEqual(30);
                            expect(lastDefaultDelayEvent.travelTimeGoogleDestinationUrl).toEqual(undefined);
                            expect(lastDefaultDelayEvent.originalStart.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastDefaultDelayEvent.originalEnd.dateTime.format()).toEqual(moment('2016-02-01T13:30:000+0200').format());
                            expect(lastDefaultDelayEvent.start.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastDefaultDelayEvent.end.dateTime.format()).toEqual(moment('2016-02-01T13:20:000+0200').format());
                            expect(lastDefaultDelayEvent.eventInfoType).toEqual('after');
                            expect(lastDefaultDelayEvent.location).toEqual('1 rue du test 74432 Test');
                            expect(lastDefaultDelayEvent.isWarning).toBe(true);
                        });
                    });


                });

                describe('creating a travelTimeEvent after the current event', function() {

                    describe('the real travel time is bigger than the displayed one', function() {

                        it('should push to the travelTimeEvents scope variable the right created travelTimeEvent', function() {

                            $scope.createInfoEvent('email@gmail.com', 'travelTime', 'after', '2016-02-01T13:00:000+0200', 30, 20, '1 rue du test 74432 Test');

                            var lastTravelTimeEvent = $scope.travelTimeEvents['email@gmail.com'][0];

                            expect(lastTravelTimeEvent.isTravelTime).toBe(true);
                            expect(lastTravelTimeEvent.travelTime).toEqual(30);
                            expect(lastTravelTimeEvent.travelTimeGoogleDestinationUrl).toEqual('https://www.google.com/maps/dir/10,20/1%20rue%20du%20test%2074432%20Test');
                            expect(lastTravelTimeEvent.originalStart.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.originalEnd.dateTime.format()).toEqual(moment('2016-02-01T13:30:000+0200').format());
                            expect(lastTravelTimeEvent.start.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.end.dateTime.format()).toEqual(moment('2016-02-01T13:20:000+0200').format());
                            expect(lastTravelTimeEvent.eventInfoType).toEqual('after');
                            expect(lastTravelTimeEvent.location).toEqual('1 rue du test 74432 Test');
                            expect(lastTravelTimeEvent.isWarning).toBe(true);
                        });
                    });

                    describe('the real travel time is the same as the displayed one', function() {

                        it('should push to the travelTimeEvents scope variable the right created travelTimeEvent', function() {

                            $scope.createInfoEvent('email@gmail.com', 'travelTime', 'after', '2016-02-01T13:00:000+0200', 30, 30, '1 rue du test 74432 Test');

                            var lastTravelTimeEvent = $scope.travelTimeEvents['email@gmail.com'][0];

                            expect(lastTravelTimeEvent.isTravelTime).toBe(true);
                            expect(lastTravelTimeEvent.travelTime).toEqual(30);
                            expect(lastTravelTimeEvent.travelTimeGoogleDestinationUrl).toEqual('https://www.google.com/maps/dir/10,20/1%20rue%20du%20test%2074432%20Test');
                            expect(lastTravelTimeEvent.originalStart.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.originalEnd.dateTime.format()).toEqual(moment('2016-02-01T13:30:000+0200').format());
                            expect(lastTravelTimeEvent.start.dateTime.format()).toEqual(moment('2016-02-01T13:00:000+0200').format());
                            expect(lastTravelTimeEvent.end.dateTime.format()).toEqual(moment('2016-02-01T13:30:000+0200').format());
                            expect(lastTravelTimeEvent.eventInfoType).toEqual('after');
                            expect(lastTravelTimeEvent.location).toEqual('1 rue du test 74432 Test');
                            expect(lastTravelTimeEvent.isWarning).toBe(false);
                        });
                    });
                });
            });

            describe('addTravelTimeEventsToCalendar', function() {

                it('should call the right method with the right parameters', function() {
                    window.currentCalendar = {
                        addCal: function(events) {}
                    };
                    $scope.travelTimeEvents = {'email@gmail.com': [{id: 1}, {id: 2}]};

                    spyOn(window.currentCalendar, 'addCal');

                    $scope.addTravelTimeEventsToCalendar('email@gmail.com');

                    expect(window.currentCalendar.addCal).toHaveBeenCalledWith([{id: 1}, {id: 2}]);
                });


            });

            describe('addDefaultDelayEventsToCalendar', function() {

                it('should call the right method with the right parameters', function() {
                    window.currentCalendar = {
                        addCal: function(events) {}
                    };
                    $scope.defaultDelayEvents = {'email@gmail.com': [{id: 1}, {id: 2}]};

                    spyOn(window.currentCalendar, 'addCal');

                    $scope.addDefaultDelayEventsToCalendar('email@gmail.com');

                    expect(window.currentCalendar.addCal).toHaveBeenCalledWith([{id: 1}, {id: 2}]);
                });
            });

            describe('computeDefaultAppointmentDelay', function() {

                it('should call the right method with the right parameters', function() {

                    $scope.events = {
                        'email@gmail.com': [
                            //{id: 1, location: '', start: {dateTime: "2016-05-05"}, end: {dateTime: "2016-05-06"}},
                            {id: 2, location: '100 rue de la rue', start: {dateTime: "2016-05-05T13:00:00.000+02:00"}, end: {dateTime: "2016-05-05T15:00:00.000+02:00"}},
                            {id: 3, location: "10 avenue de l'avenue", start: {dateTime: "2016-05-05T15:00:00.000+02:00"}, end: {dateTime: "2016-05-05T16:00:00.000+02:00"}},
                            {id: 4, location: '9 boulevard du boulevard', start: {dateTime: "2016-05-06T15:00:00.000+02:00"}, end: {dateTime: "2016-05-06T17:00:00.000+02:00"}},
                            {id: 5, location: '2 sentier du sentier', start: {dateTime: "2016-05-06T17:00:00.000+02:00"}, end: {dateTime: "2016-05-06T19:00:00.000+02:00"}},
                            {id: 6, location: '1 impasse de impasse', start: {dateTime: "2016-05-06T19:00:00.000+02:00"}, end: {dateTime: "2016-05-07T15:00:00.000+02:00"}}
                        ]};

                    $scope.travelTimeEvents['email@email.com'] = [];
                    window.threadAccount.delay_between_appointments = 10;

                    spyOn($scope, 'buildInfoEvent');
                    spyOn($scope, 'detectAvailableEdges');
                    spyOn($scope, 'addDefaultDelayEventsToCalendar');

                    $scope.computeDefaultAppointmentDelay('email@gmail.com');

                    expect($scope.detectAvailableEdges).toHaveBeenCalled();
                    expect($scope.buildInfoEvent).toHaveBeenCalled();
                    expect($scope.addDefaultDelayEventsToCalendar).toHaveBeenCalledWith('email@gmail.com');

                });
            });
        });


    });

})();