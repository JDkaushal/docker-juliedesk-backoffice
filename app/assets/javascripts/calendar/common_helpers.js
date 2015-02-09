window.CommonHelpers = {};
window.CommonHelpers.localize = function(str, locale) {
    return str;
};

window.CommonHelpers.getLocale = function() {
    return "fr";
};
window.CommonHelpers.filterEvents = function(events) {
    return $.grep(events, function(event) {
        if(event.attendees) {
            var declined = false;
            $.each(event.attendees, function(k, attendee) {
                if(attendee.self && attendee.responseStatus == "declined") {
                    declined = true;
                    return false;
                }
            });
            if(declined) {
                return false;
            }
        }
        return true;
    });
};

window.CommonHelpers.externalRequest = function (request, callback, error_callback) {
    var host = "https://juliedesk-app.herokuapp.com";
    //var host = "http://localhost:3000";
    var access_key = "gho67FBDJKdbhfj890oPm56VUdfhq8";
    console.log("Receiving request: ", request);
    if(request.action == "getJulieDeskPreferences") {
        $.ajax({
            url: host + "/api/v1/accounts/show?email=" + request.email + "&access_key=" + access_key,
            type: "GET",
            contentType: "application/json",
            error: function(e) {
                console.log("Error: ", e);
            },
            success: function(response) {
                console.log(response);
                callback(response.data);
            }
        });
    }
    else if(request.action == "get_calendars_list_jd"){
        $.ajax({
            url: host + "/api/v1/calendar_proxy/calendars_list?access_key=gho67FBDJKdbhfj890oPm56VUdfhq8",
            data: {
                email: request.email
            },
            success: function(data) {
                callback({
                    items: data.items
                });
            }
        });
    }
    else if(request.action == "events") {
        $.ajax({
            url: host + "/api/v1/calendar_proxy/events_list?access_key=" + access_key,
            tryCount : 0,
            retryLimit : 20,
            data: {
                start: request.start,
                end: request.end,
                email: request.email
            },
            success: function(data) {
                console.log(data);
                callback({
                    items: CommonHelpers.filterEvents(data.items),
                    key: request.key
                });
            },
            error: function(xhr, textStatus, errorThrown) {
                console.log("Error");
                this.tryCount++;
                if (this.tryCount <= this.retryLimit) {
                    console.log("Retrying...");
                    $.ajax(this);
                    return;
                }
                console.log("Retried too many times");
                return;
            }
        });
    }
    else if(request.action == "create_event") {
        $.ajax({
            url: host + "/api/v1/calendar_proxy/event_create",
            type: "POST",
            contentType: "application/json",
            data: JSON.stringify({
                email: request.email,
                access_key: access_key,
                summary: request.summary,
                description: request.description,
                attendees: request.attendees,
                location: request.location,
                start: request.start,
                end: request.end
            }),
            success: function(e) {
                callback(e);
            },
            error: function(e) {
                error_callback(e);
            }
        });
    }
    else if(request.action == "update_event") {
        $.ajax({
            url: host + "/api/v1/calendar_proxy/event_update",
            type: "POST",
            contentType: "application/json",
            data: JSON.stringify({
                email: request.email,
                access_key: access_key,
                event_id: request.event_id,
                calendar_id: request.calendar_id,
                summary: request.summary,
                description: request.description,
                attendees: request.attendees,
                location: request.location,
                start: request.start,
                end: request.end
            }),
            success: function(e) {
                callback(e);
            },
            error: function(e) {
                error_callback(e);
            }
        });
    }
    else if(request.action == "get_event") {
        $.ajax({
            url: host + "/api/v1/calendar_proxy/event_get",
            type: "GET",
            contentType: "application/json",
            data: {
                email: request.email,
                access_key: access_key,
                event_id: request.event_id,
                calendar_id: request.calendar_id
            },
            success: function(e) {
                callback(e);
            },
            error: function(e) {
                console.log(e);
                error_callback(e);
            }
        });
    }
};


CommonHelpers.formatDateTimeRange = function(startDate, endDate, locale) {
    if(!locale) locale = "en";
    var mStartDate = moment(startDate).locale(locale);
    var mEndDate = moment(endDate).locale(locale);

    if(mStartDate.format("YYYY-MM-DD") == mEndDate.format("YYYY-MM-DD")) {
        return mStartDate.format("dddd D MMMM YYYY") + "<br>" + mStartDate.format("HH:mm") + " - " + mEndDate.format("HH:mm");
    }
    else {
        return mStartDate.format("dddd D MMMM YYYY HH:mm") + " -<br>" + mEndDate.format("dddd D MMMM YYYY HH:mm");
    }

};