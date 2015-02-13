if(!window.wordings) window.wordings = {};

window.wordings['fr'] = {
    email_templates: {
        no_date_fits: {
            before_dates: {
                suggested: {
                    singular: "Désolé, %{client} n'est plus disponible à cet horaire, mais en revanche :",
                    plural: "Désolé, %{client} n'est plus disponible à ces horaires, mais en revanche :"
                },
                not_suggested: {
                    singular: "Désolé, cet horaire ne convient pas, mais %{client} serait disponible :",
                    plural: "Désolé, aucun de ces horaires ne convient, mais %{client} serait disponible :"
                }
            }
        },
        suggest_dates: {
            before_dates: "%{client} serait disponible pour %{appointment_nature} avec vous%{location} :",
            after_dates: "\n\nQuel horaire vous conviendrait le mieux ?",
        },
        postpone: {
            before_dates: "Ci-dessous de nouvelles disponibilités afin de décaler l'événement :"
        },
        cancel_multiple: {
            noted_gonna_cancel: {
                singular: "C'est bien noté. Je vais annuler l'évènement :\n",
                plural: "C'est bien noté. Je vais annuler les évènements :\n"
            },
            noted_no_attendees: {
                singular: "C'est bien noté. En revanche, cet évènement n'a pas de liste d'invités :\n",
                plural: "C'est bien noté. En revanche, ces évènements n'ont pas de liste d'invités :\n"
            },
            but_no_attendees: {
                singular: "En revanche, cet évènement n'a pas de liste d'invités :\n",
                plural: "En revanche, ces évènements n'ont pas de liste d'invités :\n"
            },
            what_should_i_do: {
                singular: "\nQue dois-je faire pour celui-ci ?",
                plural: "\nQue dois-je faire pour ceux-cis ?"
            }
        },
        cancel_multiple: {
            noted_gonna_cancel: {
                singular: "C'est bien noté. Je vais reporter l'évènement :\n",
                plural: "C'est bien noté. Je vais reporter les évènements :\n"
            },
            noted_no_attendees: {
                singular: "C'est bien noté. En revanche, cet évènement n'a pas de liste d'invités :\n",
                plural: "C'est bien noté. En revanche, ces évènements n'ont pas de liste d'invités :\n"
            },
            but_no_attendees: {
                singular: "En revanche, cet évènement n'a pas de liste d'invités :\n",
                plural: "En revanche, ces évènements n'ont pas de liste d'invités :\n"
            },
            what_should_i_do: {
                singular: "\nQue dois-je faire pour celui-ci ?",
                plural: "\nQue dois-je faire pour ceux-cis ?"
            }
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