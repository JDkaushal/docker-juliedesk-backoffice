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
                },
                external_invitation: {
                    proposed_date: "Désolée mais %{client} n'est finalement pas disponible %{date}.",
                    not_proposed_date: "Malheureusement %{client} n'est pas disponible %{date}."
                }
            },
            before_dates_suffix: {
                postpone: "mais voici de nouvelles disponibilités pour %{appointment_nature}%{location} :",
                new_appointment: {
                    suggested: "mais serait disponible pour %{appointment_nature}%{location} :",
                    not_suggested: "mais %{client} serait disponible pour %{appointment_nature}%{location} :"
                },
                external_invitation: "\n\nPuis-je vous proposer l'une des dates suivantes :"
            }
        },
        invitation_already_sent: {
            noted: "Merci pour l'invitation.\nJe prends note que l'événement est bien dans le calendrier de %{client} à la date du %{date}."
        },
        follow_up_contacts: {
            before_dates: "Je me permets de vous relancer concernant %{appointment_nature}%{location} avec %{clients}.\n",
            zero_dates: {
                after_dates: {
                    single_attendee_unassisted: "\nPourriez-vous me communiquer vos disponibilités ?\nMerci.",
                    multiple_attendees_unassisted: "\n%{attendees}, pourriez-vous me communiquer vos disponibilités ? \nMerci.",
                    single_attendee_assisted: "\nnPourriez-vous me communiquer les disponibilités de %{assisted_attendee} ?\nMerci.",
                    multiple_attendees_assisted: "\nPourriez-vous me communiquer les disponibilités de %{assisted_attendees} ?\nMerci.",
                    multiple_attendees_mix: "\nPourriez-vous me communiquer vos disponibilités ?\nMerci."
                }
            },
            one_date: {
                before_dates: "\nCi-dessous une proposition mise à jour :",
                after_dates: {
                    single_attendee_unassisted: "\nEst-ce que cet horaire vous conviendrait ?\nMerci.",
                    multiple_attendees_unassisted: "\n%{attendees}, est-ce que cet horaire vous conviendrait ?\nMerci.",
                    single_attendee_assisted: "\nEst-ce que cet horaire conviendrait à %{assisted_attendee} ?\nMerci.",
                    multiple_attendees_assisted: "\nEst-ce que cet horaire conviendrait à %{assisted_attendees} ?\nMerci.",
                    multiple_attendees_mix: "\nEst-ce que cet horaire vous conviendrait ?\nMerci."
                }
            },
            multiple_dates: {
                before_dates: "\nCi-dessous quelques propositions mises à jour :",
                after_dates: {
                    single_attendee_unassisted: "\nPourriez-vous m'indiquer votre préférence ?\nMerci.",
                    multiple_attendees_unassisted: "\n%{attendees}, pourriez-vous m'indiquer votre préférence ?\nMerci.",
                    single_attendee_assisted: "\nPourriez-vous m'indiquer la préférence de %{assisted_attendee} ?\nMerci.",
                    multiple_attendees_assisted: "\nPourriez-vous m'indiquer les préférences de %{assisted_attendees} ?\nMerci.",
                    multiple_attendees_mix: "\nPourriez-vous m'indiquer votre préférence ?\nMerci."
                }
            },
            thank_attendee_for_input: "Merci de votre retour.\n\n"
        },
        suggest_dates: {
            ask_agreement: {
                postpone: "Souhaitez-vous que je propose de nouvelles disponibilités ? J'ai annulé l'évènement en attendant.",
                new_appointment: "Souhaitez-vous que je propose des disponibilités ?"
            },
            before_dates: {
                new_appointment: {
                    one_client: "Permettez-moi de vous proposer les disponibilités de %{client} pour %{appointment_nature}%{location} :",
                    many_clients: "Permettez-moi de vous proposer les disponibilités de %{other_clients} et %{client} pour %{appointment_nature}%{location} :"
                },
                postpone: "Voici de nouvelles disponibilités pour %{appointment_nature}%{location} :"
            },
            after_dates: {
                singular: {
                    single_attendee_unassisted: "\n\nCela vous conviendrait-il ?",
                    multiple_attendees_unassisted: "\n\n%{attendees}, cela vous conviendrait-il ?",
                    single_attendee_assisted: "\n\nCela conviendrait-il à %{assisted_attendee} ?",
                    multiple_attendees_assisted: "\n\nCela conviendrait-il à %{assisted_attendees} ?",
                    multiple_attendees_mix: "\n\nCela conviendrait-il à chacun de vous ?"
                },
                plural: {
                    single_attendee_unassisted: "\n\nQuel horaire vous conviendrait le mieux ?",
                    multiple_attendees_unassisted: "\n\n%{attendees}, quel horaire vous conviendrait le mieux ?",
                    single_attendee_assisted: "\n\nQuel horaire conviendrait le mieux à %{assisted_attendee} ?",
                    multiple_attendees_assisted: "\n\nQuel horaire conviendrait le mieux à %{assisted_attendees} ?",
                    multiple_attendees_mix: "\n\nQuel horaire conviendrait le mieux ?"
                },
                external_invitation: "\n\nMerci de m'indiquer votre préférence."
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
            new_appointment: {
                date_suggested: "Parfait. J'ai envoyé les invitations pour %{appointment_nature}%{location} :\n%{date}%{address}",
                date_not_suggested: "Très bien. J'ai envoyé les invitations pour %{appointment_nature}%{location} :\n%{date}%{address}"
            },
            postpone: "Parfait. J'ai mis à jour l'évènement pour %{appointment_nature}%{location} :\n%{date}%{address}",
            location_in_template: "\nLieu : %{location}",
            ask_for_location: "\n\nPourriez-vous m'indiquer l'adresse si vous souhaitez que je l'ajoute à l'évènement ?",
            ask_interlocutor_for_location: "\n\nPourriez-vous m'indiquer l'adresse pour que je l'ajoute à l'évènement ?",
            number_to_call: "Numéro à appeler : %{number}\n",
            call_client_on: "Appeler %{client} au %{number_to_call}",
            meeting_room_booked: "\n\nPour ceux présents chez %{company_name}, veuillez noter que la salle de réunion %{meeting_room_name} a été réservée."

        },
        info_asked: "Voici l'information demandée :",
        confirmation: {
            default: "Très bien, c'est noté.",
            give_info: "Merci, cela est bien noté.",
            give_preference: "Merci, vos préférences ont bien été mises à jour.",
            update_event: "Merci, l'événement a bien été mis à jour.",
            update_event_location_with_restaurant_booking: "Merci.\nJ'ai mis à jour le lieu de l'événement : %{newLocation}\n\nJe reviens vers vous concernant la réservation du restaurant."
        },
        cancel: {
            attendees_noticed: "J'ai annulé %{appointment_nature} prévu %{date}.",
            attendees_not_noticed: "Désolée, mais suite à un contretemps, %{client} ne pourra malheureusement pas assurer %{appointment_nature} %{date}."
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
                    new_appointment: "\nVoulez-vous que je propose d'autres disponibilités ?",
                    postpone: "\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
                }
            }
        },
        forward_to_client: "Permettez-moi de vous transférer cet email.\nJe reste à votre disposition.",
        wait_for_contact: {
            postpone: "Je comprends que je dois attendre le retour de votre interlocuteur avant de reprogrammer.\nJ'annule %{appointment_nature} prévu %{date} en attendant.",
            no_postpone: "Je comprends que je dois attendre le retour de votre interlocuteur avant d'intervenir.\nJe reste à votre disposition si vous souhaitez que je propose des disponibilités en avance de phase."
        },
        salutations: {
            normal: {
                one: "Bonjour %{names},\n\n",
                two: "Bonjour %{names},\n\n",
                many: "Bonjour,\n\n"
            },
            soutenu: {
                one: "%{names},\n\n",
                two: "%{names},\n\n",
                many: "Bonjour,\n\n"
            }
        },
        common: {
            default_appointment_designation_in_email: "le rendez-vous",
            custom_address_at: "au %{location}",
            interlocutor_name: "%{name}, \n\n",
            hello_only: "Bonjour,\n\n",
            hello_all: "Bonjour à tous,\n\n",
            hello_named: "Bonjour %{name},\n\n",
            before: "Bonjour,\n\n",
            before_only_client: "Bonjour %{client_name},\n\n",
            names_list_and: '%{first_name} et %{last_name}',
            full_date_format: "dddd D MMMM YYYY à H[h]mm",
            full_time_format: "H[h]mm",
            only_date_format: "dddd D MMMM YYYY",
            only_date_format_without_year: "dddd D MMMM",
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
        },
        send_call_instructions: {
            placed_in_notes: "J'ai inséré les instructions d'appel dans les notes de l'événement.",
            placed_skype_in_notes: "J’ai inséré l'identifiant Skype de %{target_name} dans les notes de l’événement.",
            give_target_number: "Instructions d’appel : appeler %{target_name} au %{details}",
            give_target_confcall: "Numéro de conférence : \n%{details}",
            give_target_skype: "L’identifiant Skype de %{target_name} a été joint à l’invitation : %{details}",
            missing_infos: {
                phone: {
                    single_attendee_unassisted: "Merci de me faire parvenir le numéro sur lequel vous serez joignable.",
                    multiple_attendees_unassisted: "Merci de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu.",
                    single_attendee_assisted: "Merci de me faire parvenir le numéro sur lequel %{assisted_attendee} sera joignable.",
                    multiple_attendees_assisted: "Merci de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu.",
                    multiple_attendees_mix: "Merci de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
                },
                skype: {
                    single_attendee_unassisted: "Merci de me faire parvenir votre identifiant Skype.",
                    multiple_attendees_unassisted: "Merci de me faire parvenir vos identifiants Skype.",
                    single_attendee_assisted: "Merci de me faire parvenir l'identifiant Skype de %{assisted_attendee}.",
                    multiple_attendees_assisted: "Merci de me faire parvenir les identifiants Skype.",
                    multiple_attendees_mix: "Merci de me faire parvenir les identifiants Skype."
                },
                early: {
                    phone: {
                        single_attendee_unassisted: "Merci également de me faire parvenir le numéro sur lequel vous serez joignable.",
                        multiple_attendees_unassisted: "Merci également de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu.",
                        single_attendee_assisted: "Merci aussi de me faire parvenir le numéro sur lequel %{assisted_attendee} sera joignable.",
                        multiple_attendees_assisted: "Merci également de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu.",
                        multiple_attendees_mix: "Merci également de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
                    },
                    skype: {
                        single_attendee_unassisted: "Merci également de me faire parvenir votre identifiant Skype.",
                        multiple_attendees_unassisted: "Merci également de me faire parvenir vos identifiants Skype.",
                        single_attendee_assisted: "Merci également de me faire parvenir l'identifiant Skype de %{assisted_attendee}.",
                        multiple_attendees_assisted: "Merci également de me faire parvenir les identifiants Skype.",
                        multiple_attendees_mix: "Merci également de me faire parvenir les identifiants Skype."
                    }
                }
            }
        },
        ask_additional_informations:{
            phone: {
                single_attendee_unassisted: "%{attendee}, merci%{courtesyString} de me faire parvenir le numéro sur lequel vous serez joignable.",
                multiple_attendees_unassisted: "%{attendees}, merci%{courtesyString} de me faire parvenir le numéro sur lequel vous serez joignable.",
                single_attendee_assisted: "Merci%{courtesyString} de me faire parvenir le numéro sur lequel %{assisted_attendee} sera joignable, au cas où.",
                multiple_attendees_assisted: "Merci%{courtesyString} de me faire parvenir un numéro sur lequel %{attendees} seront joignables, au cas où.",
                multiple_attendees_mix: "Merci%{courtesyString} de me faire parvenir un numéro à joindre au cas où."
            },
            skype: {
                single_attendee_unassisted: "%{attendee}, merci%{courtesyString} de me faire parvenir votre identifiant Skype.",
                multiple_attendees_unassisted: "%{attendees}, merci%{courtesyString} de me faire parvenir vos identifiants Skype.",
                single_attendee_assisted: "Merci%{courtesyString} de me faire parvenir l'identifiant Skype de %{assisted_attendee}.",
                multiple_attendees_assisted: "Merci%{courtesyString} de me faire parvenir les identifiants Skype de %{attendees}.",
                multiple_attendees_mix: "Merci%{courtesyString} de me faire parvenir les identifiants Skype."
            }
        },
        follow_up_confirmation: {
            header: "C'est noté, je vais relancer :\n",
            item: "%{label}\n"
        },
        utilities: {
            timezone_display: "heure de %{city}"
        }
    },
    restaurant_booking: {
        no_location: "\n\nPourriez-vous m'indiquer votre choix de restaurant une fois décidé, afin que je puisse effectuer la réservation ?",
        with_location: "\n\nJe reviens vers vous concernant la réservation du restaurant."
    },
    common: {
        cancel: "Annuler",
        or: "ou",
        phone: "Téléphone :",
        egalement: "aussi",
        mister: 'M.',
        madam: 'Mme',
        on: 'le',
        from_hour: 'de',
        from_date: 'du',
        to_hour: 'à',
        to_date: 'au',
        at: 'à',
        sending: "Envoi en cours...",
        sent: "Envoyé."
    },
    gender_reference: {
        account_tile: {
            M: 'M.',
            F: 'Mme.'
        },
      with_name: {
          normal: {
              M: "M.",
              F: "Mme",
              _: ''
          },

          soutenu: {
              M: "Monsieur",
              F: "Madame",
              _: ''
          },
      },
        without_name: {
            normal: {
                M: "Monsieur",
                F: "Madame",
                _: ''
            },
            soutenu: {
                M: "Monsieur",
                F: "Madame",
                _: ''
            },
        }
    },
    events: {
        new_event: "Nouvel évènement",
        recurring_event: {
            this_event_is_part_of_recurring: "Cet évènement fait partie d'un évènement récurrent.",
            what_to_update: "Quelles occurrences voulez-vous mettre à jour ?",
            what_to_select: "Quelles occurrences voulez-vous sélectionner?",
            what_to_delete: "Quelles occurrences voulez-vous supprimer ?",
            this_occurrence: "Cette occurrence",
            all_occurrences: "Toutes les occurrences"
        },
        call_instructions: {
            contacts_infos: 'Informations-de-contacts',
            organizer_infos: "Informations-organisateur",
            title: "Instructions-d\'appel",
            display: "Appeler %{target_name} au %{details}",
            display_single_attendee: "%{caller_name} appelle %{target_name} au %{details}",
            instructions_in_notes: "Instructions d'appel dans les notes",
            give_target_number: "Appeler %{target_name} au %{details}",
            give_confcall: "%{details}",
            give_skype_for_business: "Afin de rejoindre la conférence Skype, cliquez sur le lien suivant : %{details}"
        },
        notes: {
            address_details_boundary: 'Complément-Adresse',
            meeting_rooms: {
                boundary: '-Salles-de-Réunion------',
                sentence: '%{meeting_room_name} (%{meeting_room_location})'
            }
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
        before_days: "",
        before_days_for: "",
        before_days_on: ""
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
        calendar_login_unreachable: "Compte calendrier inaccessible, si existant, veuillez rattacher l'événement manuellement",
        invitation_does_not_exist_anymore: "Le client a refusé l'invitation",
        remove_link: "Supprimer l'association",
        client_on_trip: {
            label: "Client(s) en déplacement à..."
        }
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