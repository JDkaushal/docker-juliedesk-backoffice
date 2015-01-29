if(!window.wordings) window.wordings = {};

window.wordings['en'] = {
    email_templates: {
        suggest_dates: {
            before_dates: "%{client} is available for an %{appointment_nature} (%{location}):",
            after_dates: "\n\nWhich date is the best for you?"
        },
        invites_sent: "Perfect, invites sent for a %{appointment_nature} at #{location}:\n#{date}.",
        info_asked: "Here is the info you asked:",
        common: {
            before: "Hi,\n\n",
            after: "\n\nBest,\n\nJulie\nArtificial intelligence",
            full_date_format: "dddd DD MMMM YYYY, hh:mm a",
            timezone_precision: " (Timezone: %{timezone})"
        }
    }
};