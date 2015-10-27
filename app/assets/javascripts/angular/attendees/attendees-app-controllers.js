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
        this.loaded = false;
        this.attendees = [];
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
                    if(attendee.email != undefined && attendee.email != ''){
                        return a.email == attendee.email;
                    }else if(attendee.name != '' && attendee.name != undefined){
                        return a.name == attendee.name;
                    }
                    return false;
            });
                var informations = (attendeeDetails || attendee);

                //If the current attendee is not a alias for another attendee
                if(aliasEmails.indexOf(informations.email) == -1){
                    var assistant = typeof(informations.assistedBy) == "string" ? JSON.parse(informations.assistedBy) : informations.assistedBy;

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

                    informations.assistedBy = assistant;
                    // If the current attendee was in the aliases repsonse from the server, it means it is in the accounts cache => he is client

                    if(aliasedEmails.indexOf(informations.email) > -1)
                        informations.isClient = "true";
                    if(Object.keys(companies).indexOf(informations.email) > -1)
                        informations.company = companies[informations.email];
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

            this.attendees.push(threadOwner);

            sharedProperties.setThreadOwner(threadOwner);

            _.each(window.threadComputedData.constraints_data, function(constraintData) {
                newConstraintTile(constraintData, false);
            });

            $(".add-constraint-button").click(function() {
                newConstraintTile(null, true);
            });
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

            attendeesCtrl.attendees.push(a);
        };

        this.displayAttendeeNewForm = function (){
            sharedProperties.displayAttendeeForm({attendee: {timezone: window.threadAccount.default_timezone_id, isPresent: true}, action: 'new'});
        };

        this.displayAttendeeUpdateForm = function(attendee){
            sharedProperties.displayAttendeeForm({attendee: attendee, action: 'update'});
        };

        $scope.$on('attendeeAdded', function(event, args) {
            attendeesCtrl.attendees.push(args.attendee);
        });

        this.getCompaniesNames = function(){
            return _.uniq(_.compact(_.map(attendeesCtrl.attendees, function(a) {
                if(a.company != '' &&  a.company != undefined)
                    return a.company;
            })));
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



        this.fetchAttendeeFromClientContactNetwork();

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
        getName: function(){
            return this.usageName || this.email;
        }
    });
})();