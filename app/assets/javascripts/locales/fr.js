if(!window.wordings) window.wordings = {};

window.wordings['fr'] = {
    email_templates: {
        create_events: {
            before_dates: {
                created: "J'ai ajouté à votre calendrier :\n",
                updated: "J'ai mis à jour dans votre calendrier :\n",
                deleted: "J'ai supprimé de votre calendrier :\n"
            }
        },
        no_date_fits: {
            before_dates: {
                suggested: {
                    singular: "Désolée, %{client} n'est plus disponible à cet horaire, ",
                    plural: "Désolée, %{client} n'est plus disponible à ces horaires, "
                },
                not_suggested: {
                    singular: "Désolée, cet horaire ne convient pas, ",
                    plural: "Désolée, aucun de ces horaires ne convient, "
                }
            },
            before_dates_suffix: {
                postpone: "mais voici de nouvelles disponibilités pour %{appointment_nature}%{location} :",
                new_appointment: {
                    suggested: "mais serait disponible pour %{appointment_nature}%{location} :",
                    not_suggested: "mais %{client} serait disponible pour %{appointment_nature}%{location} :"
                }
            }
        },
        suggest_dates: {
            ask_agreement: {
                postpone: "Souhaitez-vous que je propose de nouvelles disponibilités ?",
                new_appointment: "Souhaitez-vous que je propose des disponibilités ?"
            },
            before_dates: {
                new_appointment: {
                    one_client: "%{client} serait disponible pour %{appointment_nature} avec vous%{location} :",
                    many_clients: "%{other_clients} et %{client} seraient disponibles pour %{appointment_nature} avec vous%{location} :",
                },
                postpone: "Voici de nouvelles disponibilités pour %{appointment_nature}%{location} :"
            },
            after_dates: {
                singular: {
                    one_attendee: "\n\nCela vous conviendrait-il ?",
                    many_attendees: "\n\n%{attendees}, cela vous conviendrait-il ?"
                },
                plural: {
                    one_attendee: "\n\nQuel horaire vous conviendrait le mieux ?",
                    many_attendees: "\n\n%{attendees}, quel horaire vous conviendrait le mieux ?"
                }
            },
            ask_number: {
                call: "\nMerci de me préciser à quel numéro vous êtes joignable.",
                skype: "\nMerci de me préciser à quel identifiant vous êtes joignable."
            }
        },

        cancel_multiple: {
            cancel: "Annulation :",
            noted_gonna_cancel: {
                singular: "C'est bien noté. Je vais annuler l'évènement :\n",
                plural: "C'est bien noté. Je vais annuler les évènements :\n"
            },
            noted_no_attendees: {
                singular: "C'est bien noté. En revanche, je n'ai pas les contacts pour cet évènement :\n",
                plural: "C'est bien noté. En revanche, je n'ai pas les contacts pour ces évènements :\n"
            },
            but_no_attendees: {
                singular: "\nEn revanche, je n'ai pas les contacts pour cet évènement :\n",
                plural: "\nEn revanche, je n'ai pas les contacts pour ces évènements :\n"
            },
            what_should_i_do: {
                singular: "\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe.",
                plural: "\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        },
        postpone_multiple: {
            postpone: "Report :",
            noted_gonna_cancel: {
                singular: "C'est bien noté. Je vais reporter l'évènement :\n",
                plural: "C'est bien noté. Je vais reporter les évènements :\n"
            },
            noted_no_attendees: {
                singular: "C'est bien noté. En revanche, je n'ai pas les contacts pour cet évènement :\n",
                plural: "C'est bien noté. En revanche, je n'ai pas les contacts pour ces évènements :\n"
            },
            but_no_attendees: {
                singular: "\nEn revanche, je n'ai pas les contacts pour cet évènement :\n",
                plural: "\nEn revanche, je n'ai pas les contacts pour ces évènements :\n"
            },
            what_should_i_do: {
                singular: "\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe.",
                plural: "\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        },
        invites_sent: {
            new_appointment: "Parfait. J'ai envoyé les invitations pour %{appointment_nature}%{location} :\n%{date}%{address}",
            postpone: "Parfait. J'ai mis à jour l'évènement pour %{appointment_nature}%{location} :\n%{date}%{address}",
            location_in_template: "\nLieu : %{location}",
            ask_for_location: "\n\nPourriez-vous m'indiquer l'adresse si vous souhaitez que je l'ajoute à l'évènement ?",
            ask_interlocutor_for_location: "\n\nPourriez-vous m'indiquer l'adresse pour que je l'ajoute à l'évènement ?",
            number_to_call: "Numéro à appeler : %{number}\n",
            call_client_on: "Appeler %{client} au %{number_to_call}"
        },
        info_asked: "Voici l'information demandée :",
        confirmation: "Très bien, c'est noté.",
        cancel: {
            attendees_noticed: "J'ai annulé %{appointment_nature} prévu %{date}.",
            attendees_not_noticed: "Désolée, mais suite à un contretemps, %{client} ne pourra malheureusement pas assurer %{appointment_nature} avec vous %{date}."
        },
        cancel_client_agreement: "Ai-je votre approbation pour annuler %{appointment_nature} prévu %{date} ?",
        client_agreement: {
            prefix: {
                available: {
                    singular: "Vous êtes disponible pour %{appointment_nature} à cette date :\n",
                    plural: "Vous êtes disponible pour %{appointment_nature} à ces dates :\n"
                },
                not_available: {
                    singular: "Vous n'êtes pas disponible pour %{appointment_nature} à cette date :\n",
                    plural: "Vous n'êtes disponible pour %{appointment_nature} à aucune de ces dates :\n"
                }
            },
            suffix: {
                available: {
                    new_appointment: "\nVoulez-vous que je crée un évènement et envoie des invitations ?",
                    postpone: "\nVoulez-vous que je reporte l'évènement?"
                },
                not_available: {
                    new_appointment: "\nVoulez-vous que propose d'autres disponibilités ?",
                    postpone: "\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
                }
            }
        },
        common: {
            default_appointment_designation_in_email: "le rendez-vous",
            custom_address_at: "au %{location}",
            before: "Bonjour,\n\n",
            before_only_client: "Bonjour %{client_name},\n\n",
            full_date_format: "dddd D MMMM YYYY à H[h]mm",
            full_time_format: "H[h]mm",
            only_date_format: "dddd D MMMM YYYY",
            simplified_date_format: "dddd, D MMMM YYYY",
            date_time_separator: "à",
            only_time_format: "H[h]mm",
            timezone_precision: "(Fuseau horaire : %{timezone})",
            footer: {
                "juliedesk": "\n\nCordialement,\n\nJulie",//\nIntelligence artificielle",
                "breega": "\n\nSincères salutations,\n\n\nJulie Filhol",
                "hourlynerd": "\n\nCordialement,\n\nJulie"
            },
            signature: {
                "juliedesk": "",
                "breega": "<br/>\n--<br/>\n<br/>\n<img src='https://lh5.googleusercontent.com/-wbWy7ExZauI/UWvRdxVcsmI/AAAAAAAAAAc/QRQxfD5TBec/w1914-h736-no/130404-BREEG-Logo_FluroGreen.png' width='200' height='76'/><br/>\n<br/>\n<b>Julie Filhol</b><br/>\nExecutive Assistant<br/>\n<br/>\n42 avenue Montaigne<br/>\n75008 Paris - France<br/>\n<br/>\nTel: +33 1 72 74 10 01<br/>\nFax: +33 1 72 74 10 02<br/>\n<br/>\nEmail: <a href='mailto:julie.filhol@breega.com'>julie.filhol@breega.com</a><br/>\nWeb: <a href='www.breega.com'>www.breega.com</a><br/>\n<br/>\nPlease consider the environment and think twice before printing this email ...",
                "hourlynerd": ""
            }
        }
    },
    common: {
        cancel: "Annuler",
        or: "ou"
    },
    events: {
        new_event: "Nouvel évènement",
        recurring_event: {
            this_event_is_part_of_recurring: "Cet évènement fait partie d'un évènement récurrent.",
            what_to_update: "Quelles occurrences voulez-vous mettre à jour ?",
            what_to_delete: "Quelles occurrences voulez-vous supprimer ?",
            this_occurrence: "Cette occurrence",
            all_occurrences: "Toutes les occurrences"
        }
    },
    constraints: {
        cant: "ne peux pas",
        can: "peux uniquement",
        prefers: "préfère",
        from: "de",
        to: "à",
        from_date: "à partir du",
        to_date: "jusqu'au",
        every_day: "tous les jours",
        on_days: "le",
        starting_on: "du",
        ending_on: "au",
        invalid_constraint: "Contrainte non-valide",
        before_days: ""
    },
    actions: {
        to_do: {
            ask_agreement: "A faire : demander l'accord",
            suggest_dates: {
                new_appointment: "A faire : proposer des dates",
                postpone: "A faire: proposer de nouvelles dates"
            }
        }
    },
    info_panel: {
        event_does_not_exist_anymore: "Cet évènement n'existe plus.",
        remove_link: "Supprimer l'association"
    },
    classification_forms: {
        common: {
            fill_info_in: "Remplissez les infos"
        },
        ask_date_suggestions: {

        },
        ask_availabilities: {
            dates_identification: "Identification des dates",
            suggested_dates: "Dates suggérées"
        }
    },
    dates: {
        today: "aujourd'hui",
        tomorrow: "demain"
    }
};