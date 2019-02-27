window.classificationForms = {};

window.classificationForms.createClassificationForm = function (params) {
    if (!params) params = {};
    var form;

    if (params.classification == "ask_date_suggestions") {
        form = new window.classificationForms.askDateSuggestionsForm(params);
    }
    else if (params.classification == "ask_availabilities") {
        form = new window.classificationForms.askAvailabilitiesForm(params);
    }
    else if (params.classification == "give_info" || params.classification == "update_event") {
        form = new window.classificationForms.giveInfoForm(params);
    }
    else if (params.classification == "ask_cancel_appointment") {
        form = new window.classificationForms.askCancelAppointment(params);
    }
    else if (params.classification == "ask_cancel_events") {
        form = new window.classificationForms.askCancelEvents(params);
    }
    else if (params.classification == "ask_postpone_events") {
        form = new window.classificationForms.askPostponeEvents(params);
    }
    else if (params.classification == "give_preference") {
        form = new window.classificationForms.givePreferenceForm(params);
    }
    else if (params.classification == "wait_for_contact") {
        form = new window.classificationForms.waitForContactForm(params);
    }
    else if (params.classification == "follow_up_on_weekly_recap") {
        form = new window.classificationForms.followUpOnWeeklyRecapForm(params);
    }
    else if (params.classification == "invitation_already_sent") {
        form = new window.classificationForms.invitationSentEvents(params);
    }
    else if(params.classification == "follow_up_contacts") {
        form = new window.classificationForms.followUpContactsForm(params);
    }
    else {
        throw "No classification form defined for classification: '" + params.classification + "'";
    }

    return form;
};

window.classificationForms.classificationForm = function (params) {
    this.startedAt = params.startedAt;
    this.classification = params.classification;
    this.messageId = params.messageId;
    this.locale = params.locale;
    this.threadLocale = params.threadLocale;
    this.classification = params.classification;
    this.isPostpone = params.isPostpone;
    this.clientAgreement = params.clientAgreement;
    this.clickBackButtonFunctions = [];

    var classificationForm = this;

    setCurrentLocale(classificationForm.locale);
    window.threadDataIsEditable = true;

    $(function () {
        $("#back-button").click(function () {
            trackActionV2('Click_on_back_app', {ux_element: 'backoffice'});
            if (classificationForm.clickBackButtonFunctions.length == 0) {
                window.history.back();
            }
            else {
                var backFunction = classificationForm.clickBackButtonFunctions.pop();
                backFunction();
            }
        });

        $(".client-agreement-panel .no-button").click(function () {
            classificationForm.validateClientAgreement(false);
        });
        $(".attendees-are-noticed-panel .yes-button").click(function () {
            classificationForm.validateAttendeesAreNoticed(true);
        });
        $(".attendees-are-noticed-panel .no-button").click(function () {
            classificationForm.validateAttendeesAreNoticed(false);
        });
    });
};
window.classificationForms.classificationForm.isParentOf = function(child, params) {
    window.classificationForms.classificationForm.call(child, params);
    _.each(window.classificationForms.classificationForm.prototype, function(method, methodName) {
        if(!(methodName in child.__proto__)) {
            child.__proto__[methodName] = method;
        }
    });
};

window.classificationForms.classificationForm.prototype.sendFormOnlyLocale = function () {
    var classificationForm = this;

    var data = {
        classification: classificationForm.classification,
        locale: $("input[name='locale_only']:checked").val(),
        processed_in: Date.now() - classificationForm.startedAt
    };

    $.ajax({
        url: "/messages/" + classificationForm.messageId + "/classify",
        type: "POST",
        data: data,
        success: function (e) {
            window.location = e.redirect_url;
        },
        error: function (e) {
            console.log("Error: ", e);
        }
    });
};

window.classificationForms.classificationForm.prototype.validateConstaintsData = function (constraints_data) {
    var valid = true;

    _.each(constraints_data, function(constraint) {
       if(constraint.start_time && constraint.end_time) {
           var startTimeSplitted = constraint.start_time.split(':');
           var endTimeSplitted = constraint.end_time.split(':');

           var startTime = moment().hour(startTimeSplitted[0]).minute(startTimeSplitted[1]).second(0);
           var endTime = moment().hour(endTimeSplitted[0]).minute(endTimeSplitted[1]).second(0);

           if(startTime.isAfter(endTime)) {
               valid = false;
           }
       }
    });

    return valid;
};

window.classificationForms.classificationForm.prototype.getTimezoneForSendForm = function() {
    var timezone = $("#timezone").val().trim();
    var vmHelper = angular.element($('#virtual-meetings-helper')).scope();

    if(vmHelper && vmHelper.isVirtualAppointment()) {
        timezone = _.find(window.getInfoPanelAttendeesForSendForm(), function(attendee) {
            return threadAccount.email_aliases.concat([threadAccount.email]).indexOf(attendee.email) > -1;
        }).timezone;
    }
    return timezone;
};

window.classificationForms.classificationForm.prototype.getConstraintsDataForSendForm = function() {
    return $(".constraint-tile-container").map(function () {
        return $(this).data("constraint")
    }).get();
};

