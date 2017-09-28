window.classificationForms.giveInfoForm = function (params) {
    window.classificationForms.classificationForm.isParentOf(this, params);

    var giveInfoForm = this;

    window.leftColumnMessage = localize("classification_forms.common.fill_info_in");

    window.submitClassification = function () {
        if(window.currentEventTile && window.currentEventTile.isEditing()) {
            var virtualMeetingHelper = $('#virtual-meetings-helper').scope();
            var data = {event: window.currentEventTile.event};
            data.appointment = window.threadComputedData.appointment_nature;
            data.attendees = window.threadComputedData.attendees;

            // if(virtualMeetingHelper) {
            //     // Looking for differences in details should be enough to tell if the call instructions changed
            //     data.call_instructions_details = virtualMeetingHelper.currentConf.details;
            // }
            var beforeUpdateData = JSON.stringify(data);

            window.currentEventTile.doneEditingCallback = function() {
                $("#summary").val(window.currentEventTile.event.title);
                $("#location").val(window.currentEventTile.event.location);
                //$("#other_notes").val(window.currentEventTile.event.description);

                giveInfoForm.sendForm({
                    before_update_data: beforeUpdateData
                });
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