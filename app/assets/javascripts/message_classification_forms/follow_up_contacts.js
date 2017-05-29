window.classificationForms.followUpContactsForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var contactsFollowUpForm = this;
    // Used to have a common accessor between all the different forms
    var currentClassifForm = contactsFollowUpForm;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    window.submitClassification = function () {
        contactsFollowUpForm.sendForm();
    };

    $(function () {
        $(".client-agreement-panel .yes-button").click(function () {
            window.acceptClientAgreement();
        });

        contactsFollowUpForm.checkClientAgreement();

        //bypassClientAgreementIfPossible();
        window.acceptClientAgreement();
    });

    window.acceptClientAgreement = function() {
        contactsFollowUpForm.validateClientAgreement(true, false);
    };
};