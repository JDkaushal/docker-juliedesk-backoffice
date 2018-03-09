(function(){

    var app = angular.module('virtual-meetings-helper-controllers', ['templates']);

    app.directive('virtualMeetingsHelper', function(){
        return{
            restrict: 'E',
            templateUrl: 'virtual-meetings-helper.html',
            controller: ['$scope', '$element' , function($scope, $element){
                var virtualMeetingsHelperCtrl = this;
                var threadOwnerInfosReFr = new RegExp("-" + localize('events.call_instructions.organizer_infos', {locale: 'fr'})+ "-----------------.+?(?:----------------------------------------)");
                var threadOwnerInfosReEn = new RegExp("-" + localize('events.call_instructions.organizer_infos', {locale: 'en'})+ "-----------------.+?(?:----------------------------------------)");
                var callingInstructionsInfosReFr = new RegExp("-" + localize('events.call_instructions.title', {locale: 'fr'}) + "----------------.+?(?:----------------------------------------)");
                var callingInstructionsInfosReEn = new RegExp("-" + localize('events.call_instructions.title', {locale: 'en'}) + "----------------.+?(?:----------------------------------------)");

                // We use the || affectation here for testing purposes (injecting the scope manually at creation)
                $scope.attendeesManagerCtrl = $scope.attendeesManagerCtrl || angular.element($('#attendeesCtrl')).scope();
                $scope.datesVerificationManagerCtrl = $scope.datesVerificationManagerCtrl || angular.element($('#datesVerificationsManager')).scope();
                $scope.formEditMode = Boolean(window.threadDataIsEditable);
                $scope.currentConf = {};
                $scope.showHeader = true;
                $scope.displayForm = true;
                $scope.forceCurrentConfig = false;
                $scope.lastTargetInfos = '';
                $scope.detailsFrozenBecauseClient = false;
                $scope.forcedDetailsFrozen = false;
                $scope.configLoaded = false;
                $scope.cachedInterlocutor = undefined;
                $scope.cachedCurrentConf = {};

                // Used to synchronize the forms when there are multiple one on the page (i.e. when an event is present)
                $scope.otherForm = undefined;

                $scope.selectedVirtualResource = undefined;

                if(window.threadComputedData && window.threadComputedData.virtual_resource_used) {
                    $scope.selectedVirtualResource = window.threadComputedData.virtual_resource_used;
                }

                $scope.utilitiesHelper = $('#events_availabilities_methods').scope();

                if($scope.datesVerificationManagerCtrl) {
                    $scope.datesVerificationManagerCtrl.$on('datesVerifNewSelectedDate', function(event, args) {
                        $scope.determineFirstAvailableVirtualResource(args);
                    });
                }

                $('.event-tile-panel').on('change', 'input.event-dates', function(e) {
                    var currentVAConfig = $scope.getCurrentVAConfig();
                    if(currentVAConfig && currentVAConfig.virtual_resources) {
                        $scope.determineFirstAvailableVirtualResource();
                    }
                });

                $scope.isCurrentAppointmentVirtual = function() {
                    return window.getCurrentAppointment() && window.getCurrentAppointment().appointment_kind_hash.is_virtual;
                };

                $scope.isCurrentSupportUsingVirtualResources = function() {
                    return $scope.currentConf
                };

                $scope.setAttendeesManagerCtrl = function(scope){
                    $scope.attendeesManagerCtrl = scope;
                };

                $scope.$watch('currentConf.target', function(newVal, oldVal){
                    $scope.attendeesManagerCtrl.lookupAttendeesMissingInfos();
                    if(!$scope.attendeesManagerCtrl.$$phase){
                        $scope.attendeesManagerCtrl.$apply();
                    }
                }, true);

                $scope.$watch('currentConf.targetInfos', function(newVal, oldVal){
                    if(!!newVal){
                        var newValEmpty = $.isEmptyObject(newVal);

                        $scope.forcedDetailsFrozen = newValEmpty;
                        $scope.lastTargetInfos = newVal;
                        $scope.cacheCurrentInterlocutor();

                        //if($scope.currentConf.target == 'interlocutor' && !newValEmpty)
                        //    $scope.setDefaultSupportManually(findTargetAttendee(newVal));
                    }
                    $scope.computeCallDetails(true);
                }, true);

                $scope.$watch('currentConf.details', function(newVal, oldVal){
                    updateNotesCallingInfos();
                });

                $scope.$watch('currentConf.support', function(newVal, oldVal){
                    if($scope.currentConf.target == 'client')
                        $scope.changeCurrentVAConfig(newVal);
                });

                $scope.$watch('selectedVirtualResource', function(newVal,_) {
                    if($scope.otherForm){
                        $scope.otherForm.selectedVirtualResource = newVal;
                    }
                });

                $scope.$watch('currentConf', function(newVal, oldVal){
                    if($scope.otherForm){
                        $scope.otherForm.currentConf = newVal;
                        $scope.updateTargetInfosSelect();
                        if(!$scope.otherForm.$$phase){
                            $scope.otherForm.$apply();
                        }
                    }
                }, true);

                $scope.$watch('virtualMeetingsHelperCtrl.currentVAConfig', function(newVal, oldVal){
                    if($scope.otherForm){
                        $scope.otherForm.setVAConfig(newVal);
                        if(!$scope.otherForm.$$phase){
                            $scope.otherForm.$apply();
                        }
                        updateNotesCallingInfos();
                    }
                }, true);

                $scope.targetInfosChanged = function(){
                    $scope.setDefaultSupportManually(findTargetAttendee($scope.currentConf.targetInfos));
                };

                $scope.computeOptionText = function(args){
                    var text = '';

                    if(args != null)
                        text = args.name + ' (' + args.email + ')';

                    return text;
                };

                $scope.setEditMode = function(editMode){
                    $scope.formEditMode = editMode;
                };

                $scope.setVAConfig = function(vaConfig){
                    virtualMeetingsHelperCtrl.currentVAConfig = vaConfig;
                };

                $scope.attendeesManagerCtrl.$on('attendeesRefreshed', function(event, args) {
                    $scope.refresh(args.attendees.slice());
                });

                $scope.refresh = function(attendees) {

                    if(attendees){
                        var presentAttendees = _.filter(attendees, function (a) {
                            return a.isPresent;
                        });

                        var attendeesWithoutThreadOwner = _.filter(presentAttendees, function (a) {
                            return $scope.attendeesManagerCtrl.getThreadOwnerEmails().indexOf(a.email) == -1;
                        });

                        if(attendeesWithoutThreadOwner.length > 0){

                            $scope.callTargetsInfos = _.map(attendeesWithoutThreadOwner, function (a) {
                                return {email: a.email, name: a.displayNormalizedName(), guid: a.guid, displayName: $scope.computeOptionText({name: a.displayNormalizedName(), email: a.email})};
                            });

                            $scope.updateSelectedCallTargetInfos();

                            $scope.computeCallDetails();

                        }else{
                            $scope.callTargetsInfos = [];
                            if($scope.currentConf.target != 'client')
                                Object.assign($scope.currentConf, {targetInfos: {}, support: '', details: ''});
                        }
                    }

                    if ((checkIfThreadDataOk() && !$scope.formEditMode) || $scope.forceCurrentConfig || ( checkIfThreadDataOk() && !$.isEmptyObject(window.threadComputedData.call_instructions) && $scope.formEditMode)){
                        $scope.loadCurrentConfig();
                    }else if($.isEmptyObject(window.threadComputedData.call_instructions) && $scope.formEditMode && !!$('#appointment_nature').val() && $.isEmptyObject($scope.currentConf)) {
                        $scope.loadDefaultConfig(true);
                        updateNotesCallingInfos();
                    }

                    //if($scope.lastTargetInfos != null)
                    //{
                    //    var attendee = findTargetAttendee($scope.currentConf);
                    //
                    //    if(attendee){
                    //        setAttendeeSelected(attendee);
                    //    }
                    //}

                    // We only set the default support when there are 2 attendees (Thread owner and another attendee)
                    // We don't set the support when the thread is not in edit mode (to prevent overriding the current value
                    // We set automatically the support only when it is the first time filling the form
                    if(window.threadDataIsEditable && window.formFirstPass && $scope.currentConf.target == 'interlocutor' && presentAttendees && presentAttendees.length == 2 )
                        $scope.setDefaultSupportManually(findTargetAttendee($scope.currentConf.targetInfos));

                };

                $scope.changeCurrentVAConfig = function(configLabel){
                    var everyConfig = _.compact(window.threadAccount.virtual_appointments_support_config.concat(window.threadAccount.virtual_appointments_company_support_config));

                    var config = _.filter(everyConfig, function(vaConfig){
                        var testAgainst = "";

                        if(vaConfig.label) {
                            testAgainst = vaConfig.label;
                        } else {
                            testAgainst = 'resource_' + vaConfig.resource_type;
                        }


                        return testAgainst.toLowerCase().replace(/ /g, "_") == configLabel;
                    })[0];

                    if(config == undefined || config == null){
                        config = _.filter(everyConfig, function(vaConfig){
                            return (vaConfig.label || vaConfig.resource_type).toLowerCase() == 'vide';
                        })[0];
                    }
                    virtualMeetingsHelperCtrl.currentVAConfig = config;

                    updateNotesCallingInfos();
                };

                $scope.getCallTargets = function() {
                    var suffixClient = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? ' (défaut)' : '';
                    var suffixLater = virtualMeetingsHelperCtrl.currentBehaviour == 'later' ? ' (défaut)' : '';
                    var suffixInterlocutor = virtualMeetingsHelperCtrl.currentBehaviour == 'ask_interlocutor' ? ' (défaut)' : '';

                    var targets = [
                        {name:"L'interlocuteur" + suffixInterlocutor, value:'interlocutor'},
                        {name:"Décidé plus tard" + suffixLater, value:'later'},
                        {name:"Le client (" + window.threadAccount.full_name + ')' + suffixClient, value:'client'},
                        {name:"Custom", value:'custom'}
                    ];

                    return targets;
                };

                $scope.getSupports = function(){
                    var suffixMobile = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Mobile' ? ' (défaut)' : '';
                    var suffixLandline = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Landline' ? ' (défaut)' : '';
                    var suffixSkype = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Skype' ? ' (défaut)' : '';
                    var suffixConfcall = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Confcall' ? ' (défaut)' : '';
                    var suffixSfB = virtualMeetingsHelperCtrl.currentVAConfig.label == 'SKype for Business' ? ' (défaut)' : '';

                    var currentAccount = window.threadAccount;

                    var supports = [
                        {name:"Téléphone portable" + suffixMobile, value:'mobile'},
                        {name:"Téléphone fixe" + suffixLandline, value:'landline'},
                        //{name:"Skype" + suffixSkype, value:'skype'},
                        {name:"Confcall" + suffixConfcall, value:'confcall'},
                        {name:"Skype for Business" + suffixSfB, value:'skype_for_business'}
                    ];

                    if($scope.currentConf.target == 'client') {
                        supports.push({name: 'Video Conference', value: 'video_conference'});

                        if(currentAccount && currentAccount.virtual_appointments_company_support_config && currentAccount.virtual_appointments_company_support_config.length > 0) {
                            _.each(currentAccount.virtual_appointments_company_support_config, function(companyConfig) {
                                var currentText = companyConfig.resource_type;
                                currentText = currentText.charAt(0).toUpperCase() + currentText.substr(1).toLowerCase();

                                supports.push({name: 'Ressource ' + currentText, value: 'resource_' + companyConfig.resource_type});
                            });
                        }
                    }

                    return supports;
                };

                $scope.loadCurrentConfig = function(){

                    if(window.threadComputedData.call_instructions && window.threadComputedData.call_instructions.target == 'interlocutor')
                        $scope.changeCurrentVAConfig("demander à l'interlocuteur");

                    virtualMeetingsHelperCtrl.currentAppointment = virtualMeetingsHelperCtrl.currentAppointment || _.find(window.threadAccount.appointments, function(a){ return a.kind == ($('#appointment_nature option:selected').val() || window.threadComputedData.appointment_nature) });
                    virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentVAConfig || (virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash);
                    virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentBehaviour || virtualMeetingsHelperCtrl.currentAppointment.behaviour;

                    $scope.currentConf = window.threadComputedData.call_instructions;

                    $scope.callTargets = $scope.getCallTargets();

                    if($scope.otherForm)
                        $scope.otherForm.callTargets = $scope.callTargets;

                    $scope.callSupports = $scope.getSupports();

                    if($scope.otherForm)
                        $scope.otherForm.callSupports = $scope.callSupports;

                    if(!!$scope.currentConf.targetInfos && !!$scope.currentConf.targetInfos.guid && !!$scope.currentConf.targetInfos.name) {

                        var selectedAttendee = findTargetAttendee($scope.currentConf.targetInfos);

                        if(selectedAttendee){
                            $scope.currentConf.targetInfos = {
                                name: selectedAttendee.displayNormalizedName(),
                                email: selectedAttendee.email,
                                guid: selectedAttendee.guid
                            };
                        }else{
                            Object.assign($scope.currentConf, {targetInfos: {}, support: '', details: ''});
                        }
                    }
                    else {
                        if($scope.currentConf.target == 'client') {
                            var threadOwner = $scope.attendeesManagerCtrl.getThreadOwner();
                            Object.assign($scope.currentConf, {targetInfos: {email: threadOwner.email, name: threadOwner.displayNormalizedName(), guid: threadOwner.guid}});
                        }

                        if($scope.currentConf.target != 'custom')
                            Object.assign($scope.currentConf, {targetInfos: {}, support: '', details: ''});
                    }

                    // If the appointment nature has not been saved, it means it is the first time we are filling the calling infos form
                    //if(window.threadComputedData.appointment_nature == null){
                    var possibleAppointmentsTypes = _.filter(window.threadAccount.appointments, function(appointment) {
                        return appointment.appointment_kind_hash.family_kind == $("select#appointment_family_nature").val();
                    });

                    if(possibleAppointmentsTypes.length > 1){
                        var currentAppointmentType = determineAppointmentType(possibleAppointmentsTypes);

                            // window.getCurrentAppointment() return in this case the last appointment type selected, so we use it to prevent overriding the call_instructions when arriving on a thread organizing a call (the previous appointment type will be call
                        if(currentAppointmentType.kind == 'call' && window.getCurrentAppointment().kind != 'call'  && $scope.currentConf.target == 'interlocutor' && $scope.callTargetsInfos.length == 1){
                            var defaultTargetInfos = $scope.callTargetsInfos[0];
                            var defaultConfSupport = $scope.determineDefaultSupport(findTargetAttendee(defaultTargetInfos));

                            Object.assign($scope.currentConf, {target: 'interlocutor', targetInfos: defaultTargetInfos, support: defaultConfSupport});
                            $scope.computeCallDetails(true);
                        }
                        //}
                        }

                    if($scope.currentConf.details == '' && window.threadComputedData.location == '')
                    {
                        $scope.call_instructions_missing = true;
                    }

                    $scope.updateTargetInfosSelect();

                    if(!$scope.$$phase){
                        $scope.$apply();
                    }

                    $scope.configLoaded =  true;
                    if($scope.otherForm)
                        $scope.otherForm.configLoaded = true;

                    updateNotesCallingInfos();
                };

                $scope.updateSelectedCallTargetInfos = function() {
                    // Added check on $scope.formEditMode because when 2 attendees and a target of 'interlocutor', when the event attendeesRefreshed is triggered it would set the support to 'mobile' no matter what was set on the event
                    if($scope.formEditMode && !$scope.currentConf.details) {
                        if($scope.currentConf.target == 'interlocutor') {
                            if($scope.callTargetsInfos.length == 1) {
                                var selectedTargetInfos =  $scope.currentConf.targetInfos = $scope.callTargetsInfos[0];
                                var selectedSupport = $scope.determineDefaultSupport(findTargetAttendee($scope.currentConf.targetInfos));

                                var newData = {};
                                if(selectedTargetInfos) newData.targetInfos = selectedTargetInfos;
                                if(selectedSupport) newData.support = selectedSupport;

                                $scope.currentConf = Object.assign($scope.currentConf, newData);

                                //$scope.computeCallDetails(true);
                                //Set the correct attendee in the targetInfos select if there is one
                                //$scope.updateTargetInfosSelect();

                                //updateNotesCallingInfos();
                            }
                        }
                    }
                };

                $scope.loadDefaultConfig = function(refreshCallDetails){
                    if((!!!$('#appointment_nature option:selected').val() && !!!window.threadComputedData.appointment_nature) || ($scope.callTargetsInfos == undefined))
                        return;

                    virtualMeetingsHelperCtrl.currentAppointment = _.find(window.threadAccount.appointments, function(a){ return a.kind == ($('#appointment_nature option:selected').val() || window.threadComputedData.appointment_nature) });
                    virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash;
                    virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentAppointment.behaviour;

                    $scope.callTargets = $scope.getCallTargets();

                    var threadOwner = $scope.attendeesManagerCtrl.getThreadOwner();

                    var initialConfTarget;
                    var initialTargetInfos = '';
                    var initialConfSupport = '';

                    switch(virtualMeetingsHelperCtrl.currentBehaviour){
                        case 'propose':
                            initialConfTarget = 'client';
                            initialTargetInfos = {email: threadOwner.email, name: threadOwner.displayNormalizedName(), guid: threadOwner.guid};
                            break;
                        case 'ask_interlocutor':
                            initialConfTarget = 'interlocutor';
                            initialTargetInfos = $scope.callTargetsInfos.length == 1 ? $scope.callTargetsInfos[0] : '';
                            break;
                        case 'later':
                            initialConfTarget = 'later';
                            break;
                        default:
                            initialConfTarget = 'later';
                    }

                    // If the appointment nature has not been saved, it means it is the first time we are filling the calling infos form
                    if(initialTargetInfos != '' && initialConfTarget == 'interlocutor'){
                        initialConfSupport = $scope.determineDefaultSupport(findTargetAttendee(initialTargetInfos));
                    }

                    if(initialConfSupport == ''){

                        switch(virtualMeetingsHelperCtrl.currentVAConfig.label){
                            case 'Mobile':
                                initialConfSupport = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? 'mobile' : '';
                                break;
                            case 'Landline':
                                initialConfSupport = 'landline';
                                break;
                            case 'Skype':
                                initialConfSupport = 'skype';
                                break;
                            case 'Skype for Business':
                                initialConfSupport = 'skype_for_business';
                                break;
                            case 'Confcall':
                                initialConfSupport = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? 'confcall' : '';
                                break;
                            case 'Webex':
                                initialConfSupport = 'confcall';
                                break;
                            case 'Video Conference':
                                initialConfSupport = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? 'video_conference' : '';
                                break;
                            default:
                                initialConfSupport = '';
                        }

                        if(virtualMeetingsHelperCtrl.currentVAConfig.resource_type) {
                            // We prefix with 'resource_' to make distinction with some appointments named already as the resource_type
                            initialConfSupport = 'resource_' + virtualMeetingsHelperCtrl.currentVAConfig.resource_type;
                        }
                    }

                    $scope.currentConf = Object.assign($scope.currentConf, {target: initialConfTarget, targetInfos: initialTargetInfos, support: initialConfSupport, details: ''});

                    $scope.callSupports = $scope.getSupports();


                    if(!$scope.$$phase){
                        $scope.$apply();
                    }

                    $scope.configLoaded = true;

                    if(refreshCallDetails){
                        $scope.computeCallDetails(true);
                    }
                    else{
                        updateWindowCallInstructions();
                    }

                    //Set the correct attendee in the targetInfos select if there is one
                    $scope.updateTargetInfosSelect();

                    updateNotesCallingInfos();
                };

                $scope.determineDefaultSupport = function(target){
                    var selectedSupport = '';

                    if(!!target.mobile)
                        selectedSupport = 'mobile';
                    else if(!!target.landline)
                        selectedSupport = 'landline';

                    return selectedSupport;
                };

                $scope.setDefaultSupportManually = function(target){

                    var selectedSupport = '';
                    var currentAppointmentType = $('#appointment_nature').val();

                    if(target){

                        if(currentAppointmentType == 'confcall'){
                            if(!!target.confCallInstructions)
                                selectedSupport = 'confcall';
                            else if(!!target.mobile)
                                selectedSupport = 'mobile';
                            else if(!!target.landline)
                                selectedSupport = 'landline'
                        }else if(currentAppointmentType == 'call'){
                            if(!!target.mobile)
                                selectedSupport = 'mobile';
                            else if(!!target.landline)
                                selectedSupport = 'landline';
                        }
                        $scope.currentConf.support = selectedSupport;

                        $scope.computeCallDetails(true);

                    }

                };

                $scope.supportChangedCallback = function() {
                    $scope.computeCallDetails();
                    $scope.checkVirtualResourceUse();
                };

                $scope.checkVirtualResourceUse = function() {
                    $scope.changeCurrentVAConfig($scope.currentConf.support);
                    var currentVAConfig = $scope.getCurrentVAConfig();
                    if(currentVAConfig) {
                        if(currentVAConfig.virtual_resources) {
                            var currentCalendar = window.currentCalendar;

                            if(currentCalendar && currentCalendar.dispStart) {
                                if($.isEmptyObject(window.currentCalendar.virtualResourcesEvents)) {
                                    currentCalendar.clearEvents();
                                    currentCalendar.fetchAllAccountsEvents(currentCalendar.dispStart.format() + "T00:00:00Z", currentCalendar.dispEnd.format() + "T00:00:00Z");
                                } else {
                                    $scope.determineFirstAvailableVirtualResource();
                                }

                                if($scope.otherForm)
                                    $scope.otherForm.selectedVirtualResource = $scope.selectedVirtualResource;
                            }
                        } else {
                            $scope.hideNonAvailableMessage();
                            $scope.selectedVirtualResource = undefined;
                            if($scope.otherForm)
                                $scope.otherForm.selectedVirtualResource = undefined;
                        }
                    } else {
                        $scope.hideNonAvailableMessage();
                        $scope.selectedVirtualResource = undefined;
                        if($scope.otherForm)
                            $scope.otherForm.selectedVirtualResource = undefined;
                    }
                    forceUpdateNotesCallingInfos();
                };

                $scope.computeCallDetails = function(notUseLastTarget){
                    var details = '';
                    $scope.detailsFrozenBecauseClient = false;
                    if($scope.currentConf.target != 'later'){
                        var attendee;

                        if($scope.currentConf.target == 'custom')
                            details = $scope.currentConf.details;

                        if($scope.currentConf.target == 'client'){
                            attendee = $scope.attendeesManagerCtrl.getThreadOwner();
                        }

                        if ($scope.currentConf.target == 'interlocutor'){


                            if(!notUseLastTarget && $scope.lastTargetInfos != '' && $scope.lastTargetInfos.guid && $scope.lastTargetInfos.guid != -1){
                                $scope.currentConf.targetInfos = $scope.lastTargetInfos;
                            }

                            if($scope.currentConf.targetInfos){
                                attendee = findTargetAttendee($scope.currentConf.targetInfos);
                                //if(attendee != undefined)
                                //    setAttendeeSelected(attendee);
                            }

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
                                case 'skype_for_business':
                                    if($scope.currentConf.target == 'client' &&
                                            skypeForBusinessService().canCreateMeeting()) {
                                        details = attendee.sfbInstructions || "$SKYPE_FOR_BUSINESS_MEETING_LINK_TO_BE_GENERATED$";
                                    }
                                    break;
                                case 'video_conference':
                                    details = attendee.videoConferenceInstructions;
                                    break;
                            }

                            if(attendee.isClient)
                                $scope.detailsFrozenBecauseClient = true;
                        }

                    }

                    if($scope.currentConf.target){
                        $scope.currentConf.details = details;
                        // Check if an angular digest cycle is running. If not, we force one to refresh the UI (happens when we update an attendee (i.e. phone number, skype...)
                        // If it is the case, then it means that we are in a function callback (in this case the attendeesRedreshed event) and we must force the digest cycle to run

                        if(!$scope.$$phase){
                            $scope.$apply();
                        }
                    }

                    updateWindowCallInstructions();
                };

                $scope.detailsOverrided = function(){
                    if($scope.currentConf.target == 'interlocutor') {
                        var updatedDetails = $scope.currentConf.details;
                        var attendeeAttribute = '';
                        var attendee = findTargetAttendee($scope.currentConf.targetInfos);

                        if(attendee != undefined && !attendee.isClient)
                        {
                            switch($scope.currentConf.support) {
                                case 'mobile':
                                    attendeeAttribute = 'mobile';
                                    break;
                                case 'landline':
                                    attendeeAttribute = 'landline';
                                    break;
                                case 'skype':
                                    attendeeAttribute = 'skypeId';
                                    break;
                                case 'confcall':
                                    attendeeAttribute = 'confCallInstructions';
                                    break;
                            }

                            if(attendeeAttribute != ''){
                                attendee[attendeeAttribute] = updatedDetails;
                                // Need to call this manually here because the watcher doesn't seem to pick the changes done from here
                                // and so doesn't trigger the updateNotes method
                                $scope.attendeesManagerCtrl.updateNotes();
                            }
                        }
                    }
                    updateWindowCallInstructions();
                };

                $scope.setEventNotes = function(){
                    var notes = $('#notes').val();
                    var message = '';
                    var callingInfos = '';
                    var phoneInfos = '';
                    var confcallInfos = '';

                    var threadOwner = $scope.attendeesManagerCtrl.getThreadOwner();
                    var isVirtual = $scope.isVirtualAppointment();

                    if(threadOwner){
                        if(rescueInNotesUsed() && !$scope.currentConf.details){
                            if(virtualMeetingsHelperCtrl.currentVAConfig.rescue_with_mobile || virtualMeetingsHelperCtrl.currentVAConfig.rescue_with_landline){
                                phoneInfos = threadOwner.displayRescuePhoneInformations(virtualMeetingsHelperCtrl.currentVAConfig.rescue_with_landline, virtualMeetingsHelperCtrl.currentVAConfig.rescue_with_mobile);
                                if(phoneInfos != '')
                                    callingInfos += "\n" + localize('common.phone') + ' ' + phoneInfos;

                            }
                            if(virtualMeetingsHelperCtrl.currentVAConfig.rescue_with_skype){
                                if(threadOwner.skypeId != '')
                                    callingInfos += "\n" + 'Skype : ' + threadOwner.skypeId;
                            }

                            if(virtualMeetingsHelperCtrl.currentVAConfig.rescue_with_confcall){
                                if(threadOwner.confCallInstructions != '')
                                    callingInfos += "\n" + localize("email_templates.send_call_instructions.give_target_confcall", {
                                            details: threadOwner.confCallInstructions
                                        });
                            }
                        }else{
                            if(!isVirtual)
                                var currentAppointment = window.getCurrentAppointment();

                            var mobileInNote = isVirtual ? virtualMeetingsHelperCtrl.currentVAConfig.mobile_in_note : currentAppointment.support_config_hash.mobile_in_note;
                            var landlineInNote = isVirtual ? virtualMeetingsHelperCtrl.currentVAConfig.landline_in_note : currentAppointment.support_config_hash.landline_in_note;
                            var skypeInNote = isVirtual ? virtualMeetingsHelperCtrl.currentVAConfig.skype_in_note : currentAppointment.support_config_hash.skype_in_note;
                            var confcallInNote = isVirtual ? virtualMeetingsHelperCtrl.currentVAConfig.confcall_in_note : currentAppointment.support_config_hash.confcall_in_note;

                            if(mobileInNote || landlineInNote){
                                phoneInfos = threadOwner.displayRescuePhoneInformations(landlineInNote, mobileInNote);
                                if(phoneInfos != '')
                                    callingInfos += "\n" + localize('common.phone') + ' ' + phoneInfos;
                            }
                            if(skypeInNote){
                                if(threadOwner.skypeId != '')
                                    callingInfos += "\n" + 'Skype : ' + threadOwner.skypeId;
                            }
                            if(confcallInNote){
                                if(threadOwner.confCallInstructions != '')
                                    callingInfos += "\n" + localize("email_templates.send_call_instructions.give_target_confcall", {
                                            details: threadOwner.confCallInstructions
                                        });
                            }
                        }

                        if(window.notesManager){
                            if(callingInfos)
                                message += threadOwner.displayNormalizedName() + callingInfos;

                            window.notesManager.setOrganizerInfos(message);
                            window.updateNotes();
                        }
                    }

                    if(isVirtual){
                        $scope.setCallingInstructionsInNotes();

                    }
                };

                $scope.setCallingInstructionsInNotes = function(){
                    var notes = $('#notes').val();
                    var tmpNotes = "";
                    var message = '';
                    var content = '';
                    var eventInstructions = '';
                    var usedLocale = window.threadComputedData.locale;

                    if(window.formFirstPass) {
                        usedLocale = $('.locale-radio:checked').val();
                    }

                    if($scope.currentConf.details){



                        if($scope.selectedVirtualResource) {
                            content = localize("events.call_instructions.give_confcall", {
                                target_name: $scope.currentConf.targetInfos.name,
                                details: $scope.selectedVirtualResource['instructions_' + usedLocale]
                            });
                        } else {

                            if($scope.currentConf.target == 'custom'){
                                content = $scope.currentConf.details;
                                eventInstructions = content;
                            }else{

                                if ($scope.currentConf.support == 'mobile' || $scope.currentConf.support == 'landline'){
                                    var attendeesWithoutAssistant = $scope.attendeesManagerCtrl.getAttendeesWithoutAssistant();

                                    if(attendeesWithoutAssistant.length == 2){
                                        if($scope.currentConf.targetInfos.guid){
                                            var guid = $scope.currentConf.targetInfos.guid.length == 36 ? $scope.currentConf.targetInfos.guid : parseInt($scope.currentConf.targetInfos.guid);

                                            var caller = _.without(attendeesWithoutAssistant, _.findWhere(attendeesWithoutAssistant,{guid: guid}))[0];

                                            content = localize("events.call_instructions.display_single_attendee", {
                                                target_name: $scope.currentConf.targetInfos.name,
                                                caller_name: caller.displayNormalizedName(),
                                                details: $scope.currentConf.details
                                            });
                                        }
                                    }else{
                                        content = localize("events.call_instructions.give_target_number", {
                                            target_name: $scope.currentConf.targetInfos.name,
                                            details: $scope.currentConf.details
                                        });
                                    }

                                    eventInstructions = content;
                                }
                                else if($scope.currentConf.support == 'confcall' || $scope.currentConf.support == 'video_conference'){
                                    content = localize("events.call_instructions.give_confcall", {
                                        target_name: $scope.currentConf.targetInfos.name,
                                        details: $scope.currentConf.details
                                    });

                                    eventInstructions = localize("events.call_instructions.instructions_in_notes", {
                                        locale: usedLocale
                                    });
                                }
                                else if($scope.currentConf.support == 'skype_for_business') {
                                    content = localize('events.call_instructions.give_skype_for_business', {
                                        target_name: $scope.currentConf.targetInfos.name,
                                        details: $scope.currentConf.details
                                    });
                                    eventInstructions = localize("events.call_instructions.instructions_in_notes", {
                                        locale: usedLocale
                                    });
                                }
                            }
                        }
                    }

                    window.threadComputedData.call_instructions.event_instructions = eventInstructions;

                    if(window.notesManager){
                        window.notesManager.setCallInstructions(content);
                        window.updateNotes();
                    }
                };

                $scope.targetChanged = function($event){
                    $scope.callSupports = $scope.getSupports();

                    if($scope.currentConf.target == 'later'){
                        $scope.currentConf.targetInfos = '';
                        $scope.changeCurrentVAConfig('vide');
                    }
                    else if($scope.currentConf.target == 'interlocutor'){
                        if($scope.callTargetsInfos.length == 1){
                            $scope.currentConf.targetInfos = $scope.callTargetsInfos[0];
                            setTimeout(function() {
                                angular.element($('#call_target_infos option')).filter(function () {
                                    return $(this).text().trim() == $scope.callTargetsInfos[0].displayName;
                                }).prop('selected', true);
                            }, 0);
                        }else{
                            $scope.currentConf.targetInfos = '';
                            $scope.currentConf.support = '';
                        }

                        $scope.changeCurrentVAConfig("demander à l'interlocuteur");
                    }
                    else if($scope.currentConf.target == 'client'){
                        var threadOwner = $scope.attendeesManagerCtrl.getThreadOwner();
                        $scope.currentConf.targetInfos = {email: threadOwner.email, name: threadOwner.displayNormalizedName(), guid: threadOwner.guid};
                        $scope.changeCurrentVAConfig($scope.currentConf.support);
                    }
                    else if($scope.currentConf.target == 'custom'){
                        Object.assign($scope.currentConf, {targetInfos: '', support: '', details: '', event_instructions: ''});
                    }
                    updateWindowCallInstructions();
                };

                $scope.getAttendees = function(){
                    return $scope.attendeesManagerCtrl.attendees;
                };

                $scope.isVirtualAppointment = function(){
                    var currentAppointment = window.getCurrentAppointment();

                    return currentAppointment && currentAppointment.appointment_kind_hash.is_virtual;
                    //return ['call', 'confcall', 'skype', 'hangout', 'webex', 'visio'].indexOf($("select#appointment_nature").val()) > -1;
                };

                $scope.cacheCurrentInterlocutor = function(){
                    if($scope.currentConf.target == 'interlocutor') {
                        $scope.cachedInterlocutor = jQuery.extend(true, {}, findTargetAttendee($scope.currentConf.targetInfos));
                    }
                };

                $scope.restoreCachedInterlocutor = function(){
                    if(!$.isEmptyObject($scope.cachedInterlocutor)){
                        Object.assign($scope.attendeesManagerCtrl.getAttendeeByGuid($scope.cachedInterlocutor.guid), $scope.cachedInterlocutor);
                        $scope.computeCallDetails();
                    }
                };

                $scope.cacheCurrentConf = function(){
                    $scope.cachedCurrentConf = jQuery.extend(true, {}, $scope.currentConf);
                };

                $scope.restoreCurrentConf = function(){
                    $scope.currentConf = jQuery.extend(true, {}, $scope.cachedCurrentConf);
                };

                $scope.updateTargetInfosSelect = function(){
                    // Should find another method to be sure that the ng-options are set before executing code
                    setTimeout(function(){
                        angular.element($($element[0]).find('#call_target_infos option')).filter(function(){
                            return $(this).text().trim() == $scope.computeOptionText($scope.currentConf.targetInfos).trim();
                        }).prop('selected', true);
                    }, 0);
                };

                $scope.detailsDisabled = function(){
                    return !$scope.formEditMode || ($scope.detailsFrozenBecauseClient || $scope.forcedDetailsFrozen)
                };

                $scope.getOverlappingVirtualResourcesEvents = function(eventsByVirtualResources) {
                    var virtualResourceType = $scope.getCurrentVAConfig() && $scope.getCurrentVAConfig().resource_type;

                    var result = [];

                    if(virtualResourceType) {
                        result = $('#events_availabilities_methods').scope().getOverlappingEvents(eventsByVirtualResources, {isVirtualResource: true, virtualResourceType: virtualResourceType});
                    }

                    return result;
                };

                $scope.usingVirtualResources = function() {
                    var currentVAConfig = $scope.getCurrentVAConfig();
                    var result = false;
                    if(currentVAConfig) {
                        var virtualResources = $scope.getCurrentVAConfig().virtual_resources;
                        result = virtualResources && virtualResources.length > 0;
                    }

                    return result;
                };

                $scope.determineFirstAvailableVirtualResource = function(specifiedDate) {
                    if(window.currentCalendar && !$.isEmptyObject(window.currentCalendar.virtualResourcesEvents) &&
                        (window.julie_action_nature == 'check_availabilities' || window.classification == 'update_event')) {

                        // When there is an event linked to the messages thread, we will check if the schedule we check is not the same event
                        // To avoid saying the virtual resource is not available when it is actually booked for the specified period
                        if(window.currentEventTile) {
                            var currentEventId = window.currentEventTile.event.provider_id;
                        }

                        if (window.classification == 'update_event') {
                            var selectedDateStartTime = window.currentEventTile.getEditedEvent().start;
                            var selectedDateEndTime = window.currentEventTile.getEditedEvent().end;
                        } else {

                            if(specifiedDate) {
                                var selectedDateStartTime = moment(specifiedDate);
                            }   else if($scope.datesVerificationManagerCtrl.selectedDate) {
                                var selectedDateStartTime = moment($scope.datesVerificationManagerCtrl.selectedDate.date);
                            } else {
                                var selectedDateStartTime = null;
                            }

                            if(selectedDateStartTime)
                                var selectedDateEndTime = selectedDateStartTime.clone().add(window.currentCalendar.getCurrentDuration(), 'm');
                        }

                        var virtualResourcesAvailable = $scope.getCurrentVAConfig().virtual_resources;

                        if($scope.selectedVirtualResource) {
                            virtualResourcesAvailable = _.reject(virtualResourcesAvailable, function(va) { return va.id == $scope.selectedVirtualResource.id; });
                            var selectedVirtualResourceCopy = angular.copy($scope.selectedVirtualResource);
                            // $scope.selectedVirtualResource is holding id in a string format, the currentVAConfig virtual_resources attribute hold them as integer
                            //  We work with integers further down so we cast it here
                            selectedVirtualResourceCopy.id = parseInt(selectedVirtualResourceCopy.id);
                            virtualResourcesAvailable.unshift(selectedVirtualResourceCopy);
                        }

                        var available = [];

                        if(selectedDateStartTime) {

                            _.each(virtualResourcesAvailable, function (vR) {
                                var virtualResourcesEvents = window.currentCalendar.virtualResourcesEvents[vR.id];
                                var currentAvailability = $.extend(vR, {isAvailable: true});

                                // We either directly specify the selected date (from the event) or we will fetch it from the datesVerif module

                                if (virtualResourcesEvents) {
                                    var eventOnThisSchedule = _.find(virtualResourcesEvents, function (event) {
                                        var currentStartDate = moment(event.start);
                                        var currentEndDate = moment(event.end);

                                        return event.id != currentEventId && $scope.eventIsOverlapping(selectedDateStartTime, selectedDateEndTime, currentStartDate, currentEndDate);
                                    });

                                    if (eventOnThisSchedule) {
                                        currentAvailability.isAvailable = false;
                                    }
                                }
                                available.push(currentAvailability);
                            });

                            var firstAvailableVr = _.find(available, function (hash) {
                                return hash.isAvailable;
                            });

                            if (firstAvailableVr) {
                                $scope.hideNonAvailableMessage();
                                $scope.selectedVirtualResource = firstAvailableVr;
                                $scope.currentConf.details = 'Visio instructions';

                                // TODO :  $scope.selectedVirtualResource
                                // set on $scope.currentConf.details

                                // To update the form select option if we have triggered this function from the calendar events fetched callback
                                if(!$scope.$$phase)
                                    $scope.$apply();
                            } else {
                                $scope.selectedVirtualResource = undefined;
                                var resourceType = $scope.getCurrentVAConfig().resource_type;
                                // Depending on the number of total rooms, we then display the correct message
                                $scope.displayNonAvailableMessage('Aucune Ressource ' + resourceType + ' de disponible');
                            }

                            forceUpdateNotesCallingInfos();
                        }
                    }
                };

                $scope.eventIsOverlapping = function(firstEventDateStartTime, firstEventDateEndTime, secondEventDateStartTime, secondEventDateEndTime) {
                    return $scope.utilitiesHelper.eventIsOverlapping(firstEventDateStartTime, firstEventDateEndTime, secondEventDateStartTime, secondEventDateEndTime);
                    //return (
                    //    firstEventDateStartTime.isSame(secondEventDateStartTime) || firstEventDateEndTime.isSame(secondEventDateEndTime) ||
                    //    firstEventDateStartTime.isBetween(secondEventDateStartTime, secondEventDateEndTime, 'minute', '()') ||
                    //    firstEventDateEndTime.isBetween(secondEventDateStartTime, secondEventDateEndTime, 'minute', '()') ||
                    //    secondEventDateStartTime.isBetween(firstEventDateStartTime, firstEventDateEndTime, 'minute', '()') ||
                    //    secondEventDateEndTime.isBetween(firstEventDateStartTime, firstEventDateEndTime, 'minute', '()')
                    //);
                };

                $scope.hideNonAvailableMessage = function() {
                    $scope.unavailableMessageDisplayed = false;
                    $('.virtual-resources-non-available-msg').html('');
                    $('.virtual-resources-details-container').hide();

                    $scope.scaleEventTile();
                };

                $scope.displayNonAvailableMessage = function(msg) {
                    $scope.unavailableMessageDisplayed = true;
                    $('.virtual-resources-non-available-msg').html(msg);
                    $('.virtual-resources-details-container').show();

                    $scope.scaleEventTile();
                };

                $scope.scaleEventTile = function() {

                    if($('#event-cancel-button').css('display') == 'block') {

                        var virtualMeetingHelperUsed = $('#event_update_virtual_meetings_helper').length > 0;

                        var currentHeightContainer = '650px';
                        var currentHeightPanel = '635px';

                        if(virtualMeetingHelperUsed) {
                            currentHeightContainer = '810px';
                            currentHeightPanel = '790px';
                        }

                        if($scope.unavailableMessageDisplayed) {
                            currentHeightContainer = '695px';
                            currentHeightPanel = '680px';

                            if(virtualMeetingHelperUsed) {
                                currentHeightContainer = '855px';
                                currentHeightPanel = '840px';
                            }
                        }
                    } else {
                        var currentHeightContainer = '575px';
                        var currentHeightPanel = '545px';

                        if($scope.unavailableMessageDisplayed) {
                            currentHeightContainer = '605px';
                            currentHeightPanel = '590px';
                        }
                    }

                    $('.event-tile-container').css('height', currentHeightContainer);
                    $('.created-event-panel').css('height', currentHeightPanel);
                };

                updateWindowCallInstructions = function(){
                    if(!$.isEmptyObject($scope.currentConf)){
                        window.threadComputedData.call_instructions = $scope.currentConf;
                    }
                };

                getCurrentThreadOwnerInfos = function(notes){
                    return threadOwnerInfosRe.exec(notes);
                };

                findTargetAttendee = function(targetInfos){

                    if(!!targetInfos){
                        return _.find($scope.attendeesManagerCtrl.attendees, function (a) {
                            var found = false;
                            if(targetInfos.email != null)
                                found = a.email == targetInfos.email;
                            else if(targetInfos.guid != null)
                                found = a.guid == targetInfos.guid;
                            else if(targetInfos.name != null)
                                found = a.displayNormalizedName() == targetInfos.name;
                            return found;
                        });
                    }

                };

                setAttendeeSelected = function(attendee){

                    setTimeout(function() {
                        angular.element($('#call_target_infos option')).filter(function () {
                            return $(this).text().trim() == $scope.computeOptionText({
                                    name: attendee.displayNormalizedName(),
                                    email: attendee.email
                                });
                        }).prop('selected', true);
                    }, 0);
                };

                rescueInNotesUsed = function(){
                    if(!virtualMeetingsHelperCtrl.currentVAConfig)
                        return false;
                    var currentVAConfig = virtualMeetingsHelperCtrl.currentVAConfig;

                    return currentVAConfig.rescue_with_confcall || currentVAConfig.rescue_with_landline || currentVAConfig.rescue_with_mobile || currentVAConfig.rescue_with_skype || currentVAConfig.rescue_with_video_conference;
                };

                checkIfThreadDataOk = function(){
                    if(typeof(window.threadComputedData.call_instructions) != 'object'){
                        return false;
                    }
                    return checkNullity(window.threadComputedData.call_instructions.target) && checkNullity(window.threadComputedData.call_instructions.targetInfos);
                };

                checkNullity = function(attr){
                    return attr != null && attr != undefined;
                };

                //Tests Purpose ---------------------------------------------

                $scope.getCurrentAppointment = function(){
                    return virtualMeetingsHelperCtrl.currentAppointment;
                };

                $scope.getCurrentVAConfig = function(){
                    return virtualMeetingsHelperCtrl.currentVAConfig;
                };

                $scope.getCurrentBehaviour = function(){
                    return virtualMeetingsHelperCtrl.currentBehaviour;
                };
                //-----------------------------------------------------------

            }],
            controllerAs: 'virtualMeetingsHelperCtrl'
        }
    });
})();