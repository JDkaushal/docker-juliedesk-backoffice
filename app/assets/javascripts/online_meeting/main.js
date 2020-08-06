$(function () {
    $("#add-meeting").click(function () {

        var user = window.threadAccount.user_id;
        var email = window.threadAccount.email;
        var start = window.currentEventData.start.date;
        var end= window.currentEventData.end.date;
        var provider = window.threadComputedData.online_meeting_provider;
        var message = window.replyingToMessageId;
        $(".add-meeting").prop("disabled", true);
        $(".add-meeting .add-meeting-text").hide();
        $(".add-meeting .basic-loader-in-add-meeting-text").html("Creating..");
        $(".add-meeting .basic-loader-in-add-meeting").show();
        createMeeting(user,email,start,end,provider,message)
    })
});