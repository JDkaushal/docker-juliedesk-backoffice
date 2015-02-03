if(!window.wordings) window.wordings = {};

window.wordings['en'] = {
    email_templates: {
        suggest_dates: {
            before_dates: "%{client} would be available for a %{appointment_nature} at %{location}:",
            after_dates: "\n\nWhich time would work best for you?"
        },
        invites_sent: "Perfect, invites sent for a %{appointment_nature} at %{location}:\n%{date}.",
        info_asked: "Here is the info you asked:",
        common: {
            before: "Hi,\n\n",
            after: "\n\nBest,\n\nJulie",//\nArtificial intelligence",
            full_date_format: "dddd DD MMMM YYYY, hh:mm a",
            timezone_precision: "\n(Timezone: %{timezone})"
        }
    }
};