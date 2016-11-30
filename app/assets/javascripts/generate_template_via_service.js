window.generateEmailTemplateViaService = function(params, callback) {

    var dataForService = {
        client_names: params.client_names,
        dates: params.dates,
        timezones: params.timezones,
        default_timezone: params.default_timezone,
        locale: params.locale,
        is_virtual: params.is_virtual,
        attendees: params.attendees,
        appointment_in_email: params.appointment_in_email,
        location_in_email: params.location_in_email,
        should_ask_location: params.should_ask_location,
        missing_contact_info: params.missing_contact_info
    };


    $.ajax({
        type : "POST",
        url :  "http://template-generator.juliedesk.net/api/v1/templates/suggest_dates",
        dataType: 'json',
        contentType: 'application/json',
        data : JSON.stringify(dataForService),
        success: function(response) {
            callback(response.data);
        }
    });
};