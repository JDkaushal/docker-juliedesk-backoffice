if(!window.wordings) window.wordings = {};

window.wordings['fr'] = {
    email_templates: {
        suggest_dates: {
            before_dates: "%{client} est disponible pour un %{appointment_nature} (%{location}):",
            after_dates: "\n\nQuel créneau vous convient le mieux ?"
        },
        invites_sent: "Parfait, invitations envoyées pour un %{appointment_nature} au #{location}:\n#{date}.",
        info_asked: "Voici l'information demandée :",
        common: {
            before: "Bonjour,\n\n",
            after: "\n\nCordialement,\n\nJulie\nIntelligence artificielle",
            full_date_format: "dddd DD MMMM YYYY à HH:mm",
            timezone_precision: " (Fuseau horaire : %{timezone})"
        }
    }
};