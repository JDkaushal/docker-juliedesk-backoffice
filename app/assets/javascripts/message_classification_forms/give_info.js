window.classificationForms.giveInfoForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var giveInfoForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    window.submitClassification = function () {
        if(window.currentEventTile && window.currentEventTile.isEditing()) {
            window.currentEventTile.doneEditingCallback = function() {
                $("#summary").val(window.currentEventTile.event.title);
                $("#location").val(window.currentEventTile.event.location);
                $("#other_notes").val(window.currentEventTile.event.description);

                giveInfoForm.sendForm();
            };
            window.currentEventTile.saveEvent();
        }
        else {
            giveInfoForm.sendForm();
        }
    };

    window.afterEventFetched = function() {
        window.currentEventTile.mode = "edit_only";
        window.currentEventTile.redraw();
    };
    $(function () {
        $(".client-agreement-panel").data("client-agreement", giveInfoForm.clientAgreement);
    });
};