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
                        attendeesFormCtrl.attendeeInForm = new Attendee({});

                    attendeesFormCtrl.setAttendeeInForm(args.attendee);
                    attendeesFormCtrl.checkIfTimezoneNeeded($('#appointment_nature').val());

                    // Need to encapsulate the function in a setTimeout because otherwise It doesn't update the select correctly
                    setTimeout(function(){
                        attendeesFormCtrl.setCorrectAssistedBy();
                    }, 0);

                    attendeesFormCtrl.isVisible = true;
                    $('.messages-thread-info-panel').removeClass('scrollable').addClass('frozen');
                });

                $scope.init = function() {
                    $('#attendees_form_submit_btn').tooltip({});
                };

                this.sanitizeContent = function(attribute){
                    this.attendeeInForm[attribute] = this.attendeeInForm[attribute].trim();
                };

                this.cancelAttendeeForm = function(){
                    Object.assign(attendeesFormCtrl.attendeeInForm, originalAttendee);
                    attendeesFormCtrl.isVisible = false;
                    $('.messages-thread-info-panel').removeClass('frozen').addClass('scrollable');
                };

                this.addAttendee = function(){
                    // if(this.attendeeInForm.usageName == '' || this.attendeeInForm.usageName === undefined)
                    //     this.attendeeInForm.usageName = this.attendeeInForm.firstName;

                    if(this.attendeeInForm.company === undefined)
                        this.attendeeInForm.company = '';

                    if(this.attendeeInForm.firstName)
                        this.sanitizeContent('firstName');

                    if(this.attendeeInForm.lastName)
                        this.sanitizeContent('lastName');

                    // if(this.attendeeInForm.usageName)
                    //     this.sanitizeContent('usageName');

                    if(this.attendeeInForm.timezone)
                        this.sanitizeContent('timezone');

                    if(this.attendeeInForm.needAIConfirmation)
                        this.attendeeInForm.confirmAI();

                    this.attendeeInForm.validatedCompany = this.attendeeInForm.company;

                    this.attendeeInForm.name = this.attendeeInForm.firstName + ' ' + this.attendeeInForm.lastName;

                    this.attendeeInForm.alreadySetPresent = this.attendeeInForm.isPresent;

                    if(attendeesFormCtrl.currentMode == 'new')
                    {
                        sharedProperties.notifyAttendeeAdded(this.attendeeInForm);
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
                                assisted.assistedBy.displayName = this.attendeeInForm.computeUsageName();
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

                this.isFormValid = function(attendeesForm) {
                    var noFormError = jQuery.isEmptyObject(attendeesForm.email.$error);
                    var attendeeInForm = $scope.attendeesFormCtrl.attendeeInForm;
                    var fullName = (!$.isEmptyObject(attendeeInForm) && attendeeInForm.fullName()) || '';

                   return noFormError && fullName.length > 0;
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

                // For testing purposes
                this.getOriginalAttendee = function(){
                    return originalAttendee;
                };

                
                this.importContactInfos = function(){
                    $http({
                        url: '/client_contacts/fetch_one?client_email=' + attendeesFormCtrl.getThreadOwner().email + '&email=' + attendeesFormCtrl.attendeeInForm.email,
                        method: "GET"
                    }).then(function success(response) {
                        if(response.data.error) {
                            attendeesFormCtrl.setAttendeeInFormDetails({email: attendeesFormCtrl.attendeeInForm.email});
                        } else {
                            attendeesFormCtrl.setAttendeeInFormDetails(response.data);
                        }

                    }, function error(response){
                        console.log("Error: ", response);
                    });
                };

                this.getThreadOwner = function(){
                    return attendeesManager.getThreadOwner();
                };

                this.setAttendeeInFormDetails = function(attendeeDetails){
                    //attendeesFormCtrl.attendeeInForm = {isPresent: true};
                    if(attendeeDetails.assistedBy)
                        attendeeDetails.assistedBy = JSON.parse(attendeeDetails.assistedBy);
                    Object.assign(attendeesFormCtrl.attendeeInForm, attendeeDetails);
                };
                
                $scope.init();

            }],
            controllerAs: 'attendeesFormCtrl'
        };
    });

    app.controller("AttendeesCtrl", ['$scope', '$rootScope','sharedProperties', '$http', function($scope, $rootScope, sharedProperties, $http){
        var attendeesCtrl = this;
        var contactInfosReFr = new RegExp("-" + localize("events.call_instructions.contacts_infos", {locale: 'fr'}) + "-------------------.+?(?:----------------------------------------)");
        var contactInfosReEn = new RegExp("-" + localize("events.call_instructions.contacts_infos", {locale: 'en'}) + "-------------------.+?(?:----------------------------------------)");

        var excludedAttendeesEmails = ['support@juliedesk.com', 'hello@juliedesk.com'];

        $scope.displaySearchList = false;
        $scope.attendeeSearchFilter = '';
        $scope.currentlySelectedSearchedAttendeeIndex = -1;

        // Used for the actions tracking (provide some context on the tracking like the id of the tracking in the form of
        // operator_id-messagesThreadId
        var messagesContainerNode = $('#messages_container');
        if(messagesContainerNode.length > 0) {
            var messagesThreadId = messagesContainerNode.data('messages-thread-id');
            var trackingId = messagesContainerNode.data('operator-id').toString() + '-' + messagesThreadId.toString();
        }


        angular.element(document).ready(function () {
            $scope.virtualAppointmentsHelper = $('#virtual-meetings-helper').scope();
            $scope.messageBuilder = $scope.messageBuilder || $('#reply-area').scope();
        });

        $scope.readyToOpenCalendar = false;

        this.loaded = false;
        $scope.attendees = [];
        $scope.missingInformationLookedFor = '';
        $scope.displayAttendeesTimezone = false;
        this.readOnly = window.threadDataIsEditable == undefined;
        this.usageNamev2Enabled = window.featuresHelper.isFeatureActive('usage_name_v2');

        $scope.meetingRoomsManager = $scope.meetingRoomsManager || $('#meeting-rooms-manager').scope();

        //Watchers------------------------------------------------------------------------
        $scope.$watch('attendees', function (newVal, oldVal){
            updateNotesCallingInfos();

            if(newVal.length > 0){
                $rootScope.$broadcast('attendeesRefreshed', {attendees: $scope.attendees});
                $scope.lookupAttendeesMissingInfos();
                $scope.setTitlePreference();
                processAppointmentType();
                //$scope.postProcessAttendees();
            }
        }, true);

        $scope.$watch('attendeeSearchFilter', function(newVal, oldVal) {
            $scope.displaySearchList = newVal != '';
            $scope.currentlySelectedSearchedAttendeeIndex = - 1;
            $scope.resetHighlightedAttendeeInSearch();
        });
        //--------------------------------------------------------------------------------

        //Events Listeners----------------------------------------------------------------
        $scope.$on('attendeeAdded', function(event, args) {
            $scope.attendees.push(args.attendee);
        });

        angular.element(document).ready(function () {
            $scope.meetingRoomsManager = $scope.meetingRoomsManager || $('#meeting-rooms-manager').scope();

            if($scope.meetingRoomsManager) {
                $scope.meetingRoomsManager.$on('meetingRoomsInitialized', function(event, args) {
                    if($scope.readyToOpenCalendar && !window.currentCalendar && window.drawCalendarCallback)
                        window.drawCalendarCallback();
                });
            }
        });
        //--------------------------------------------------------------------------------

        //Attendees-----------------------------------------------------------------------

        //$scope.postProcessAttendees = function() {
        //    var languageLevel = window.threadAccount.language_level;
        //
        //    _.each($scope.attendees, function(attendee) {
        //        $scope.formatUsageName(languageLevel, attendee);
        //
        //
        //    });
        //};

        $scope.keydownAttendeesSearchAction = function(event) {
            var availableAttendeesInSearch = _.sortBy($scope.getRegisteredAvailableAttendees(), function(att) {
                return att.company;
            });

            switch(event.keyCode) {
                case 13:
                    availableAttendeesInSearch[$scope.currentlySelectedSearchedAttendeeIndex].isPresent = true;
                    availableAttendeesInSearch[$scope.currentlySelectedSearchedAttendeeIndex].alreadySetPresent = true;
                    $scope.resetAttendeesSearch();
                    break;
                case 38:
                    if($scope.currentlySelectedSearchedAttendeeIndex > 0) {
                        $scope.resetHighlightedAttendeeInSearch();
                        $scope.currentlySelectedSearchedAttendeeIndex -= 1;
                        availableAttendeesInSearch[$scope.currentlySelectedSearchedAttendeeIndex].highligthedInSearch = true;
                    }

                    break;
                case 40:
                    if($scope.currentlySelectedSearchedAttendeeIndex < availableAttendeesInSearch.length - 1) {
                        $scope.resetHighlightedAttendeeInSearch();
                        $scope.currentlySelectedSearchedAttendeeIndex += 1;
                        availableAttendeesInSearch[$scope.currentlySelectedSearchedAttendeeIndex].highligthedInSearch = true;
                    }
                    break;
            }
        };

        $scope.resetAttendeesSearch = function() {
            $scope.attendeeSearchFilter = '';
            // Sometime when a new attendee is added a display bug occure, hiding/showing the attendees seems to fix it
            setTimeout(function(){
                $('.contact').hide().show(0);
            }, 10);
        };

        $scope.resetHighlightedAttendeeInSearch = function() {
            _.each($scope.getRegisteredAvailableAttendees(), function(att) {
                att.highligthedInSearch = false;
            });
        };

        $scope.updateAttendeesUsageName = function() {
            // _.each($scope.attendees, function(attendee) {
            //     $scope.formatUsageName(attendee);
            // });

        };

        $scope.formatUsageName = function(attendee) {
            //attendee.dispatchUsageName();
            // if(window.threadAccount.language_level == 'soutenu') {
            //     attendee.usageName = attendee.displayUsageNameSoutenu();
            // }
        };

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
                var emailValid = true;
                var emailLowCase = attendee.email ? attendee.email.toLowerCase() : undefined;

                // Very simplistic test to discard false emails (which doesn't contains an '@')
                if(attendee.email && attendee.email.indexOf('@') === -1)
                    emailValid = false;

                return (threadOwnerEmailAliasesDowncase.indexOf(emailLowCase) == -1) && (emailLowCase != window.threadAccount.email.toLowerCase()) && (excludedAttendeesEmails.indexOf(emailLowCase) == - 1) && emailValid
            }), function(attendee) {
                var attendeeDetails = _.find(attendeesDetails.contacts, function(a) {
                    var searchedEmail = attendee.email;

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

                if(companies[informations.email]) {
                    informations.company = companies[informations.email];
                }

                //If the current email is the principal email for a user
                // if(aliasedEmails.indexOf(informations.email) > -1) {
                //     //informations.isClient = "true";
                //     //informations.company = companies[informations.email];
                //
                //     // If it is in the recipients, we create the attendee, because if there will be an alias for this email in the recipients, it will be discarded
                //     if(window.currentToCC.indexOf(informations.email.toLowerCase()) > -1) {
                //         attendeesCtrl.createAttendee(informations, attendee);
                //      // If it is not in the recipients, we check to see if an alias for this email is in the recipients, if not we create the attendee, if yes we don't because we will use the alias instead
                //     }else{
                //         var aliasInTheRecipients = false;
                //
                //         // Check if an alias for this email is in the recipients
                //         _.each(aliases[informations.email], function(alias){
                //             if(window.currentToCC.indexOf(alias.toLowerCase()) > -1)
                //                 aliasInTheRecipients = true;
                //         });
                //         // If yes we don't create the attendee, because we will use the alias
                //         if(aliasInTheRecipients){
                //
                //          // If no, we use the main email and we create the attendee
                //         }else{
                //             attendeesCtrl.createAttendee(informations, attendee);
                //         }
                //     }
                //     // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client
                //
                //  // If the current email is an alias for a client
                // } else if(aliasEmails.indexOf(informations.email) > -1) {
                //     //informations.isClient = "true";
                //
                //     //We find the client main email
                //     var clientMainEmail;
                //     _.each(aliases, function (aliases, aliased) {
                //         if (aliases.indexOf(informations.email) > -1)
                //             clientMainEmail = aliased;
                //     });
                //
                //     if(clientMainEmail)
                //         informations.company = companies[clientMainEmail];
                //
                //     // We found the client main email and it is the recipients, so we will use it as the attendee, we do nothing here
                //     if (clientMainEmail && window.currentToCC.indexOf(clientMainEmail.toLowerCase()) > -1) {
                //     }
                //     // If we found it or not and it is not in the recipients, we can create the attendee
                //     else {
                //         // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client
                //         attendeesCtrl.createAttendee(informations, attendee);
                //     }
                //     // If the email is not an aliased email nor a alias email, we create the attendee
                // }

                if(aliasedEmails.indexOf(informations.email) > -1) {
                    // If main email is not in recipients we will check which alias is, so we will use it, in case several are present we will use the first found
                    if(window.currentToCC.indexOf(informations.email.toLowerCase()) == -1) {
                        var firstUsedAlias = _.find(aliases[informations.email], function(alias){
                            return window.currentToCC.indexOf(alias.toLowerCase()) > -1;
                        });

                        if (firstUsedAlias) {
                            informations.email = firstUsedAlias;
                        }
                    }
                } else if (aliasEmails.indexOf(informations.email) > -1) {
                    //informations.isClient = "true";

                    //We find the client main email
                    var clientMainEmail;
                    _.each(aliases, function (aliases, aliased) {
                        if (aliases.indexOf(informations.email) > -1)
                            clientMainEmail = aliased;
                    });

                    if(clientMainEmail)
                        informations.company = companies[clientMainEmail];
                }

                attendeesCtrl.createAttendee(informations, attendee);
            });

            // We store here the domain extracted from the attendees that have no company set
            // This will allow us to query the backend only one if there are multiple attendees with the same domain
            var attendeesDomainsWithoutCompany = new Set;
            angular.forEach($scope.attendees, function(a){
                var assisted = undefined;
                if(assisted = $scope.getAssistedByEmail(a)){
                    // We do that to actualize if necessary the temporary guid with the one returned by the database
                    assisted.assistedBy.guid = a.guid;
                }

                if(!a.isClient && !a.aIHasBeenConfirmed && !a.company && !!a.email) {
                    var attendeeDomain = a.email.substring(a.email.lastIndexOf("@") + 1);
                    attendeesDomainsWithoutCompany.add(attendeeDomain);
                }
            });

            if(attendeesDomainsWithoutCompany.size > 0) {
                var messageText = decodeURIComponent(window.messageText);

                attendeesDomainsWithoutCompany.forEach(function(domain) {
                    $scope.fetchCompanyByDomain(messageText, domain);
                });
            }

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

            var threadOwnerAttendee = _.find(window.currentAttendees, function(attendee) {
                return attendee.email == threadOwnerEmail;
            });

            var threadOwnerAttendeeTimezone = null;
            if(threadOwnerAttendee) {
                threadOwnerAttendeeTimezone = threadOwnerAttendee.timezone;
            }

            var threadOwner = new Attendee({
                guid: -1,
                email: threadOwnerEmail,
                email_aliases: window.threadAccount.email_aliases,
                firstName: threadAccountFullName[0],
                lastName: threadAccountFullName.splice(1, threadAccountFullName.length).join(' '),
                name: window.threadAccount.full_name,
                usageName: window.threadAccount.usage_name,
                gender: "Unknown",
                isAssistant: false,
                assisted: true,
                subscribed: window.threadAccount.subscribed,
                assistedBy: {email: window.currentJulieAlias.email, displayName: window.currentJulieAlias.name},
                company: companyName,
                validatedCompany: companyName,
                timezone: threadOwnerAttendeeTimezone || window.threadAccount.default_timezone_id,
                landline: window.threadAccount.landline_number,
                mobile: window.threadAccount.mobile_number,
                skypeId: window.threadAccount.skype,
                confCallInstructions: window.threadAccount.confcall_instructions,
                videoConferenceInstructions: window.threadAccount.video_conference_instructions,
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
            $scope.checkAssistantsPresence();
            $rootScope.$broadcast('attendeesRefreshed', {attendees: $scope.attendees});
            $rootScope.$broadcast('attendeesFetched', {attendees: $scope.attendees});
        };

        this.createAttendee = function(informations, attendee){
            var company = informations.company || '';
            var needAIConfirmation = informations.needAIConfirmation || false;

            var aIHasBeenConfirmed = informations.aIHasBeenConfirmed || false;

            var validatedCompany = needAIConfirmation ? '' : company;

            var attendeesLength = window.threadComputedData.attendees.length;

            var isPresent = attendee.isPresent == "true" || (window.threadDataIsEditable && attendeesLength == 0 && window.currentToCC.indexOf(informations.email.toLowerCase()) > -1);

            if(attendeesLength > 0 && informations.email) {
                var alreadyPresent = window.currentToCC.indexOf(informations.email.toLowerCase()) > -1;
            }
            var email = informations.email ? informations.email.toLowerCase() : undefined;

            var linkedAttendees = _.flatten(Object.values(window.threadComputedData.linked_attendees || {}));
            var isClient = informations.isClient == "true";
            var currentGender = ['M', 'F'].indexOf(informations.gender) == -1 ? "Unknown" : informations.gender;

            var a = new Attendee({
                accountEmail: attendee.account_email,
                guid: informations.id || $scope.guid(),
                email: email,
                email_aliases: informations.email_aliases || [],
                firstName: informations.firstName,
                lastName: informations.lastName,
                name: (informations.firstName + ' ' + informations.lastName).trim(),
                // Used for clients (is set in the admin panel)
                usageName: informations.usageName || informations.name,
                gender: currentGender,
                isAssistant: informations.isAssistant == "true",
                assisted: informations.assisted == "true",
                assistedBy: informations.assistedBy,
                subscribed: informations.subscribed == "true",
                company: company,
                validatedCompany: validatedCompany,
                timezone: informations.timezone || window.threadAccount.default_timezone_id,
                landline: informations.landline,
                mobile: informations.mobile,
                skypeId: informations.skypeId,
                confCallInstructions: informations.confCallInstructions,
                videoConferenceInstructions: informations.video_conference_instructions,
                isPresent: isPresent,
                alreadySetPresent: isPresent || alreadyPresent,
                isClient: isClient,
                needAIConfirmation: needAIConfirmation,
                aIHasBeenConfirmed: aIHasBeenConfirmed,
                isThreadOwner: false,
                hasMissingInformations: false,
                missingInformationsTemp: {},
                linkedAttendee: linkedAttendees.indexOf(email) > -1
            });

            if((a.firstName == '' || a.firstName == undefined) && (a.lastName == '' || a.lastName == undefined))
                a.firstName = a.usageName;

            //We ask the AI only when we are classifying an email and if the attendee is not a client
            if(window.isClassifying && !a.isClient && !a.aIHasBeenConfirmed) {

                // If he has no lastName it means it is the first time this contact is processed. So we ask the AI to
                // give us the civilities
                if(!a.lastName) {
                    var fullName = ("" + a.firstName).replace("'", "");
                    $http({
                        url: '/client_contacts/ai_parse_contact_civilities?fullname=' + fullName + '&email=' + a.email,
                        method: "GET"
                    }).then(function success(response) {
                        if(response.data.status == "success") {
                            a.firstName = response.data.first_name;
                            //a.usageName = response.data.first_name;
                            a.lastName = response.data.last_name;

                            a.needAIConfirmation = true;
                            a.validatedCompany = '';

                            a.firstNameAI = response.data.first_name;
                            a.lastNameAI = response.data.last_name;

                            switch(response.data.gender) {
                                case 'male':
                                    a.gender = 'M';
                                    break;
                                case 'female':
                                    a.gender = 'F';
                                    break;
                                case 'unknown':
                                    a.gender = "Unknown";
                                    break;
                            }
                        }

                        $scope.trackFetchFirstNameLastNameEvent({
                            is_error: (response.data.status == 'error' || response.data.status == 'invalid' || response.status == 'invalid' || response.data.error || false),
                            error_message: response.data.message,
                            contact_full_name: fullName,
                            contact_email_address: a.email,
                            first_name: response.data.first_name,
                            last_name: response.data.last_name,
                            gender: response.data.gender
                        });
                    }, function error(response) {
                        console.log(response);
                        $scope.trackFetchFirstNameLastNameEvent({
                            is_error: true,
                            contact_email_address: a.email
                        });
                    })
                }
            }

            if(!window.featuresHelper.isFeatureActive('usage_name_v2')) {
                //We compute the usage name based on the client language level preference only in the first pass of the form filling
                if(!window.threadComputedData.appointment_nature) {
                    a.dispatchUsageName();
                } else {
                    if(!a.computeUsageName()) {
                        a.dispatchUsageName();
                    }
                }
            }

            $scope.attendees.push(a);
        };

        $scope.fetchCompanyByDomain = function(messageText, searchedDomain) {
            // We fake an email with the specified domain to get retrocompatibility (we used to pass directly the attendee email)
            var fakeEmail = 'email@' + searchedDomain;

            $http({
                url: '/client_contacts/ai_get_company_name',
                method: "POST",
                data: { contact_address: fakeEmail, message_text: messageText }
            }).then(function success(response) {
                $scope.setCompanyOnUsersFromDomain(response.data, searchedDomain, messageText);
            }, function error(response) {
                console.log(response);
                $scope.trackGetCompanyNameEvent({
                    is_error: true
                });
            })
        };

        $scope.setCompanyOnUsersFromDomain = function(responseData, searchedDomain, messageText) {
            var setCompany = responseData.identification != "fail" && !responseData.error;
            var responseIsError = responseData.status == 'error' || responseData.status == 'invalid' || responseData.error || false;

            _.each($scope.attendees, function(attendee) {
                if(!!attendee.email && attendee.email.indexOf(searchedDomain) > -1 && !attendee.company) {

                    if(setCompany) {
                        attendee.company = responseData.company;
                        attendee.needAIConfirmation = true;
                        attendee.validatedCompany = '';

                        attendee.companyAI = responseData.company;
                    }

                    $scope.trackGetCompanyNameEvent({
                        identification: responseData.identification,
                        is_error: responseIsError,
                        error_message: responseData.message,
                        contact_email_address: attendee.email,
                        message_text: messageText,
                        company_name_found: responseData.company,
                        extra_checks: {database_id: responseData.database_id, database_domain: responseData.database_domain, security_check_is_empty: responseData.security_check_is_empty}
                    });
                }
            });
        };

        this.fetchAttendeeFromClientContactNetwork = function(){
            $('.submit-classification').attr('disabled', true);

            var currentAttendeesEmails = _.map(window.currentAttendees, function( a ){
                return a.email;
            });

            $http({
                url: '/client_contacts/fetch?client_email=' + window.threadAccount.email,
                method: "GET",
                params: {"contacts_emails[]": _.without(currentAttendeesEmails, '')}
            }).then(function success(attendeesDetails) {
                $('.submit-classification').attr('disabled', false);
                attendeesCtrl.loaded = true;
                attendeesCtrl.populateAttendeesDetails(attendeesDetails.data);
                $scope.exposeAttendeesToGlobalScope();
                $(".attendee-timezone").timezonePicker();
                $scope.displayExtendedInfos();
                $rootScope.$broadcast('attendeesInitialized', {attendees: $scope.attendees});
            }, function error(response){
                attendeesCtrl.loaded = true;
                console.log("Error: ", response);
            });
        };

        $scope.trackFetchFirstNameLastNameEvent = function(params) {

            window.trackEvent("ask_ai_first_name_last_name", {
                distinct_id: trackingId,
                thread_id: messagesThreadId,
                is_error: params.is_error,
                error_message: params.error_message,
                contact_full_name: params.contact_full_name,
                contact_email_address: params.contact_email_address,
                first_name: params.first_name,
                last_name: params.last_name,
                gender: params.gender
            });
        };

        $scope.trackGetCompanyNameEvent = function(params) {

            window.trackEvent("ask_ai_company_name", {
                distinct_id: trackingId,
                thread_id: messagesThreadId,
                is_error: params.is_error,
                error_message: params.error_message,
                identification: params.identification,
                contact_email_address: params.contact_email_address,
                message_text: params.message_text,
                company_name_found: params.company_name_found
            });
        };

        $scope.getDisplayedAttendees = function() {
          return _.filter($scope.attendees, function(a) {
             return (a.alreadySetPresent || !a.company || (a.company && a.isPresent));
          });
        };

        $scope.getRegisteredAvailableAttendees = function() {
            var filter = $scope.attendeeSearchFilter.toLowerCase();

            var filteredAttendees = _.filter($scope.attendees, function(a) {
                var computedSearchContent = [a.firstName, a.lastName, a.email].join(' ');

                var filtered = computedSearchContent.indexOf(filter) > -1;

                return !a.alreadySetPresent && filtered && a.company && !a.isPresent;
            });

            return _.filter(filteredAttendees, function(a) {
                var allEmails = a.email_aliases.concat(a.email);

                var authorizedEmail = false;
                _.each(allEmails, function(email) {
                    if(window.isAuthorizedAttendee(email)) {
                        authorizedEmail = true;
                    }
                });

               return authorizedEmail;
            });
        };

        // Check if every assistant is present as attendee
        // If not we remove him/her from the assisted client
        $scope.checkAssistantsPresence = function() {
            var presentAttendees = $scope.getAttendeesOnPresence(true);
            var presentAttendeesEmails = _.map(presentAttendees, function(att) { return att.email; });
            _.each(presentAttendees, function(att) {
                if(att.assistedBy && att.assistedBy.email) {
                    // If the assitant is not present as attendee
                    if(!(_.contains(presentAttendeesEmails, att.assistedBy.email))) {
                        att.assistedBy = null;
                        att.assisted = false;
                    }
                }
            })
        };

        $scope.confirmAIOnPresentAttendees = function() {
            _.each($scope.getAttendeesOnPresence(true), function(a) {
                a.confirmAI();
            });
        };

        $scope.exposeAttendeesToGlobalScope = function() {
            var threadAccountEmail = window.threadAccount.email;
            var recipientsManager = $('#recipients-manager').scope();

            window.otherAttendeesWithAccount = _.filter($scope.attendees, function (attendee) {
                return attendee.isPresent && attendee.isClient && attendee.accountEmail && attendee.accountEmail != threadAccountEmail;
            });
            window.otherAccountEmails = _.map(window.otherAttendeesWithAccount, function (attendee) {
                return attendee.accountEmail;
            });

            if(allowedAttendeesAreComputed && !allowedAttendeesAreComputed()) {
                window.addAllowedAttendeesEmails(window.otherAccountEmails);
            }

            if(recipientsManager)
                recipientsManager.initTokenInputs();

            window.clientAccountTilesScope.fetchOtherAccounts();

            // if(window.drawCalendarCallback)
            //     window.drawCalendarCallback();

            $scope.readyToOpenCalendar = true;
        };

        $scope.setTitlePreference = function() {
            if(!window.threadComputedData.title_preference && !window.titlePreferenceOverridden && window.threadAccount.title_preferences) {
                var onlyAttendeesFromSameCompany = $scope.getPresentAttendeesFromOtherCompanies().length == 0;
                var titlePreference = window.threadAccount.title_preferences.general;

                if(onlyAttendeesFromSameCompany) {
                    titlePreference = window.threadAccount.title_preferences.internal_meetings;
                }

                titlePreferencesSelection(titlePreference)
            }
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

        $scope.getUsedTimezones = function() {
            return _.compact(_.uniq(_.map($scope.attendees, function(attendee) {
                var timezone = undefined;

                if(attendee.isPresent && !attendee.isThreadOwner) {
                    timezone = attendee.timezone;
                }

                return timezone;
            })));
        };

        $scope.getLinkedAttendees = function() {
          return _.filter(angular.copy($scope.attendees), function(a) {
              var isLinked = a.isPresent && !a.isClient && a.linkedAttendee;

              if(isLinked) {
                  a.usageName = a.computeUsageName();
              }

            return isLinked
          });
        };

        $scope.getAttendeeByGuid = function(guid) {
            return _.find($scope.attendees, function (a) {
                return a.guid == guid;
            });
        };

        $scope.getAttendeeByEmail = function(email) {
            return _.find($scope.attendees, function (a) {
                return a.email == email;
            });
        };

        $scope.getNonClientAndNonAssistantAttendees = function() {
            return _.filter($scope.attendees, function (a) {
                return a.isPresent && !a.isClient && !a.isAssistant;
            });
        };

        $scope.getNonClientAndNonAssistantWithMissingInfosAttendees = function() {
            return _.filter($scope.attendees, function (a) {
                return a.hasMissingInformations && a.isPresent && !a.isClient && !a.isAssistant;
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

        $scope.getAttendeesWithEmailOnPresence = function(isPresent){
            return _.filter($scope.attendees, function(a) {
                return a.email && a.isPresent == isPresent;
            });
        };

        // Usage
        // First create some filters
        // var filter1 = $scope.createAttendeesFilter('isPresent')(true)
        // var filter2 = $scope.createAttendeesFilter('isClient')(true)

        // Then execute the search
        // var result = $scope.filterAttendees([filter1, filter2])

        $scope.filterAttendees = function(filters) {
            return _.filter($scope.attendees,function(attendee) {
               return _.all(filters, function(filter) {
                   return filter(attendee);
               })
            });
        };

        $scope.createAttendeesFilter = function(attr) {
            return function(val) {
                return function(attendee) {
                    return attendee[attr] === val;
                };
            };
        };

        $scope.getAttendeesWithoutClients = function() {
            return _.filter($scope.attendees, function(a) {
                return !a.isClient;
            });
        };

        $scope.getAttendeesOnlyClients = function() {
            return _.filter($scope.attendees, function(a) {
                return a.isClient;
            });
        };

        $scope.getAttendeesOnlyPresentClients = function() {
            return _.filter($scope.attendees, function(a) {
                return a.isClient && a.isPresent;
            });
        };

        $scope.currentAppointmentIsVirtual = function() {
            var currentAppointment = window.getCurrentAppointment();
            return currentAppointment &&
                currentAppointment.appointment_kind_hash &&
                currentAppointment.appointment_kind_hash.is_virtual;
        };


        $scope.displayExtendedInfos = function(){
            return $scope.displayAttendeesTimezone = $scope.currentAppointmentIsVirtual();
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

            return (attendee.computeUsageName() && attendee.computeUsageName().length > 0 && !!(attendee.email || (!attendee.email && attendee.assistedBy && attendee.assistedBy.guid)) && !attendeeFromSameCompanyWithInfos);
        };

        $scope.mustAskCallInstructions = function(type){
            var result = false;
            var presentAttendees = $scope.getAttendeesWithoutAssistant();

            if(type == 'call'){
                // Ask if call instructions empty
                if($scope.virtualAppointmentsHelper && !$scope.virtualAppointmentsHelper.currentConf.details)
                    result = true;
            }else if(type == 'skype') {
                var attendeeNotClientWithASkype = _.find(presentAttendees, function(a) {
                    return !a.isClient && !a.hasMissingInformations;
                });
                // Don't ask skype informations early if any present attendee not being a client has already a skype
                if(!attendeeNotClientWithASkype)
                    result = true;
            }

            return result;
        };

        // By Nico on Nov 30, 2016
        // To get missing contact info (new rules from spec https://trello.com/c/eAt0Uzvt/137-3-julie-demande-le-numero-ou-le-lieu-en-avance-de-phase-pour-tous-les-types-de-rendez-vous)
        // Returns null | "mobile" | "skype" | "landline_or_mobile"
        // Returns a non-null value if and only if each one the attendees from other companies miss the required_additional information of the current appointment
        $scope.missingContactInfo = function() {
            // First, get contact info that
            var contactInfoNature = window.getCurrentAppointment().required_additional_informations;
            var methodToCheck;
            var result;
            switch(contactInfoNature){
                case 'mobile_only':
                    methodToCheck = 'has_mobile';
                    result = "mobile";
                    break;
                case 'skype_only':
                    methodToCheck = 'has_skype';
                    result = "skype";
                    break;
                case 'landline_or_mobile':
                    methodToCheck = 'has_mobile_or_landline';
                    result = "landline_or_mobile";
                    break;
                default:
                    // If no information required, returns null
                    return null;
                    break;
            }
            var presentAttendeesFromOtherCompanies = $scope.getPresentAttendeesFromOtherCompanies();
            if(presentAttendeesFromOtherCompanies.length == 0) {
                return null;
            }
            if(_.find(presentAttendeesFromOtherCompanies, function(a){
                return a[methodToCheck]();
            })) {
                return null
            }
            return result;
        };

        $scope.checkMissingInformations = function(params){
            params = params || {};
            var check = true;
            var result = {missingInfos: false, attendeesNames: [], assisted: false};
            var methodToCheck;
            var message = '';
            var presentAttendees = $scope.getAttendeesWithoutAssistant();
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

                    if($scope.virtualAppointmentsHelper && $scope.virtualAppointmentsHelper.currentConf.target == 'interlocutor')
                        check = false;

                    if(check){
                        presentAttendeesLength = presentAttendees.length;

                        var attendeesWithMissingInfos = $scope.getAttendeesWithMissingInfos(presentAttendees);

                        if(attendeesWithMissingInfos.length > 0){
                            _.each(attendeesWithMissingInfos, function(a){
                                if($scope.missingInformationAttendeesFilter(a, attendeesWithMissingInfos)){
                                    var names = a.computeUsageName().split(" ");
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
                message = params.sticky ? "\n" : "\n\n";
                message += $scope.messageBuilder.generateReply({
                    action: 'ask_additional_informations',
                    requiredAdditionalInformations: result.infoScope,
                    assisted: result.assisted,
                    attendees: result.attendeesNames,
                    // More than one attendee including the threadOwner
                    multipleAttendees: presentAttendeesLength > 2,
                    redundantCourtesy: params.redundantCourtesy || false,
                    //askingEarly: params.askingEarly || false,
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

        $scope.getPresentAttendeesFromOtherCompanies = function(){
            var threadOwner = $scope.getThreadOwner();
            if(!!threadOwner.company) {
                return _($scope.attendees).filter(function(a) {
                    return a.isPresent && a.company !== threadOwner.company;
                });
            } else {
                return $scope.attendees;
            }
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
                var suggestions = response.data;

                suggestions = _.filter(suggestions, function(suggestion) { return window.allowedAttendeesEmails.indexOf(suggestion) > -1; });
                suggestions = _.uniq(suggestions.concat(_.filter(window.allowedAttendeesEmails, function(allowedEmail) { return allowedEmail.indexOf(subString) > -1; })));
                
                return suggestions;
            });
        };

        this.displayAttendeeNewForm = function (){
            sharedProperties.displayAttendeeForm({attendee: $scope.generateNewAttendee(), action: 'new'});
        };

        this.displayAttendeeUpdateForm = function(attendee){
            sharedProperties.displayAttendeeForm({attendee: attendee, action: 'update'});
        };

        $scope.guid = function(){
            return generateGuid();
        };

        $scope.generateNewAttendee = function() {
          return new Attendee({timezone: window.threadAccount.default_timezone_id, isPresent: true});
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
        usingPictogram: function() {
          return this.isClient || this.linkedAttendee;
        },
        dispatchUsageName: function() {
            // if(this.usageNameManuallyModified) {
            //     return;
            // }
            // if(window.threadAccount.language_level == 'soutenu') {
            //     this.usageName = this.displayUsageNameSoutenu();
            // } else {
            //     this.setUsageName(this.firstName);
            // }
        },
        usageNameKeyup: function() {
          this.usageNameManuallyModified = true;
        },
        firstLastNameKeyup: function(){
            if(window.formFirstPass || this.needAIConfirmation) {
                this.dispatchUsageName();
            }
        },
        firstNameMirrored: function(){
            return (this.computeUsageName() == '' || this.computeUsageName() == undefined);
        },
        computeUsageName: function() {
            var that = this;
            var computedUsageName = '';

            if(window.featuresHelper.isFeatureActive('usage_name_v2')) {

                if(that.isClient) {
                    computedUsageName = that.usageName;
                } else {
                    var unknownGender = that.gender == "Unknown" || !that.gender;
                    var genderCode = unknownGender ? '_' : that.gender;
                    var translationKey = ["gender_reference", null, window.threadComputedData.language_level, genderCode];
                    var nameKey = null;
                    var computedName = null;
                    var genderDenomination = null;

                    var lastNamePresent = that.lastName && that.lastName.length > 0;
                    var firstNamePresent = that.firstName && that.firstName.length > 0;

                    if(window.threadComputedData.language_level == 'soutenu') {
                        if(lastNamePresent) {
                            if(unknownGender) {
                                if(firstNamePresent) {
                                    computedName = [that.firstName, that.lastName].join(' ');
                                }
                            } else {
                                computedName = that.lastName;
                                nameKey = 'with_name';
                            }
                        } else {
                            nameKey = 'without_name';
                        }
                    } else {
                        if(firstNamePresent) {
                            computedName = that.firstName;
                        } else if(lastNamePresent) {
                            if(that.gender != "Unknown") {
                                computedName = that.lastName;
                                nameKey = 'with_name';
                            }
                        } else {
                            nameKey = 'without_name';
                        }
                    }

                    if(nameKey) {
                        translationKey[1] = nameKey;
                        genderDenomination = localize(translationKey.join('.'), {locale: window.threadComputedData.locale});
                    }

                    computedUsageName = _.compact([genderDenomination, computedName]).join(' ') || null;
                }
            } else {
                computedUsageName = that.usageName;
            }

            return computedUsageName;
        },
        setUsageName: function(value) {
            // if(this.firstNameMirrored){
            //     this.usageName = value;
            //     this.usageNameManuallyModified = false;
            // }
            // else {
            //     this.usageNameManuallyModified = true;
            // }
        },
        confirmAI: function() {
            if(this.needAIConfirmation) {
                this.validatedCompany = this.company;
                this.needAIConfirmation = false;
                this.aIHasBeenConfirmed = true;

                this.trackAIResults();
            }
        },
        trackAIResults: function() {
            var messageId = $('.email.highlighted').attr('id');
            var that = this;

            var baseInfos = {
                message_id: messageId,
                contact_email_address: that.email
            };

            // Sometimes the AI will not be refetched, especially when a non present attendee is saved and not AI confirmed
            // When the form will be accessed again, the AI will not be queried again so we will not know what the first response of the AI was
            // SO ne no need to track it
            if(that.firstNameAI) {
                window.trackEvent("ai_first_name_detection", $.extend({
                        first_name_detected: that.firstNameAI,
                        first_name_confirmed: that.firstName,
                        ai_success_boolean: that.firstNameAI == that.firstName
                    }, baseInfos)
                );
            }

            if(that.lastNameAI) {
                window.trackEvent("ai_last_name_detection", $.extend({
                        last_name_detected: that.lastNameAI,
                        last_name_confirmed: that.lastName,
                        ai_success_boolean: that.lastNameAI == that.lastName
                    }, baseInfos)
                );
            }

            if(that.companyAI) {
                window.trackEvent("ai_company_name_detection", $.extend({
                        company_name_detected: that.companyAI,
                        company_name_confirmed: that.company,
                        ai_success_boolean: that.companyAI == that.company
                    }, baseInfos)
                );
            }
        },
        showAIConfirmation: function() {
          return this.isPresent && this.needAIConfirmation;
        },
        displayUsageNameSoutenu: function() {
            var displayedUsageName = '';
            var displayedGender = this.displayGender();
            var displayedName = this.lastName || this.firstName;

            if(displayedGender == '') {
                displayedName = this.displayNormalizedName();
            }

            return [displayedGender, displayedName].join(' ').trim();
        },
        displayGender: function(){
            var displayedGender = '';
            var currentLocale = window.currentLocale;

          if(this.gender){
              switch(this.gender){
                  case('M'):
                      displayedGender = localize("common.mister", {locale: currentLocale});
                      break;
                  case('F'):
                      displayedGender = localize("common.madam", {locale: currentLocale});
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
                name = ((this.assistedBy.computeUsageName && this.assistedBy.computeUsageName()) || this.assistedBy.displayName) + ' (' + this.assistedBy.email + ')';
            return name;
        },

        fullName: function() {
            return _.compact([this.firstName, this.lastName]).join(' ');
        },
        displayNormalizedName: function(){
            var that = this;
            var name = that.fullName();
            // var _lastName = (this.lastName == undefined || this.lastName == null) ? '' : this.lastName;
            // var _firstName = (this.firstName == undefined || this.firstName == null) ? '' : this.firstName;
            // var separator = (_firstName == '' || _lastName == '') ? '' : ' ';
            // var name = _firstName + separator + _lastName;
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
            return this.computeUsageName() || this.email;
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
        displayAsLinkedAttendee: function() {
            return this.linkedAttendee && !this.isClient;
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


