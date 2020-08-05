$(function () {
    $("#add-meeting").click(function () {
        var user = window.threadAccount.user_id;
        var email = window.threadAccount.email;
        var start = window.currentEventData.start.date;
        var end= window.currentEventData.end.date;
        var provider = window.threadComputedData.online_meeting_provider
        createMeeting(user,email,start,end,provider)
    })
});