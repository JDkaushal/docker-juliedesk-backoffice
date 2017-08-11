window.getDatesSuggestionManager = function () {
    return $('#dates-suggestion-manager').scope();
};

window.activateCalendarWithParams = function (calendarParams) {
    calendarParams.height = $(".calendar-container").height();
    calendarParams.other_emails = window.otherAccountEmails;

    if (window.threadComputedData && window.threadComputedData.timezone) {
        calendarParams.default_timezone_id = window.threadComputedData.timezone;
        calendarParams.additional_timezone_ids = [window.threadAccount.default_timezone_id];
    } else {
        if (window.threadAccount) {
            calendarParams.default_timezone_id = window.threadAccount.default_timezone_id;
        }
        calendarParams.additional_timezone_ids = [window.threadComputedData.timezone];
    }

    calendarParams.constraintsData = _.groupBy(window.threadComputedData.constraints_data, function (data) {
        return data.attendee_email;
    });

    calendarParams.default_calendar_login_username = window.threadComputedData.calendar_login_username;
    calendarParams.default_calendar_login_type = window.threadComputedData.calendar_login_type;

    window.currentCalendar = new Calendar($(".calendar-container"), calendarParams);
    $(".calendar-container").addClass("visible");
};

window.getClientSettings = function () {
    var result = {};

    if (window.threadAccount) {
        result['auto_follow_up'] = window.threadAccount.auto_follow_up_enabled;
    }

    return result;
};

// Allow to manage the disability of the send button (responsible for sending the email) based on the current classification
// and external conditions
window.checkSendButtonAvailability = function (params) {
    var disabled_by_ai = false;
    var disabled_by_invalid_recipients = $('.token-input-token-facebook.juliedesk-unauthorized-email').length > 0;
    var warningText = '';
    var replyButtonNode = $('#reply-button');

    var currentTooltips = [];

    switch (window.classification) {

        case 'follow_up_contacts':
        //fall-through
        case 'ask_availabilities':
        //fall-through
        case 'ask_date_suggestions':
            if (window.julie_action_nature != "check_availabilities") {
                disabled_by_ai = getDatesSuggestionManager().aiSuggestionsRemaining();
                warningText = getDatesSuggestionManager().getTimeSlotsSuggestedByAi().length + ' proposition(s) reste(nt) à (in)valider avant envoie';
                $('#reply-button-popover-warning-details').text(warningText);
            }
            break;
    }

    if (disabled_by_ai) {
        $('#reply-button-popover-warning-details-wrapper').show();
    } else {
        $('#reply-button-popover-warning-details-wrapper').hide();
    }

    if (disabled_by_invalid_recipients) {
        currentTooltips.push("Veuillez n'entrer que des adresses figurant dans l'un des emails du client ou de ses contacts")
    }

    var disabled =
        disabled_by_ai
        || disabled_by_invalid_recipients;

    if (currentTooltips) {
        var sendEmailTooltipHolderNode = $('#send-email-tooltip-holder');
        sendEmailTooltipHolderNode.attr('title', currentTooltips.join("\n"));

        if (currentTooltips.length > 0) {
            sendEmailTooltipHolderNode.width(replyButtonNode.innerWidth());
            sendEmailTooltipHolderNode.height(replyButtonNode.innerHeight());
            sendEmailTooltipHolderNode.css(replyButtonNode.position());
            sendEmailTooltipHolderNode.show();
        } else {
            sendEmailTooltipHolderNode.hide();
        }
    }

    replyButtonNode.prop('disabled', disabled);
};

window.deleteEventBeforeReply = function (callback) {
    if (window.currentEventTile) {
        window.currentEventTile.doneEditingCallback = function () {
            window.actionDeletedEvent = true;
            $(".messages-thread-info-panel .created-event-panel").hide();
            callback();
        };
        window.currentEventTile.deleteEvent();
    }
};

window.redrawTimeSlotsToSuggestContainer = function (params) {
    params = params || {};
    getDatesSuggestionManager().setSuggestions(params.forceDisplayManager);
};

