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
                        var attendeesWithoutThreadOwner = _.filter(attendees, function (a) {
                            return $scope.attendeesManagerCtrl.getThreadOwnerEmails().indexOf(a.email) == -1 && a.isPresent;
                        });

                        if(attendeesWithoutThreadOwner.length > 0){

                            $scope.callTargetsInfos = _.map(attendeesWithoutThreadOwner, function (a) {
                                return {email: a.email, name: a.displayNormalizedName(), guid: a.guid, displayName: $scope.computeOptionText({name: a.displayNormalizedName(), email: a.email})};
                            });

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

                    //if($scope.currentConf.target == 'interlocutor' )
                    //    $scope.setDefaultSupportManually(findTargetAttendee($scope.currentConf.targetInfos));

                };

                $scope.changeCurrentVAConfig = function(configLabel){

                    var config = _.filter(window.threadAccount.virtual_appointments_support_config, function(vaConfig){
                        return vaConfig.label.toLowerCase() == configLabel;
                    })[0];

                    if(config == undefined || config == null){
                        config = _.filter(window.threadAccount.virtual_appointments_support_config, function(vaConfig){
                            return vaConfig.label.toLowerCase() == 'vide';
                        })[0];
                    }
                    virtualMeetingsHelperCtrl.currentVAConfig = config;

                    updateNotesCallingInfos();
                };

                $scope.loadCurrentConfig = function(){

                    if(window.threadComputedData.call_instructions && window.threadComputedData.call_instructions.target == 'interlocutor')
                        $scope.changeCurrentVAConfig("demander à l'interlocuteur");

                    virtualMeetingsHelperCtrl.currentAppointment = virtualMeetingsHelperCtrl.currentAppointment || _.find(window.threadAccount.appointments, function(a){ return a.kind == ($('#appointment_nature option:selected').val() || window.threadComputedData.appointment_nature) });
                    virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentVAConfig || (virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash);
                    virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentBehaviour || virtualMeetingsHelperCtrl.currentAppointment.behaviour;
                    $scope.callTargets = [
                        {name:"L'interlocuteur", value:'interlocutor'},
                        {name:"Décidé plus tard", value:'later'},
                        {name:"Le client (" + window.threadAccount.full_name + ')', value:'client'},
                        {name:"Custom", value:'custom'}
                    ];

                    if($scope.otherForm)
                        $scope.otherForm.callTargets = $scope.callTargets;

                    $scope.callSupports = [
                        {name:"Téléphone portable", value:'mobile'},
                        {name:"Téléphone fixe", value:'landline'},
                        //{name:"Skype", value:'skype'},
                        {name:"Confcall", value:'confcall'}
                    ];

                    $scope.currentConf = window.threadComputedData.call_instructions;
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

                $scope.loadDefaultConfig = function(refreshCallDetails){
                    if((!!!$('#appointment_nature option:selected').val() && !!!window.threadComputedData.appointment_nature) || ($scope.callTargetsInfos == undefined))
                        return;

                    virtualMeetingsHelperCtrl.currentAppointment = _.find(window.threadAccount.appointments, function(a){ return a.kind == ($('#appointment_nature option:selected').val() || window.threadComputedData.appointment_nature) });
                    virtualMeetingsHelperCtrl.currentVAConfig = virtualMeetingsHelperCtrl.currentAppointment == undefined ? {} : virtualMeetingsHelperCtrl.currentAppointment.support_config_hash;
                    virtualMeetingsHelperCtrl.currentBehaviour = virtualMeetingsHelperCtrl.currentAppointment.behaviour;

                    var suffixClient = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? ' (défaut)' : '';
                    var suffixLater = virtualMeetingsHelperCtrl.currentBehaviour == 'later' ? ' (défaut)' : '';
                    var suffixInterlocutor = virtualMeetingsHelperCtrl.currentBehaviour == 'ask_interlocutor' ? ' (défaut)' : '';

                    $scope.callTargets = [
                        {name:"L'interlocuteur" + suffixInterlocutor, value:'interlocutor'},
                        {name:"Décidé plus tard" + suffixLater, value:'later'},
                        {name:"Le client (" + window.threadAccount.full_name + ')' + suffixClient, value:'client'},
                        {name:"Custom", value:'custom'}
                    ];

                    var suffixMobile = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Mobile' ? ' (défaut)' : '';
                    var suffixLandline = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Landline' ? ' (défaut)' : '';
                    var suffixSkype = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Skype' ? ' (défaut)' : '';
                    var suffixConfcall = virtualMeetingsHelperCtrl.currentVAConfig.label == 'Confcall' ? ' (défaut)' : '';

                    $scope.callSupports = [
                        {name:"Téléphone portable" + suffixMobile, value:'mobile'},
                        {name:"Téléphone fixe" + suffixLandline, value:'landline'},
                        //{name:"Skype" + suffixSkype, value:'skype'},
                        {name:"Confcall" + suffixConfcall, value:'confcall'}
                    ];

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
                            case 'Confcall':
                                initialConfSupport = virtualMeetingsHelperCtrl.currentBehaviour == 'propose' ? 'confcall' : '';
                                break;
                            case 'Webex':
                                initialConfSupport = 'confcall';
                                break;
                            default:
                                initialConfSupport = '';
                        }
                    }

                    $scope.currentConf = Object.assign($scope.currentConf, {target: initialConfTarget, targetInfos: initialTargetInfos, support: initialConfSupport, details: ''});

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

                        if(callingInfos != ''){
                            message += "-" + localize('events.call_instructions.organizer_infos', {locale: window.currentLocale})+ "-----------------";
                            message += "\n" +threadOwner.displayNormalizedName();
                            message += callingInfos;
                            message += "\n----------------------------------------";
                        }

                        var tmpNotes = notes.replace(/\n/g,'');
                        var regexFrResult = threadOwnerInfosReFr.exec(tmpNotes);
                        var regexEnResult = threadOwnerInfosReEn.exec(tmpNotes);

                        if(regexFrResult == null && regexEnResult == null){
                            var space = message == '' ? '' : "\n\n";
                            notes = message + space + notes;
                        }else{
                            var usedRegex = regexFrResult != null ? regexFrResult : regexEnResult;
                            notes = notes.replace(/\n/g,'__n').replace(usedRegex, message).replace(/__n/g, "\n");
                        }

                        $("#notes").val(notes);
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

                    if($scope.currentConf.details){

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
                            else if($scope.currentConf.support == 'confcall'){
                                content = localize("events.call_instructions.give_confcall", {
                                    target_name: $scope.currentConf.targetInfos.name,
                                    details: $scope.currentConf.details
                                });

                                eventInstructions = localize("events.call_instructions.instructions_in_notes", {
                                    locale: window.threadComputedData.locale
                                });
                            }
                        }
                    }

                    window.threadComputedData.call_instructions.event_instructions = eventInstructions;

                    if(content != ''){
                        message += "-" + localize('events.call_instructions.title', {locale: window.currentLocale}) + "----------------";
                        message += "\n" + content;
                        message += "\n----------------------------------------";
                    }

                    tmpNotes = notes.replace(/^\s+|\s+$/g, '').replace(/\n/g, '__n');
                    var regexFrResult = callingInstructionsInfosReFr.exec(tmpNotes);
                    var regexEnResult = callingInstructionsInfosReEn.exec(tmpNotes);

                    if(regexFrResult == null && regexEnResult == null){
                        var space = message == '' ? '' : "\n\n";
                        notes = message + space + notes;
                    }else{
                        var usedRegex = regexFrResult != null ? regexFrResult : regexEnResult;
                        notes = tmpNotes.replace(usedRegex, message).replace(/__n/g, "\n");
                    }
                    $("#notes").val(notes);
                };

                $scope.targetChanged = function($event){
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
                    return ['call', 'confcall', 'skype', 'hangout', 'webex'].indexOf($("select#appointment_nature").val()) > -1;
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

                    return currentVAConfig.rescue_with_confcall || currentVAConfig.rescue_with_landline || currentVAConfig.rescue_with_mobile || currentVAConfig.rescue_with_skype;
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