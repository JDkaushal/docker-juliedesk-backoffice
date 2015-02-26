window.classificationForms.askCancelAppointment = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var askCancelAppointmentForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    $(function () {
        $(".client-agreement-panel .yes-button").click(function () {
            askCancelAppointmentForm.validateClientAgreement(true, false);
        });

        askCancelAppointmentForm.checkClientAgreement();
    });
};

window.classificationForms.askCancelAppointment.prototype.onceAgreementAndAttendeesNoticedDone = function() {
    var askCancelAppointmentForm = this;
    askCancelAppointmentForm.sendForm();
};