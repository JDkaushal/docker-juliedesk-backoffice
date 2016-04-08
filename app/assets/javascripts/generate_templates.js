window.generateEmailTemplate = function (params) {
    var previousLocale = window.getCurrentLocale();
    window.setCurrentLocale(params.locale);

    var message = "";

    var locationInTemplate = "";
    var addressInTemplate = "";
    var isAskInterlocutor = false;
    var isClientWillDefine = false;

    var today = "";
    var tomorrow = "";
    var dateString = "";
    var appointmentNature = "";
    var date = "";

    if(params.address) {
        if(params.address.address_in_template) {
            if(params.address.address_in_template[params.locale] == "") {
                if(params.address.address != "") {
                    addressInTemplate = localize("email_templates.invites_sent.location_in_template", {location: params.address.address});
                }
            }
            else {
                locationInTemplate = " " + params.address.address_in_template[params.locale];
            }
            isAskInterlocutor = (params.address.type == "ask_interlocuter");
            isClientWillDefine = (params.address.type == "client_will_define");
        }
        else {
            if (params.action != "suggest_dates") {
                addressInTemplate = localize("email_templates.invites_sent.location_in_template", {location: params.address});
            }
        }
    }

    var isVirtualAppointment = false;
    var attendeesWithMissingInfos = [];

    if(params.appointment) {
        if(!params.appointment.appointment_kind_hash) {
            console.log('Oups', params);
        }
        isVirtualAppointment = params.appointment.appointment_kind_hash.is_virtual;
    }

    if(isVirtualAppointment) {
        locationInTemplate = "";
        addressInTemplate = "";
    }

    if(params.attendeesWithMissingInfos && params.attendeesWithMissingInfos.length > 0){
        attendeesWithMissingInfos = params.attendeesWithMissingInfos;
    }

    if (params.action == "suggest_dates") {
        if(params.timezoneId != undefined){
            today = moment().tz(params.timezoneId);
            tomorrow = today.clone().add(1, "d");
        }
        if (params.client_agreement) {
            if (params.timeSlotsToSuggest.length > 0) {
                if(params.isPostpone && !params.attendeesAreNoticed) {

                    message += window.generateEmailTemplate({
                            action: "cancel_event",
                            clientAgreement: true,
                            attendeesAreNoticed: false,
                            appointment: params.previousAppointment,
                            locale: params.locale,
                            timezoneId: params.timezoneId,
                            defaultTimezoneId: params.defaultTimezoneId,
                            client: params.client,
                            currentEventData: params.currentEventData
                        }) + "\n\n";
                }

                if(params.noDateFits) {
                    var templateName;
                    var templateSuffixName;
                    var templateNameParams = {
                        client: params.client,
                        location: locationInTemplate
                    };
                    var templateSuffixNameParams = {
                        client: params.client,
                        location: locationInTemplate
                    };

                    if(params.appointment) {
                        templateNameParams['appointment_nature'] = params.appointment.title_in_email[params.locale];
                        templateSuffixNameParams['appointment_nature'] = params.appointment.title_in_email[params.locale];
                    }


                    if(params.noDateFits == "suggested_multiple") {
                        templateName = "email_templates.no_date_fits.before_dates.suggested.plural";
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.new_appointment.suggested";
                    }
                    else if(params.noDateFits == "not_suggested_multiple") {
                        templateName = "email_templates.no_date_fits.before_dates.not_suggested.plural";
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.new_appointment.not_suggested";
                    }
                    else if(params.noDateFits == "suggested_single"){
                        templateName = "email_templates.no_date_fits.before_dates.suggested.singular";
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.new_appointment.suggested";
                    }
                    else if(params.noDateFits == "not_suggested_single"){
                        templateName = "email_templates.no_date_fits.before_dates.not_suggested.singular";
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.new_appointment.not_suggested";
                    }
                    else if(params.noDateFits == "external_invitation"){
                        templateName = "email_templates.no_date_fits.before_dates.external_invitation" + (params.declining_previously_suggested_date ? '.proposed_date' : '.not_proposed_date');
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.external_invitation";

                        date = moment(params.invitation_start_date).tz(params.timezoneId);
                        var dateString = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
                        var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString);
                        var formattedDate = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));

                        if(date.isSame(today, "day"))
                            dateString = localize("dates.today") + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
                        else if(date.isSame(tomorrow, "day"))
                            dateString = localize("dates.tomorrow") + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
                        else
                            dateString = (window.getCurrentLocale() == 'en' ? window.helpers.capitalize(formattedDate) : window.helpers.lowerize(formattedDate)) + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));

                        templateNameParams['date'] = dateString;
                    }
                    if(params.isPostpone) {
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.postpone";
                    }

                    message += localize(templateName, templateNameParams);

                    message += localize(templateSuffixName, templateSuffixNameParams);
                }
                else {
                    if(params.isPostpone) {
                        message += localize("email_templates.suggest_dates.before_dates.postpone", {
                            client: params.client,
                            appointment_nature: params.appointment.title_in_email[params.locale],
                            location: locationInTemplate
                        });
                    }
                    else {
                        var otherClientsString = "";
                        if(params.other_clients) {
                            otherClientsString = params.other_clients.join(", ");
                        }

                        if(otherClientsString == "") {
                            message += localize("email_templates.suggest_dates.before_dates.new_appointment.one_client", {
                                client: params.client,
                                appointment_nature: params.appointment.title_in_email[params.locale],
                                location: locationInTemplate
                            });
                        }
                        else {
                            message += localize("email_templates.suggest_dates.before_dates.new_appointment.many_clients", {
                                client: params.client,
                                other_clients: otherClientsString,
                                appointment_nature: params.appointment.title_in_email[params.locale],
                                location: locationInTemplate
                            });
                        }
                    }

                }

                if (params.timezoneId != params.defaultTimezoneId || isVirtualAppointment) {
                    message += "\n" + localize("email_templates.common.timezone_precision", {timezone: params.timezoneId.replace("_", " ")});
                }

                _.each(_.groupBy(params.timeSlotsToSuggest, function(timeSlot) {
                    return moment(timeSlot).tz(params.timezoneId).format("YYYY-MM-DD");
                }), function(timeSlots, day) {
                    date = moment(timeSlots[0]).tz(params.timezoneId);

                    dateString = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
                    var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString);


                    if(date.isSame(today, "day"))
                        dateString = window.helpers.capitalize(localize('dates.today')) + ", " + localizedDateString;
                    else if(date.isSame(tomorrow, "day"))
                        dateString = window.helpers.capitalize(localize('dates.tomorrow')) + ", " + localizedDateString;

                    var timeSlotsStrings = _.map(timeSlots, function(timeSlot) {
                        return moment(timeSlot).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.only_time_format"))
                    });
                    var lastTimeSlotString = timeSlotsStrings.pop();
                    var timesString = timeSlotsStrings.join(", ");
                    if(timesString != "") timesString +=  " " + localize("common.or") + " ";
                    timesString += lastTimeSlotString;

                    message += "\n - " + dateString + " " + localize("email_templates.common.date_time_separator") + " " + timesString;
                });

                if(params.noDateFits == "external_invitation"){
                    message += localize("email_templates.suggest_dates.after_dates.external_invitation");
                }else{
                    var timeSlotsPlural = "plural";
                    if (params.timeSlotsToSuggest.length == 1) timeSlotsPlural = "singular";

                    var attendeesSpecificConf = determineAttendeesSpecificConf('email_templates.suggest_dates.after_dates', params.assistedAttendees, params.unassistedAttendees);

                    message += localize("email_templates.suggest_dates.after_dates." + timeSlotsPlural + attendeesSpecificConf[0], attendeesSpecificConf[1]);
                }
            }
        }
        else {
            if(params.isPostpone) {
                message += localize("email_templates.suggest_dates.ask_agreement.postpone");
            }
            else {
                message += localize("email_templates.suggest_dates.ask_agreement.new_appointment");
            }

        }
    }
    else if(params.action == "invites_sent") {
        dateString = "";
        today = "";
        tomorrow = "";
        var dateFormatted = "";

        var timezoneIds = params.allTimezoneIds;
        if (params.allTimezoneIds.length == 0) {
            timezoneIds = [params.defaultTimezoneId];
        }
        if (timezoneIds.length == 1 && timezoneIds[0] == params.defaultTimezoneId && !isVirtualAppointment) {
            today = moment().tz(params.defaultTimezoneId);
            tomorrow = today.clone().add(1, 'd');
            date = moment(params.timeSlotToCreate).tz(params.defaultTimezoneId);

            dateString = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
            var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString);

            if(date.isSame(today, "day"))
                dateString = window.helpers.capitalize(localize("dates.today")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format")) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[0].replace("_", " ")});
            else if(date.isSame(tomorrow, "day"))
                dateString = window.helpers.capitalize(localize("dates.tomorrow")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format")) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[0].replace("_", " ")});
            else
                dateString = dateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format")) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[0].replace("_", " ")});
        }
        else {
            for (var i = 0; i < timezoneIds.length; i++) {
                if (dateString != "") {
                    dateString = dateString + "\n";
                }
                today = moment().tz(timezoneIds[i]);
                tomorrow = today.clone().add(1, 'd');
                date = moment(params.timeSlotToCreate).tz(timezoneIds[i]);

                dateFormatted = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
                var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateFormatted) : window.helpers.lowerize(dateFormatted);

                if(date.isSame(today, "day"))
                    dateString += window.helpers.capitalize(localize("dates.today")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format")) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[i].replace("_", " ")});
                else if(date.isSame(tomorrow, "day"))
                    dateString += window.helpers.capitalize(localize("dates.tomorrow")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format")) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[i].replace("_", " ")});
                else
                    dateString += dateFormatted + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format")) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[i].replace("_", " ")});

            }
        }

        var postponeSuffix = "new_appointment";
        if(params.isPostpone)  postponeSuffix = "postpone";

        message = localize("email_templates.invites_sent." + postponeSuffix, {
            appointment_nature: params.appointment.title_in_email[params.locale],
            location: locationInTemplate,
            address: addressInTemplate,
            date: dateString
        });

        if(attendeesWithMissingInfos.length <= 2){
            if(addressInTemplate == "" && locationInTemplate == "" && !isVirtualAppointment) {
                if (isAskInterlocutor) {
                    message += localize("email_templates.invites_sent.ask_interlocutor_for_location");
                }
                else if (isClientWillDefine) {

                }
                else {
                    message += localize("email_templates.invites_sent.ask_for_location");
                }
            }
        }
    }
    else if(params.action == "cancel_event") {
        dateString = getScheduledEventDateString(params);

        appointmentNature = localize("email_templates.common.default_appointment_designation_in_email");

        if(params.appointment) {
            appointmentNature = params.appointment.designation_in_email[params.locale];
        }

        if(params.clientAgreement) {
            if(params.attendeesAreNoticed) {
                message = localize("email_templates.cancel.attendees_noticed", {
                    client: params.client,
                    date: dateString,
                    appointment_nature: appointmentNature
                });
            }
            else {
                message = localize("email_templates.cancel.attendees_not_noticed", {
                    client: params.client,
                    date: dateString,
                    appointment_nature: appointmentNature
                });
            }
        }
        else {
            message = localize("email_templates.cancel_client_agreement", {
                date: dateString,
                appointment_nature: appointmentNature
            });
        }

    }
    else if(params.action == "create_event") {
        if(params.createdEvents.length > 0) {
            message += localize("email_templates.create_events.before_dates.created");
            _.each(params.createdEvents, function(event) {
                message += "- " + event.title + (window.getCurrentLocale() == 'en' ? '-' : ' ') + ": " + CommonHelpers.formatDateTimeRangeInText(event.start, event.end, params.locale, event.timezoneId, event.allDay) + "\n";
            });
            message += "\n";
        }
        if(params.updatedEvents.length > 0) {
            message += localize("email_templates.create_events.before_dates.updated");
            _.each(params.updatedEvents, function(event) {
                message += "- " + event.title + (window.getCurrentLocale() == 'en' ? '-' : ' ') + ": " + CommonHelpers.formatDateTimeRangeInText(event.start, event.end, params.locale, event.timezoneId, event.allDay) + "\n";
            });
            message += "\n";
        }
        if(params.deletedEvents.length > 0) {
            message += localize("email_templates.create_events.before_dates.deleted");
            _.each(params.deletedEvents, function(event) {
                message += "- " + event.title + (window.getCurrentLocale() == 'en' ? '-' : ' ') + ": " + CommonHelpers.formatDateTimeRangeInText(event.start, event.end, params.locale, event.timezoneId, event.allDay) + "\n";
            });
            message += "\n";
        }
    }
    else if(params.action == "client_agreement") {
        var dateTimesToCheckPlural = "singular";
        today = moment().tz(params.timezoneId);
        tomorrow = today.clone().add(1, 'd');
        date  = "";
        dateString = "";

        if(params.dateTimesToCheck.length > 1)  dateTimesToCheckPlural = "plural";
        var available = "available";

        if(!params.isAvailable) available = "not_available";
        appointmentNature = params.appointment.title_in_email[params.locale];
        message += localize("email_templates.client_agreement.prefix." + available + "." + dateTimesToCheckPlural, {
            appointment_nature: appointmentNature
        });
        _.each(params.dateTimesToCheck, function(dateTime) {
            date = moment(dateTime).tz(params.timezoneId);

            var dateString = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
            var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString);


            if(date.isSame(today, "day"))
                dateString = window.helpers.capitalize(localize("dates.today")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
            else if(date.isSame(tomorrow, "day"))
                dateString = window.helpers.capitalize(localize("dates.tomorrow")) + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
            else
                dateString = dateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));

            message += "- " + dateString + "\n";
        });

        if(params.isPostpone) {
            message += localize("email_templates.client_agreement.suffix." + available + ".postpone");
        }
        else {
            message += localize("email_templates.client_agreement.suffix." + available + ".new_appointment");
        }
    }
    else if(params.action == "cancel_postpone_multiple_events") {
        var wordingBase = "cancel_multiple";
        today = moment().tz(params.timezoneId);
        tomorrow = today.clone().add(1, 'd');
        date = "";
        dateString = "";

        if(params.kind == "postpone") {
            wordingBase = "postpone_multiple";
        }
        if (params.selectedEventsToCancel.length > 0) {
            var toCancelPlural = (params.selectedEventsToCancel.length > 1) ? "plural" : "singular";
            message += localize("email_templates." + wordingBase + ".noted_gonna_cancel." + toCancelPlural);

            _.each(params.selectedEventsToCancel, function (selectedEvent) {
                date = moment(selectedEvent.start).tz(params.timezoneId);
                var formattedDate = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
                var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(formattedDate) : window.helpers.lowerize(formattedDate);


                if(date.isSame(today, "day"))
                    dateString = localize("dates.today") + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
                else if(date.isSame(tomorrow, "day"))
                    dateString = localize("dates.tomorrow") + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
                else
                    dateString = formattedDate + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));

                message += " - " + selectedEvent.title + " (" + dateString.replace(/<br>/g, " ") + ")\n";
            });
        }

        if (params.selectedEventsNotToCancel.length > 0) {
            var notToCancelPlural = (params.selectedEventsNotToCancel.length > 1) ? "plural" : "singular";
            if (params.selectedEventsToCancel.length > 0) {
                message += localize("email_templates." + wordingBase + ".but_no_attendees." + notToCancelPlural);
            }
            else {
                message += localize("email_templates." + wordingBase + ".noted_no_attendees." + notToCancelPlural);
            }

            _.each(params.selectedEventsNotToCancel, function (selectedEvent) {
                date = moment(selectedEvent.start).tz(params.timezoneId);
                var formattedDate = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
                var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(formattedDate) : window.helpers.lowerize(formattedDate);

                if(date.isSame(today, "day"))
                    dateString = localize("dates.today") + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
                else if(date.isSame(tomorrow, "day"))
                    dateString = localize("dates.tomorrow") + ', ' + localizedDateString + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
                else
                    dateString = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.full_date_format")));

                message += " - " + selectedEvent.title + " (" + dateString.replace(/<br>/g, " ") + ")\n";
            });
            message += localize("email_templates." + wordingBase + ".what_should_i_do." + notToCancelPlural);
        }
    }
    else if(params.action == "send_confirmation") {
        message += localize("email_templates.confirmation");
    }
    else if(params.action == "send_call_instructions") {
        var callInstructions = params.callInstructions;
        var callInstructionsMessage = '';

        if(callInstructions.target == 'later')
            message += '';
        else if(callInstructions.details != '' && callInstructions.details != null && callInstructions.details != undefined) {
            if(callInstructions.targetInfos.name != '' && (callInstructions.support == 'mobile' || callInstructions.support == 'landline' || callInstructions.support == 'confcall')) {

                callInstructionsMessage = localize("email_templates.send_call_instructions.placed_in_notes");
            } else if (callInstructions.support == 'skype') {
                var names = callInstructions.targetInfos.name.split(" ");
                var usageName = '';
                if(names.length > 0) {
                    usageName = window.helpers.capitalize(names[0]);
                }
                callInstructionsMessage = localize("email_templates.send_call_instructions.placed_skype_in_notes", {
                    target_name: usageName
                });
            } else if(callInstructions.target == 'custom'){
                callInstructionsMessage = localize("email_templates.send_call_instructions.placed_in_notes");
            }
        }else{
            if(callInstructions.target != 'client' && params.askCallInstructions){
                var attendeesSpecificConf = determineAttendeesSpecificConf('email_templates.send_call_instructions.missing_infos', params.assistedAttendees, params.unassistedAttendees);
                callInstructionsMessage = localize("email_templates.send_call_instructions.missing_infos" + (params.askingEarly ? '.early' : '') + ( callInstructions.support == 'skype' ? '.skype' : '.phone' ) + attendeesSpecificConf[0], attendeesSpecificConf[1]);
            }
        }

        message += callInstructionsMessage;
    }
    else if(params.action == "ask_additional_informations"){
        var requiredAdditionalInformations = params.requiredAdditionalInformations;
        var redundantCourtesy = params.redundantCourtesy;
        var attendeesSpecificConf = [];
        var templateName = '';

        if(params.askingEarly) {
            attendeesSpecificConf = determineAttendeesSpecificConf('email_templates.ask_additional_informations.early', params.assistedAttendees, params.unassistedAttendees);
            templateName = "email_templates.ask_additional_informations.early" + (requiredAdditionalInformations == 'skype_only' ? '.skype' : '.phone') + attendeesSpecificConf[0];

            message += localize(templateName, attendeesSpecificConf[1]);
        }else {
            attendeesSpecificConf = determineAttendeesSpecificConf('email_templates.ask_additional_informations', params.assistedAttendees, params.unassistedAttendees);
            templateName = "email_templates.ask_additional_informations" + (requiredAdditionalInformations == 'skype_only' ? '.skype' : '.phone') + attendeesSpecificConf[0];

            var courtesyString = redundantCourtesy ? ' ' + localize('common.egalement'): '';
            attendeesSpecificConf[1]['courtesyString'] = courtesyString;

            message += localize(templateName, attendeesSpecificConf[1]);
        }
    }
    else if(params.action == "forward_to_client") {
        message += localize("email_templates.forward_to_client");
    }
    else if(params.action == "invitation_already_sent") {
        var date = moment(params.invitation_start_date).tz(params.timezoneId);
        var formattedDate = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));

        var invitationStartDate = formattedDate + ' ' + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));

        message += localize("email_templates.invitation_already_sent.noted", {date: invitationStartDate, client: params.client});
    }
    else if(params.action == "wait_for_contact") {
        if(params.isPostpone) {
            dateString = getScheduledEventDateString(params);
            appointmentNature = localize("email_templates.common.default_appointment_designation_in_email");

            if(params.previousAppointment) {
                appointmentNature = params.previousAppointment.designation_in_email[params.locale];
            }

            message += localize("email_templates.wait_for_contact.postpone", {
                appointment_nature: appointmentNature,
                date: dateString
            });
        }
        else {
            message += localize("email_templates.wait_for_contact.no_postpone");
        }

    }
    else if(params.action == "follow_up_confirmation") {
        message += localize("email_templates.follow_up_confirmation.header");
        _.each(params.followUpData, function(followUpItem) {
            message += localize("email_templates.follow_up_confirmation.item", {label: followUpItem.label});
        });
    }

    window.setCurrentLocale(previousLocale);
    return message;
};

