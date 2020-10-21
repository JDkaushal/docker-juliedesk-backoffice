$(function () {
    $("#add-meeting").click(function () {
        const current_provider = window.getCurrentMeetingTool();
        const current_provider_text = window.getCurrentMeetingToolText();
        window.online_meeting_link = "";
        if(current_provider == "" || typeof current_provider === 'undefined') {
            alert("No Meeting Provider Selected");
            return false;
        }
        var user = window.threadAccount.user_id;
        var email = window.threadAccount.email;
        var start = window.timeSlotToCreate;
        var duration = window.threadComputedData.duration;
        //var d = moment.duration({'mins' : duration});

        //var end= moment(new Date(start)).add(d);
        var provider = window.threadComputedData.online_meeting_provider;
        var message = window.replyingToMessageId;
        var timezone = window.threadComputedData.timezone;

        $(".add-meeting").prop("disabled", true);
        $(".add-meeting .add-meeting-text").hide();
        $(".add-meeting .basic-loader-in-add-meeting-text").html("Creating..");
        $(".add-meeting .basic-loader-in-add-meeting").show();

        if(current_provider_text == 'Ms Teams')
            createMeeting(user,email,start,provider,message,timezone,duration);
        if(current_provider_text == 'Zoom')
            createZoomMeeting(user,email,start,provider,message,timezone,duration);
    });

    $("#remove-meeting").click(function () {
        var other_notes = $("textarea#other_notes").val();
        window.notesManager.setSpecificNotes(other_notes);
        window.updateNotes();
        window.online_meeting_link = "";
    })
});

