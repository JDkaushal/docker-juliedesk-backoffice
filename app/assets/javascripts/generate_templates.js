    window.generateEmailTemplate = function (params) {
    var previousLocale = window.getCurrentLocale();
    window.setCurrentLocale(params.locale);

    message = "";

    var locationInTemplate = "";
    if(params.address) {
        if(params.address.address_in_template) {
            locationInTemplate = " " + params.address.address_in_template[params.locale];
        }
        else {
            locationInTemplate = " " + localize("email_templates.common.custom_address_at", {location: params.address});
        }
    }


    var isVirtualAppointment = false;
    if(params.appointment) {
        isVirtualAppointment = ["call", "skype", "webex"].indexOf(params.appointment.label) > -1;
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
                        message += localize("email_templates.suggest_dates.before_dates.new_appointment", {
                            client: params.client,
                            appointment_nature: params.appointment.title_in_email[params.locale],
                            location: locationInTemplate
                        });
                    }

                }


                if (params.timezoneId != params.defaultTimezoneId || isVirtualAppointment) {
                    message += "\n" + localize("email_templates.common.timezone_precision", {timezone: params.timezoneId.replace("_", " ")});
                }

                _.each(params.timeSlotsToSuggest, function (timeSlot) {
                    message += "\n - " + window.helpers.capitalize(moment(timeSlot).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
                });
                var timeSlotsPlural = "plural";
                if (params.timeSlotsToSuggest.length == 1) timeSlotsPlural = "singular";
                message += localize("email_templates.suggest_dates.after_dates." + timeSlotsPlural);
                if (params.appointment.label == "call") {
                    message += localize("email_templates.suggest_dates.ask_number.call");
                }
                else if (params.appointment.label == "skype") {
                    message += localize("email_templates.suggest_dates.ask_number.skype");
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
        var dateString = "";

        var timezoneIds = params.allTimezoneIds;
        if (params.allTimezoneIds.length == 0) {
            timezoneIds = [params.defaultTimezoneId];
        }
        if (timezoneIds.length == 1 && timezoneIds[0] == params.defaultTimezoneId && !isVirtualAppointment) {
            dateString = window.helpers.capitalize(moment(params.timeSlotToCreate).tz(params.defaultTimezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
        }
        else {
            for (var i = 0; i < timezoneIds.length; i++) {
                if (dateString != "") {
                    dateString = dateString + "\n";
                }
                dateString = dateString + window.helpers.capitalize(moment(params.timeSlotToCreate).tz(timezoneIds[i]).locale(params.locale).format(localize("email_templates.common.full_date_format"))) + " " + localize("email_templates.common.timezone_precision", {timezone: timezoneIds[i].replace("_", " ")});
            }
        }

        var postponeSuffix = "new_appointment";
        if(params.isPostpone)  postponeSuffix = "postpone";
        message = localize("email_templates.invites_sent." + postponeSuffix, {
            appointment_nature: params.appointment.title_in_email[params.locale],
            location: locationInTemplate,
            date: dateString
        });
    }
    else if(params.action == "cancel_event") {
        var dateString = window.helpers.capitalize(moment(params.currentEventData).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
        if(params.timezoneId != params.defaultTimezoneId) {
            dateString = dateString + " " + localize("email_templates.common.timezone_precision", {timezone: params.timezoneId.replace("_", " ")});
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
        message += localize("email_templates.create_events.before_dates");
        _.each(_.filter(params.newEventEventTiles, function(eventTile) {
            return eventTile.eventId && eventTile.event.title && eventTile.event.start;
        }), function(eventTile) {
            message += "- " + eventTile.event.title + " : " + CommonHelpers.formatDateTimeRangeInText(eventTile.event.start, eventTile.event.end, params.locale, eventTile.getTimezoneId(), eventTile.event.allDay) + "\n";
        });
    }
    else if(params.action == "client_agreement") {
        var dateTimesToCheckPlural = "singular";
        if(params.dateTimesToCheck.length > 1)  dateTimesToCheckPlural = "plural";
        var available = "available";
        if(!params.isAvailable) available = "not_available";
        appointmentNature = params.appointment.title_in_email[params.locale];
        message += localize("email_templates.client_agreement.prefix." + available + "." + dateTimesToCheckPlural, {
            appointment_nature: appointmentNature
        });
        _.each(params.dateTimesToCheck, function(dateTime) {
            message += "- " + moment(dateTime).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")) + "\n";
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
        if(params.kind == "postpone") {
            wordingBase = "postpone_multiple";
        }
        if (params.selectedEventsToCancel.length > 0) {
            var toCancelPlural = (params.selectedEventsToCancel.length > 1) ? "plural" : "singular";
            message += localize("email_templates." + wordingBase + ".noted_gonna_cancel." + toCancelPlural);

            _.each(params.selectedEventsToCancel, function (selectedEvent) {
                var dateString = window.helpers.capitalize(moment(selectedEvent.start).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
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
                var dateString = window.helpers.capitalize(moment(selectedEvent.start).tz(params.timezoneId).locale(params.locale).format(localize("email_templates.common.full_date_format")));
                message += " - " + selectedEvent.title + " (" + dateString.replace(/<br>/g, " ") + ")\n";
            });
            message += localize("email_templates." + wordingBase + ".what_should_i_do." + notToCancelPlural);
        }
    }
    else if(params.action == "send_confirmation") {
        message += localize("email_templates.confirmation");
    }
    window.setCurrentLocale(previousLocale);
    return message;
};