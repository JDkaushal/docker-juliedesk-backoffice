// Not accessible when loaded from the source files for some reasons
//= require jquery-ui
//= require timezone_picker

(function(){
    var app = angular.module('attendees-manager-controllers', ['templates', 'ngMessages', 'ui.bootstrap', 'ui.bootstrap.tpls']);

    app.directive('attendeesForm', function(){
        return {
            restrict: 'E',
            templateUrl: 'attendees-form.html',
            controller: [ '$scope', 'sharedProperties', '$http', function($scope, sharedProperties, $http){
                var attendeesFormCtrl = this;
                var originalAttendee = {};
                var firstNameMirrored = false;
                var attendeesManager = angular.element($('#attendeesCtrl')).scope();

                this.isVisible = false;
                this.attendeeInForm = {};

                this.displayAssistantEmailError = false;
                this.timezoneNeeded = false;
                this.currentMode = 'new';

                var virtualMeetings = ['call', 'confcall', 'skype', 'hangout', 'webex'];

                $("#attendee_timezone").timezonePicker();

                var timezones = $("#attendee_timezone").timezonePicker.getTimezonesNames();

                $scope.$on('attendeeFormDisplayed', function(event, args){
                    attendeesFormCtrl.currentMode = args.action;
                    if(attendeesFormCtrl.currentMode == 'new')
                        attendeesFormCtrl.attendeeInForm = {};

                    attendeesFormCtrl.setAttendeeInForm(args.attendee);
                    attendeesFormCtrl.checkIfTimezoneNeeded($('#appointment_nature').val());

                    // Need to encapsulate the function in a setTimeout because otherwise It doesn't update the select correctly
                    setTimeout(function(){
                        attendeesFormCtrl.setCorrectAssistedBy();
                    }, 0);

                    attendeesFormCtrl.isVisible = true;
                    $('.messages-thread-info-panel').removeClass('scrollable').addClass('frozen');
                });

                this.sanitizeContent = function(attribute){
                    this.attendeeInForm[attribute] = this.attendeeInForm[attribute].trim();
                };

                this.cancelAttendeeForm = function(){
                    Object.assign(attendeesFormCtrl.attendeeInForm, originalAttendee);
                    attendeesFormCtrl.isVisible = false;
                    $('.messages-thread-info-panel').removeClass('frozen').addClass('scrollable');
                };

                this.addAttendee = function(){
                    if(this.attendeeInForm.usageName == '' || this.attendeeInForm.usageName === undefined)
                        this.attendeeInForm.usageName = this.attendeeInForm.firstName;

                    if(this.attendeeInForm.company === undefined)
                        this.attendeeInForm.company = '';

                    if(this.attendeeInForm.firstName)
                        this.sanitizeContent('firstName');

                    if(this.attendeeInForm.lastName)
                        this.sanitizeContent('lastName');

                    if(this.attendeeInForm.usageName)
                        this.sanitizeContent('usageName');

                    this.attendeeInForm.name = this.attendeeInForm.firstName + ' ' + this.attendeeInForm.lastName;

                    if(attendeesFormCtrl.currentMode == 'new')
                    {
                        sharedProperties.notifyAttendeeAdded(new Attendee(this.attendeeInForm));
                        // Sometime when a new attendee is added a display bug occure, hiding/showing the attendees seems to fix it
                        setTimeout(function(){
                            $('.contact').hide().show(0);
                        }, 10);
                    }else{
                        if(this.attendeeInForm.isAssistant){
                            var assisted = attendeesManager.getAssisted(this.attendeeInForm);

                            if(assisted)
                            {
                                assisted.assistedBy.email = this.attendeeInForm.email;
                                assisted.assistedBy.displayName = this.attendeeInForm.displayNormalizedName();
                            }
                        }
                    }
                    attendeesFormCtrl.isVisible = false;
                    $('.messages-thread-info-panel').removeClass('frozen').addClass('scrollable');

                    processAppointmentType();
                    reProcessTitle();
                };

                this.checkFormValidations =function(attendeesForm){
                    if(jQuery.isEmptyObject(attendeesForm.email.$error))
                        $('#email-error-area').removeClass('highlighted');
                    else
                        $('#email-error-area').addClass('highlighted');
                };

                this.checkAssistantConditions = function(attendeesForm){
                    if(this.attendeeInForm.email == '' || this.attendeeInForm.email == undefined || !$.isEmptyObject(attendeesForm.email.$error))
                    {
                        this.attendeeInForm.isAssistant = false;
                        this.displayAssistantEmailError = true;
                    }else
                    {
                        this.displayAssistantEmailError = false;
                        if(this.attendeeInForm.assisted)
                            this.attendeeInForm.assisted = false;
                    }
                };

                this.setAssistant = function(){
                    if(this.attendeeInForm.isAssistant)
                        this.attendeeInForm.isAssistant = false;
                };

                this.setAttendeeInForm = function(attendee){
                    this.attendeeInForm = attendee;
                    originalAttendee = jQuery.extend(true, {}, attendee);
                };

                this.isCurrentMode = function(mode){
                    return this.currentMode == mode;
                };

                this.checkIfTimezoneNeeded = function(appointmentType){
                    this.timezoneNeeded = virtualMeetings.indexOf(appointmentType) > -1;
                };

                this.timezoneChanged = function(attendeesForm){
                    if(timezones.indexOf($('#attendee_timezone').val()) > -1)
                        attendeesForm.attendee_timezone.$setValidity("timezoneFormat", true);
                    else
                        attendeesForm.attendee_timezone.$setValidity("timezoneFormat", false);
                };

                this.setCorrectAssistedBy = function(){
                    // Angular uses Object references to deal with select options values when they are set to an object
                    // so when the page is loaded and the data are fetched the saved assistedBy object have a different
                    // reference than those in the select options
                    // You must then update the selected option manually based on the option's text value for example

                    if(!attendeesFormCtrl.attendeeInForm.isClient && attendeesFormCtrl.attendeeInForm.assistedBy != "" && attendeesFormCtrl.attendeeInForm.assistedBy != undefined){
                        var assistant = attendeesManager.getAssistant(attendeesFormCtrl.attendeeInForm);
                        if(assistant)
                            angular.element($('#assisted_by option')).filter(function(){
                                return $(this).text().trim() == assistant.displayNormalizedName();
                            }).prop('selected', true);
                    }
                };

                this.firstNameKeyup = function(event){
                  if(firstNameMirrored){
                      attendeesFormCtrl.attendeeInForm.usageName = event.currentTarget.value;
                  }
                };

                this.firstNameFocus = function(){
                    firstNameMirrored = !!(attendeesFormCtrl.attendeeInForm.usageName == '' || attendeesFormCtrl.attendeeInForm.usageName == undefined);
                };

                // For testing purposes
                this.getOriginalAttendee = function(){
                    return originalAttendee;
                };

                
                this.importContactInfos = function(){
                    $http({
                        url: '/client_contacts/fetch_one?client_email=' + attendeesFormCtrl.getThreadOwner().email + '&email=' + attendeesFormCtrl.attendeeInForm.email,
                        method: "GET"
                    }).then(function success(response) {
                        attendeesFormCtrl.setAttendeeInFormDetails(response.data);
                    }, function error(response){
                        console.log("Error: ", response);
                    });
                };

                this.getThreadOwner = function(){
                    return attendeesManager.getThreadOwner();
                };

                this.setAttendeeInFormDetails = function(attendeeDetails){
                    attendeesFormCtrl.attendeeInForm = {isPresent: true};
                    if(attendeeDetails.assistedBy)
                        attendeeDetails.assistedBy = JSON.parse(attendeeDetails.assistedBy);
                    Object.assign(attendeesFormCtrl.attendeeInForm, attendeeDetails);
                };

            }],
            controllerAs: 'attendeesFormCtrl'
        };
    });

    app.controller("AttendeesCtrl", ['$scope', '$rootScope','sharedProperties', '$http', function($scope, $rootScope, sharedProperties, $http){
        var attendeesCtrl = this;
        var contactInfosReFr = new RegExp("-" + localize("events.call_instructions.contacts_infos", {locale: 'fr'}) + "-------------------.+?(?:----------------------------------------)");
        var contactInfosReEn = new RegExp("-" + localize("events.call_instructions.contacts_infos", {locale: 'en'}) + "-------------------.+?(?:----------------------------------------)");

        angular.element(document).ready(function () {
            $scope.virtualAppointmentsHelper = angular.element($('#virtual-meetings-helper')).scope();
        });

        this.loaded = false;
        $scope.attendees = [];
        $scope.missingInformationLookedFor = '';
        this.readOnly = window.threadDataIsEditable == undefined;

        //Watchers------------------------------------------------------------------------
        $scope.$watch('attendees', function (newVal, oldVal){
            updateNotesCallingInfos();

            if(newVal.length > 0){
                $rootScope.$broadcast('attendeesRefreshed', {attendees: $scope.attendees});
                $scope.lookupAttendeesMissingInfos();
            }
        }, true);
        //--------------------------------------------------------------------------------

        //Events Listeners----------------------------------------------------------------
        $scope.$on('attendeeAdded', function(event, args) {
            $scope.attendees.push(args.attendee);
        });
        //--------------------------------------------------------------------------------

        //Attendees-----------------------------------------------------------------------
        this.callingInformationsChanged = function(){
            var virtualMeetingsHelper = angular.element($('#virtual-meetings-helper')).scope();
            if(virtualMeetingsHelper)
                virtualMeetingsHelper.targetInfosChanged();
        };


        this.populateAttendeesDetails = function(attendeesDetails){
            // We filter the attendees to not include the threadOwner as we will add him after
            var companies = attendeesDetails.companies;
            var aliases = attendeesDetails.aliases;
            var aliasedEmails = Object.keys(aliases);
            var aliasEmails = _.flatten(_.map(aliases, function(aliases, email){
               return aliases;
            }));

            var threadOwnerEmailAliasesDowncase = _.map(window.threadAccount.email_aliases, function(email){return email.toLowerCase()});

            angular.forEach(window.currentAttendees.filter(function(attendee){
                var emailLowCase = attendee.email ? attendee.email.toLowerCase() : undefined;
                return (threadOwnerEmailAliasesDowncase.indexOf(emailLowCase)) == -1 && (emailLowCase != window.threadAccount.email.toLowerCase())
            }), function(attendee) {
                var attendeeDetails = _.find(attendeesDetails.contacts, function(a) {
                    var searchedEmail = attendee.email;
                    //
                    //var clientMainEmail;
                    //_.each(aliases, function (aliases, aliased) {
                    //    if (aliases.indexOf(attendee.email) > -1)
                    //        clientMainEmail = aliased;
                    //});
                    //
                    //console.log(searchedEmail);
                    //console.log(clientMainEmail);
                    //
                    //if(clientMainEmail)
                    //    searchedEmail = clientMainEmail;

                    if(searchedEmail != undefined && searchedEmail != ''){
                        return a.email == searchedEmail;
                    }else if(attendee.name != '' && attendee.name != undefined){
                        return a.name == attendee.name;
                    }
                    return false;
                });

                var informations = (attendeeDetails || attendee);
                var assistant = (typeof(informations.assistedBy) == "string" && informations.assistedBy.length > 0) ? JSON.parse(informations.assistedBy) : informations.assistedBy;
                informations.assistedBy = assistant;

                //if(aliasedEmails.indexOf(informations.email) > -1)
                //    // If the current attendee was in the aliases response from the server, it means it is in the accounts cache => he is client
                //    informations.isClient = "true";

                if(Object.keys(companies).indexOf(informations.email) > -1)
                    informations.company = companies[informations.email];
                //If the current email is the principal email for a user
                if(aliasedEmails.indexOf(informations.email) > -1){
                    informations.isClient = "true";
                    informations.company = companies[informations.email];

                    // If it is in the recipients, we create the attendee, because if there will be an alias for this email in the recipients, it will be discarded
                    if(window.currentToCC.indexOf(informations.email.toLowerCase()) > -1){

                        attendeesCtrl.createAttendee(informations, attendee);
                     // If it is not in the recipients, we check to see if an alias for this email is in the recipients, if not we create the attendee, if yes we don't because we will use the alias instead
                    }else{
                        var aliasInTheRecipients = false;

                        // Check if an alias for this email is in the recipients
                        _.each(aliases[informations.email], function(alias){
                            if(window.currentToCC.indexOf(alias.toLowerCase()) > -1)
                                aliasInTheRecipients = true;
                        });
                        // If yes we don't create the attendee, because we will use the alias
                        if(aliasInTheRecipients){

                         // If no, we use the main email and we create the attendee
                        }else{
                            attendeesCtrl.createAttendee(informations, attendee);
                        }
                    }
                    // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client

                 // If the current email is an alias for a client
                }else if(aliasEmails.indexOf(informations.email) > -1) {
                    informations.isClient = "true";

                    //We find the client main email
                    var clientMainEmail;
                    _.each(aliases, function (aliases, aliased) {
                        if (aliases.indexOf(informations.email) > -1)
                            clientMainEmail = aliased;
                    });

                    if(clientMainEmail)
                        informations.company = companies[clientMainEmail];

                    // We found the client main email and it is the recipients, so we will use it as the attendee, we do nothing here
                    if (clientMainEmail && window.currentToCC.indexOf(clientMainEmail.toLowerCase()) > -1) {

                    }
                    // If we found it or not and it is not in the recipients, we can create the attendee
                    else{
                        // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client
                        attendeesCtrl.createAttendee(informations, attendee);
                    }
                    // If the email is not an aliased email nor a alias email, we create the attendee
                }else{
                    attendeesCtrl.createAttendee(informations, attendee);
                }
            });

            angular.forEach($scope.attendees, function(a){
                var assisted = undefined;
                if(assisted = $scope.getAssistedByEmail(a)){
                    // We do that to actualize if necessary the temporary guid with the one returned by the database
                    assisted.assistedBy.guid = a.guid;
                }
            });

            var threadAccountFullName = window.threadAccount.full_name.split(' ');
            var companyName = '';
            if(window.threadAccount.company_hash != undefined)
                companyName = window.threadAccount.company_hash.name;

            //var currentToCCDowncase = _.map(window.currentToCC, function(email){return email.toLowerCase()});
            var threadOwnerEmail = window.threadAccount.email;
            if(window.threadAccount.email_aliases.length > 0){
                _.each(window.threadAccount.email_aliases, function(alias){
                    if(window.currentToCC.indexOf(alias.toLowerCase()) > -1){
                        threadOwnerEmail = alias;
                    }
                });
            }

            var threadOwner = new Attendee({
                guid: -1,
                email: threadOwnerEmail,
                firstName: threadAccountFullName[0],
                lastName: threadAccountFullName.splice(1, threadAccountFullName.length).join(' '),
                name: window.threadAccount.full_name,
                usageName: window.threadAccount.usage_name,
                gender: '?',
                isAssistant: false,
                assisted: true,
                assistedBy: {email: window.currentJulieAlias.email, displayName: window.currentJulieAlias.name},
                company: companyName,
                timezone: window.threadAccount.default_timezone_id,
                landline: window.threadAccount.landline_number,
                mobile: window.threadAccount.mobile_number,
                skypeId: window.threadAccount.skype,
                confCallInstructions: window.threadAccount.confcall_instructions,
                isPresent: true,
                isClient: true,
                isThreadOwner: true
            });

            $scope.attendees.push(threadOwner);

            sharedProperties.setThreadOwner(threadOwner);

            _.each(window.threadComputedData.constraints_data, function(constraintData) {
                newConstraintTile(constraintData, false);
            });

            $(".add-constraint-button").click(function() {
                newConstraintTile(null, true);
            });

            reProcessTitle();
            $rootScope.$broadcast('attendeesRefreshed', {attendees: $scope.attendees});
        };

        this.createAttendee = function(informations, attendee){
            var a = new Attendee({
                guid: informations.id || $scope.guid(),
                email: informations.email ? informations.email.toLowerCase() : undefined,
                firstName: informations.firstName,
                lastName: informations.lastName,
                name: (informations.firstName + ' ' + informations.lastName).trim(),
                usageName: informations.usageName || informations.name,
                gender: informations.gender,
                isAssistant: informations.isAssistant == "true",
                assisted: informations.assisted == "true",
                assistedBy: informations.assistedBy,
                company: informations.company || '',
                timezone: informations.timezone || window.threadAccount.default_timezone_id,
                landline: informations.landline,
                mobile: informations.mobile,
                skypeId: informations.skypeId,
                confCallInstructions: informations.confCallInstructions,
                isPresent: attendee.isPresent == "true" || (window.threadDataIsEditable && window.threadComputedData.attendees.length == 0 && window.currentToCC.indexOf(informations.email.toLowerCase()) > -1),
                isClient: informations.isClient == "true",
                isThreadOwner: false,
                hasMissingInformations: false,
                missingInformationsTemp: {}
            });

            if((a.firstName == '' || a.firstName == undefined) && (a.lastName == '' || a.firstName == undefined))
                a.firstName = a.usageName;

            $scope.attendees.push(a);
        };

        this.fetchAttendeeFromClientContactNetwork = function(){
            $('.submit-classification').attr('disabled', true);
            $http({
                url: '/client_contacts/fetch?client_email=' + window.threadAccount.email,
                method: "GET",
                params: {"contacts_emails[]": _.map(window.currentAttendees, function( a ){
                    return a.email;
                })}
            }).then(function success(attendeesDetails) {
                $('.submit-classification').attr('disabled', false);
                attendeesCtrl.loaded = true;
                attendeesCtrl.populateAttendeesDetails(attendeesDetails.data);
            }, function error(response){
                attendeesCtrl.loaded = true;
                console.log("Error: ", response);
            });

        };
        //--------------------------------------------------------------------------------

        //Event Notes---------------------------------------------------------------------
        $scope.updateNotes = function(){
            var notes = $('#notes').val();

            var wrappedContactInfos = '';
            var computedContactInfos = '';

            var i = 0;
            var j = 0;

            _.each($scope.attendees, function(a){
                // In any case if the attendee's company is not set and it is not the threadOwner (even on his aliases), we will mark the informations in the notes
                if(a.isPresent && ((a.company == '' && $scope.getThreadOwnerEmails().indexOf(a.email) == -1 ) || a.company != $scope.getThreadOwner().company)){
                    if(a.hasCallingInformations()){
                        // In case if the first contacts doesn't have any informations so it doesn't print a carriage return

                        if(j > 0)
                            computedContactInfos += "\n";
                        j++;
                    }
                    computedContactInfos += a.computeContactNotes($("input[name='locale']:checked").val());
                    i++;
                }
            });

            if(computedContactInfos != ''){
                wrappedContactInfos += "-" + localize("events.call_instructions.contacts_infos", {locale: window.currentLocale}) + "-------------------";
                wrappedContactInfos += computedContactInfos;
                wrappedContactInfos += "\n----------------------------------------";
            }

            var tmpNotes = notes.replace(/\n/g,'');
            var regexFrResult = contactInfosReFr.exec(tmpNotes);
            var regexEnResult = contactInfosReEn.exec(tmpNotes);

            if(regexFrResult == null && regexEnResult == null){
                if(notes.replace(/\n/g,'').length > 0)
                    notes += "\n\n";
                notes += wrappedContactInfos;
            }else{
                // Maybe use contactInfosReFr and contactInfosReEn in place of regexFrResult and regexEnResult
                var usedRegex = regexFrResult != null ? regexFrResult : regexEnResult;
                notes = notes.replace(/\n/g,'__n').replace(usedRegex, wrappedContactInfos).replace(/(__n){2,}/g, '\n\n').replace(/__n/g, "\n");
            }

            $('#notes').val(notes);
        };
        //--------------------------------------------------------------------------------

        //Thread Owner--------------------------------------------------------------------
        $scope.getThreadOwner = function(){
            if($scope.threadOwner == undefined){
                $scope.threadOwner = _.find($scope.attendees, function(a){
                    return a.isThreadOwner;
                });
            }
            return $scope.threadOwner;
        };

        $scope.getThreadOwnerEmails = function(){
            var emails = [];
            emails.push(window.threadAccount.email);
            emails.push(window.threadAccount.email_aliases);
            return _.flatten(emails);
        };
        //--------------------------------------------------------------------------------

        //Helpers-------------------------------------------------------------------------

        $scope.displayAttendeesInformations = function(){
            var currentAppointment = window.getCurrentAppointment();

            return (currentAppointment && currentAppointment.required_additional_informations != 'empty');
        };

        $scope.getAttendeeByGuid = function(guid) {
            return _.find($scope.attendees, function (a) {
                return a.guid == guid;
            });
        };

        $scope.getAttendeesWithoutThreadOwner = function(){
            return _.filter($scope.attendees, function (a) {
                return $scope.getThreadOwnerEmails().indexOf(a.email) == -1 && a.isPresent;
            });
        };

        $scope.getAssistant = function(attendee){
            return _.find($scope.attendees, function(a){
                return a.guid == attendee.assistedBy.guid;
            });
        };

        $scope.getAssisted = function(assistant){
            return _.find($scope.attendees, function(a){
                var found = false;
                if(a.assistedBy)
                    found = a.assistedBy.guid == assistant.guid;
                return found;
            });
        };

        $scope.getAssistedByEmail = function(assistant){
            return _.find($scope.attendees, function(a){
                var found = false;
                if(a.assistedBy)
                    found = a.assistedBy.email == assistant.email;
                return found;
            });
        };

        $scope.getAttendeesOnPresence = function(isPresent){
            return _.filter($scope.attendees, function(a) {
                return a.isPresent == isPresent;

            });
        };

        $scope.lookupAttendeesMissingInfos = function(){
            if($("select#appointment_nature").val()){
                var attendeesFromOtherCompanies = _.filter($scope.getAttendeesFromOtherCompanies(),function(att){
                    return !att.isClient && att.isPresent;
                });

                // When we are in a virtual appointment and targeting an interlocutor, we don't care for the missing informations

                $scope.missingInformationLookedFor = window.getCurrentAppointment().required_additional_informations;
                var methodToCheck;

                switch($scope.missingInformationLookedFor){
                    case 'mobile_only':
                        methodToCheck = 'has_mobile';
                        break;
                    case 'skype_only':
                        methodToCheck = 'has_skype';
                        break;
                    case 'landline_or_mobile':
                        methodToCheck = 'has_mobile_or_landline';
                        break;
                    default:
                        methodToCheck = 'empty';
                        break;
                }

                // We check on attendees that are not in the threadOwner company nor are client at Julie Desk and are present
                _.each(attendeesFromOtherCompanies, function(a){
                    a.hasMissingInformations = methodToCheck == 'empty' ? false : !a[methodToCheck]();
                });

            }
        };

        this.displayMissingInformationsText = function(){
            var text = '';
                switch($scope.missingInformationLookedFor){
                    case 'mobile_only':
                        text = 'Tel Mob. manquant';
                        break;
                    case 'skype_only':
                        text = 'Skype manquant';
                        break;
                    case 'landline_or_mobile':
                        text = 'Tel Mob. ou Fix. manquant';
                        break;
                }
            return text;
        };

        // We use that on the input blur event when setting the missing informations from the attendees details thumbnail to avoid having the input disappear after the first character is entered
        // Currently not used anymore but maybe in future who knows...
        $scope.setAttendeeProperty = function(attendee, property, value){
            attendee[property] = attendee.missingInformationsTemp[property];
            attendee.missingInformationsTemp[property] = '';
        };

        $scope.missingInformationAttendeesFilter = function(attendee){
            var attendeeFromSameCompanyWithInfos = _.find($scope.getAttendeesOnPresence(true), function(a){
                return a.company != '' && a.guid != attendee.guid && a.company == attendee.company && !a.hasMissingInformations;
            });

            return (attendee.usageName && attendee.usageName.length > 0 && !!(attendee.email || (!attendee.email && attendee.assistedBy && attendee.assistedBy.guid)) && !attendeeFromSameCompanyWithInfos);
        };

        $scope.checkMissingInformations = function(params){
            params = params || {};
            var check = true;
            var result = {missingInfos: false, attendeesNames: [], assisted: false};
            var methodToCheck;
            var message = '';
            var presentAttendees;
            var presentAttendeesLength = 0;

            if($("select#appointment_nature").val()){
                result.infoScope = window.getCurrentAppointment().required_additional_informations;

                if(result.infoScope != 'empty'){
                    switch(result.infoScope){
                        case 'mobile_only':
                            methodToCheck = 'has_mobile';
                            break;
                        case 'skype_only':
                            methodToCheck = 'has_skype';
                            break;
                        case 'landline_or_mobile':
                            methodToCheck = 'has_mobile_or_landline';
                            break;
                    }

                    if(params.ask_early_call){
                        if($scope.virtualAppointmentsHelper && $scope.virtualAppointmentsHelper.currentConf.target != 'interlocutor')
                            check = false;
                    }else if(params.ask_early_skype) {
                        // let check at true
                    }
                    else{
                        if($scope.virtualAppointmentsHelper && $scope.virtualAppointmentsHelper.currentConf.target == 'interlocutor')
                            check = false;
                    }

                    if(check){
                        presentAttendees = $scope.getAttendeesWithoutAssistant();
                        presentAttendeesLength = presentAttendees.length;

                        var attendeesWithMissingInfos = $scope.getAttendeesWithMissingInfos(presentAttendees);

                        if(attendeesWithMissingInfos.length > 0){
                            if(presentAttendeesLength == 2){
                                // We can assess that if there is only one attendee (not counting assistants) plus the threadOwner and the attendeesMissingInfos array is not empty that the first item in this array is our only attendee
                                // So we can access it to check whether it is assited by someone

                                result.assisted = !!attendeesWithMissingInfos[0].assistedBy && !!attendeesWithMissingInfos[0].assistedBy.guid;
                            }

                            _.each(attendeesWithMissingInfos, function(a){
                                if($scope.missingInformationAttendeesFilter(a, attendeesWithMissingInfos)){
                                    var names = a.usageName.split(" ");
                                    if(names.length > 0) {
                                        result.attendeesNames.push(window.helpers.capitalize(names[0]));
                                    }
                                }
                            });

                            if(result.attendeesNames.length > 0)
                                result.missingInfos = true;
                        }
                    }
                }
            }

            if(result.missingInfos){
                var message = params.sticky ? "\n" : "\n\n";
                message += window.generateEmailTemplate({
                    action: 'ask_additional_informations',
                    requiredAdditionalInformations: result.infoScope,
                    assisted: result.assisted,
                    attendees: result.attendeesNames,
                    // More than one attendee including the threadOwner
                    multipleAttendees: presentAttendeesLength > 2,
                    redundantCourtesy: params.redundantCourtesy || false,
                    locale: window.threadComputedData.locale
                });
            }

            return message;
        };

        $scope.getAttendeesFromOtherCompanies = function(){
            var threadOwner = $scope.getThreadOwner();
            return _($scope.attendees).filter(function(a) {
                return a.company !== threadOwner.company;
            });
        };

        $scope.getAttendeesWithoutAssistant = function() {
            var attendees = $scope.getAttendeesOnPresence(true).slice();

            _.each(attendees.slice(), function (a) {
                if (a.assistedBy && a.assistedBy.guid) {
                    attendees = _.without(attendees, _.findWhere(attendees, {guid: a.assistedBy.guid}));
                }
            });

            return attendees;
        };

        $scope.getAttendeesWithMissingInfos = function(attendees){
            return _.filter(attendees, function(a){
                return a.hasMissingInformations;
            });
        };

        this.getCurrentContactsInfosEn = function(notes){
            return contactInfosReEn.exec(notes);
        };

        this.getCurrentContactsInfosFr = function(notes){
            return contactInfosReFr.exec(notes);
        };

        this.getCompaniesNames = function(){
            return _.uniq(_.compact(_.map($scope.attendees, function(a) {
                if(a.company != '' &&  a.company != undefined)
                    return a.company;
            })));
        };

        this.getEmailsSuggestions = function(subString){
            return $http.get("/client_contacts/emails_suggestions?sub_string=" + subString).then(function(response){
                return response.data;
            });
        };

        this.displayAttendeeNewForm = function (){
            sharedProperties.displayAttendeeForm({attendee: {timezone: window.threadAccount.default_timezone_id, isPresent: true}, action: 'new'});
        };

        this.displayAttendeeUpdateForm = function(attendee){
            sharedProperties.displayAttendeeForm({attendee: attendee, action: 'update'});
        };

        $scope.guid = function(){
            return generateGuid();
        };
        //--------------------------------------------------------------------------------

        //Initializers--------------------------------------------------------------------
        this.fetchAttendeeFromClientContactNetwork();
        //--------------------------------------------------------------------------------

    }]);

    function generateGuid() {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }
        return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
            s4() + '-' + s4() + s4() + s4();
    }
    
    var Class = function(methods) {
        var klass = function() {
            this.initialize.apply(this, arguments);
        };

        for (var property in methods) {
            klass.prototype[property] = methods[property];
        }

        if (!klass.prototype.initialize) klass.prototype.initialize = function(){};

        return klass;
    };

    var Attendee = Class({
        initialize: function(params){
            var that = this;
            if(params.guid == undefined)
                that['guid'] = generateGuid();

            $.each( params, function( key, value ) {
                that[key] = value;
            });
        },
        displayGender: function(){
            var displayedGender = '';
          if(this.gender){
              switch(this.gender){
                  case('M'):
                      displayedGender = 'M.';
                      break;
                  case('F'):
                      displayedGender = 'Mme.';
                      break;
                  default:
                      displayedGender = '';
                      break;
              }

          }
            return displayedGender;
        },
        assistantDisplayText: function(){
            var name = '';
            if(this.assistedBy != undefined)
                name = (this.assistedBy.usageName || this.assistedBy.displayName) + ' (' + this.assistedBy.email + ')';
            return name;
        },
        displayNormalizedName: function(){
            var _lastName = (this.lastName == undefined || this.lastName == null) ? '' : this.lastName;
            var _firstName = (this.firstName == undefined || this.firstName == null) ? '' : this.firstName;
            var separator = (_firstName == '' || _lastName == '') ? '' : ' ';
            var name = _firstName + separator + _lastName;
            return name || this.email;
        },
        hasPhoneInformations: function(){
          return ((this.mobile != undefined && this.mobile != null && this.mobile != '') || (this.landline != undefined && this.landline != null && this.landline != ''))
        },
        hasSkype: function(){
            return this.skypeId != undefined && this.skypeId != null && this.skypeId != '';
        },
        hasCallingInformations: function(){
          return this.hasSkype() || this.hasPhoneInformations();
        },
        displayPhoneInformations: function(){
            var _mobile = (this.mobile == undefined || this.mobile == null) ? '' : this.mobile;
            var _landline = (this.landline == undefined || this.landline == null) ? '' : this.landline;
            var separator = (_mobile == '' || _landline == '') ? '' : ' / ';

            return _mobile + separator + _landline;
        },
        displayRescuePhoneInformations: function(landline, mobile){
            var _mobile = (mobile && this.mobile) ? this.mobile : '';
            var _landline = (landline && this.landline) ? this.landline : '';
            var separator = (_mobile == '' || _landline == '') ? '' : ' / ';

            return _mobile + separator + _landline;
        },
        getName: function(){
            return this.usageName || this.email;
        },
        has_mobile_or_landline: function(){
            return this.has_mobile() || this.has_landline();
        },
        has_mobile: function(){
            return Boolean(this.mobile);
        },
        has_landline: function(){
            return Boolean(this.landline);
        },
        has_skype: function(){
            return Boolean(this.skypeId);
        },
        computeContactNotes: function(locale){
            var notes = "";
            var that = this;
            var hasPhoneInfos = that.hasPhoneInformations();
            var hasSkype = that.hasSkype();

            if(this.hasCallingInformations()){
                notes += "\n";
                switch(locale)
                {
                    case 'fr':
                        notes += that.displayNormalizedName() + "\n";
                        if(hasPhoneInfos){
                            notes += 'Téléphone : ' + that.displayPhoneInformations();
                            if(hasSkype)
                                notes += "\n";
                        }
                        if(hasSkype)
                            notes += 'Skype : ' + that.skypeId;
                        break;
                    case 'en':
                        notes += that.displayNormalizedName() + "\n";
                        if(hasPhoneInfos){
                            notes += 'Phone Number: ' + that.displayPhoneInformations();
                            if(hasSkype)
                                notes += "\n";
                        }
                        if(hasSkype)
                            notes += 'Skype: ' + that.skypeId;
                        break;
                    default:
                        notes += that.displayNormalizedName() + "\n";
                        if(hasPhoneInfos){
                            notes += 'Téléphone : ' + that.displayPhoneInformations();
                            if(hasSkype)
                                notes += "\n";
                        }
                        if(hasSkype)
                            notes += 'Skype : ' + that.skypeId;
                }
            }

            return notes;
        }
    });
})();


