    window.classificationForms.askDateSuggestionsForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var askDateSuggestionsForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    window.submitClassification = function () {
        askDateSuggestionsForm.sendForm();
    };

    $(function () {
        $(".client-agreement-panel .yes-button").click(function () {
            askDateSuggestionsForm.validateClientAgreement(true, false);
        });

        askDateSuggestionsForm.checkClientAgreement();
    });
};