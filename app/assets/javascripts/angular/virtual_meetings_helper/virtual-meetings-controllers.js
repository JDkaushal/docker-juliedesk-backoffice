(function(){

    var app = angular.module('virtual-meetings-helper-controllers', ['templates']);

    app.directive('virtualMeetingsHelper', function(){
        return{
            restrict: 'E',
            templateUrl: 'virtual-meetings-helper.html',
            controller: ['$scope' , function($scope){
                var virtualMeetingsHelperCtrl = this;
                var attendeesManagerCtrl = angular.element($('#attendeesCtrl')).scope();
                virtualMeetingsHelperCtrl.currentAppointment = _.find(window.threadAccount.appointments, function(a){ return a.kind == (window.threadComputedData.appointment_nature || $('#appointment_nature option:selected').val()) });
                virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash;
                virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentAppointment.behaviour;

                var suffixClient = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? ' (défaut)' : '';
                var suffixLater = virtualMeetingsHelperCtrl.currentBehaviour == 'later' ? ' (défaut)' : '';
                var suffixInterlocutor = virtualMeetingsHelperCtrl.currentBehaviour == 'ask_interlocutor' ? ' (défaut)' : '';

                $scope.callTargets =
                [
                    {name:"L'interlocuteur" + suffixInterlocutor, value:'interlocutor'},
                    {name:"Décidé plus tard" + suffixLater, value:'later'},
                    {name:"Le client (" + window.threadAccount.full_name + ')' + suffixClient, value:'client'}
                ];

                var suffixMobile = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Mobile' ? ' (défaut)' : '';
                var suffixLandline = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Landline' ? ' (défaut)' : '';
                var suffixSkype = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Skype' ? ' (défaut)' : '';
                var suffixConfcall = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Confcall' ? ' (défaut)' : '';

                $scope.callSupports = [
                    {name:"Téléphone portable" + suffixMobile, value:'mobile'},
                    {name:"Téléphone fixe" + suffixLandline, value:'landline'},
                    {name:"Skype" + suffixSkype, value:'skype'},
                    {name:"Confcall" + suffixConfcall, value:'confcall'}
                ];

                var initialConfTarget;
                switch(virtualMeetingsHelperCtrl.currentBehaviour){
                    case 'propose':
                        initialConfTarget = 'client';
                        break;
                    case 'ask_interlocutor':
                        initialConfTarget = 'interlocutor';
                        break;
                    case 'later':
                        initialConfTarget = 'later';
                        break;
                    default:
                        initialConfTarget = 'later';
                }

                var initialConfSupport;

                switch(virtualMeetingsHelperCtrl.currentVAConfig.label){
                    case 'Mobile':
                        initialConfSupport = 'mobile';
                        break;
                    case 'Landline':
                        initialConfSupport = 'landline';
                        break;
                    case 'Skype':
                        initialConfSupport = 'skype';
                        break;
                    case 'Confcall':
                        initialConfSupport = 'confcall';
                        break;
                    default:
                        initialConfSupport = '';
                }

                $scope.computeCallDetails = function(){
                    var details = '';
                    if($scope.currentConf.target != 'later'){
                        var attendees = attendeesManagerCtrl.attendees_manager.attendees.slice();
                        var attendee;

                        if($scope.currentConf.target == 'client'){
                            attendee = _.find(attendees, function (a) {
                                return a.email == window.threadAccount.email;
                            })
                        }

                        if ($scope.currentConf.target == 'interlocutor'){
                            attendee = _.find(attendees, function (a) {
                                return a.email == $scope.currentConf.targetName;
                            })
                        }

                        if(attendee != undefined)
                        {
                            switch($scope.currentConf.support) {
                                case 'mobile':
                                    details = attendee.mobile;
                                    break;
                                case 'landline':
                                    details = attendee.landline;
                                    break;
                                case 'skype':
                                    details = attendee.skypeId;
                                    break;
                                case 'confcall':
                                    details = attendee.confCallInstructions;
                                    break;
                            }
                        }
                    }

                    $scope.currentConf.details = details;
                };

                $scope.setEventNotes = function(){
                    var message = '';
                    var threadOwner =_.find(attendeesManagerCtrl.attendees_manager.attendees.slice(), function (a) {
                        return a.email == window.threadAccount.email;
                    });

                    if(virtualMeetingsHelperCtrl.currentVAConfig.mobile_in_note)
                        message += 'Portable ' + threadOwner.firstName + ' : ' + threadOwner.mobile + "\n";
                    if(virtualMeetingsHelperCtrl.currentVAConfig.landline_in_note)
                        message += 'Fixe ' + threadOwner.firstName + ' : ' + threadOwner.landline + "\n";
                    if(virtualMeetingsHelperCtrl.currentVAConfig.skype_in_note)
                        message += 'SkypeId ' + threadOwner.firstName + ' : ' + threadOwner.skypeId + "\n";
                    if(virtualMeetingsHelperCtrl.currentVAConfig.confcall_in_note)
                        message += 'Confcall ' + threadOwner.firstName + ' : ' + threadOwner.confCallInstructions + "\n";

                    $("textarea#notes").val(message);
                };

                $scope.targetChanged = function($event){
                  console.log($scope.currentConf);
                    if($scope.currentConf.target == 'later')
                        $scope.currentConf.targetName = '';


                };

                setTimeout(function(){
                    var attendeesWithoutThreadOwner = _.filter(attendeesManagerCtrl.attendees_manager.attendees.slice(), function (a) {
                        return a.email != window.threadAccount.email;
                    });

                    $scope.callTargetsNames = _.map(attendeesWithoutThreadOwner, function (a) {
                        var _lastName = a.lastName == null ? '' : ' ' + a.lastName;
                        var name = a.firstName + _lastName;
                        return {value: a.email, name: name + ' (' + a.email + ')'};
                    });

                    var initialTargetName = attendeesWithoutThreadOwner.length == 1 ? attendeesWithoutThreadOwner[0] : '';
                    $scope.currentConf = {target: initialConfTarget, targetName: initialTargetName, support: initialConfSupport, details: ''};
                    $scope.$apply();

                    $scope.computeCallDetails();
                    $scope.setEventNotes();
                }, 3000);
            }],
            controllerAs: 'virtualMeetingsHelperCtrl'
        }
    });
})();