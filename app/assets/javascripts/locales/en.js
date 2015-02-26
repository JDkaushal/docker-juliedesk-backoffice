if(!window.wordings) window.wordings = {};

window.wordings['en'] = {
    email_templates: {
        create_events: {
            before_dates: "I added to your calendar:\n"
        },
        no_date_fits: {
            before_dates: {
                suggested: {
                    singular: "Sorry, %{client} is not available anymore at this time, ",
                    plural: "Sorry, %{client} is not available anymore at these times, "
                },
                not_suggested: {
                    singular: "Sorry this time does not fit, ",
                    plural: "Sorry none of these times fit, "
                }
            },
            before_dates_suffix: {
                postpone: "but here are some new availabilities for %{appointment_nature}%{location}:",
                new_appointment: {
                    suggested: "but would be available for %{appointment_nature}%{location}:",
                    not_suggested: "but %{client} would be available for %{appointment_nature}%{location}:"
                }
            }
        },
        suggest_dates: {
            ask_agreement: {
                postpone: "Do you want me to new suggest availabilities?",
                new_appointment: "Do you want me to suggest availabilities?"
            },
            before_dates: {
                new_appointment: "%{client} would be available for %{appointment_nature}%{location}:",
                postpone: "Here are some new availabilities for %{appointment_nature}%{location}:"
            },
            after_dates: {
                singular: "\n\nWould that work for you?",
                plural: "\n\nWhich time would work best for you?"
            },
            ask_number: {
                call: "\nPlease let me know where you can be reached.",
                skype: "\nPlease let me know where you can be reached."
            }
        },
        cancel_multiple: {
            cancel: "Cancellation:",
            noted_gonna_cancel: {
                singular: "It's noted. I am going to cancel the event:\n",
                plural: "It's noted. I am going to cancel these events:\n"
            },
            noted_no_attendees: {
                singular: "It's noted. But I don't have any email address for this event:\n",
                plural: "It's noted. But I don't have any email address for these events:\n"
            },
            but_no_attendees: {
                singular: "\nBut I don't have any email address for this event:\n",
                plural: "\nBut I don't have any email address for these events:\n"
            },
            what_should_i_do: {
                singular: "\nPlease provide attendees emails if you want me to take care of it.",
                plural: "\nPlease provide attendees emails if you want me to take care of them."
            }
        },
        postpone_multiple: {
            postpone: "Postpone:",
            noted_gonna_cancel: {
                singular: "It's noted. I am going to postpone the event:\n",
                plural: "It's noted. I am going to postpone these events:\n"
            },
            noted_no_attendees: {
                singular: "It's noted. But I don't have any email address for this event:\n",
                plural: "It's noted. But I don't have any email address for these events:\n"
            },
            but_no_attendees: {
                singular: "\nBut I don't have any email address for this event:\n",
                plural: "\nBut I don't have any email address for these events:\n"
            },
            what_should_i_do: {
                singular: "\nPlease provide attendees emails if you want me to take care of it.",
                plural: "\nPlease provide attendees emails if you want me to take care of them."
            }
        },
        invites_sent: {
            new_appointment: "Perfect, invites sent for %{appointment_nature}%{location}:\n%{date}.",
            postpone: "Perfect, the event has been updated for %{appointment_nature}%{location}:\n%{date}."
        },
        info_asked: "Here is the info you asked:",
        confirmation: "Very well, it's noted.",
        cancel: {
            attendees_noticed: "I canceled %{appointment_nature} scheduled on %{date}.",
            attendees_not_noticed: "Very sorry for the setback but unfortunately, %{client} won't be able to ensure %{appointment_nature} with you on %{date}.",
        },
        cancel_client_agreement: "Do I have your agreement to cancel %{appointment_nature} scheduled on %{date}?",
        client_agreement: {
            prefix: {
                available: {
                    singular: "You are available for %{appointment_nature} at this date:\n",
                    plural: "You are available for %{appointment_nature} at these dates:\n"
                },
                not_available: {
                    singular: "You are not available for %{appointment_nature} at this date:\n",
                    plural: "You are not available for %{appointment_nature} at any of those dates:\n"
                }
            },
            suffix: {
                available: {
                    new_appointment: "\nDo you want me to create an event and send an invitation?",
                    postpone: "\nDo you want me to postpone the appointment?"
                },
                not_available: {
                    new_appointment: "\nDo you want me to suggest other availabilities?",
                    postpone: "\nDo you want me to suggest new availabilities to postpone the appointment?"
                }
            }
        },
        common: {
            default_appointment_designation_in_email: "the meeting",
            custom_address_at: "at %{location}",
            before: "Hi,\n\n",
            full_date_format: "LLLL",
            timezone_precision: "(Timezone: %{timezone})",
            footer: {
                "juliedesk": "\n\nBest regards,\n\nJulie",//\nIntelligence artificielle",
                "breega": "\n\nBest regards,\n\n\nJulie Filhol",
                "hourlynerd": "\n\nBest regards,\n\nJulie"
            },
            signature: {
                "juliedesk": "",
                "breega": "<br/>\n--<br/>\n<br/>\n<img src='https://lh5.googleusercontent.com/-wbWy7ExZauI/UWvRdxVcsmI/AAAAAAAAAAc/QRQxfD5TBec/w1914-h736-no/130404-BREEG-Logo_FluroGreen.png' width='200' height='76'/><br/>\n<br/>\n<b>Julie Filhol</b><br/>\nExecutive Assistant<br/>\n<br/>\n42 avenue Montaigne<br/>\n75008 Paris - France<br/>\n<br/>\nTel: +33 1 72 74 10 01<br/>\nFax: +33 1 72 74 10 02<br/>\n<br/>\nEmail: <a href='mailto:julie.filhol@breega.com'>julie.filhol@breega.com</a><br/>\nWeb: <a href='www.breega.com'>www.breega.com</a><br/>\n<br/>\nPlease consider the environment and think twice before printing this email ...",
                "hourlynerd": ""
            }
        }
    },
    events: {
        new_event: "New event"
    },
    constraints: {
        cant: "can't",
        can: "can only",
        prefers: "prefers"
    },
    actions: {
        to_do: {
            ask_agreement: "To do: ask agreement",
            suggest_dates: {
                new_appointment: "To do: suggest dates",
                postpone: "To do: suggest new dates"
            }
        }
    },
    classification_forms: {
        common: {
            fill_info_in: "Please fill info in"
        },
        ask_date_suggestions: {

        },
        ask_availabilities: {
            dates_identification: "Dates identification",
            suggested_dates: "Suggested dates"
        }
    }
};