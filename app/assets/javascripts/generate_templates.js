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

    params.isVirtualAppointment = isVirtualAppointment;

    if(params.timezoneId != undefined){
        today = moment().tz(params.timezoneId);
        tomorrow = today.clone().add(1, "d");

        params.today = today;
        params.tomorrow = tomorrow;
    }



    if (params.action == "suggest_dates") {
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

                if(params.usedTimezones.length > 1) {
                    message += generateDatesForMultipleTimezones(params);
                }else {
                    message += generateDatesForSingleTimezone(params);
                }

                if(params.noDateFits == "external_invitation"){
                    message += localize("email_templates.suggest_dates.after_dates.external_invitation");
                }else{
                    var timeSlotsPlural = "plural";

                    var firstTimeSlotProposition = params.timeSlotsToSuggest[0];
                    // We first check if we are only suggesting on one day, then if we only gave one suggestion ofr this day
                    // If this is the case it means that we will use the singular case template in the email
                    if ( params.timeSlotsToSuggest.length == 1 && firstTimeSlotProposition[Object.keys(firstTimeSlotProposition)[0]].length == 1 ) timeSlotsPlural = "singular";

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
    else if(params.action == "follow_up_contacts") {
        var afterDatesTemplate = '';

        if(params.timezoneId != undefined){
            today = moment().tz(params.timezoneId);
            tomorrow = today.clone().add(1, "d");
        }

        message += localize("email_templates.follow_up_contacts.before_dates", {
            clients: [params.client].concat(params.other_clients).join(', '),
            appointment_nature: params.appointment.designation_in_email[params.locale],
            location: locationInTemplate
        });

        if(params.timeSlotsToSuggest.length > 0) {

            if(params.usedTimezones.length > 1) {
                message += generateDatesForMultipleTimezones(params);
            }else {
                message += generateDatesForSingleTimezone(params);
            }

            var multipleDates = params.timeSlotsToSuggest.length > 1 || params.timeSlotsToSuggest[0][params.usedTimezones[0]].length > 1;
            if(multipleDates){
                afterDatesTemplate = "email_templates.follow_up_contacts.multiple_dates.after_dates";
            }else {
                afterDatesTemplate = "email_templates.follow_up_contacts.one_date.after_dates";
            }
        } else {
            afterDatesTemplate = "email_templates.follow_up_contacts.zero_dates.after_dates";
        }

        attendeesSpecificConf = determineAttendeesSpecificConf("email_templates.follow_up_contacts", params.assistedAttendees, params.unassistedAttendees);
        message += localize(afterDatesTemplate + attendeesSpecificConf[0], attendeesSpecificConf[1]);
    }
    else if(params.action == "invites_sent") {
        var dateStringBuff = '';
        dateString = "";
        today = "";
        tomorrow = "";
        var currentDay = undefined;
        var dateFormatted = "";

        var i = 0;

        currentDay = moment(params.timeSlotToCreate).tz(params.usedTimezones[0]).format("YYYY-MM-DD");
        _.each(params.usedTimezones, function(timezone) {

            if(i > 0) {
                dateString += ' / ';
            }

            date = moment(params.timeSlotToCreate).tz(timezone);
            dateFormatted = date.format("YYYY-MM-DD");

            if( i== 0 || dateFormatted != currentDay) {
                dateString += computeDatePart(date, timezone, params.locale) + ' ';

                dateString += localize("email_templates.common.date_time_separator") + " ";
            }

            dateString += date.format(localize("email_templates.common.full_time_format")) + ' (' + localize("email_templates.utilities.timezone_display", {city: extractCityFromTimezone(timezone)}) + ')';

            //currentDay =  date.clone();

            i += 1;
        });

        var postponeSuffix = "new_appointment";
        var suggestedDateSuffix = "";
        if(params.isPostpone)  postponeSuffix = "postpone";

        if(postponeSuffix == "new_appointment") {
            suggestedDateSuffix = ".date_not_suggested";

            if(params.suggestedDates) {
                var alreadySuggestedDate = _.find(params.suggestedDates, function(suggestedDate) {
                    return date.isSame(moment(suggestedDate));
                });

                if(alreadySuggestedDate)
                    suggestedDateSuffix = ".date_suggested";
            }
        }

        message = localize("email_templates.invites_sent." + postponeSuffix + suggestedDateSuffix, {
            appointment_nature: params.appointment.title_in_email[params.locale],
            location: locationInTemplate,
            address: addressInTemplate,
            date: dateString
        });

        if(params.usingRestaurantBooking) {
            if(addressInTemplate == "" && locationInTemplate == "") {
                message += localize("restaurant_booking.no_location");
            } else {
                message += localize("restaurant_booking.with_location");
            }
        } else {
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

        if(params.usingMeetingRoom && params.appointment && params.appointment.appointment_kind_hash.is_virtual) {
            message += localize("email_templates.invites_sent.meeting_room_booked", {company_name: params.threadOwnerCompanyName, meeting_room_name: params.selectedRoomName})
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
        var subMessage = '';
        if(params.origin == "give_info") {
            subMessage = localize("email_templates.confirmation.give_info");
        } else if(params.origin == 'give_preference') {
            subMessage = localize("email_templates.confirmation.give_preference");
        } else if(params.origin == 'update_event') {
            if(params.usingRestaurantBooking && params.locationUpdated) {
                subMessage = localize("email_templates.confirmation.update_event_location_with_restaurant_booking", {newLocation: params.location});
            } else {
                subMessage = localize("email_templates.confirmation.update_event");
            }

        } else {
            subMessage = localize("email_templates.confirmation.default");
        }

        message += subMessage;
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
            case "email_templates.follow_up_contacts":
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

function computeDatePart(date, timezone, locale) {
    var today = moment().tz(timezone);
    var tomorrow = today.clone().add(1, "d");
    var dateFormat = "email_templates.common.only_date_format_without_year";

    if(today.year() != date.year())
        dateFormat = "email_templates.common.only_date_format";

    var dateString = window.helpers.capitalize(date.locale(locale).format(localize(dateFormat)));
    var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString);

    if(date.isSame(today, "day"))
        dateString = window.helpers.capitalize(localize('dates.today')) + ", " + localizedDateString;
    else if(date.isSame(tomorrow, "day"))
        dateString = window.helpers.capitalize(localize('dates.tomorrow')) + ", " + localizedDateString;

    return dateString;
};

function extractCityFromTimezone(timezone) {
  return timezone.split('/')[1];
};

function generateDatesForSingleTimezone(params) {
    var date, dateString;
    var message = "";

    // We use the old system when only one timezone is used
    params.timezoneId = params.usedTimezones[0];

    if (params.timezoneId != params.defaultTimezoneId || params.isVirtualAppointment) {
        message += "\n" + localize("email_templates.common.timezone_precision", {timezone: params.timezoneId.replace("_", " ")});
    }

    _.each(params.timeSlotsToSuggest, function(hash) {
        date = moment(hash[params.timezoneId][0]).tz(params.timezoneId);

        dateString = computeDatePart(date, params.timezoneId, params.locale);
        //dateString = window.helpers.capitalize(date.locale(params.locale).format(localize("email_templates.common.only_date_format")));
        //var localizedDateString = window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString);
        //
        //if(date.isSame(params.today, "day"))
        //    dateString = window.helpers.capitalize(localize('dates.today')) + ", " + localizedDateString;
        //else if(date.isSame(tomorrow, "day"))
        //    dateString = window.helpers.capitalize(localize('dates.tomorrow')) + ", " + localizedDateString;

        var timeSlotsStrings = _.map(hash[params.timezoneId], function(timeSlot) {
            return moment(timeSlot).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.only_time_format"))
        });
        var lastTimeSlotString = timeSlotsStrings.pop();
        var timesString = timeSlotsStrings.join(", ");
        if(timesString != "") timesString +=  " " + localize("common.or") + " ";
        timesString += lastTimeSlotString;

        message += "\n - " + dateString + " " + localize("email_templates.common.date_time_separator") + " " + timesString;
    });

    return message;
};

function generateDatesForMultipleTimezones(params) {

    var currentTimeString = '';
    var currentTime = undefined;
    var currentDay = '';
    var currentSubDay = '';
    var currentSubDayReference = '';
    var currentSubTimeString = '';
    var i = 0;
    var timezoneIndex = 0;
    var currentTotalTimeSlots = 0;
    var message = "";

    _.each(params.timeSlotsToSuggest, function(hash) {

        timezoneIndex = 0;

        currentDay = hash[params.usedTimezones[0]][0].format("YYYY-MM-DD");

        _.each(params.usedTimezones, function(timezone) {

            i = 0;
            currentTotalTimeSlots = hash[timezone].length;

            if(timezoneIndex > 0) {
                currentTimeString += " / ";
            }

            currentSubTimeString = '';
            _.each(hash[timezone], function(timeSlot) {
                currentTime = timeSlot.locale(params.locale);

                currentSubDay = currentTime.format("YYYY-MM-DD");

                if(i > 0) {
                    if(i == currentTotalTimeSlots - 1) {
                        currentSubTimeString +=  " " + localize("common.or") + " ";
                    }else {
                        currentSubTimeString += ', ';
                    }
                } else {
                    currentSubDayReference = '';
                }

                // For the first timeslot of the first timezone we set the reference day, which we will use to check if the timeslots in the following timezones are the same or not
                // So we can display the full day name when it is different
                if(timezoneIndex == 0 && i == 0) {
                    // Here we override the previous currentTimeString so we clear the previous content
                    currentTimeString = computeDatePart(currentTime, timezone, params.locale) + ' ' + localize("email_templates.common.date_time_separator") + ' ';
                } else {
                    if(currentSubDay == currentDay) {
                        currentSubTimeString += '';
                    }else {
                        if(currentSubDayReference != currentSubDay) {
                            currentSubTimeString += computeDatePart(currentTime, timezone, params.locale) + ' ' + localize("email_templates.common.date_time_separator") + ' ';
                        } else {
                            currentSubTimeString += '';
                        }
                    }
                }

                currentSubDayReference = currentSubDay;
                currentSubTimeString += currentTime.format(localize("email_templates.common.only_time_format"));
                i += 1;
            });
            currentTimeString += currentSubTimeString + ' (' + localize("email_templates.utilities.timezone_display", {city: extractCityFromTimezone(timezone)}) + ')';

            timezoneIndex += 1;
        });
        message += "\n - " + currentTimeString;
    });

    return message;
};

window.getScheduledEventDateString = function(params) {
    var dateString = "";
    today = moment().tz(params.timezoneId);
    tomorrow = today.clone().add(1, 'd');
    var date = moment(params.currentEventData.start.dateTime).tz(params.timezoneId);

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