window.classificationForms.askAvailabilitiesForm = function(params) {
    window.classificationForms.classificationForm.isParentOf(this, params);
    this.alreadySuggestedDates = params.alreadySuggestedDates;

    var askAvailabilitiesForm = this;
    // Used to have a common accessor between all the different forms
    var currentClassifForm = askAvailabilitiesForm;

    window.leftColumnMessage = localize("classification_forms.ask_availabilities.dates_identification");

    function showAiThinkingLoader() {
        $('.submit-classification').hide();
        $('.ai-thinking-loader').show();
    };

    function hideAiThinkingLoader() {
        $('.submit-classification').show();
        $('.ai-thinking-loader').hide();
    };

    function isVirtual(appointment) {
      return appointment.appointment_kind_hash.is_virtual;
    };

    function locationIsSame(appointmentIsVirtual) {
        var isSame = true;
        if(!appointmentIsVirtual) {
            isSame = window.threadComputedData.location == $("#location").val();
        }

        return isSame;
    };
    
    function checkIfAppointmentTypeChangedFromVirtual(currentAppointmentIsVirtual) {
        var result = currentAppointmentIsVirtual;

        if(window.threadComputedData && window.threadComputedData.appointment_nature) {
            result = isVirtual(window.getAppointment(window.threadComputedData.appointment_nature)) == currentAppointmentIsVirtual;
        }

       return result;
    }

    function checkAppointmentDuration() {
        return $("#duration").val() <= window.threadComputedData.duration;
    }

    function checkAttendeesWhereInPreviousForm() {
        var currentlyPresentAttendeesEmails = _.map(window.presentAttendees(), function(att) {return att.email});
        var lastFormAttendeesEmails = _.map(window.threadComputedDataPresentAttendees, function(att) {return att.email});

        return _.difference(currentlyPresentAttendeesEmails, lastFormAttendeesEmails).length == 0;
    }

    function checkNoDatesSuggestionsFullAi() {
        return window.threadComputedData.date_suggestions_full_ai == false;
    }

    function canVerifyWithAiV1() {
        var currentAppointmentIsVirtual = isVirtual(window.getCurrentAppointment());
        var notChangedType = checkIfAppointmentTypeChangedFromVirtual(currentAppointmentIsVirtual);
        var notIncreasedDuration = checkAppointmentDuration();
        var notChangedLocation = locationIsSame(currentAppointmentIsVirtual);
        var notChangedTimezone = window.threadComputedData.timezone == $("#timezone").val().trim();
        var notChangedAttendees = checkAttendeesWhereInPreviousForm();

        return {
            notChangedType: notChangedType,
            notIncreasedDuration: notIncreasedDuration,
            notChangedLocation: notChangedLocation,
            notChangedTimezone: notChangedTimezone,
            notChangedAttendees: notChangedAttendees
        };
    };

    function canVerifyWithAiV2() {
        var noMeetingRoom = !$('#meeting-rooms-manager').scope().usingMeetingRoom;
        var noVirtualResources = !$('#virtual-meetings-helper').scope().usingVirtualResources();
        var noLinkedAttendees = $('#attendeesCtrl').scope().getLinkedAttendees().length == 0;
        var allCalendarServer = everyClientUsingCalendarServer();

        return {
            noMeetingRoom: noMeetingRoom,
            noVirtualResources: noVirtualResources,
            noLinkedAttendees: noLinkedAttendees,
            allCalendarServer: allCalendarServer
        };
    }

    function canVerifyWithAiV3() {

        var noMeetingRoom = !$('#meeting-rooms-manager').scope().usingMeetingRoom;
        var noVirtualResources = !$('#virtual-meetings-helper').scope().usingVirtualResources();
        var allCalendarServer = everyClientUsingCalendarServer();

        return {
            noMeetingRoom: noMeetingRoom,
            noVirtualResources: noVirtualResources,
            allCalendarServer: allCalendarServer
        };
    }

    function everyClientUsingCalendarServer() {
        return _.all(window.clientAccountTilesScope.accounts, function(acc) { return acc.using_calendar_server; });
    }

    window.submitClassification = function () {

        var message_classification_identifier = window.classificationForm.messageId + '-' + window.classificationForm.startedAt;

        var canVerifyV1Result = canVerifyWithAiV1();
        var canVerifyV2Result = canVerifyWithAiV2();
        var canVerifyV3Result = canVerifyWithAiV3();

        var canVerifyV1 = _.all(canVerifyV1Result, function(v,k) { return v;});
        var canVerifyV2 = _.all(canVerifyV2Result, function(v,k) { return v;});
        var canVerifyV3 = _.all(canVerifyV3Result, function(v,k) { return v;});

        var passedConditions = Object.assign(canVerifyV1Result, canVerifyV2Result);

        if(window.featuresHelper.isFeatureActive('ai_dates_verification')) {

            var highlightedEmailNode = $('.email.highlighted');

            var datesFromLastSuggestions = _.map($('.dates-identification-panel').data('last-dates-suggested'), function(date) {
                return moment(date.date).utc().format("YYYY-MM-DDTHH:mm:ss");
            });
            var aiDatesVerificationManager = $('#ai_dates_verification_manager').scope();

            var datesToVerify = _.compact(_.map(classificationForm.getSuggestedDateTimes(), function(date) {
                var currentDate = moment(date.date).utc().format("YYYY-MM-DDTHH:mm:ss");
                var result = undefined;

                if(datesFromLastSuggestions.indexOf(currentDate) > -1) {
                    result = currentDate;
                }

                return result
            }));

            var clientOnTripScope = $("#client-on-trip-data-entry").scope();

            var threadData = $.extend({}, window.threadComputedData);
            threadData.appointment_nature = threadData.appointment_nature || $('#appointment_nature').val();

            var verifyParams = {
                account_email: window.threadAccount.email,
                thread_data: threadData,
                dates_to_check: datesToVerify,
                server_message_id: highlightedEmailNode.attr('id'),
                today_date: moment().utc().format("YYYY-MM-DDTHH:mm:ss"),
                attendees: $('#attendeesCtrl').scope().attendees,
                check_differences: true,
                message_id: window.classificationForm.messageId,
                message_classification_identifier: message_classification_identifier,
                client_on_trip: clientOnTripScope && clientOnTripScope.value
                //message_id: highlightedEmailNode.data('message-id'),
            };

            verifyParams.raw_constraints_data = $(".constraint-tile-container").map(function () {
                return $(this).data("constraint")
            }).get();

            verifyParams.meeting_rooms_to_show =  _.map($('#meeting-rooms-manager').scope().getCurrentMeetingRoomsToDisplay(), function(mR) { return mR.id; });
            verifyParams.all_conditions_satisfied = canVerifyV1;
            
            if (canVerifyV3 && classificationForm.getSuggestedDateTimes().length > 0) {
                verifyParams.dates_to_check = [];

                _.each(classificationForm.getSuggestedDateTimes(), function(date) {
                    verifyParams.dates_to_check.push(moment(date.date).utc().format("YYYY-MM-DDTHH:mm:ss"));
                });

                aiDatesVerificationManager.verifyDatesV3(verifyParams).then(
                    function(response) {
                        var verifiedDatesByAI = undefined;

                        if(!response.error && response.status != 'fail') {
                            var verifiedDates = [];
                            var now = moment();
                            _.each(response.dates_validate, function (validated, date) {
                                if (validated && moment(date).isAfter(now)) {
                                    // Add Z at the end of the date string to specify momentJS it is an utc date
                                    verifiedDates.push(date+'Z');
                                }
                            });

                            if(verifiedDates.length > 0) {
                                verifiedDates = _.sortBy(verifiedDates, function(date) {
                                    return moment(date).valueOf();
                                });

                                verifiedDatesByAI = {verified_dates: verifiedDates, timezone: response.timezone};
                            } else {
                                verifiedDatesByAI = {no_suitable_dates: true};
                            }
                        } else {
                            var errorStr = response.error ? 'timeout' : 'fail';
                            verifiedDatesByAI = {error_response:  errorStr};
                        }

                        askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: verifiedDatesByAI, message_classification_identifier: verifyParams.message_classification_identifier});
                    }, function(error) {
                        askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: {error_response: 'http request failed'}, message_classification_identifier: verifyParams.message_classification_identifier});
                    }
                );
            }

            // if (canVerifyV2) {
            //     if(datesToVerify.length > 0) {
            //
            //         showAiThinkingLoader();
            //         aiDatesVerificationManager.verifyDatesV2(verifyParams).then(
            //             function(response) {
            //
            //                 var verifiedDatesByAI = undefined;
            //
            //                 if(!response.error && response.status != 'fail') {
            //                     var verifiedDates = [];
            //                     var now = moment();
            //                     _.each(response.dates_validate, function (validated, date) {
            //                         if (validated && moment(date).isAfter(now)) {
            //                             // Add Z at the end of the date string to specify momentJS it is an utc date
            //                             verifiedDates.push(date+'Z');
            //                         }
            //                     });
            //
            //                     if(verifiedDates.length > 0) {
            //                         verifiedDates = _.sortBy(verifiedDates, function(date) {
            //                             return moment(date).valueOf();
            //                         });
            //
            //                         verifiedDatesByAI = {verified_dates: verifiedDates, timezone: response.timezone};
            //                     } else {
            //                         verifiedDatesByAI = {no_suitable_dates: true};
            //                     }
            //                 } else {
            //                     var errorStr = response.error ? 'timeout' : 'fail';
            //                     verifiedDatesByAI = {error_response:  errorStr};
            //                 }
            //
            //                 askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: verifiedDatesByAI, message_classification_identifier: verifyParams.message_classification_identifier});
            //             }, function(error) {
            //                 askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: {error_response: 'http request failed'}, message_classification_identifier: verifyParams.message_classification_identifier});
            //             }
            //         );
            //
            //     } else {
            //         askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: {error_response: 'No call made because no dates to verify'}, message_classification_identifier: message_classification_identifier});
            //     }
            // }
            else {
                askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: {error_response: 'No call made'}, message_classification_identifier: message_classification_identifier});
            }
        } else {
            askAvailabilitiesForm.sendForm({passed_conditions: passedConditions, verifiedDatesByAI: {error_response: 'No call made'}, message_classification_identifier: message_classification_identifier});
        }

        //askAvailabilitiesForm.sendForm();
    };

    $(function(e) {
        $(".client-agreement-panel .yes-button").click(function () {
            window.acceptClientAgreement();
        });

        askAvailabilitiesForm.checkClientAgreement();

        $("#submit-these-already-suggested-dates").click(function() {
            trackActionV2('Click_on_validate_suggested_dates', {ux_element: 'standDC'});
            askAvailabilitiesForm.submitSuggestedDates(true);
        });
        $("#none-of-already-suggested-dates").click(function() {
            trackActionV2('Click_on_select_other_dates', {ux_element: 'standDI'});
            askAvailabilitiesForm.submitSuggestedDates(false);
        });
        $("#submit-detected-date-button").click(function() {
            trackActionV2('Click_on_validate_other_dates', {ux_element: 'standDI'});
            askAvailabilitiesForm.submitDetectedDates();
        });

        $(".already-suggested-dates-container .already-suggested-date input[type=checkbox]").change(function() {
            askAvailabilitiesForm.changeAlreadySuggestedDateCheckbox();
        });
        $("body").on("click", ".detected-date .detected-date-remove-button", function(e) {
            $(this).closest(".detected-date").remove();
        });
        $("#add-detected-date-button").click(function(e) {
            askAvailabilitiesForm.appendDetectedDateRow({
                startDate: moment()
            });
        });

        askAvailabilitiesForm.processDateDetection();
        askAvailabilitiesForm.changeAlreadySuggestedDateCheckbox();


        $(".classic-info-panel").hide();
        //$(".waiting-for-others-panel").show();
        //window.acceptClientAgreement();

    });

    // When the dates identification manager has been loaded, we bypass when possible the client agreement validation
    window.datesIdentificationManageInitiatedCallback = function() {
        window.acceptClientAgreement();
    };

    window.acceptClientAgreement = function() {
        askAvailabilitiesForm.validateClientAgreement(true, true);
    };
};