function determineAttendeesSpecificConf(root, assistedAttendees, unassistedAttendees) {

    if(assistedAttendees && unassistedAttendees) {
        var attendeesKey = ".single_attendee_unassisted";
        var params = {};

        var assistedLength = assistedAttendees.length;
        var unassistedLength = unassistedAttendees.length;

        var assistedAttendeesNames = assistedAttendees.join(', ');

        var unassistedAttendeesNames = unassistedAttendees.join(', ');

        if(assistedLength == 0 && unassistedLength > 1) {
            attendeesKey = '.multiple_attendees_unassisted';
        }else if(assistedLength == 1 && unassistedLength == 0) {
            attendeesKey = '.single_attendee_assisted';
        }else if(assistedLength > 1 && unassistedLength == 0) {
            attendeesKey = '.multiple_attendees_assisted';
        }else if(assistedLength > 0 && unassistedLength > 0) {
            attendeesKey = '.multiple_attendees_mix';
        }

        switch(root) {
            case 'email_templates.suggest_dates.after_dates':
                switch(attendeesKey){
                    case '.multiple_attendees_unassisted':
                        params = {attendees: unassistedAttendeesNames};
                        break;
                    case '.single_attendee_assisted':
                        params = {assisted_attendee: assistedAttendeesNames};
                        break;
                    case '.multiple_attendees_assisted':
                        params = {assisted_attendees: assistedAttendeesNames};
                        break;
                };
                break;
            case 'email_templates.ask_additional_informations.early':
                if(attendeesKey == '.single_attendee_assisted')
                    params = {assisted_attendee: assistedAttendeesNames};
                break;
            case 'email_templates.ask_additional_informations':
                if(attendeesKey == '.single_attendee_unassisted')
                    params = {attendee: unassistedAttendeesNames};
                else if(attendeesKey == '.single_attendee_assisted')
                    params = {assisted_attendee: assistedAttendeesNames};
                else if(attendeesKey == '.multiple_attendees_unassisted')
                    params = {attendees: unassistedAttendeesNames};
                else if(attendeesKey == '.multiple_attendees_assisted')
                    params = {attendees: assistedAttendeesNames};
                break;
            case 'email_templates.send_call_instructions.missing_infos':
                if(attendeesKey == '.single_attendee_assisted')
                    params = {assisted_attendee: assistedAttendeesNames};
                break;
        };

        return [attendeesKey, params];
    }
};

