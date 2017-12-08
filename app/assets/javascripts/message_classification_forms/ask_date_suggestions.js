window.classificationForms.askDateSuggestionsForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var askDateSuggestionsForm = this;
    // Used to have a common accessor between all the different forms
    var currentClassifForm = askDateSuggestionsForm;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    window.submitClassification = function () {
        if(window.featuresHelper.isFeatureActive("auto_date_suggestions_from_backend")) {
            askDateSuggestionsForm.fetchDateSuggestionsFromAi(function(dateSuggestionsFromAi) {
                askDateSuggestionsForm.sendForm({
                    dateSuggestionsFromAi: dateSuggestionsFromAi
                });
            },function(errorResponse) {
                askDateSuggestionsForm.sendForm({
                    dateSuggestionsFromAi: errorResponse
                });
            });
        }
        else {
            askDateSuggestionsForm.sendForm();
        }

    };

    if(window.messagesDispatcher) {
        window.messagesDispatcher.registerListener("info-panel-next-item-event", function () {
            if(window.featuresHelper.isFeatureActive("auto_date_suggestions_from_backend") && $(".subject-form-entry:visible").length > 0) {
                askDateSuggestionsForm.initiatePutsCalendarInConscienceCacheIfNeeded();
            }
        });
    }


    $(function () {
        $(".client-agreement-panel .yes-button").click(function () {
            window.acceptClientAgreement();
        });

        askDateSuggestionsForm.checkClientAgreement();

        //bypassClientAgreementIfPossible();
        window.acceptClientAgreement();
    });

    window.acceptClientAgreement = function() {
        askDateSuggestionsForm.validateClientAgreement(true, false);
    };
};
window.classificationForms.askDateSuggestionsForm.prototype.initiatePutsCalendarInConscienceCacheIfNeeded = function() {
    var askDateSuggestionsForm = this;
    if(askDateSuggestionsForm.calendarConscienceCacheInitiated) {
        return;
    }
    askDateSuggestionsForm.calendarConscienceCacheInitiated = true;
    askDateSuggestionsForm.putsCalendarInConscienceCache(function() {

    }, function() {

    });
};

window.classificationForms.askDateSuggestionsForm.prototype.putsCalendarInConscienceCache = function(successCallback, errorCallback) {
    var askDateSuggestionsForm = this;


    askDateSuggestionsForm.sendFormConscienceLoading(true);

    var attendeesControllerScope = $('#attendeesCtrl').scope();
    var aiDatesSuggestionsManagerScope = $('#ai_dates_suggestions_manager').scope();

    var meetingRoomsToShow = askDateSuggestionsForm.getMeetingRoomsToShow();

    var fetchParams = {
        account_email: window.threadAccount.email,
        attendees: attendeesControllerScope.getAttendeesOnPresence(true),
        thread_data: {
            appointment_nature: $("#appointment_nature").val(),
            location: $("#location").val(),
            duration: parseInt($("#duration").val(), 10),
            timezone: askDateSuggestionsForm.getTimezoneForSendForm()
        },
        raw_constraints_data: askDateSuggestionsForm.getConstraintsDataForSendForm(),
        compute_linked_attendees: true,
        message_id: $('.email.highlighted').data('message-id'),
        old_attendees: _.filter(window.threadComputedData.attendees, function(att) { return att.isPresent == 'true' }),
        meeting_rooms_to_show: meetingRoomsToShow
    };

    aiDatesSuggestionsManagerScope.putsCalendarInConscienceCache(fetchParams).then(function(response) {
        if (response && response.data) {
            var data = response.data;
            askDateSuggestionsForm.sendFormConscienceLoading(false);
            successCallback(data);
        } else {
            askDateSuggestionsForm.sendFormConscienceLoading(false);
            var error = new Error("putsCalendarInConscienceCache Aborted", window.location.href, "", {});
            errorManager.sendError(error);
            errorCallback('No response (request most likely aborted');
        }

    }, function(error) {
        askDateSuggestionsForm.sendFormConscienceLoading(false);
        errorCallback(error.status === 408 ? 'timeout' : 'error');
    });
};

window.classificationForms.askDateSuggestionsForm.prototype.fetchDateSuggestionsFromAi = function(successCallback, errorCallback) {
    var askDateSuggestionsForm = this;

    askDateSuggestionsForm.sendFormConscienceLoading(true);

    var suggestionsToGet = 4;
    var attendeesControllerScope = $('#attendeesCtrl').scope();
    var aiDatesSuggestionsManagerScope = $('#ai_dates_suggestions_manager').scope();

    var meetingRoomsToShow = askDateSuggestionsForm.getMeetingRoomsToShow();

    var version = "stable";

    var fetchParams = {
        account_email: window.threadAccount.email,
        thread_data: {
            appointment_nature: $("#appointment_nature").val(),
            location: $("#location").val(),
            duration: parseInt($("#duration").val(), 10),
            timezone: askDateSuggestionsForm.getTimezoneForSendForm(),
        },
        compute_linked_attendees: true,
        old_attendees: _.filter(window.threadComputedData.attendees, function(att) { return att.isPresent == 'true' }),
        n_suggested_dates: suggestionsToGet,
        attendees: attendeesControllerScope.getAttendeesOnPresence(true),
        message_id: $('.email.highlighted').data('message-id'),
        multi_clients: false,
        meeting_rooms_to_show: meetingRoomsToShow,
        asap: $("input[name='asap_constraint']:checked").length > 0,
        version: version,
        client_on_trip: $("#client-on-trip-data-entry").scope().value,
        raw_constraints_data: askDateSuggestionsForm.getConstraintsDataForSendForm()
    };

    aiDatesSuggestionsManagerScope.fetchSuggestedDatesByAi(fetchParams).then(function(response) {
        var data = response.data;
        askDateSuggestionsForm.sendFormConscienceLoading(false);
        successCallback(data);
    }, function(error) {
        askDateSuggestionsForm.sendFormConscienceLoading(false);
        errorCallback({
            status: error.status === 408 ? 'timeout' : 'error'
        });
    });
};

window.classificationForms.askDateSuggestionsForm.prototype.getMeetingRoomsToShow = function() {
    var meetingRoomsToShow = {};
    _.each($('.calendar-item.is-meeting-room input[type="checkbox"]:checked'), function (c) {
        var calendarItemNode = $(c).closest('.calendar-item');

        meetingRoomsToShow[calendarItemNode.data('calendar-login-username')] = meetingRoomsToShow[calendarItemNode.data('calendar-login-username')] || [];
        meetingRoomsToShow[calendarItemNode.data('calendar-login-username')].push(calendarItemNode.data('calendar-id'));
    });
    return meetingRoomsToShow;
};