if(!window.wordings) window.wordings = {};

window.wordings['fr'] = {
    email_templates: {
        suggest_dates: {
            before_dates: "%{client} serait disponible pour %{appointment_nature} avec vous%{location} :",
            after_dates: "\n\nQuel horaire vous conviendrait le mieux ?",
        },
        postpone: {
            before_dates: "Ci-dessous de nouvelles disponibilités afin de décaler l'événement :"
        },
        invites_sent: "Parfait, invitations envoyées pour %{appointment_nature}%{location}:\n%{date}.",
        info_asked: "Voici l'information demandée :",
        confirmation: "Très bien, c'est noté.",
        cancel: "Suite à un contretemps, %{client} ne pourra malheureusement pas assurer son rendez-vous avec vous %{date}.",
        common: {
            custom_address_at: "au %{location}",
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