window.classificationForms.askAvailabilitiesForm.prototype.getSuggestedDateTimes = function() {
    var askAvailabilitiesForm = this;

    return $.map(askAvailabilitiesForm.suggestedDates, function(d) {
        if(d.date) {
            return {
                date: d.date.clone().tz("utc").format(),
                timezone: d.date.tz()
            }
        }
        else {
            return {
                text: d.text
            }
        }
    });
};

window.classificationForms.askAvailabilitiesForm.prototype.checkAlreadySuggestedDates = function() {
    var askAvailabilitiesForm = this;
    var datesmanager = $('#dates-identifications-manager').scope();

    $(".messages-thread-info-panel .classic-info-panel").hide();
    $(".messages-thread-info-panel .dates-identification-panel").show();
    if(askAvailabilitiesForm.alreadySuggestedDates.length > 0) {
        $(".messages-thread-info-panel .dates-identification-panel .already-suggested-dates-container").show();
        $(".messages-thread-info-panel .dates-identification-panel .detected-dates-container").hide();
        datesmanager.showAlreadySuggestedDates();
    }
    else {
        $(".messages-thread-info-panel .dates-identification-panel .already-suggested-dates-container").hide();
        $(".messages-thread-info-panel .dates-identification-panel .detected-dates-container").show();
        datesmanager.showDetectedDates();
    }

    datesmanager.$apply();
};