window.classificationForms.classificationForm.prototype.sendFormConscienceLoading = function(isLoading) {
    this.sendFormLoading(isLoading, "Jul.IA is thinking...");
};

window.classificationForms.classificationForm.prototype.sendFormLoading = function(isLoading, loadingMessage) {
    if(isLoading) {
        $(".submit-classification").prop("disabled", true);
        $(".submit-classification .submit-classification-text").hide();
        $(".submit-classification .basic-loader-in-save-button-text").html(loadingMessage);
        $(".submit-classification .basic-loader-in-save-button").show();
    }
    else {
        $(".submit-classification").prop("disabled", false);
        $(".submit-classification .basic-loader-in-save-button").hide();
        $(".submit-classification .basic-loader-in-save-button-text").html("");
        $(".submit-classification .submit-classification-text").show();
    }
};

window.classificationForms.classificationForm.prototype.sendForm = function (params) {
    params = params || {};
    var classificationForm = this;
    var meetingRoomManager = $('#meeting-rooms-manager').scope();
    var restaurantBookingManager = $('#restaurant-booking-manager').scope();
    var vmHelper = angular.element($('#virtual-meetings-helper')).scope();
    var currentAppointment = window.getCurrentAppointment();

    classificationForm.sendFormLoading(true, "Loading...");

    var errorInConstraintTiles = false;
    $(".constraint-tile-container").each(function () {
        errorInConstraintTiles = errorInConstraintTiles || ($(this).data("constraint") == null);
    });

    if(errorInConstraintTiles) {
        alert("Please fix incorrect constraints.");
        classificationForm.sendFormLoading(false);
        return;
    }

    var timezone = classificationForm.getTimezoneForSendForm();

    var constraints_data = classificationForm.getConstraintsDataForSendForm();

    if(!classificationForm.validateConstaintsData(constraints_data)) {
        alert('Some constraints are invalid, please make sure that the constraints starting dates are sooner than the ending dates');
        classificationForm.sendFormLoading(false);
        return
    }

    var data = {
        locale: $("input[name='locale']:checked").val(),
        // Need to trim the timezone because it can lead to bug as 'Europe/Berlin  ' is not recognized as a correct timezone
        timezone: timezone,
        classification: classificationForm.classification,
        appointment_nature: $("#appointment_nature").val(),
        summary: $("#summary").val(),
        duration: $("#duration").val(),
        location_nature: $("#location_nature").val(),
        location: $("#location").val(),
        cluster_specified_location: $('#cluster_specified_location').val(),
        client_on_trip: $("#client-on-trip-data-entry").scope().value,
        location_coordinates: $('#location_coordinates').val(),
        call_instructions: window.getCallInstructions(),
        notes: window.notesManager.getJulieDeskNotesHTML(),
        other_notes: $("#other_notes").val(),
        private: $("#private:checked").length > 0,
        // We send the old_attendees for optimization purpose when looking if we need to recompute the linked attendees
        old_attendees: _.filter(window.threadComputedData.attendees, function(att) { return att.isPresent == 'true' }),
        attendees: window.getInfoPanelAttendeesForSendForm(),
        constraints: $("#constraints").val(),
        constraints_data: constraints_data,
        client_agreement: true,
        attendees_are_noticed: $(".attendees-are-noticed-panel").data("attendees-are-noticed"),
        number_to_call: $("#number_to_call").val(),
        date_times: classificationForm.getSuggestedDateTimes(),
        processed_in: Date.now() - classificationForm.startedAt,
        title_preference: $('.title-preferences-checkbox:checked').val(),
        // We separate using_meeting_room and meeting_room_details to have a quick access to the using_meeting_room boolean
        // on the model without having to link into the JSON
        using_meeting_room: meetingRoomManager.getUsingMeetingRoom() || undefined,
        meeting_room_details: meetingRoomManager.getMeetingRoomDetails() || undefined,
        booked_rooms_details: meetingRoomManager.getBookedRoomsDetails() || undefined,
        // We separate using_meeting_room and meeting_room_details to have a quick access to the using_restaurant_booking boolean
        // on the model without having to link into the JSON
        using_restaurant_booking: restaurantBookingManager.getUsingRestaurantBooking() || undefined,
        restaurant_booking_details: restaurantBookingManager.getRestaurantBookingDetails() || undefined,
        location_changed: window.threadComputedData.location != $("#location").val(),
        before_update_data: JSON.parse(params.before_update_data),
        verified_dates_by_ai: params.verifiedDatesByAI,
        passed_conditions: params.passed_conditions,
        message_classification_identifier: params.message_classification_identifier,
        date_suggestions_from_ai: params.dateSuggestionsFromAi,
        language_level: $("input[name='language_level']:checked").val(),
        asap_constraint: $("input[name='asap_constraint']:checked").length > 0
    };

    if(vmHelper && vmHelper.isVirtualAppointment() && vmHelper.selectedVirtualResource !== undefined) {
        data.virtual_resource_used = vmHelper.selectedVirtualResource;
    }

    // We don't care about the location of the apointment when it is a virtual one
    // We use the location to know the available meeting rooms to a client when he is performing a virtual appointment
    if(currentAppointment && currentAppointment.appointment_kind_hash.is_virtual) {
        data.location = '';
    }

    if(window.currentEventTile) {
        data.event_booked_date = window.currentEventTile.getEditedEvent().start.format();
    }

    if(data.classification == 'ask_date_suggestions' && window.threadComputedData.do_not_ask_suggestions && window.location.hash == '#ignore_linked_attendees')
        data.ignore_linked_attendees = true;

    $.ajax({
        url: "/messages/" + classificationForm.messageId + "/classify",
        type: "POST",
        data: data,
        success: function (e) {
            window.location = e.redirect_url;
        },
        error: function (e) {
            console.log("Error: ", e);
            classificationForm.sendFormLoading(false);
        }
    });

};