$(function () {

    if (window.specialCallbacks) {
        for (var i = 0; i < window.specialCallbacks.length; i++) {
            window.specialCallbacks[i]();
        }
    }


    $("#show-calendar-button").click(function () {
        trackActionV2("Click_on_open_calendar", {
            calendars_types: _.map(window.threadAccount.calendar_logins, function (cal) {
                return cal.type;
            })
        });

        $(".calendar-container").removeClass("minimized");
        window.currentCalendar.redrawFullCalendar();
        if (window.newEventEventTiles && window.showEditedEventInCalendar) {
            window.showEditedEventInCalendar();
        }
    });

    $("body").on("click", ".time-slots-to-suggest-list-container .time-slot-to-suggest .ai-suggestion-action-item-container.accept", function (e) {
        var dateTime = $(this).closest('.time-slot-to-suggest').data("date-time");
        getDatesSuggestionManager().acceptAiSuggestion(dateTime);
    });

    $("body").on("click", ".time-slots-to-suggest-list-container .time-slot-to-suggest .ai-suggestion-action-item-container.reject", function (e) {
        var dateTime = $(this).closest('.time-slot-to-suggest').data("date-time");
        getDatesSuggestionManager().rejectAiSuggestion(dateTime);
    });

    $("body").on("click", ".time-slots-to-suggest-list-container .time-slot-to-suggest", function (e) {
        var that = $(this);
        var dateTime = that.data("date-time");
        $(".calendar-container").removeClass("minimized");
        window.currentCalendar.goToDateTime(dateTime);

        if (that.hasClass('from-ai')) {
            getDatesSuggestionManager().scrollToAiSuggestionInCalendar(dateTime);
            // Get the scrollable div that contains all the events
//            var calendarEventContainer = window.currentCalendar.$selector.find('.fc-agenda-divider').next();
//            var currentPos = calendarEventContainer.scrollTop();
//            calendarEventContainer.animate({scrollTop: currentPos + $('.unread-email-container').offset().top - 40}, 300);
        }

    });

    $(".left-column").scroll(function () {
        if ($(this).scrollTop() < 40) {
            $(".julie-action-title").css({top: 40});
        }
        else {
            var currentScrollTop = $(this).scrollTop();
            $(".julie-action-title").css({top: currentScrollTop});
        }
    });

    $("select#julie-alias-select").change(function () {
        window.julieAlias = _.find(window.julieAliases, function (julieAlias) {
            return julieAlias.email == $("select#julie-alias-select").val();
        });
        window.assignCurrentReplyMessage();
    });

    $("#reply-button").click(function () {
        var trackingData = {ux_element: 'email'};

        if (window.threadComputedData && window.threadComputedData.locale) {
            trackingData.locale = window.threadComputedData.locale;
        }

        trackActionV2('Click_on_send_email', trackingData);
        $("#reply-button").prop('disabled', true);
        if (window.clickReplyButton) {
            window.clickReplyButton();
        }
        else {
            $.ajax({
                url: "/julie_actions/" + window.julie_action_id + "/update",
                method: "post",
                data: {
                    text: $("textarea#reply-text").val(),
                    generated_text: window.currentFullMessageWithFooter,
                    to: window.currentRecipients().to,
                    cc: window.currentRecipients().cc,
                    done: true,
                    processed_in: Date.now() - window.startedAt,
                    messages_thread_id: window.processingMessageThreadId,
                    client_settings: window.getClientSettings(),
                    date_times: window.timeSlotsToSuggest || [],
                    timezone: $('#dates_suggestion_timezone').val()
                }
            });
            window.sendReply();
        }
    });

    $("#forward-button").click(function () {
        trackActionV2('Click_on_send_email', {ux_element: 'backoffice'});

        $("#forward-button").prop('disabled', true);
        if (window.clickForwardButton) {
            window.clickForwardButton();
        }
        else {
            $.ajax({
                url: "/julie_actions/" + window.julie_action_id + "/update",
                method: "post",
                data: {
                    text: $("textarea#reply-text").val(),
                    generated_text: window.currentFullMessageWithFooter,
                    to: window.currentRecipients().to,
                    cc: window.currentRecipients().cc,
                    done: true,
                    processed_in: Date.now() - window.startedAt,
                    messages_thread_id: window.processingMessageThreadId,
                    client_settings: window.getClientSettings()
                }
            });
            window.sendReply({forward: true});
        }
    });

    $(".reply-to-all-button").click(function () {
        window.setReplyRecipients("all");
        window.assignCurrentReplyMessage()
    });

    $(".reply-to-client-button").click(function () {
        window.setReplyRecipients("only_client");
        window.assignCurrentReplyMessage()
    });

    window.flowConditionsHandler.processFlowConditions(window.flowConditions);
});

window.autoProcessDateSuggestions = function() {
    getDatesSuggestionManager().trustAllAiSuggestions();
};
