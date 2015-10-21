(function(){

    var app = angular.module('virtual-meetings-helper-controllers', ['templates']);

    app.directive('virtualMeetingsHelper', function(){
        return{
            restrict: 'E',
            templateUrl: 'virtual-meetings-helper.html',
            controller: ['$scope' , function($scope){
                var virtualMeetingsHelperCtrl = this;
                virtualMeetingsHelperCtrl.currentAppointment = _.find(window.threadAccount.appointments, function(a){ return a.kind == window.threadComputedData.appointment_nature });
                virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash;
                virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentAppointment.behaviour;

                $scope.callTargets =
                [
                    {name:"L'interlocuteur", value:'interlocutor'},
                    {name:"Décidé plus tard", value:'later'},
                    {name:"Le client", value:'client'}
                ];

                $scope.callTargetsNames = ["Nicolas Anelka", "Other", "Other 1"];

                $scope.callSupports = [
                    {name:"Téléphone portable", value:'portable'},
                    {name:"Téléphone fixe", value:'landline'},
                    {name:"Skype", value:'skype'}
                ];

                var currentConfTarget;
                console.log(virtualMeetingsHelperCtrl.currentBehaviour);
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
                console.log(currentConfTarget);
                $scope.currentConf = {target: currentConfTarget, targetName: "Other", support: 'portable', details: ''};

                console.log(virtualMeetingsHelperCtrl.currentVAConfig);
            }],
            controllerAs: 'virtualMeetingsHelperCtrl'
        }
    });
})();