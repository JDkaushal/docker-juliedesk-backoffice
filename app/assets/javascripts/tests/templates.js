window.tests.templates = [
    {
        name: "Wordings",
        should: "be correct",
        test_result: function () {
            var result = true;
            var locales = ["en", "fr"];
            _.each(window.testsData.templatesData, function (paramGroups) {
                _.each(paramGroups, function (params) {
                    var expectedResults = params.expectedResults;
                    _.each(locales, function (locale) {
                        params.locale = locale;
                        var template = window.generateEmailTemplate(params);
                        if(template != expectedResults[locale]) {
                            result = false;
                        }
                    });
                });
            });
            return result;
        },
        expected_result: true
    }
];

window.testsData.templatesData = [
    [{
        action: "suggest_dates",
        client_agreement: true,
        client: "Nicolas Marlier",
        timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
        timezoneId: "Europe/Paris",
        defaultTimezoneId: "Europe/Paris",
        appointment: {
            title_in_email: {
                fr: "un rendez-vous",
                en: "an appointment"
            }
        },
        address: {
            address_in_template: {
                fr: "au bureau",
                en: "at the office"
            }
        },
        expectedResults: {
            en: "Nicolas Marlier would be available for an appointment at the office:\n - Thursday, January 1, 2015 12:00 PM\n - Thursday, January 1, 2015 2:00 PM\n - Sunday, January 4, 2015 12:00 PM\n - Tuesday, January 6, 2015 12:00 PM\n\nWhich time would work best for you?",
            fr: "Nicolas Marlier serait disponible pour un rendez-vous avec vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00\n - Jeudi 1 janvier 2015 à 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Nicolas Marlier would be available for an appointment at the office:\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous avec vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                }
            },
            address: "9 rue Dareau",
            expectedResults: {
                en: "Nicolas Marlier would be available for an appointment at 9 rue Dareau:\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous avec vous au 9 rue Dareau :\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "America/Los_Angeles",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Nicolas Marlier would be available for an appointment at the office:\n(Timezone: America/Los Angeles)\n - Thursday, January 1, 2015 3:00 AM\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous avec vous au bureau :\n(Fuseau horaire : America/Los Angeles)\n - Jeudi 1 janvier 2015 à 3h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a call"
                },
                label: "call"
            },
            expectedResults: {
                en: "Nicolas Marlier would be available for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous téléphonique avec vous :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a skype"
                },
                label: "skype"
            },
            expectedResults: {
                en: "Nicolas Marlier would be available for a skype:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Nicolas Marlier serait disponible pour un skype avec vous :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel identifiant vous êtes joignable."
            }
        }],


    [{
        action: "suggest_dates",
        client_agreement: true,
        client: "Nicolas Marlier",
        noDateFits: "suggested_multiple",
        timeSlotsToSuggest: ["2015-01-01T12:00:00"],
        timezoneId: "Europe/Paris",
        defaultTimezoneId: "Europe/Paris",
        appointment: {
            title_in_email: {
                fr: "un rendez-vous téléphonique",
                en: "a call"
            },
            label: "call"
        },
        expectedResults: {
            en: "Sorry, Nicolas Marlier is not available anymore at these times, but would be available for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
            fr: "Désolée, Nicolas Marlier n'est plus disponible à ces horaires, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "not_suggested_multiple",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a call"
                },
                label: "call"
            },
            expectedResults: {
                en: "Sorry none of these times fit, but Nicolas Marlier would be available for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Désolée, aucun de ces horaires ne convient, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "suggested_single",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a call"
                },
                label: "call"
            },
            expectedResults: {
                en: "Sorry, Nicolas Marlier is not available anymore at this time, but would be available for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "not_suggested_single",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a call"
                },
                label: "call"
            },
            expectedResults: {
                en: "Sorry this time does not fit, but Nicolas Marlier would be available for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Désolée, cet horaire ne convient pas, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
            }
        }],


    [{
        action: "suggest_dates",
        client_agreement: true,
        client: "Nicolas Marlier",
        isPostpone: true,
        currentEventData: {
            start: {
                dateTime: "2015-01-01T08:00:00"
            }
        },
        timeSlotsToSuggest: ["2015-01-01T12:00:00"],
        timezoneId: "Europe/Paris",
        defaultTimezoneId: "Europe/Paris",
        appointment: {
            title_in_email: {
                fr: "un rendez-vous téléphonique",
                en: "a call"
            },
            label: "call"
        },
        expectedResults: {
            en: "Very sorry for the setback but unfortunately, Nicolas Marlier won't be able to ensure the meeting with you on Thursday, January 1, 2015 8:00 AM.\n\nHere are some new availabilities for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
            fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous avec vous Jeudi 1 janvier 2015 à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            currentEventData: {
                start: {
                    dateTime: "2015-01-01T08:00:00"
                }
            },
            attendeesAreNoticed: false,
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a call"
                },
                label: "call"
            },
            expectedResults: {
                en: "Very sorry for the setback but unfortunately, Nicolas Marlier won't be able to ensure the meeting with you on Thursday, January 1, 2015 8:00 AM.\n\nHere are some new availabilities for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous avec vous Jeudi 1 janvier 2015 à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            attendeesAreNoticed: true,
            noDateFits: "suggested_single",
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a call"
                },
                label: "call"
            },
            expectedResults: {
                en: "Sorry, Nicolas Marlier is not available anymore at this time, but here are some new availabilities for a call:\n(Timezone: Europe/Paris)\n - Thursday, January 1, 2015 12:00 PM\n\nWould that work for you?\nPlease let me know where you can be reached.",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais voici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?\nMerci de me préciser à quel numéro vous êtes joignable."
            }
        }],


    [{
        action: "suggest_dates",
        client_agreement: false,
        isPostpone: false,
        expectedResults: {
            en: "Do you want me to suggest availabilities?",
            fr: "Souhaitez-vous que je propose des disponibilités ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: false,
            isPostpone: true,
            expectedResults: {
                en: "Do you want me to new suggest availabilities?",
                fr: "Souhaitez-vous que je propose de nouvelles disponibilités ?"
            }
        }],


    [{
        action: "invites_sent",
        client_agreement: true,
        client: "Nicolas Marlier",
        timeSlotToCreate: "2015-01-01T12:00:00",
        defaultTimezoneId: "Europe/Paris",
        allTimezoneIds: ["Europe/Paris"],
        appointment: {
            title_in_email: {
                fr: "un diner",
                en: "a dinner"
            },
            label: "dinner"
        },
        address: {
            address_in_template: {
                fr: "au bureau",
                en: "at the office"
            }
        },
        expectedResults: {
            en: "Perfect. Invites sent for a dinner at the office:\nThursday, January 1, 2015 12:00 PM.",
            fr: "Parfait, invitations envoyées pour un diner au bureau :\nJeudi 1 janvier 2015 à 12h00."
        }
    },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: "2015-01-01T12:00:00",
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a skype"
                },
                label: "skype"
            },
            expectedResults: {
                en: "Perfect. Invites sent for a skype:\nThursday, January 1, 2015 12:00 PM (Timezone: Europe/Paris).",
                fr: "Parfait, invitations envoyées pour un skype :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)."
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: "2015-01-01T12:00:00",
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris", "America/Los_Angeles"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner"
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. Invites sent for a dinner at the office:\nThursday, January 1, 2015 12:00 PM (Timezone: Europe/Paris)\nThursday, January 1, 2015 3:00 AM (Timezone: America/Los Angeles).",
                fr: "Parfait, invitations envoyées pour un diner au bureau :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)\nJeudi 1 janvier 2015 à 3h00 (Fuseau horaire : America/Los Angeles)."
            }
        }],


    [{
        action: "cancel_event",
        client: "Nicolas Marlier",
        currentEventData: {
            start: {
                dateTime: "2015-01-01T08:00:00"
            }
        },
        timezoneId: "Europe/Paris",
        defaultTimezoneId: "Europe/Paris",
        clientAgreement: true,
        attendeesAreNoticed: false,
        expectedResults: {
            en: "Very sorry for the setback but unfortunately, Nicolas Marlier won't be able to ensure the meeting with you on Thursday, January 1, 2015 8:00 AM.",
            fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous avec vous Jeudi 1 janvier 2015 à 8h00."
        }
    },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: "2015-01-01T08:00:00"
                }
            },
            timezoneId: "America/Los_Angeles",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            expectedResults: {
                en: "Very sorry for the setback but unfortunately, Nicolas Marlier won't be able to ensure the meeting with you on Wednesday, December 31, 2014 11:00 PM (Timezone: America/Los Angeles).",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous avec vous Mercredi 31 décembre 2014 à 23h00 (Fuseau horaire : America/Los Angeles)."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: "2015-01-01T08:00:00"
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner"
                },
                label: "dinner"
            },
            expectedResults: {
                en: "Very sorry for the setback but unfortunately, Nicolas Marlier won't be able to ensure the dinner with you on Thursday, January 1, 2015 8:00 AM.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le diner avec vous Jeudi 1 janvier 2015 à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: "2015-01-01T08:00:00"
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: true,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner"
                },
                label: "dinner"
            },
            expectedResults: {
                en: "I canceled the dinner scheduled on Thursday, January 1, 2015 8:00 AM.",
                fr: "J'ai annulé le diner prévu Jeudi 1 janvier 2015 à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: "2015-01-01T08:00:00"
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: false,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner"
                },
                label: "dinner"
            },
            expectedResults: {
                en: "Do I have your agreement to cancel the dinner scheduled on Thursday, January 1, 2015 8:00 AM?",
                fr: "Ai-je votre approbation pour annuler le diner prévu Jeudi 1 janvier 2015 à 8h00 ?"
            }
        }],


    [{
        action: "create_event",
        createdEvents: [
            {
                title: "EVENT #1",
                start: "2015-01-01T12:00:00",
                end: "2015-01-01T14:00:00",
                allDay: false,
                timezoneId: "Europe/Paris"
            },
            {

                title: "EVENT #2",
                start: "2015-01-06T12:00:00",
                end: "2015-01-09T14:00:00",
                allDay: false,
                timezoneId: "America/Los_Angeles"

            }
        ],
        updatedEvents: [
            {

                title: "EVENT #3",
                start: "2015-01-02",
                end: "2015-01-03",
                allDay: true,
                timezoneId: "Europe/Paris"

            }
        ],
        deletedEvents: [
            {
                title: "EVENT #4",
                start: "2015-01-04",
                end: "2015-01-06",
                allDay: true,
                timezoneId: "Europe/Paris"
            }
        ],
        expectedResults: {
            en: "I added to your calendar:\n- EVENT #1 : Thursday 1 January 2015, 12:00 - 14:00 (Europe/Paris)\n- EVENT #2 : Tuesday 6 January 2015 03:00 - Friday 9 January 2015 05:00 (America/Los Angeles)\n\nI updated in your calendar:\n- EVENT #3 : Friday 2 January 2015\n\nI deleted from your calendar:\n- EVENT #4 : Sunday 4 January 2015 - Monday 5 January 2015\n\n",
            fr: "J'ai ajouté à votre calendrier :\n- EVENT #1 : jeudi 1 janvier 2015, 12:00 - 14:00 (Europe/Paris)\n- EVENT #2 : mardi 6 janvier 2015 03:00 - vendredi 9 janvier 2015 05:00 (America/Los Angeles)\n\nJ'ai mis à jour dans votre calendrier :\n- EVENT #3 : vendredi 2 janvier 2015\n\nJ'ai supprimé de votre calendrier :\n- EVENT #4 : dimanche 4 janvier 2015 - lundi 5 janvier 2015\n\n"
        }
    }],
    [{
        action: "client_agreement",
        dateTimesToCheck: ["2015-01-01T12:00:00"],
        defaultTimezoneId: "Europe/Paris",
        timezoneId: "Europe/Paris",
        isPostpone: false,
        appointment: {
            title_in_email: {
                fr: "un skype",
                en: "a skype"
            },
            label: "skype"
        },
        expectedResults: {
            en: "You are not available for a skype at this date:\n- Thursday, January 1, 2015 12:00 PM\n\nDo you want me to suggest other availabilities?",
            fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- jeudi 1 janvier 2015 à 12h00\n\nVoulez-vous que propose d'autres disponibilités ?"
        }
    },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00"],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: true,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a skype"
                },
                label: "skype"
            },
            expectedResults: {
                en: "You are not available for a skype at this date:\n- Thursday, January 1, 2015 12:00 PM\n\nDo you want me to suggest new availabilities to postpone the appointment?",
                fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- jeudi 1 janvier 2015 à 12h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00", "2015-02-02T13:00:00"],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: true,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a skype"
                },
                label: "skype"
            },
            expectedResults: {
                en: "You are not available for a skype at any of those dates:\n- Thursday, January 1, 2015 12:00 PM\n- Monday, February 2, 2015 1:00 PM\n\nDo you want me to suggest new availabilities to postpone the appointment?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- jeudi 1 janvier 2015 à 12h00\n- lundi 2 février 2015 à 13h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00", "2015-02-02T13:00:00"],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: false,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a skype"
                },
                label: "skype"
            },
            expectedResults: {
                en: "You are not available for a skype at any of those dates:\n- Thursday, January 1, 2015 12:00 PM\n- Monday, February 2, 2015 1:00 PM\n\nDo you want me to suggest other availabilities?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- jeudi 1 janvier 2015 à 12h00\n- lundi 2 février 2015 à 13h00\n\nVoulez-vous que propose d'autres disponibilités ?"
            }
        }],
    [
        {
            action: "cancel_postpone_multiple_events",
            kind: "cancel",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [],
            selectedEventsNotToCancel: [
                {
                    title: "Event #4",
                    start: "2015-01-03T15:00:00"
                }
            ],
            expectedResults: {
                en: "It's noted. But I don't have any email address for this event:\n - Event #4 (Saturday, January 3, 2015 3:00 PM)\n\nPlease provide attendees emails if you want me to take care of it.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour cet évènement :\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        },
        {
            action: "cancel_postpone_multiple_events",
            kind: "cancel",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [],
            selectedEventsNotToCancel: [
                {
                    title: "Event #3",
                    start: "2015-01-02T16:00:00"
                },
                {
                    title: "Event #4",
                    start: "2015-01-03T15:00:00"
                }
            ],
            expectedResults: {
                en: "It's noted. But I don't have any email address for these events:\n - Event #3 (Friday, January 2, 2015 4:00 PM)\n - Event #4 (Saturday, January 3, 2015 3:00 PM)\n\nPlease provide attendees emails if you want me to take care of them.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        },
        {
            action: "cancel_postpone_multiple_events",
            kind: "cancel",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [
                {
                    title: "Event #1",
                    start: "2015-01-01T12:00:00"
                }
            ],
            selectedEventsNotToCancel: [],
            expectedResults: {
                en: "It's noted. I am going to cancel the event:\n - Event #1 (Thursday, January 1, 2015 12:00 PM)\n",
                fr: "C'est bien noté. Je vais annuler l'évènement :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n"
            }
        },
        {
            action: "cancel_postpone_multiple_events",
            kind: "cancel",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [
                {
                    title: "Event #1",
                    start: "2015-01-01T12:00:00"
                },
                {
                    title: "Event #2",
                    start: "2015-01-01T14:00:00"
                }
            ],
            selectedEventsNotToCancel: [],
            expectedResults: {
                en: "It's noted. I am going to cancel these events:\n - Event #1 (Thursday, January 1, 2015 12:00 PM)\n - Event #2 (Thursday, January 1, 2015 2:00 PM)\n",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n"
            }
        },
        {
            action: "cancel_postpone_multiple_events",
            kind: "cancel",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [
                {
                    title: "Event #1",
                    start: "2015-01-01T12:00:00"
                },
                {
                    title: "Event #2",
                    start: "2015-01-01T14:00:00"
                }
            ],
            selectedEventsNotToCancel: [
                {
                    title: "Event #3",
                    start: "2015-01-02T16:00:00"
                }
            ],
            expectedResults: {
                en: "It's noted. I am going to cancel these events:\n - Event #1 (Thursday, January 1, 2015 12:00 PM)\n - Event #2 (Thursday, January 1, 2015 2:00 PM)\n\nBut I don't have any email address for this event:\n - Event #3 (Friday, January 2, 2015 4:00 PM)\n\nPlease provide attendees emails if you want me to take care of it.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour cet évènement :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        },
        {
            action: "cancel_postpone_multiple_events",
            kind: "cancel",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [
                {
                    title: "Event #1",
                    start: "2015-01-01T12:00:00"
                },
                {
                    title: "Event #2",
                    start: "2015-01-01T14:00:00"
                }
            ],
            selectedEventsNotToCancel: [
                {
                    title: "Event #3",
                    start: "2015-01-02T16:00:00"
                },
                {
                    title: "Event #4",
                    start: "2015-01-03T15:00:00"
                }
            ],
            expectedResults: {
                en: "It's noted. I am going to cancel these events:\n - Event #1 (Thursday, January 1, 2015 12:00 PM)\n - Event #2 (Thursday, January 1, 2015 2:00 PM)\n\nBut I don't have any email address for these events:\n - Event #3 (Friday, January 2, 2015 4:00 PM)\n - Event #4 (Saturday, January 3, 2015 3:00 PM)\n\nPlease provide attendees emails if you want me to take care of them.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        },
        {
            action: "cancel_postpone_multiple_events",
            kind: "postpone",
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            selectedEventsToCancel: [
                {
                    title: "Event #1",
                    start: "2015-01-01T12:00:00"
                },
                {
                    title: "Event #2",
                    start: "2015-01-01T14:00:00"
                }
            ],
            selectedEventsNotToCancel: [
                {
                    title: "Event #3",
                    start: "2015-01-02T16:00:00"
                },
                {
                    title: "Event #4",
                    start: "2015-01-03T15:00:00"
                }
            ],
            expectedResults: {
                en: "It's noted. I am going to postpone these events:\n - Event #1 (Thursday, January 1, 2015 12:00 PM)\n - Event #2 (Thursday, January 1, 2015 2:00 PM)\n\nBut I don't have any email address for these events:\n - Event #3 (Friday, January 2, 2015 4:00 PM)\n - Event #4 (Saturday, January 3, 2015 3:00 PM)\n\nPlease provide attendees emails if you want me to take care of them.",
                fr: "C'est bien noté. Je vais reporter les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        }],


        [{
            action: "send_confirmation",
            expectedResults: {
                en: "Very well, it's noted.",
                fr: "Très bien, c'est noté."
            }
        }]
];