window.classificationForms.classificationForm.prototype.getSuggestedDateTimes = function () {
    return [];
};


window.classificationForms.classificationForm.prototype.checkClientAgreement = function () {

    var classificationForm = this;

    var $infoPanelContainer = $(".messages-thread-info-panel");

    if(classificationForm.clientAgreement) {
        $infoPanelContainer.find(".client-agreement-panel").data("client-agreement", true);
        $infoPanelContainer.find(".attendees-are-noticed-panel").data("attendees-are-noticed", true);
        classificationForm.onceAgreementAndAttendeesNoticedDone();
    }
    else {
        $infoPanelContainer.find(".classic-info-panel").hide();
        $infoPanelContainer.find(".client-agreement-panel").show();
        $infoPanelContainer.find(".client-agreement-panel").data("client-agreement", false);
        $infoPanelContainer.find(".attendees-are-noticed-panel").data("attendees-are-noticed", false);
    }
};

window.classificationForms.classificationForm.prototype.validateClientAgreement = function (clientAgreement, attendeesAreNoticedImplied) {
    var classificationForm = this;

    var $infoPanelContainer = $(".messages-thread-info-panel");
    $infoPanelContainer.find(".client-agreement-panel").data("client-agreement", clientAgreement);

    trackActionV2("Click_on_agreement", {ux_element: 'form'});

    if(clientAgreement) {
        if(classificationForm.isPostpone) {
            $infoPanelContainer.find(".client-agreement-panel").hide();

            if(attendeesAreNoticedImplied) {
                $infoPanelContainer.find(".attendees-are-noticed-panel").data("attendees-are-noticed", true);
                classificationForm.onceAgreementAndAttendeesNoticedDone();

                classificationForm.clickBackButtonFunctions.push(function () {
                    classificationForm.onceAgreementAndAttendeesNoticedDoneRevert();
                    $infoPanelContainer.find(".client-agreement-panel").show();
                });
            }
            else {
                $infoPanelContainer.find(".attendees-are-noticed-panel").show();
                $infoPanelContainer.find(".attendees-are-noticed-panel").data("attendees-are-noticed", false);
                classificationForm.clickBackButtonFunctions.push(function () {
                    $infoPanelContainer.find(".attendees-are-noticed-panel").hide();
                    $infoPanelContainer.find(".client-agreement-panel").show();
                });
            }



        }
        else {
            $infoPanelContainer.find(".client-agreement-panel").hide();
            classificationForm.onceAgreementAndAttendeesNoticedDone();

            classificationForm.clickBackButtonFunctions.push(function () {
                classificationForm.onceAgreementAndAttendeesNoticedDoneRevert();
                $infoPanelContainer.find(".client-agreement-panel").show();
            })
        }
    }
    else {
        if(classificationForm.isPostpone) {
            $infoPanelContainer.find(".attendees-are-noticed-panel").data("attendees-are-noticed", true);
        }
        $infoPanelContainer.find(".client-agreement-panel").hide();
        classificationForm.onceAgreementAndAttendeesNoticedDone();

        classificationForm.clickBackButtonFunctions.push(function () {
            classificationForm.onceAgreementAndAttendeesNoticedDoneRevert();
            $infoPanelContainer.find(".client-agreement-panel").show();
        })
    }
};
window.classificationForms.classificationForm.prototype.validateAttendeesAreNoticed = function (attendeesAreNoticed) {
    var classificationForm = this;

    var $infoPanelContainer = $(".messages-thread-info-panel");
    $infoPanelContainer.find(".attendees-are-noticed-panel").data("attendees-are-noticed", attendeesAreNoticed);

    $infoPanelContainer.find(".attendees-are-noticed-panel").hide();
    classificationForm.onceAgreementAndAttendeesNoticedDone();

    classificationForm.clickBackButtonFunctions.push(function () {
        classificationForm.onceAgreementAndAttendeesNoticedDoneRevert();
        $infoPanelContainer.find(".attendees-are-noticed-panel").show();
    })
};

window.classificationForms.classificationForm.prototype.onceAgreementAndAttendeesNoticedDone = function() {
    $(".messages-thread-info-panel .classic-info-panel").show();
};

window.classificationForms.classificationForm.prototype.onceAgreementAndAttendeesNoticedDoneRevert = function() {
    $(".messages-thread-info-panel .classic-info-panel").hide();
};
