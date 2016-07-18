window.classificationForms.givePreferenceForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var givePreferenceForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    $(".submit-add-preference").click(function () {
        trackActionV2('Click_on_save_preference', {ux_element: 'backoffice'});
        $(this).prop("disabled", true);
        var data = {
            classification: givePreferenceForm.classification,
            awaiting_current_notes: $("textarea#preference_to_add").val(),
            processed_in: Date.now() - givePreferenceForm.startedAt
        };
        $.ajax({
            url: "/messages/" + givePreferenceForm.messageId + "/classify",
            type: "POST",
            data: data,
            success: function (e) {
                window.location = e.redirect_url;
            },
            error: function (e) {
                console.log("Error: ", e);
            }
        });
    });

    $(".classic-info-panel").hide();
    $(".add-preference-panel").show();
};