window.getScheduledEventDateString = function(params) {
    var dateString = "";
    today = moment().tz(params.timezoneId);
    tomorrow = today.clone().add(1, 'd');
    date = moment(params.currentEventData.start.dateTime).tz(params.timezoneId);

    var formatted_date = date.locale(params.locale).format(localize("email_templates.common.only_date_format"));
    var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(formatted_date) : window.helpers.lowerize(formatted_date);

    if(date.isSame(today, "day"))
        dateString = localize("dates.today") + ", " + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + window.helpers.lowerize(date.format(localize("email_templates.common.full_time_format")));
    else if(date.isSame(tomorrow, "day"))
        dateString = localize("dates.tomorrow") + ", " + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + window.helpers.lowerize(date.format(localize("email_templates.common.full_time_format")));
    else{
        dateString = date.locale(params.locale).format(localize("email_templates.common.full_date_format"));
        var beforeDays = '';
        if(params.attendeesAreNoticed || !params.clientAgreement){
            beforeDays = localize("constraints.before_days_for");
        }else{
            beforeDays = localize("constraints.before_days_on");
        }

        dateString = beforeDays + (window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString));
    }

    if(params.timezoneId != params.defaultTimezoneId) {
        dateString += " " + localize("email_templates.common.timezone_precision", {timezone: params.timezoneId.replace("_", " ")});
    }
    return dateString;
};