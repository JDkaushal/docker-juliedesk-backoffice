// Not accessible when loaded from the source files for some reasons
//= require jquery-ui
//= require timezone_picker

(function(){
    var app = angular.module('attendees-manager-controllers', ['templates', 'ngMessages', 'ui.bootstrap', 'ui.bootstrap.tpls']);

    app.directive('attendeesForm', function(){
        return {
            restrict: 'E',
            templateUrl: 'attendees-form.html',
            controller: [ '$scope', 'sharedProperties', function($scope, sharedProperties){
                var attendeesFormCtrl = this;
                var originalAttendee = {};
                var firstNameMirrored = false;
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

                    this.attendeeInForm.name = this.attendeeInForm.firstName + ' ' + this.attendeeInForm.lastName;

                    if(attendeesFormCtrl.currentMode == 'new')
                    {
                        sharedProperties.notifyAttendeeAdded(new Attendee(this.attendeeInForm));
                        console.log("Added" + attendeesFormCtrl.isVisible);
                    }else{
                        console.log("Updated");
                    }
                    attendeesFormCtrl.isVisible = false;
                    $('.messages-thread-info-panel').removeClass('frozen').addClass('scrollable');

                    // Need to wait a little in order for the ng-repeat to redraw its content and do set the data-name attribute correctly on the newly created contact
                    setTimeout(function(){
                        reProcessTitle();
                    }, 500);
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
                    // You must then update the selected option manually based on the text value for example

                    if(attendeesFormCtrl.attendeeInForm.assistedBy != "" && attendeesFormCtrl.attendeeInForm.assistedBy != undefined){
                        var selectedAssistedBy = attendeesFormCtrl.attendeeInForm.assistedBy.usageName;

                        angular.element($('#assisted_by option')).filter(function(){
                            return $(this).text().trim() == selectedAssistedBy;
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
            }],
            controllerAs: 'attendeesFormCtrl'
        };
    });

    app.controller("AttendeesCtrl", ['$scope','sharedProperties', '$http', function($scope, sharedProperties, $http){
        var attendeesCtrl = this;
        var contactInfosRe = new RegExp("-Contacts-Infos-------------------(.*)----------------------------------");

        this.loaded = false;
        $scope.attendees = [];
        this.readOnly = window.threadDataIsEditable == undefined;

        this.populateAttendeesDetails = function(attendeesDetails){
            // We filter the attendees to not include the threadOwner as we will add him after
            var companies = attendeesDetails.companies;
            var aliases = attendeesDetails.aliases;
            var aliasedEmails = Object.keys(aliases);
            var aliasEmails = _.flatten(_.map(aliases, function(aliases, email){
               return aliases;
            }));

            angular.forEach(window.currentAttendees.filter(function(attendee){
                return (window.threadAccount.email_aliases.indexOf(attendee.email)) == -1 && (attendee.email != window.threadAccount.email)
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
                var assistant = typeof(informations.assistedBy) == "string" ? JSON.parse(informations.assistedBy) : informations.assistedBy;
                informations.assistedBy = assistant;

                if(aliasedEmails.indexOf(informations.email) > -1)
                    informations.isClient = "true";
                if(Object.keys(companies).indexOf(informations.email) > -1)
                    informations.company = companies[informations.email];

                //If the current email is the principal email for a user
                if(aliasedEmails.indexOf(informations.email) > -1){

                    //if(informations.isClient != "true" && assistant != undefined && assistant != '' && assistant != null){
                    //    var alreadyExist = _.find(window.currentAttendees, function(a) {
                    //        return a.email == assistant.email;
                    //    });
                    //
                    //    if(alreadyExist == undefined) {
                    //        var assistantFullName = assistant.usageName || assistant.displayName;
                    //        attendeesCtrl.createAttendee({
                    //            email: assistant.email,
                    //            lastName: assistantFullName.split(' ').splice(1, assistantFullName.length).join(' '),
                    //            usageName: assistantFullName,
                    //            firstName: assistantFullName.split(' ')[0],
                    //            isAssistant: 'true',
                    //            timezone: informations.timezone
                    //        }, {});
                    //    }
                    //}

                    // If it is in the recipients, we create the attendee, because if there will be an alias for this email in the recipients, it will be discarded
                    if(window.currentToCC.indexOf(informations.email) > -1){

                        attendeesCtrl.createAttendee(informations, attendee);
                     // If it is not in the recipients, we check to see if an alias for this email is in the recipients, if not we create the attendee, if yes we don't because we will use the alias instead
                    }else{
                        var aliasInTheRecipients = false;

                        // Check if an alias for this email is in the recipients
                        _.each(aliases[informations.email], function(alias){
                            if(window.currentToCC.indexOf(alias) > -1)
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

                    //We find the client main email
                    var clientMainEmail;
                    _.each(aliases, function (aliases, aliased) {
                        if (aliases.indexOf(informations.email) > -1)
                            clientMainEmail = aliased;
                    });

                    // We found the client main email and it is the recipients, so we will use it as the attendee, we do nothing here
                    if (clientMainEmail && window.currentToCC.indexOf(clientMainEmail) > -1) {

                    }
                    // If we found it or not and it is not in the recipients, we can create the attendee
                    else{
                        //if(informations.isClient != "true" && assistant != undefined && assistant != '' && assistant != null){
                        //    var alreadyExist = _.find(window.currentAttendees, function(a) {
                        //        return a.email == assistant.email;
                        //    });
                        //
                        //    if(alreadyExist == undefined) {
                        //        var assistantFullName = assistant.usageName || assistant.displayName;
                        //        attendeesCtrl.createAttendee({
                        //            email: assistant.email,
                        //            lastName: assistantFullName.split(' ').splice(1, assistantFullName.length).join(' '),
                        //            usageName: assistantFullName,
                        //            firstName: assistantFullName.split(' ')[0],
                        //            isAssistant: 'true',
                        //            timezone: informations.timezone
                        //        }, {});
                        //    }
                        //}
                        // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client

                        attendeesCtrl.createAttendee(informations, attendee);
                    }
                    // If the email is not an aliased email nor a alias email, we create the attendee
                }else{
                    //if(informations.isClient != "true" && assistant != undefined && assistant != '' && assistant != null){
                    //    var alreadyExist = _.find(window.currentAttendees, function(a) {
                    //        return a.email == assistant.email;
                    //    });
                    //
                    //    if(alreadyExist == undefined) {
                    //        var assistantFullName = assistant.usageName || assistant.displayName;
                    //        attendeesCtrl.createAttendee({
                    //            email: assistant.email,
                    //            lastName: assistantFullName.split(' ').splice(1, assistantFullName.length).join(' '),
                    //            usageName: assistantFullName,
                    //            firstName: assistantFullName.split(' ')[0],
                    //            isAssistant: 'true',
                    //            timezone: informations.timezone
                    //        }, {});
                    //    }
                    //}

                    // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client

                    attendeesCtrl.createAttendee(informations, attendee);
                }
            });

            var threadAccountFullName = window.threadAccount.full_name.split(' ');
            var companyName = '';
            if(window.threadAccount.company_hash != undefined)
                companyName = window.threadAccount.company_hash.name;

            var threadOwnerEmail = window.threadAccount.email;
            if(window.threadAccount.email_aliases.length > 0){
                _.each(window.threadAccount.email_aliases, function(alias){
                    if(window.currentToCC.indexOf(alias) > -1){
                        threadOwnerEmail = alias;
                    }
                });
            }

            var threadOwner = new Attendee({
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
        };

        this.createAttendee = function(informations, attendee){
            var a = new Attendee({
                email: informations.email,
                firstName: informations.firstName,
                lastName: informations.lastName,
                name: informations.firstName + ' ' + informations.lastName,
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
                isPresent: attendee.isPresent == "true" || (window.threadDataIsEditable && window.threadComputedData.attendees.length == 0 && window.currentToCC.indexOf(informations.email) > -1),
                isClient: informations.isClient == "true",
                isThreadOwner: false
            });

            if((a.firstName == '' || a.firstName == undefined) && (a.lastName == '' || a.firstName == undefined))
                a.firstName = a.usageName;

            $scope.attendees.push(a);
        };

        this.displayAttendeeNewForm = function (){
            sharedProperties.displayAttendeeForm({attendee: {timezone: window.threadAccount.default_timezone_id, isPresent: true}, action: 'new'});
        };

        this.displayAttendeeUpdateForm = function(attendee){
            sharedProperties.displayAttendeeForm({attendee: attendee, action: 'update'});
        };

        $scope.$on('attendeeAdded', function(event, args) {
            $scope.attendees.push(args.attendee);
        });

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

        $scope.updateNotes = function(){
            var notes = $('#notes').val();

            var wrappedContactInfos = '';
            var computedContactInfos = '';

            var i = 0;
            var j = 0;
            _.each($scope.attendees, function(a){
                // In any case if the attendee's company is not set and it is not the threadOwner (even on his aliases), we will mark the informations in the notes
                if(a.isPresent && ((a.company == '' && attendeesCtrl.getThreadOwnerEmails().indexOf(a.email) == -1 ) || a.company != attendeesCtrl.getThreadOwner().company)){

                    console.log(i);
                    console.log(j);
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
                wrappedContactInfos += '-Contacts-Infos-------------------';
                wrappedContactInfos += computedContactInfos;
                wrappedContactInfos += "\n----------------------------------";
            }

            console.log(computedContactInfos);

            if(getCurrentContactsInfos(notes.replace(/\n/g,'')) == null)
            {
                notes += "\n" + wrappedContactInfos;
            }else{
                notes = notes.replace(/\n/g,'__n').replace(contactInfosRe, wrappedContactInfos).replace(/__n/g, "\n");
            }

            $('#notes').val(notes);
        };

        getCurrentContactsInfos = function(notes){
            return contactInfosRe.exec(notes);
        };

        this.getThreadOwner = function(){
            if(this.threadOwner == undefined){
                this.threadOwner = _.find($scope.attendees, function(a){
                    return a.isThreadOwner;
                });
            }
          return this.threadOwner;
        };

        this.getThreadOwnerEmails = function(){
            var emails = [];
            emails.push(window.threadAccount.email);
            emails.push(window.threadAccount.email_aliases);
            return _.flatten(emails);
        };

        this.fetchAttendeeFromClientContactNetwork();

        $scope.$watch('attendees', function (newVal, oldVal){$scope.updateNotes();}, true);

        this.getCompaniesNames = function(){
            return _.uniq(_.compact(_.map($scope.attendees, function(a) {
                if(a.company != '' &&  a.company != undefined)
                    return a.company;
            })));
        };

    }]);


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
            $.each( params, function( key, value ) {
                that[key] = value;
            });
        },
        assistantDisplayText: function(){
            var name = '';
            if(this.assistedBy != undefined)
                name = (this.assistedBy.usageName || this.assistedBy.displayName) + ' (' + this.assistedBy.email + ')';
            return name;
        },
        displayNormalizedName: function(){
            var _lastName = (this.lastName == undefined || this.lastName == null) ? '' : ' ' + this.lastName;
            var name = this.firstName + _lastName;
            return name;
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
        getName: function(){
            return this.usageName || this.email;
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
                            notes += 'Téléphone: ' + that.displayPhoneInformations();
                            if(hasSkype)
                                notes += "\n";
                        }
                        if(hasSkype)
                            notes += 'Skype: ' + that.skypeId;
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
                            notes += 'Téléphone: ' + that.displayPhoneInformations();
                            if(hasSkype)
                                notes += "\n";
                        }
                        if(hasSkype)
                            notes += 'Skype: ' + that.skypeId;
                }
            }

            return notes;
        }
    });
})();