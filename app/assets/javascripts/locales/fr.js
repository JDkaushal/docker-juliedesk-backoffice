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
            full_date_format: "dddd DD MMMM YYYY à HH:mm",
            timezone_precision: "(Fuseau horaire : %{timezone})",
            footer: {
                "juliedesk": "\n\nCordialement,\n\nJulie",//\nIntelligence artificielle",
                "breega": "\n\nSincères salutations,\n\n\nJulie Filhol"
            },
            signature: {
                "juliedesk": "",
                "breega": "<br/>\n--<br/>\n<br/>\n<img src='https://lh5.googleusercontent.com/-wbWy7ExZauI/UWvRdxVcsmI/AAAAAAAAAAc/QRQxfD5TBec/w1914-h736-no/130404-BREEG-Logo_FluroGreen.png' width='200' height='76'/><br/>\n<br/>\n<b>Julie Filhol</b><br/>\nExecutive Assistant<br/>\n<br/>\n42 avenue Montaigne<br/>\n75008 Paris - France<br/>\n<br/>\nTel: +33 1 72 74 10 01<br/>\nFax: +33 1 72 74 10 02<br/>\n<br/>\nEmail: <a href='mailto:julie.filhol@breega.com'>julie.filhol@breega.com</a><br/>\nWeb: <a href='www.breega.com'>www.breega.com</a><br/>\n<br/>\nPlease consider the environment and think twice before printing this email ..."
            }
        }
    }
};