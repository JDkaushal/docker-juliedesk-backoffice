
window.activateCalendarWithParams = function (calendarParams) {
    calendarParams.height = $(".calendar-container").height();
    calendarParams.other_emails = window.otherAccountEmails;

    if(window.threadComputedData && window.threadComputedData.timezone) {
        calendarParams.default_timezone_id = window.threadComputedData.timezone;
        calendarParams.additional_timezone_ids = [window.threadAccount.default_timezone_id];
    } else {
        if(window.threadAccount) {
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

window.getClientSettings = function() {
    var result = {};

    if(window.threadAccount) {
        result['auto_follow_up'] = window.threadAccount.auto_follow_up_enabled;
    }

    return result;
};


window.initializeEmailLanguageSelector = function(callback){

    var $languageSelector = $("<div>").addClass("language-selector-container");
    $languageSelector.append($("<div>").addClass("selector").data("value", "en").html("EN"));
    $languageSelector.append($("<div>").addClass("selector").data("value", "fr").html("FR"));

    $(".reply-box").append($languageSelector);

    $(".language-selector-container .selector").click(function() {
        window.threadComputedData.locale = $(this).data("value");
        callback();
    });

    $('.email.extended').removeClass('extended');
};

var datesSuggestionManager = $('#dates-suggestion-manager');

function emailSender() {
    return {
        name: window.message_email_sender
    };
}
function initialToRecipients() {
    return getRecipients('to');
}
function initialCcRecipients() {
    return getRecipients('cc');
}
function clientRecipient() {
    return {
        name: initial_recipients.client
    };
}
function possibleRecipients() {
    return getRecipients('possible');
}

function getRecipients(mode) {
    return _.map(initial_recipients[mode], function(recipient) {
        return {
            name: recipient
        }
    });
}

window.currentRecipients = function () {
    return {
        to: $.map($("#recipients-to-input").tokenInput("get"), function (elt) {
            return elt.name;
        }),
        cc: $.map($("#recipients-cc-input").tokenInput("get"), function (elt) {
            return elt.name;
        })
    };
};


function toRecipientAdded(item) {
    setQuoteMessageCheckboxState();
}

function toRecipientDeleted(item) {
    setQuoteMessageCheckboxState();
}

function ccRecipientAdded(item) {
    setQuoteMessageCheckboxState();
}

function ccRecipientDeleted(item) {
    setQuoteMessageCheckboxState();
}

function setQuoteMessageCheckboxState(){

    if(window.julie_action_nature != "forward_to_support") {
        var toRecipients = $("#recipients-to-input").tokenInput("get");
        var ccRecipients = $("#recipients-cc-input").tokenInput("get");
        var state = true;

        if(window.isResponseToClient){
            // If there are more than 1 recipients (means one or more were added
            // Or if one or more cc recipients are presents (means one or more were added)
            // Or if the client email is not present in the to recipient list

            var clientAllEmails = (window.threadAccount.email_aliases || []).concat(window.threadAccount.email);

            // If the operator then add a recipient (either To or Cc), we uncheck the quote message checkbox, because
            // the previous message is obviously containing informations only destined to Julie or the client
            if (toRecipients.length > 1 || ccRecipients.filter(function(item) {
                    return item.name != "support@juliedesk.com" && item.name != "hello@juliedesk.com";
                }).length > 0 || toRecipients.filter(function (item) {
                    return (clientAllEmails.indexOf(item.name) > -1);
                }).length == 0)
            {
                state = false;
            }
        }

        $('#quote_message').prop('checked', state);
        return state;
    }

}

// Allow to manage the disability of the send button (responsible for sending the email) based on the current classification
// and external conditions
function checkSendButtonAvailability(params) {
    var disabled_by_ai = false;
    var disabled_by_invalid_recipients = $('.token-input-token-facebook.juliedesk-unauthorized-email').length > 0;
    var warningText = '';
    var replyButtonNode = $('#reply-button');

    var currentTooltips = [];

    switch(window.classification) {

        case 'follow_up_contacts':
        //fall-through
        case 'ask_availabilities':
        //fall-through
        case 'ask_date_suggestions':
            if(window.julie_action_nature != "check_availabilities") {
                var datesSuggestionManager = $('#dates-suggestion-manager').scope();

                disabled_by_ai = datesSuggestionManager.aiSuggestionsRemaining();
                warningText = datesSuggestionManager.getTimeSlotsSuggestedByAi().length + ' proposition(s) reste(nt) à (in)valider avant envoie';
                $('#reply-button-popover-warning-details').text(warningText);
            }
            break;
    }

    if(disabled_by_ai) {
        $('#reply-button-popover-warning-details-wrapper').show();
    } else {
        $('#reply-button-popover-warning-details-wrapper').hide();
    }

    if(disabled_by_invalid_recipients) {
        currentTooltips.push("Veuillez n'entrer que des adresses figurant dans l'un des emails du client ou de ses contacts")
    }

    var disabled =
        disabled_by_ai
        || disabled_by_invalid_recipients;

    if(currentTooltips) {
        var sendEmailTooltipHolderNode = $('#send-email-tooltip-holder');
        sendEmailTooltipHolderNode.attr('title', currentTooltips.join("\n"));

        if(currentTooltips.length > 0) {
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

$(function () {
    for(var i = 0; i < window.specialCallbacks.length; i++) {
        window.specialCallbacks[i]();
    }

    $("#show-calendar-button").click(function () {
        trackActionV2("Click_on_open_calendar", {
            calendars_types: _.map(window.threadAccount.calendar_logins, function(cal) {return cal.type;})
        });

        $(".calendar-container").removeClass("minimized");
        window.currentCalendar.redrawFullCalendar();
        if (window.newEventEventTiles && window.showEditedEventInCalendar) {
            window.showEditedEventInCalendar();
        }
    });

    $("body").on("click", ".time-slots-to-suggest-list-container .time-slot-to-suggest .ai-suggestion-action-item-container.accept", function (e) {
        var dateTime = $(this).closest('.time-slot-to-suggest').data("date-time");
        datesSuggestionManager.scope().acceptAiSuggestion(dateTime);
    });

    $("body").on("click", ".time-slots-to-suggest-list-container .time-slot-to-suggest .ai-suggestion-action-item-container.reject", function (e) {
        var dateTime = $(this).closest('.time-slot-to-suggest').data("date-time");
        datesSuggestionManager.scope().rejectAiSuggestion(dateTime);
    });

    $("body").on("click", ".time-slots-to-suggest-list-container .time-slot-to-suggest", function (e) {
        var that = $(this);
        var dateTime = that.data("date-time");
        $(".calendar-container").removeClass("minimized");
        window.currentCalendar.goToDateTime(dateTime);

        if(that.hasClass('from-ai')) {
            $('#dates-suggestion-manager').scope().scrollToAiSuggestionInCalendar(dateTime);
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

    $("select#julie-alias-select").change(function() {
        window.julieAlias = _.find(window.julieAliases, function(julieAlias) {
            return julieAlias.email == $("select#julie-alias-select").val();
        });
        window.assignCurrentReplyMessage();
    });



    $("#reply-button").click(function () {
        var trackingData = {ux_element: 'email'};

        if(window.threadComputedData && window.threadComputedData.locale) {
            trackingData.locale = window.threadComputedData.locale;
        }

        trackActionV2('Click_on_send_email', trackingData);
        $("#reply-button").prop('disabled', true);
        if(window.clickReplyButton) {
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
        if(window.clickForwardButton) {
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

    $(".reply-to-all-button").click(function() {
        window.setReplyRecipients("all");
        window.assignCurrentReplyMessage()
    });

    $(".reply-to-client-button").click(function() {
        window.setReplyRecipients("only_client");
        window.assignCurrentReplyMessage()
    });

    window.deleteEventBeforeReply = function (callback) {
        if(window.currentEventTile) {
            window.currentEventTile.doneEditingCallback = function() {
                window.actionDeletedEvent = true;
                $(".messages-thread-info-panel .created-event-panel").hide();
                callback();
            };
            window.currentEventTile.deleteEvent();
        }
    };

    window.redrawTimeSlotsToSuggestContainer = function (params) {
        params = params || {};

        var suggestedDateScope = $("#dates-suggestion-manager").scope();
        suggestedDateScope.setSuggestions(params.forceDisplayManager);
    };

    window.sendReply = function (replyParams) {
        $(".reply-box #callback-message").html(localize('common.sending'));

        var forward = false;
        if(replyParams && replyParams.forward) {
            forward =  true;
        }

        $.ajax({
            url: "/messages/" + window.replyingToMessageId + "/reply",
            method: "post",
            data: {
                text: $("textarea#reply-text").val(),
                html_signature: $("#reply-text-signature").html(),
                from: $("select#julie-alias-select").val(),
                to: window.currentRecipients().to,
                cc: window.currentRecipients().cc,
                quote_message: $("input#quote_message:checked").length > 0,
                julie_action_id: window.julie_action_id,
                forward: forward,
                segment_params: {
                    using_trust_circle_template: window.usingTrustCircleTemplate
                }
            },
            success: function (e) {
                $(".reply-box #callback-message").html(localize('common.sent'));
                $("#reply-button").removeProp('disabled');
                window.location = window.afterMessageSentUrl;
            },
            error: function (e) {
                console.log("error", e);
                $("#reply-button").removeProp('disabled');
                $(".reply-box #callback-message").html("Error: " + e.responseJSON.message);
            }
        });
    };

});

window.getRecipientsJulieAliases = function() {
    var result = window.julieAliases;
    if(window.julieAliases.length > 0) {
        result = _.reject(window.julieAliases, function(jA) {
            return jA.email == window.julieAlias.email;
        })
    }

    return result;
};

window.setReplyRecipients = function(recipients, otherRecipients) {
    var replyBox = angular.element($('#recipients-manager')).scope();
    if(replyBox && replyBox.initiated)
        replyBox.setReplyRecipients(recipients, otherRecipients);
};

window.processSignature = function(signature) {
    if(signature) {
        if(window.threadAccount) {
            signature = signature.replace("%USER_NAME%", window.threadAccount.full_name);
            signature = signature.replace("%USER_EMAIL%", window.threadAccount.email);
            if(window.threadAccount.is_pro) {
                signature = signature.replace(/%REMOVE_IF_PRO%([\s\S]*)%REMOVE_IF_PRO%/m, "");
            }
            else {
                signature = signature.replace(/%REMOVE_IF_PRO%/g, "");
            }
        } else {
            signature = signature.replace(/%REMOVE_IF_PRO%/g, "");
        }
    }
    return signature;
};


window.setReplyMessage = function (message, recipients, otherRecipients) {
    window.setReplyRecipients(recipients, otherRecipients);
    window.currentFullMessage = message;
    window.assignCurrentReplyMessage();
};

window.computeSalutation = function() {
    if(window.featuresHelper.isFeatureActive('usage_name_v2')) {
        var shouldSayHi = !window.threadComputedData.last_message_sent_at || moment().diff(moment(window.threadComputedData.last_message_sent_at), 'hours') > 12;
        var recipientsTos = $('#recipients-to-input').tokenInput('get');
        var salutationKeys = ['email_templates.salutations', window.threadComputedData.language_level, null];

        var recipientsToName = null;
        var attendeesApp = $('#attendeesCtrl').scope();
        if(attendeesApp) {
            if (recipientsTos.length == 1) {
                var attendee = attendeesApp.getAttendeeByEmail(recipientsTos[0].name);
                if (attendee) {
                    var usageName = attendee.computeUsageName();
                    if(usageName) {
                        recipientsToName = usageName;
                    }

                }
            }
            else if (recipientsTos.length == 2) {
                var firstAttendee = attendeesApp.getAttendeeByEmail(recipientsTos[0].name);
                var secondAttendee = attendeesApp.getAttendeeByEmail(recipientsTos[1].name);
                if (firstAttendee && secondAttendee) {
                    var firstAttUsageName = firstAttendee.computeUsageName();
                    var secondAttUsageName = secondAttendee.computeUsageName();

                    if(firstAttUsageName && secondAttUsageName && (firstAttUsageName != secondAttUsageName)) {
                        recipientsToName = localize("email_templates.common.names_list_and", {
                            first_name: firstAttUsageName,
                            last_name: secondAttUsageName
                        });
                    }
                }
            }
        }
        if(shouldSayHi) {
            if(recipientsTos.length == 1) {
                if(recipientsToName) {
                    salutationKeys[2] = 'one';
                }
            } else if(recipientsTos.length == 2) {
                if(recipientsToName) {
                    salutationKeys[2] = 'two';
                }
            }

            // Default we fallback to simple Hi/bonjour
            if(salutationKeys[2] == null) {
                salutationKeys[2] = 'many';
            }
        }

        var salutationStr = '';

        if(salutationKeys[2] == null) {
            if(recipientsToName) {
                salutationStr = recipientsToName + ",\n\n";
            }
        } else {
            salutationStr = localize(salutationKeys.join('.'), {
                names: recipientsToName
            });
        }

        return salutationStr;
    } else {

        var shouldSayHi = !window.threadComputedData.last_message_sent_at || moment().diff(moment(window.threadComputedData.last_message_sent_at), 'hours') > 12;
        var recipientsTos = $('#recipients-to-input').tokenInput('get');
        var recipientsToName = null;
        var attendeesApp = $('#attendeesCtrl').scope();
        if(attendeesApp) {
            if (recipientsTos.length == 1) {
                var attendee = attendeesApp.getAttendeeByEmail(recipientsTos[0].name);
                if (attendee && attendee.usageName) {
                    recipientsToName = attendee.usageName;
                }
            }
            else if (recipientsTos.length == 2) {
                var firstAttendee = attendeesApp.getAttendeeByEmail(recipientsTos[0].name);
                var secondAttendee = attendeesApp.getAttendeeByEmail(recipientsTos[1].name);
                if (firstAttendee && firstAttendee.usageName && secondAttendee && secondAttendee.usageName) {
                    recipientsToName = localize("email_templates.common.names_list_and", {
                        first_name: firstAttendee.usageName,
                        last_name: secondAttendee.usageName
                    });
                }
            }
        }
        if(shouldSayHi) {
            if(recipientsTos.length < 3) {
                if(recipientsToName) {
                    return localize("email_templates.common.hello_named", {name: recipientsToName});
                } else {
                    return localize("email_templates.common.hello_only");
                }
            }
            else {
                return localize("email_templates.common.hello_all");
            }
        } else if(recipientsTos.length < 3) {
            if(recipientsToName) {
                return localize("email_templates.common.interlocutor_name", {name: recipientsToName});
            }
        }
        return "";
    }

};

window.computeFooter = function() {
    if(window.threadComputedData.locale == "fr") {
        return window.julieAlias.footer_fr;
    }
    else {
        return window.julieAlias.footer_en;
    }
};

window.computeSignature = function() {
    var signature = window.julieAlias.signature_en;
    if(window.threadComputedData.locale == "fr") {
        signature = window.julieAlias.signature_fr;
    }
    return window.processSignature(signature);
};

window.assignCurrentReplyMessage = function() {
    setCurrentLocale(window.threadComputedData.locale);

    var salutation = window.computeSalutation();
    var footer = window.computeFooter();
    var signature = window.computeSignature();

    window.currentFullMessageWithFooter = salutation + window.currentFullMessage + footer;

    $("textarea#reply-text").val(window.currentFullMessageWithFooter);
    $("textarea#reply-text").elastic();
    $("div#reply-text-signature").html(signature);

    setCurrentLocale(getDefaultLocale());
};