window.classificationForms.askAvailabilitiesForm.prototype.submitSuggestedDates = function(answerToSuggestedDates) {
    var askAvailabilitiesForm = this;
    var datesManager = $('#dates-identifications-manager').scope();

    if(answerToSuggestedDates) {
        askAvailabilitiesForm.suggestedDates = $(".already-suggested-dates-container .already-suggested-date input[type=checkbox]:checked").map(function() {
            var date = $(this).closest(".already-suggested-date").data("date");
            var timezone = $(this).closest(".already-suggested-date").data("timezone");
            return {
                date: moment(date).tz(timezone)
            };
        }).toArray();
        $(".messages-thread-info-panel .dates-identification-panel").hide();
        $(".messages-thread-info-panel .classic-info-panel").show();

        askAvailabilitiesForm.addSuggestedDatesToHeader();

        askAvailabilitiesForm.clickBackButtonFunctions.push(function() {
            $(".messages-thread-info-panel .dates-identification-panel").show();
            $(".messages-thread-info-panel .classic-info-panel").hide();
            askAvailabilitiesForm.removeSuggestedDatesToHeader();
        });
    }
    else {
        datesManager.showDetectedDates();
        if(!datesManager.$$phase)
            datesManager.$apply();

        askAvailabilitiesForm.clickBackButtonFunctions.push(function() {
            askAvailabilitiesForm.removeSuggestedDatesToHeader();
            datesManager.showAlreadySuggestedDates();
            if(!datesManager.$$phase)
                datesManager.$apply();
        });
    }
};

