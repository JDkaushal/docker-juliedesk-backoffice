if(!window.wordings) window.wordings = {};

window.wordings['en'] = {
    email_templates: {
        create_events: {
            before_dates: {
                created: "I have added the following to your calendar:\n",
                updated: "I have updated the following in your calendar:\n",
                deleted: "I have deleted the following from your calendar:\n"
            }
        },
        no_date_fits: {
            before_dates: {
                suggested: {
                    singular: "Sorry, %{client} is no longer available at this time, ",
                    plural: "Sorry, %{client} is no longer available at these times, "
                },
                not_suggested: {
                    singular: "Sorry this timeslot is not open, ",
                    plural: "Sorry none of these timeslots are open, "
                },
                external_invitation: {
                    proposed_date: "Sorry but %{client} is no longer available %{date}.",
                    not_proposed_date: "Unfortunately %{client} is not available %{date}."
                }
            },
            before_dates_suffix: {
                postpone: "but here are some new availabilities for %{appointment_nature}%{location}:",
                new_appointment: {
                    suggested: "but would be available for %{appointment_nature}%{location}:",
                    not_suggested: "but %{client} would be available for %{appointment_nature}%{location}:"
                },
                external_invitation: "\n\nMay I suggest one of the following time slot :"
            }
        },
        invitation_already_sent: {
            noted: "Thank you for the invite.\nI confirm, the event is in %{client}'s calendar for %{date}."
        },
        follow_up_contacts: {
            before_dates: "Allow me to follow up regarding %{appointment_nature}%{location} with %{clients}.",
            zero_dates: {
                after_dates: {
                    single_attendee_unassisted: "\nCould you please provide me your availabilities?\nThank you.",
                    multiple_attendees_unassisted: "\n%{attendees}, could you please provide me your availabilities? \nThank you.",
                    single_attendee_assisted: "\nCould you please prodive me the availabilities of %{assisted_attendee}?\nThank you.",
                    multiple_attendees_assisted: "\nCould you please provide me the availabilities of %{assisted_attendees}?\nThank you.",
                    multiple_attendees_mix: "\nCould you please provide me your availabilities?\nThank you."
                }
            },
            one_date: {
                before_dates: "Here is an updated availability:\n",
                after_dates: {
                    single_attendee_unassisted: "\nWould that work for you?\nThank you.",
                    multiple_attendees_unassisted: "\n%{attendees}, would that work for you?\nThank you.",
                    single_attendee_assisted: "\nWould that work for %{assisted_attendee}?\nThank you.",
                    multiple_attendees_assisted: "\nWould that work for %{assisted_attendees}?\nThank you.",
                    multiple_attendees_mix: "\nWould that work for you?\nThank you."
                }
            },
            multiple_dates: {
                before_dates: "Here are updated availabilities:\n",
                after_dates: {
                    single_attendee_unassisted: "\nCould you let me know your preference?\nThank you.",
                    multiple_attendees_unassisted: "\n%{attendees}, could you let me know your preference?\nThank you.",
                    single_attendee_assisted: "\nCould you let me know the preference of %{assisted_attendee}?\nThank you.",
                    multiple_attendees_assisted: "\nCould you let me know the preference of %{assisted_attendees}?\nThank you.",
                    multiple_attendees_mix: "\nCould you let me know your preference?\nThank you."
                }
            }
        },
        suggest_dates: {
            ask_agreement: {
                postpone: "Would you like me to suggest other availabilities? I have cancelled the original event in the meantime.",
                new_appointment: "Would you like me to suggest some other availabilities?"
            },
            before_dates: {
                new_appointment: {
                    one_client: "%{client} is available for %{appointment_nature}%{location}:",
                    many_clients: "%{other_clients} and %{client} are available for %{appointment_nature}%{location}:",
                },
                postpone: "Here are some new availabilities for %{appointment_nature}%{location}:"
            },
            after_dates: {
                singular: {
                    single_attendee_unassisted: "\n\nWould that work for you?",
                    multiple_attendees_unassisted: "\n\n%{attendees}, would that work for you?",
                    single_attendee_assisted: "\n\nWould that work for %{assisted_attendee}?",
                    multiple_attendees_assisted: "\n\nWould that work for %{assisted_attendees}?",
                    multiple_attendees_mix: "\n\nWould that work for all of you?"
                },
                plural: {
                    single_attendee_unassisted: "\n\nWhich time works best for you?",
                    multiple_attendees_unassisted: "\n\n%{attendees}, which time works best for you?",
                    single_attendee_assisted: "\n\nWhich time works best for %{assisted_attendee}?",
                    multiple_attendees_assisted: "\n\nWhich time works best for %{assisted_attendees}?",
                    multiple_attendees_mix: "\n\nWhich time would work best?"
                },
                external_invitation: "\n\nLet me know what would you prefer."
            },
            ask_number: {
                call: "\nPlease let me know where you can be reached.",
                skype: "\nPlease let me know where you can be reached."
            }
        },
        cancel_multiple: {
            cancel: "Cancellation:",
            noted_gonna_cancel: {
                singular: "Duly noted. I will cancel the event:\n",
                plural: "Duly noted. I will cancel these events:\n"
            },
            noted_no_attendees: {
                singular: "Duly noted. But I don't have the email addresses for this event:\n",
                plural: "Duly noted. But I don't have the email addresses for these events:\n"
            },
            but_no_attendees: {
                singular: "\nBut I don't have the email addresses for this event:\n",
                plural: "\nBut I don't have the email addresses for these events:\n"
            },
            what_should_i_do: {
                singular: "\nPlease provide the attendees' email addresses if you would like me to take care of it.",
                plural: "\nPlease provide the attendees' email addresses if you would like me to take care of them."
            }
        },
        postpone_multiple: {
            postpone: "Postpone:",
            noted_gonna_cancel: {
                singular: "Duly noted. I will reschedule the event:\n",
                plural: "Duly noted. I will reschedule these events:\n"
            },
            noted_no_attendees: {
                singular: "Duly noted. But I don't have the email addresses for this event:\n",
                plural: "Duly noted. But I don't have the email addresses for these events:\n"
            },
            but_no_attendees: {
                singular: "\nBut I don't have the email addresses for this event:\n",
                plural: "\nBut I don't have the email addresses for these events:\n"
            },
            what_should_i_do: {
                singular: "\nPlease provide the attendees' email addresses if you would like me to take care of it.",
                plural: "\nPlease provide the attendees' email addresses if you would like me to take care of them."
            }
        },
        invites_sent: {
            new_appointment: {
                date_suggested: "Perfect. I've sent invites for %{appointment_nature}%{location}:\n%{date}%{address}",
                date_not_suggested: "Perfect. I've sent invites for %{appointment_nature}%{location}:\n%{date}%{address}"
            },
            postpone: "Perfect. I updated the event for %{appointment_nature}%{location}:\n%{date}%{address}",
            location_in_template: "\nLocation: %{location}",
            ask_for_location: "\n\nPlease let me know the location if you want me to add it to the event.",
            ask_interlocutor_for_location: "\n\nPlease let me know the location to add it to the event.",
            number_to_call: "Number to call: %{number}\n",
            call_client_on: "Call %{client} at %{number_to_call}",
            meeting_room_booked: "\n\nTo those at %{company_name}, the meeting room %{meeting_room_name} has been booked."
        },
        info_asked: "Here is the info you asked:",
        confirmation: {
            default: "Duly noted!",
            give_info: "Thank you, I have made a note of that.",
            give_preference: "Thank you, your preferences have been updated.",
            update_event: "Thank you, the event was updated.",
            update_event_location_with_restaurant_booking: "Thank you.\nI have updated the venue: %{newLocation}\n\nI will get back to you concerning the reservation."
        },
        cancel: {
            attendees_noticed: "I have cancelled %{appointment_nature} scheduled %{date}.",
            attendees_not_noticed: "Very sorry for the inconvenience, but something has come up and %{client} won't be able to make %{appointment_nature} with you %{date}.",
        },
        cancel_client_agreement: "Should I cancel %{appointment_nature} scheduled %{date}?",
        client_agreement: {
            prefix: {
                available: {
                    singular: "You are available for %{appointment_nature} at this date:\n",
                    plural: "You are available for %{appointment_nature} at these dates:\n"
                },
                not_available: {
                    singular: "You are not available for %{appointment_nature} on this date:\n",
                    plural: "You are not available for %{appointment_nature} on any of those dates:\n"
                }
            },
            suffix: {
                available: {
                    new_appointment: "\nDo you want me to create an event and send an invitation?",
                    postpone: "\nDo you want me to reschedule the appointment?"
                },
                not_available: {
                    new_appointment: "\nWould you like me to suggest a few other availabilities?",
                    postpone: "\nWould you like me to suggest other availabilities to reschedule the appointment?"
                }
            }
        },
        forward_to_client: "Please allow me to forward you this email.\nI remain at your disposal.",
        wait_for_contact: {
            postpone: "Pending your contact's response, before rescheduling I will cancel %{appointment_nature} scheduled %{date}.",
            no_postpone: "Pending your contact's response, I remain at your disposal if you need me to suggest your availabilities beforehand."
        },
        common: {
            default_appointment_designation_in_email: "the meeting",
            custom_address_at: "at %{location}",
            interlocutor_name: "%{name}, \n\n",
            hello_only: "Hi,\n\n",
            hello_all: "Hi all,\n\n",
            hello_named: "Hi %{name},\n\n",
            before: "Hi,\n\n",
            before_only_client: "Hi %{client_name},\n\n",
            full_date_format: "dddd D MMMM YYYY h:mma",
            full_time_format: "h:mma",
            only_date_format: "dddd D MMMM YYYY",
            only_date_format_without_year: "dddd D MMMM",
            simplified_date_format: "dddd D MMMM YYYY",
            date_time_separator: "at",
            only_time_format: "h:mma",
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
        },
        send_call_instructions: {
            placed_in_notes: "I have included the call instructions in the event notes.",
            placed_skype_in_notes: "I have noted %{target_name}’s Skype ID in the event notes.",
            give_target_number: "Call instructions: Reach %{target_name} at %{details}",
            give_target_confcall: "Conference Dialing: \n%{details}",
            give_target_skype: "%{target_name}’s Skype ID was included in the invite: %{details}",
            missing_infos: {
                phone: {
                    single_attendee_unassisted: "Please provide the number on which you will be reachable.",
                    multiple_attendees_unassisted: "Please provide a number on which the conference call can be made.",
                    single_attendee_assisted: "Please provide the number on which %{assisted_attendee} will be reachable.",
                    multiple_attendees_assisted: "Please provide a number on which the conference call can be made.",
                    multiple_attendees_mix: "Please provide a number on which the conference call can be made."
                },
                skype: {
                    single_attendee_unassisted: "Please provide your Skype ID.",
                    multiple_attendees_unassisted: "Please provide your Skype IDs.",
                    single_attendee_assisted: "Please provide %{assisted_attendee}’s Skype ID.",
                    multiple_attendees_assisted: "Please provide Skype IDs accordingly.",
                    multiple_attendees_mix: "Please provide Skype IDs accordingly."
                },
                early: {
                    phone: {
                        single_attendee_unassisted: "Please also provide a number on which you will be reachable.",
                        multiple_attendees_unassisted: "Please also provide a number on which the conference call can be made.",
                        single_attendee_assisted: "Please also provide a number on which %{assisted_attendee} will be reachable.",
                        multiple_attendees_assisted: "Please also provide a number on which the conference call can be made.",
                        multiple_attendees_mix: "Please also provide a number on which the conference call can be made."
                    },
                    skype: {
                        single_attendee_unassisted: "Please also provide your Skype ID.",
                        multiple_attendees_unassisted: "Please also provide your Skype IDs.",
                        single_attendee_assisted: "Please also provide %{assisted_attendee}’s Skype ID.",
                        multiple_attendees_assisted: "Please also provide Skype IDs accordingly.",
                        multiple_attendees_mix: "Please also provide Skype IDs accordingly."
                    }
                }
            }
        },
        ask_additional_informations:{
            phone: {
                single_attendee_unassisted: "%{attendee}, please%{courtesyString} provide your phone number, just in case!",
                multiple_attendees_unassisted: "%{attendees}, please%{courtesyString} provide the number on which you will be reachable.",
                single_attendee_assisted: "Please%{courtesyString} provide the number on which %{assisted_attendee} will be reachable, just in case!",
                multiple_attendees_assisted: "Please%{courtesyString} provide a number on which %{attendees} will be reachable, just in case!",
                multiple_attendees_mix: "Please%{courtesyString} provide a number to reach, just in case!"
            },
            skype: {
                single_attendee_unassisted: "%{attendee}, please%{courtesyString} provide your Skype ID.",
                multiple_attendees_unassisted: "%{attendees}, please%{courtesyString} provide your Skype IDs.",
                single_attendee_assisted: "Please%{courtesyString} provide %{assisted_attendee}’s Skype ID.",
                multiple_attendees_assisted: "Please%{courtesyString} provide %{attendees} Skype IDs.",
                multiple_attendees_mix: "Please%{courtesyString} provide Skype IDs accordingly."
            }
        },
        follow_up_confirmation: {
            header: "Got it, I'm going to follow-up on:\n",
            item: "- %{label}\n"
        },
        utilities: {
            timezone_display: "%{city} time"
        }
    },
    restaurant_booking: {
        no_location: "\n\nOnce you have decided, could you let me know your choice of restaurant, so I can make the reservation?",
        with_location: "\n\nI will get back to you concerning the restaurant booking."
    },
    common: {
        cancel: "Cancel",
        or: "or",
        phone: "Phone:",
        egalement: "also",
        mister: 'Mr.',
        madam: 'Ms.'
    },
    events: {
        new_event: "New event",
        recurring_event: {
            this_event_is_part_of_recurring: "This event is part of a recurring event.",
            what_to_update: "Which occurrences do you want to update?",
            what_to_delete: "Which occurrences do you want to delete?",
            this_occurrence: "This occurrence",
            all_occurrences: "All occurrences"
        },
        call_instructions: {
            contacts_infos: 'Contacts-Infos',
            organizer_infos: "Organizer-Infos",
            title: "Call-Instructions",
            display: "Reach %{target_name} at %{details}",
            display_single_attendee: "%{caller_name} to call %{target_name} at %{details}",
            instructions_in_notes: "Call instructions in the notes",
            give_confcall: "%{details}",
            give_target_number: "Reach %{target_name} at %{details}"
        },
        notes: {
            address_details_boundary: 'Address-Details',
            meeting_rooms: {
                boundary: '-Meeting-Room------',
                sentence: 'Meeting room booked at %{company_name}: %{meeting_room_name}'
            }
        }
    },
    constraints: {
        cant: "can't",
        can: "can only",
        prefers: "prefers",
        from: "from",
        to: "to",
        from_date: "from",
        to_date: "to",
        every_day: "every day",
        on_days: "on",
        starting_on: "from",
        ending_on: "to",
        invalid_constraint: "Invalid constraint",
        before_days_for: "for ",
        before_days_on: "on "
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
    info_panel: {
        event_does_not_exist_anymore: "This event does not exists anymore.",
        invitation_does_not_exist_anymore: "This invitation does not exists anymore.",
        remove_link: "Remove association"
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
    },

    dates: {
        today: 'today',
        tomorrow: 'tomorrow'
    }
};