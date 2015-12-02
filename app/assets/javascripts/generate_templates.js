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
                    if(params.isPostpone) {
                        templateSuffixName = "email_templates.no_date_fits.before_dates_suffix.postpone";
                    }

                    message += localize(templateName, {
                        client: params.client,
                        appointment_nature: params.appointment.title_in_email[params.locale],
                        location: locationInTemplate
                    });

                    message += localize(templateSuffixName, {
                        client: params.client,
                        appointment_nature: params.appointment.title_in_email[params.locale],
                        location: locationInTemplate
                    });
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
//                _.each(params.timeSlotsToSuggest, function (timeSlot) {
//                    message += "\n - " + window.helpers.capitalize(moment(timeSlot).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
//                });

//                _.each(params.timeSlotsToSuggest, function (timeSlot) {
//                    message += "\n - " + window.helpers.capitalize(moment(timeSlot).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
//                });


                var timeSlotsPlural = "plural";
                if (params.timeSlotsToSuggest.length == 1) timeSlotsPlural = "singular";

                var attendeesString = "";
                var attendeesKey = ".one_attendee";
                if(params.attendees && params.attendees.length > 1) {
                    attendeesString = params.attendees.join(", ");
                    var attendeesKey = ".many_attendees";
                }

                message += localize("email_templates.suggest_dates.after_dates." + timeSlotsPlural + attendeesKey, {
                    attendees: attendeesString
                });
//                if (params.appointment.label == "call") {
//                    message += localize("email_templates.suggest_dates.ask_number.call");
//                }
//                else if (params.appointment.label == "skype") {
//                    message += localize("email_templates.suggest_dates.ask_number.skype");
//                }
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
                dateString = window.helpers.capitalize(localize("dates.today")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
            else if(date.isSame(tomorrow, "day"))
                dateString = window.helpers.capitalize(localize("dates.tomorrow")) + ', ' + localizedDateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
            else
                dateString = dateString + " " + localize("email_templates.common.date_time_separator") + " " + date.format(localize("email_templates.common.full_time_format"));
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

        if(addressInTemplate == "" && locationInTemplate == "" && !isVirtualAppointment) {
            if(isAskInterlocutor) {
                message += localize("email_templates.invites_sent.ask_interlocutor_for_location");
            }
            else if(isClientWillDefine) {

            }
            else {
                message += localize("email_templates.invites_sent.ask_for_location");
            }

        }
    }
    else if(params.action == "cancel_event") {
        dateString = "";
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
            var dateString = date.locale(params.locale).format(localize("email_templates.common.full_date_format"));
            dateString = localize("constraints.before_days") + (window.getCurrentLocale() == 'en' ? window.helpers.capitalize(dateString) : window.helpers.lowerize(dateString));
        }

        if(params.timezoneId != params.defaultTimezoneId) {
            dateString += " " + localize("email_templates.common.timezone_precision", {timezone: params.timezoneId.replace("_", " ")});
        }

        var appointmentNature = localize("email_templates.common.default_appointment_designation_in_email");

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
                message += "- " + event.title + " : " + CommonHelpers.formatDateTimeRangeInText(event.start, event.end, params.locale, event.timezoneId, event.allDay) + "\n";
            });
            message += "\n";
        }
        if(params.updatedEvents.length > 0) {
            message += localize("email_templates.create_events.before_dates.updated");
            _.each(params.updatedEvents, function(event) {
                message += "- " + event.title + " : " + CommonHelpers.formatDateTimeRangeInText(event.start, event.end, params.locale, event.timezoneId, event.allDay) + "\n";
            });
            message += "\n";
        }
        if(params.deletedEvents.length > 0) {
            message += localize("email_templates.create_events.before_dates.deleted");
            _.each(params.deletedEvents, function(event) {
                message += "- " + event.title + " : " + CommonHelpers.formatDateTimeRangeInText(event.start, event.end, params.locale, event.timezoneId, event.allDay) + "\n";
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
    }else if(params.action == "send_call_instructions") {
        var callInstructions = params.callInstructions;
        var callInstructionsMessage = '';

        if(callInstructions.target == 'later')
            message += '';
        else if(callInstructions.details != '' && callInstructions.details != null && callInstructions.details != undefined) {
            if (callInstructions.targetInfos.name != '' && (callInstructions.support == 'mobile' || callInstructions.support == 'landline' || callInstructions.support == 'confcall')) {

                //callInstructionsMessage = localize("email_templates.send_call_instructions.give_target_number", {
                //    target_name: callInstructions.targetInfos.name,
                //    details: callInstructions.details
                //});
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
            if(callInstructions.target != 'client')
                callInstructionsMessage = localize("email_templates.send_call_instructions.missing_infos");
        }

        message += callInstructionsMessage;
    }else if(params.action == "ask_additional_informations"){
        var attendees = params.attendees;
        var multipleAttendees = params.multipleAttendees;
        var assisted = params.assisted;
        var requiredAdditionalInformations = params.requiredAdditionalInformations;
        var redundantCourtesy = params.redundantCourtesy;

        var templateName = "email_templates.ask_additional_informations" + (multipleAttendees ? '.multiple_attendees' : '.single_attendee') + (requiredAdditionalInformations == 'skype_only' ? '.skype' : '.phone');

        if(!multipleAttendees)
            templateName += assisted ? ".assisted" : ".nonassisted";
        else
            templateName += attendees.length > 1 ? ".multiple_recipients" : ".single_recipient";

        var courtesyString = redundantCourtesy ? ' ' + localize('common.egalement'): '';

        message += localize(templateName, {
            attendees_names: attendees.join(', '),
            courtesyString: courtesyString
        });

    }
    else if(params.action == "forward_to_client") {
        message += localize("email_templates.forward_to_client");
    }

    window.setCurrentLocale(previousLocale);
    return message;
};