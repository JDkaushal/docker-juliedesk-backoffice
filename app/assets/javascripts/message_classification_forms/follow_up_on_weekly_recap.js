window.classificationForms.followUpOnWeeklyRecapForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var followUpOnWeeklyRecapForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    $(function () {
        var $infoPanelContainer = $(".messages-thread-info-panel");
        $infoPanelContainer.find(".classic-info-panel").hide();

        followUpOnWeeklyRecapForm.showSelectThreadsPanel();
    });
};

window.classificationForms.followUpOnWeeklyRecapForm.prototype.showSelectThreadsPanel = function() {
    var followUpOnWeeklyRecapForm = this;
    var $infoPanelContainer = $(".messages-thread-info-panel");
    var $selectThreadsPanel = $("<div>").addClass("follow-up-select-threads-panel");
    var data = followUpOnWeeklyRecapForm.getContextThreadsData();
    for(var i in data) {
        var dataEntry = data[i];
        var $entry = $("<div>").addClass("messages-thread-entry").data("messages-thread-id", dataEntry.messagesThreadId).data("label", dataEntry.label);
        // Cleaning form unnecessary infos
        //$entry.append($("<div>").addClass("messages-thread-label").append($("<input type='checkbox'/>")).append(dataEntry.label));
        $entry.append($("<textarea name='message'>").val("A relancer"));

        $selectThreadsPanel.append($entry);
    }

    $selectThreadsPanel.append($("<div>").addClass("btn btn-success").attr("id", "validate-follow-up-button").html("Follow-up"));
    $infoPanelContainer.append($selectThreadsPanel);


    followUpOnWeeklyRecapForm.redrawSelectThreadsPanel();
    $infoPanelContainer.find("input[type=checkbox]").change(followUpOnWeeklyRecapForm.redrawSelectThreadsPanel);
    $infoPanelContainer.find("#validate-follow-up-button").click(function() {
        trackActionV2('Click_on_follow_up', {ux_element: 'backoffice', threads_to_follow_up_count: $('.follow-up-select-threads-panel input[type="checkbox"]:checked').length});
        followUpOnWeeklyRecapForm.sendFollowUpData();
    })
};

window.classificationForms.followUpOnWeeklyRecapForm.prototype.redrawSelectThreadsPanel = function() {
    var $infoPanelContainer = $(".messages-thread-info-panel");
    $infoPanelContainer.find(".messages-thread-entry").each(function() {
        if($(this).find("input[type=checkbox]:checked").length > 0) {
           $(this).find("textarea").show();
        }
        else {
            $(this).find("textarea").hide();
        }
    });
};

window.classificationForms.followUpOnWeeklyRecapForm.prototype.getContextThreadsData = function() {
    var result = [];
    $("span[data-mode='scheduling'], span[data-mode='aborted']").each(function() {
        var $span = $(this);
        result.push({
            mode: $span.data("mode"),
            messagesThreadId: $span.data("messages-thread-id"),
            label: $span.text()
        });
    });
    return result;
};

window.classificationForms.followUpOnWeeklyRecapForm.prototype.getThreadsToFollowUpData = function() {
    var $infoPanelContainer = $(".messages-thread-info-panel");
    var result = [];
    $infoPanelContainer.find(".messages-thread-entry input[type=checkbox]:checked").each(function() {
        var $entry = $(this).closest(".messages-thread-entry");
        result.push({
            messagesThreadId: $entry.data("messagesThreadId"),
            message: $entry.find("textarea").val(),
            label: $entry.data("label")
        });
    });

    return result;
};

window.classificationForms.followUpOnWeeklyRecapForm.prototype.sendFollowUpData = function() {
    var followUpOnWeeklyRecapForm = this;
    $.ajax({
        url: "/messages/" + classificationForm.messageId + "/classify",
        type: "POST",
        data: {
            classification: followUpOnWeeklyRecapForm.classification,
            follow_up_data: followUpOnWeeklyRecapForm.getThreadsToFollowUpData()
        },
        success: function (e) {
            window.location = e.redirect_url;
        },
        error: function (e) {
            console.log("Error: ", e);
        }
    });
};