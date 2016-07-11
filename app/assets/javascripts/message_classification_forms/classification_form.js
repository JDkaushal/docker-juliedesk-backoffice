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
    } else {
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
    console.log(classificationForm);
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

window.classificationForms.classificationForm.prototype.sendForm = function () {
    var classificationForm = this;

    var errorInConstraintTiles = false;
    $(".constraint-tile-container").each(function () {
        errorInConstraintTiles = errorInConstraintTiles || ($(this).data("constraint") == null);
    });
    if(errorInConstraintTiles) {
        alert("Please fix incorrect constraints");
        $(".submit-classification").removeAttr('disabled');
        return;
    }

    var data = {
        locale: $("input[name='locale']:checked").val(),
        // Need to trim the timezone because it can lead to bug as 'Europe/Berlin  ' is not recognized as a correct timezone
        timezone: $("#timezone").val().trim(),
        classification: classificationForm.classification,
        appointment_nature: $("#appointment_nature").val(),
        summary: $("#summary").val(),
        duration: $("#duration").val(),
        location_nature: $("#location_nature").val(),
        location: $("#location").val(),
        location_coordinates: $('#location_coordinates').val(),
        call_instructions: window.getCallInstructions(),
        notes: $("#notes").val(),
        other_notes: $("#other_notes").val(),
        private: $("#private:checked").length > 0,
        attendees: window.getInfoPanelAttendees(),
        constraints: $("#constraints").val(),
        constraints_data: $(".constraint-tile-container").map(function () {
            return $(this).data("constraint")
        }).get(),
        client_agreement: $(".client-agreement-panel").data("client-agreement"),
        attendees_are_noticed: $(".attendees-are-noticed-panel").data("attendees-are-noticed"),
        number_to_call: $("#number_to_call").val(),
        date_times: classificationForm.getSuggestedDateTimes(),
        processed_in: Date.now() - classificationForm.startedAt,
        title_preference: $('.title-preferences-checkbox:checked').val()
    };

    if(window.currentEventTile) {
        data.event_booked_date = window.currentEventTile.getEditedEvent().start.format();
    }

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
