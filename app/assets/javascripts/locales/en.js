if(!window.wordings) window.wordings = {};

window.wordings['en'] = {
    email_templates: {
        no_date_fits: {
            before_dates: {
                suggested: {
                    singular: "Sorry, %{client} is not available anymore at this time, but will be available for %{appointment_nature}%{location}:",
                    plural: "Sorry, %{client} is not available anymore at these times, but will be available for %{appointment_nature}%{location}:"
                },
                not_suggested: {
                    singular: "Sorry this time does not fit, but %{client} would be available for %{appointment_nature}%{location}:",
                    plural: "Sorry none of these times fit, but %{client} would be available for %{appointment_nature}%{location}:"
                }
            }
        },
        suggest_dates: {
            before_dates: "%{client} would be available for %{appointment_nature}%{location}:",
            after_dates: "\n\nWhich time would work best for you?"
        },
        postpone: {
            before_dates: "Here are some new availabilities for %{appointment_nature}%{location}:"
        },
        cancel_multiple: {
            noted_gonna_cancel: {
                singular: "It's noted. I am going to cancel the event:\n",
                plural: "It's noted. I am going to cancel these events:\n"
            },
            noted_no_attendees: {
                singular: "It's noted. But this event has no invitees list:\n",
                plural: "It's noted. But these events have no invitees list:\n"
            },
            but_no_attendees: {
                singular: "\nBut this event has no invitees list:\n",
                plural: "\nBut these events have no invitees list:\n"
            },
            what_should_i_do: {
                singular: "\nWhat should I do for this one?",
                plural: "\nWhat should I do for these ones?"
            }
        },
        postpone_multiple: {
            noted_gonna_cancel: {
                singular: "It's noted. I am going to postpone the event:\n",
                plural: "It's noted. I am going to postpone these events:\n"
            },
            noted_no_attendees: {
                singular: "It's noted. But this event has no invitees list:\n",
                plural: "It's noted. But these events have no invitees list:\n"
            },
            but_no_attendees: {
                singular: "\nBut this event has no invitees list:\n",
                plural: "\nBut these events have no invitees list:\n"
            },
            what_should_i_do: {
                singular: "\nWhat should I do for this one?",
                plural: "\nWhat should I do for these ones?"
            }
        },
        invites_sent: "Perfect, invites sent for %{appointment_nature}%{location}:\n%{date}.",
        info_asked: "Here is the info you asked:",
        confirmation: "Very well, it's noted.",
        cancel: "Very sorry for the setback but unfortunately, %{client} won't be able to ensure %{appointment_nature} with you on %{date}.",
        common: {
            default_appointment_designation_in_email: "the meeting",
            custom_address_at: "at %{location}",
            before: "Hi,\n\n",
            full_date_format: "dddd DD MMMM YYYY, hh:mm a",
            timezone_precision: "(Timezone: %{timezone})",
            footer: {
                "juliedesk": "\n\nBest regards,\n\nJulie",//\nIntelligence artificielle",
                "breega": "\n\nBest regards,\n\n\nJulie Filhol"
            },
            signature: {
                "juliedesk": "",
                "breega": "<br/>\n--<br/>\n<br/>\n<img src='https://lh5.googleusercontent.com/-wbWy7ExZauI/UWvRdxVcsmI/AAAAAAAAAAc/QRQxfD5TBec/w1914-h736-no/130404-BREEG-Logo_FluroGreen.png' width='200' height='76'/><br/>\n<br/>\n<b>Julie Filhol</b><br/>\nExecutive Assistant<br/>\n<br/>\n42 avenue Montaigne<br/>\n75008 Paris - France<br/>\n<br/>\nTel: +33 1 72 74 10 01<br/>\nFax: +33 1 72 74 10 02<br/>\n<br/>\nEmail: <a href='mailto:julie.filhol@breega.com'>julie.filhol@breega.com</a><br/>\nWeb: <a href='www.breega.com'>www.breega.com</a><br/>\n<br/>\nPlease consider the environment and think twice before printing this email ..."
            }
        }
    }
};