window.classificationForms.askAvailabilitiesForm.prototype.submitDetectedDates = function() {
    var askAvailabilitiesForm = this;
    var datesManager = $('#dates-identifications-manager').scope();

    askAvailabilitiesForm.suggestedDates = $(".detected-dates-container .detected-dates .detected-date").map(function() {
        var $radio = $(this).find(".detected-date-radios input[type=radio]:checked");
        if($radio.length > 0 && $radio.val() == "freetext") {
            return {
                text: $(this).find(".detected-date-freetext").val()
            };
        }
        else {
            var mDate = moment.tz($(this).find(".detected-date-real-date").val() + "T" + $(this).find(".detected-date-time").val(), $(this).find(".detected-date-timezone").val());
            return {
                date: mDate
            };
        }
    }).toArray();
    $(".messages-thread-info-panel .dates-identification-panel").hide();
    $(".messages-thread-info-panel .classic-info-panel").show();

    askAvailabilitiesForm.addSuggestedDatesToHeader();

    askAvailabilitiesForm.clickBackButtonFunctions.push(function() {
        askAvailabilitiesForm.removeSuggestedDatesToHeader();
        datesManager.showDetectedDates();
        if(!datesManager.$$phase)
            datesManager.$apply();
        $(".messages-thread-info-panel .dates-identification-panel").show();
        $(".messages-thread-info-panel .classic-info-panel").hide();
    });
};

window.classificationForms.askAvailabilitiesForm.prototype.processDateDetection = function() {
    var askAvailabilitiesForm = this;
    var addedDates = [];

    $(".detected-dates").html("");

    var timeEntities = $('.email.highlighted .body .juliedesk-entity.time');

    detectedDates = _.each(timeEntities, function(node) {
        var $node = $(node);
        var date = $node.attr('value');

        if(addedDates.indexOf(date) == -1) {
            askAvailabilitiesForm.appendDetectedDateRow({
                text: $node.text(),
                startDate: moment(date)
            });
        }

        addedDates.push(date);
    });

    //if(mainAiInterpretation && !mainAiInterpretation.error && mainAiInterpretation.raw_response) {
    //    var datesToCheck = JSON.parse(mainAiInterpretation.raw_response).dates_to_check;
    //    if(datesToCheck && datesToCheck.length > 0) {
    //        var suggestedTimesNodes = $('.already-suggested-date');
    //        var currentNodeDate;
    //        var current$Node;
    //        datesToCheck = _.map(datesToCheck, function(date) {
    //           return moment(date);
    //        });
    //        _.each(suggestedTimesNodes, function(node) {
    //            current$Node = $(node);
    //            currentNodeDate = moment(current$Node.data('date'));
    //            console.log(currentNodeDate);
    //            _.every(datesToCheck, function(date) {
    //                if(currentNodeDate.isSame(date)) {
    //                    console.log('hereeee');
    //                    // We trigger the change event to undisable the "Oui" button in the suggestion date pannel
    //                    current$Node.find('input[type="checkbox"]').prop('checked', true).trigger('change');
    //                    return false;
    //                }
    //                return true;
    //            });
    //        });
    //    }
    //}
};

