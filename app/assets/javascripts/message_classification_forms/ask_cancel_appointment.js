window.classificationForms.askCancelAppointment = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var askCancelAppointmentForm = this;
    // Used to have a common accessor between all the different forms
    var currentClassifForm = askCancelAppointmentForm;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    $(function () {
        $(".client-agreement-panel .yes-button").click(function () {
            window.acceptClientAgreement();
        });

        askCancelAppointmentForm.checkClientAgreement();

        window.acceptClientAgreement();
    });

    window.acceptClientAgreement = function() {
        askCancelAppointmentForm.validateClientAgreement(true, false);
    };
};

window.classificationForms.askCancelAppointment.prototype.onceAgreementAndAttendeesNoticedDone = function() {
    var askCancelAppointmentForm = this;
    askCancelAppointmentForm.sendForm();
};