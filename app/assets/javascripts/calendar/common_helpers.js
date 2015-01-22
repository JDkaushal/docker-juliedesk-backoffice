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
    //var host = "https://juliedesk-app.herokuapp.com";
    var host = "http://localhost:3000";
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
        if(request.calendar_nature == "google") {
            $.get("https://www.googleapis.com/calendar/v3/users/me/calendarList?access_token=" + request.access_token, function(data) {
                callback({
                    items: data.items
                });
            }).fail(function() {});
        }
        else if(request.calendar_nature == "icloud" || "exchange") {
            $.ajax({
                url: host + "/api/v1/" + request.calendar_nature + "_proxy/calendars_list?access_key=gho67FBDJKdbhfj890oPm56VUdfhq8",
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
    }
    else if(request.action == "events") {
        if(request.calendar_nature == "google") {
            var url = "https://www.googleapis.com/calendar/v3/calendars/" + encodeURIComponent(request.cal) + "/events?access_token=" + request.access_token;
            url += "&timeMin=" + encodeURIComponent(request.start);
            url += "&timeMax=" + encodeURIComponent(request.end);
            url += "&singleEvents=true";
            url += "&fields=items(end,htmlLink,start,summary,status,attendees,organizer,reminders,id)";

            $.get(url, function(data) {
                callback({
                    items: CommonHelpers.filterEvents(data.items),
                    key: request.key
                });
            });
        }
        else if(request.calendar_nature == "icloud" || request.calendar_nature == "exchange") {
            $.ajax({
                url: host + "/api/v1/" + request.calendar_nature + "_proxy/events_list?access_key=" + access_key,
                tryCount : 0,
                retryLimit : 20,
                data: {
                    start: request.start,
                    end: request.end,
                    email: request.email
                },
                success: function(data) {
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
    }
    else if(request.action == "create_event") {
        if(request.calendar_nature == "google") {

        }
        else if(request.calendar_nature == "icloud" || request.calendar_nature == "exchange") {
            $.ajax({
                url: host + "/api/v1/" + request.calendar_nature + "_proxy/event_create",
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
    }
};