window.classificationForms.askAvailabilitiesForm.prototype.removeSuggestedDatesToHeader = function() {
    $("#selected-suggested-dates").html("");
};

window.classificationForms.askAvailabilitiesForm.prototype.addSuggestedDatesToHeader = function() {
    var askAvailabilitiesForm = this;

    askAvailabilitiesForm.removeSuggestedDatesToHeader();
    var $dataEntry = $("<div>").addClass("data-entry");
    var $dataEntryName = $("<div>").addClass("data-entry-name").html(localize("classification_forms.ask_availabilities.suggested_dates"));
    var $dataEntryValue = $("<div>").addClass("data-entry");

    $.each(askAvailabilitiesForm.suggestedDates, function(k, v) {
        var formattedDate = "";
        if(v.date) {
            formattedDate = v.date.format(localize("email_templates.common.full_date_format"));
            formattedDate = formattedDate + "<br>";
            formattedDate = formattedDate + v.date.tz();
        }
        else {
            formattedDate = v.text;
        }

        $dataEntryValue.append($("<div>").html(formattedDate));
    });
    $dataEntry.append($dataEntryName);
    $dataEntry.append($dataEntryValue);
    $("#selected-suggested-dates").append($dataEntry);

    $("#selected-suggested-dates").append("<br/><br/>");
};

window.classificationForms.askAvailabilitiesForm.prototype.appendDetectedDateRow = function(params) {

    var $detectedDate = $("<div>").addClass("detected-date");
    if(params.text) {
        var $detectedDateText = $("<div>").addClass("detected-date-text").html(params.text);
        $detectedDate.append($detectedDateText);
    }


    var mStartDate = params.startDate;
    var $detectedDateDate = $("<input>").addClass("detected-date-date").val(mStartDate.format("dddd D MMMM YYYY"));
    $detectedDate.append($detectedDateDate);

    var $detectedDateRealDate = $("<input>").addClass("detected-date-real-date").val(mStartDate.format("YYYY-MM-DD"));
    $detectedDate.append($detectedDateRealDate);

    var $detectedDateTime = $("<input>").addClass("detected-date-time").val(mStartDate.format("HH:mm"));
    $detectedDate.append($detectedDateTime);

    var timezone = mStartDate.tz();
    if(!timezone) {
        timezone = window.threadComputedData.timezone;
    }
    var $detectedDateTimezone = $("<input>").addClass("detected-date-timezone").val(timezone);
    $detectedDate.append($detectedDateTimezone);

    var $detectedDateRemoveButton = $("<div>").addClass("detected-date-remove-button").html("x");
    $detectedDate.append($detectedDateRemoveButton);



    $(".detected-dates").append($detectedDate);

    $(".detected-dates .detected-date:last .detected-date-time").timepicker({timeFormat: 'H:i'});
    $(".detected-dates .detected-date:last .detected-date-date").each(function() {
        var $input = $(this);
        $input.datepicker({
            dateFormat: 'DD d MM yy',
            altField: $(this).siblings(".detected-date-real-date"),
            altFormat : 'yy-mm-dd',
            minDate: new Date,
        });
    });
    $(".detected-dates .detected-date:last .detected-date-timezone").timezonePicker();
};

window.classificationForms.askAvailabilitiesForm.prototype.changeAlreadySuggestedDateCheckbox = function() {
    $checkedCheckboxes = $(".already-suggested-dates-container .already-suggested-date input[type=checkbox]:checked");
    if($checkedCheckboxes.length == 0) {
        $("#none-of-already-suggested-dates").removeAttr("disabled");
        $("#submit-these-already-suggested-dates").attr("disabled", "disabled");
    }
    else {
        $("#none-of-already-suggested-dates").attr("disabled", "disabled");
        $("#submit-these-already-suggested-dates").removeAttr("disabled");
    }
};

window.classificationForms.askAvailabilitiesForm.prototype.onceAgreementAndAttendeesNoticedDone = function() {
    var askAvailabilitiesForm = this;
    askAvailabilitiesForm.checkAlreadySuggestedDates();
};

window.classificationForms.askAvailabilitiesForm.prototype.onceAgreementAndAttendeesNoticedDoneRevert = function() {
    $(".messages-thread-info-panel .dates-identification-panel").hide();
};