window.generateEmailTemplateViaService = function(params, callback) {

    var dataForService = {};

    if(params.template == "suggest_dates") {
        dataForService = {
            client_names: params.client_names,
            timezones: params.timezones,
            default_timezone: params.default_timezone,
            locale: params.locale,
            is_virtual: params.is_virtual,
            attendees: params.attendees,
            appointment_in_email: params.appointment_in_email,
            location_in_email: params.location_in_email,
            should_ask_location: params.should_ask_location,
            missing_contact_info: params.missing_contact_info,

            dates: params.dates
        };
    }
    else if(params.template == "send_invitations") {
        dataForService = {
            client_names: params.client_names,
            timezones: params.timezones,
            default_timezone: params.default_timezone,
            locale: params.locale,
            is_virtual: params.is_virtual,
            attendees: params.attendees,
            appointment_in_email: params.appointment_in_email,
            location_in_email: params.location_in_email,
            should_ask_location: params.should_ask_location,
            missing_contact_info: params.missing_contact_info,

            date: params.date,
            location_kind: params.location_kind
        }
    }
    else {
        return null;
    }

    $.ajax({
        type : "POST",
        url :  "https://template-generator.juliedesk.net/api/v1/templates/" + params.template,
        // url :  "http://localhost:4567/api/v1/templates/" + params.template,
        dataType: 'json',
        contentType: 'application/json',
        data : JSON.stringify(dataForService),
        success: function(response) {
            callback(response.data);
        }
    });

};