window.classificationForms.askCancelEvents = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var askCancelEventsForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    $(function () {
        $(".classic-info-panel").hide();

        $(".only-locale-panel .validate-locale-button").click(function() {
            $(this).prop("disabled", true);
            askCancelEventsForm.sendFormOnlyLocale();
        });
        $(".only-locale-panel").show();
    });
};
