window.classificationForms.waitForContactForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var waitForContactForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");



    window.submitClassification = function () {
        waitForContactForm.sendForm();
    };

    $(function () {
        waitForContactForm.clientAgreement = true;
        waitForContactForm.checkClientAgreement();
    });
};