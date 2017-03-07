    window.classificationForms.askDateSuggestionsForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var askDateSuggestionsForm = this;
    // Used to have a common accessor between all the different forms
    var currentClassifForm = askDateSuggestionsForm;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    window.submitClassification = function () {
        askDateSuggestionsForm.sendForm();
    };

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