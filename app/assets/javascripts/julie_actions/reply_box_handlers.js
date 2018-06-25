window.initializeEmailLanguageSelector = function (callback) {

    var $languageSelector = $("<div>").addClass("language-selector-container");
    $languageSelector.append($("<div>").addClass("selector").data("value", "en").html("EN"));
    $languageSelector.append($("<div>").addClass("selector").data("value", "fr").html("FR"));

    $(".reply-box").append($languageSelector);

    $(".language-selector-container .selector").click(function () {
        window.threadComputedData.locale = $(this).data("value");
        callback();
    });

    $('.email.extended').removeClass('extended');
};

window.emailSender = function () {
    return {
        name: window.message_email_sender
    };
};

window.initialToRecipients = function () {
    return getRecipients('to');
};

window.initialCcRecipients = function () {
    return getRecipients('cc');
};

window.clientRecipient = function () {
    return {
        name: initial_recipients.client
    };
};

window.possibleRecipients = function () {
    return getRecipients('possible');
};

window.getRecipients = function (mode) {
    return _.map(initial_recipients[mode], function (recipient) {
        return {
            name: recipient
        }
    });
};

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

window.toRecipientAdded = function (item) {
    setQuoteMessageCheckboxState();
};

window.toRecipientDeleted = function (item) {
    setQuoteMessageCheckboxState();
};

window.ccRecipientAdded = function (item) {
    setQuoteMessageCheckboxState();
};

window.ccRecipientDeleted = function (item) {
    setQuoteMessageCheckboxState();
};

window.setQuoteMessageCheckboxState = function () {

    if (window.julie_action_nature != "forward_to_support") {
        var toRecipients = $("#recipients-to-input").tokenInput("get");
        var ccRecipients = $("#recipients-cc-input").tokenInput("get");
        var state = true;

        if (window.isResponseToClient) {
            // If there are more than 1 recipients (means one or more were added
            // Or if one or more cc recipients are presents (means one or more were added)
            // Or if the client email is not present in the to recipient list

            var clientAllEmails = (window.threadAccount.email_aliases || []).concat(window.threadAccount.email);

            // If the operator then add a recipient (either To or Cc), we uncheck the quote message checkbox, because
            // the previous message is obviously containing informations only destined to Julie or the client
            if (toRecipients.length > 1 || ccRecipients.filter(function (item) {
                    return item.name != "support@juliedesk.com" && item.name != "hello@juliedesk.com";
                }).length > 0 || toRecipients.filter(function (item) {
                    return (clientAllEmails.indexOf(item.name) > -1);
                }).length == 0) {
                state = false;
            }
        }

        $('#quote_message').prop('checked', state);
        return state;
    }
};

window.getRecipientsJulieAliases = function () {
    var result = window.julieAliases;
    if (window.julieAliases.length > 0) {
        result = _.reject(window.julieAliases, function (jA) {
            return jA.email == window.julieAlias.email;
        })
    }
    return result;
};

window.setReplyRecipients = function (recipients, otherRecipients) {
    var replyBox = angular.element($('#recipients-manager')).scope();
    if (replyBox && replyBox.initiated)
        replyBox.setReplyRecipients(recipients, otherRecipients);
};

