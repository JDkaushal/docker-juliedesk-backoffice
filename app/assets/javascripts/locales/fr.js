if(!window.wordings) window.wordings = {};

window.wordings['fr'] = {
    email_templates: {
        suggest_dates: {
            before_dates: "%{client} serait disponible pour un %{appointment_nature} avec vous au %{location} :",
            after_dates: "\n\nQuel horaire vous conviendrait le mieux ?"
        },
        invites_sent: "Parfait, invitations envoyées pour un %{appointment_nature} au %{location}:\n%{date}.",
        info_asked: "Voici l'information demandée :",
        common: {
            before: "Bonjour,\n\n",
            after: "\n\nCordialement,\n\nJulie",//\nIntelligence artificielle",
            full_date_format: "dddd DD MMMM YYYY à HH:mm",
            timezone_precision: "(Fuseau horaire : %{timezone})",
            signature: {
                "juliedesk": "\n\nCordialement,\n\nJulie",//\nIntelligence artificielle",
                "breega": "\n\nSincères salutations,\n\nJulie Filhol\nExecutive Assistant\n\n42 avenue Montaigne\n\n75008 Paris - France\n\nTel: +33 1 72 74 10 01\nFax: +33 1 72 74 10 02\n\nEmail: julie.filhol@breega.com\nWeb: www.breega.com"
            }
        }
    }
};