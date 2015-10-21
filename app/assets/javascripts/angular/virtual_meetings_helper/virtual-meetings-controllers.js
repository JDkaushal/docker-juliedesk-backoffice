(function(){

    var app = angular.module('virtual-meetings-helper-controllers', ['templates']);

    app.directive('virtualMeetingsHelper', function(){
        return{
            restrict: 'E',
            templateUrl: 'virtual-meetings-helper.html',
            controller: ['$scope' , function($scope){
                var virtualMeetingsHelperCtrl = this;
                var attendeesManagerCtrl = angular.element($('#attendeesCtrl')).scope();
                virtualMeetingsHelperCtrl.currentAppointment = _.find(window.threadAccount.appointments, function(a){ return a.kind == window.threadComputedData.appointment_nature });
                virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash;
                virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentAppointment.behaviour;

                var suffixClient = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? ' (défaut)' : '';
                var suffixLater = virtualMeetingsHelperCtrl.currentBehaviour == 'later' ? ' (défaut)' : '';
                var suffixInterlocutor = virtualMeetingsHelperCtrl.currentBehaviour == 'ask_interlocutor' ? ' (défaut)' : '';

                $scope.callTargets =
                [
                    {name:"L'interlocuteur" + suffixInterlocutor, value:'interlocutor'},
                    {name:"Décidé plus tard" + suffixLater, value:'later'},
                    {name:"Le client" + suffixClient, value:'client'}
                ];

                setTimeout(function(){
                    $scope.callTargetsNames = _.map(_.filter(attendeesManagerCtrl.attendees_manager.attendees.slice(), function (a) {
                        return a.email != window.threadAccount.email;
                    }), function (a) {
                        return {value: a.email, name: a.name + ' (' + a.email + ')'};
                    });

                    $scope.computeCallDetails();
                }, 1000);

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

                var currentConfTarget;
                switch(virtualMeetingsHelperCtrl.currentBehaviour){
                    case 'propose':
                        currentConfTarget = 'client';
                        break;
                    case 'ask_interlocutor':
                        currentConfTarget = 'interlocutor';
                        break;
                    case 'later':
                        currentConfTarget = 'later';
                        break;
                    default:
                        currentConfTarget = 'later';
                }

                var currentConfSupport;

                switch(virtualMeetingsHelperCtrl.currentVAConfig.label){
                    case 'Mobile':
                        currentConfSupport = 'mobile';
                        break;
                    case 'Landline':
                        currentConfSupport = 'landline';
                        break;
                    case 'Skype':
                        currentConfSupport = 'skype';
                        break;
                    case 'Confcall':
                        currentConfSupport = 'confcall';
                        break;
                    default:
                        currentConfSupport = '';
                }

                $scope.currentConf = {target: currentConfTarget, targetName: "Other", support: currentConfSupport, details: ''};
                $scope.computeCallDetails = function(){
                    var details = '';
                    if(currentConfTarget != 'later'){
                        var attendees = attendeesManagerCtrl.attendees_manager.attendees.slice();
                        var attendee;

                        if(currentConfTarget == 'client'){
                            attendee = _.find(attendees, function (a) {
                                return a.email == window.threadAccount.email;
                            })
                        }

                        if (currentConfTarget == 'interlocutor'){
                            attendee = _.find(attendees, function (a) {
                                return a.email == $scope.currentConf.targetName;
                            })
                        }

                        switch(currentConfSupport) {
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

                    console.log(attendee);
                    console.log(details);
                    $scope.currentConf.details = details;
                };

            }],
            controllerAs: 'virtualMeetingsHelperCtrl'
        }
    });
})();