window.processSignature = function (signature) {
    if (signature) {
        if (window.threadAccount) {
            signature = signature.replace("%USER_NAME%", window.threadAccount.full_name);
            signature = signature.replace("%USER_EMAIL%", window.threadAccount.email);
            if (window.threadAccount.is_pro) {
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

window.setReplyMessage = function (message, recipients, otherRecipients, options) {
    var options = options || {};
    var contentType = options.contentType || 'text';
    window.setReplyRecipients(recipients, otherRecipients);

    if(contentType == 'html')
      window.currentFullHtmlMessage = message;
    else
      window.currentFullMessage = message;

    window.assignCurrentReplyMessage({ contentType: contentType });
};

window.computeSalutation = function () {
    if (window.featuresHelper.isFeatureActive('usage_name_v2')) {
        var shouldSayHi = !window.threadComputedData.last_message_sent_at || moment().diff(moment(window.threadComputedData.last_message_sent_at), 'hours') > 12;
        var recipientsTos = $('#recipients-to-input').tokenInput('get');
        var salutationKeys = ['email_templates.salutations', window.threadComputedData.language_level, null];

        var recipientsToName = null;
        var attendeesApp = $('#attendeesCtrl').scope();
        if (attendeesApp) {
            if (recipientsTos.length == 1) {
                var attendee = attendeesApp.getAttendeeByEmail(recipientsTos[0].name);
                if (attendee) {
                    var usageName = attendee.computeUsageName();
                    if (usageName) {
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

                    if (firstAttUsageName && secondAttUsageName && (firstAttUsageName != secondAttUsageName)) {
                        recipientsToName = localize("email_templates.common.names_list_and", {
                            first_name: firstAttUsageName,
                            last_name: secondAttUsageName
                        });
                    }
                }
            }
        }
        if (shouldSayHi) {
            if (recipientsTos.length == 1) {
                if (recipientsToName) {
                    salutationKeys[2] = 'one';
                }
            } else if (recipientsTos.length == 2) {
                if (recipientsToName) {
                    salutationKeys[2] = 'two';
                }
            }

            // Default we fallback to simple Hi/bonjour
            if (salutationKeys[2] == null) {
                salutationKeys[2] = 'many';
            }
        }

        var salutationStr = '';

        if (salutationKeys[2] == null) {
            if (recipientsToName) {
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
        if (attendeesApp) {
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
        if (shouldSayHi) {
            if (recipientsTos.length < 3) {
                if (recipientsToName) {
                    return localize("email_templates.common.hello_named", {name: recipientsToName});
                } else {
                    return localize("email_templates.common.hello_only");
                }
            }
            else {
                return localize("email_templates.common.hello_all");
            }
        } else if (recipientsTos.length < 3) {
            if (recipientsToName) {
                return localize("email_templates.common.interlocutor_name", {name: recipientsToName});
            }
        }
        return "";
    }

};

window.computeFooter = function () {
    if (window.threadComputedData.locale == "fr") {
        return window.julieAlias.footer_fr;
    }
    else {
        return window.julieAlias.footer_en;
    }
};

window.computeSignature = function () {
    var signature = window.julieAlias.signature_en;
    if (window.threadComputedData.locale == "fr") {
        signature = window.julieAlias.signature_fr;
    }
    return window.processSignature(signature);
};

window.assignCurrentReplyMessage = function (options) {
    var opts = options || {};
    var contentType = opts.contentType || 'text';

    setCurrentLocale(window.threadComputedData.locale);

    var salutation = window.computeSalutation();
    var footer = window.computeFooter();
    var signature = window.computeSignature();

    window.currentFullMessageWithFooter = salutation + window.currentFullMessage + footer;

    $("textarea#reply-text").val(window.currentFullMessageWithFooter);
    $("textarea#reply-text").elastic();

    if(contentType == 'html') {
      var htmlFooter      = footer.replace(/\n/g, '<br/>');
      var htmlSalutation  = salutation.replace(/\n/g, '<br/>');
      $("div#reply-html").html(window.currentFullHtmlMessage).prepend('<p>' + htmlSalutation + '</p>').append('<p>' + htmlFooter + '</p>').show();
      $('textarea#reply-text').val( $('div#reply-html')[0].innerText).hide();
    }
    else {
      $("#reply-html").empty().hide();
      $("textarea#reply-text").show();
    }

  $("div#reply-text-signature").html(signature);

    setCurrentLocale(getDefaultLocale());
};

window.sendReply = function (replyParams) {
    $(".reply-box #callback-message").html(localize('common.sending'));

    var forward = false;
    if (replyParams && replyParams.forward) {
        forward = true;
    }

    $.ajax({
        url: "/messages/" + window.replyingToMessageId + "/reply",
        method: "post",
        data: {
            text: $("textarea#reply-text").val(),
            html: $("div#reply-html").is(':visible') ? $("div#reply-html").html() : null,
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