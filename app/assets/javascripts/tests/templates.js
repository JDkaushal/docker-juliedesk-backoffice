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
        timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", moment().hour(12).minute(0).second(0), "2015-01-06T12:00:00"],
        timezoneId: "Europe/Paris",
        defaultTimezoneId: "Europe/Paris",
        appointment: {
            title_in_email: {
                fr: "un rendez-vous",
                en: "an appointment"
            },
            appointment_kind_hash: {
                is_virtual: false
            }
        },
        address: {
            address_in_template: {
                fr: "au bureau",
                en: "at the office"
            }
        },
        assistedAttendees: [],
        unassistedAttendees: ['singleAttendee'],
        expectedResults: {
            en: "Nicolas Marlier is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
            fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", moment().hour(12).minute(0).second(0).add(1, 'd'), "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            }
        },
        {
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
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            },
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
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            },
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: "9 rue Dareau",
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment:\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous :\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: "9 rue Dareau",
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment:\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous :\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: "9 rue Dareau",
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment:\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous :\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n(Timezone: America/Los Angeles)\n - Thursday 1 January 2015 at 3:00am\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n(Fuseau horaire : America/Los Angeles)\n - Jeudi 1 janvier 2015 à 3h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "America/Los_Angeles",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n(Timezone: America/Los Angeles)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00am\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n(Fuseau horaire : America/Los Angeles)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 3h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "America/Los_Angeles",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for an appointment at the office:\n(Timezone: America/Los Angeles)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00am\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous au bureau :\n(Fuseau horaire : America/Los Angeles)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 3h00\n\nCela vous conviendrait-il ?"
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
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for a Skype appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un skype :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for a Skype appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un skype :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas Marlier is available for a Skype appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Nicolas Marlier serait disponible pour un skype :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        }],

    [{
        action: "suggest_dates",
        client_agreement: true,
        client: "Nicolas",
        other_clients: ["Julien", "Guillaume"],
        timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
        timezoneId: "Europe/Paris",
        defaultTimezoneId: "Europe/Paris",
        appointment: {
            title_in_email: {
                fr: "un rendez-vous",
                en: "an appointment"
            },
            appointment_kind_hash: {
                is_virtual: false
            }
        },
        address: {
            address_in_template: {
                fr: "au bureau",
                en: "at the office"
            }
        },
        assistedAttendees: [],
        unassistedAttendees: ['singleAttendee'],
        expectedResults: {
            en: "Julien, Guillaume and Nicolas are available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
            fr: "Julien, Guillaume et Nicolas seraient disponibles pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: ["Julien", "Guillaume"],
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0), moment().hour(14).minute(0).second(0), "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Julien, Guillaume and Nicolas are available for an appointment at the office:\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Julien, Guillaume et Nicolas seraient disponibles pour un rendez-vous au bureau :\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: ["Julien", "Guillaume"],
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd'), moment().hour(14).minute(0).second(0).add(1, 'd'), "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Julien, Guillaume and Nicolas are available for an appointment at the office:\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Julien, Guillaume et Nicolas seraient disponibles pour un rendez-vous au bureau :\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John"],
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", moment().hour(12).minute(0).second(0), "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John"],
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", moment().hour(12).minute(0).second(0).add(1, 'd'), "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John"],
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: [],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nJohn, Jack, which time works best for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nJohn, Jack, quel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: ['Pierre'],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time would work best?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: ['Pierre'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for Pierre?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire conviendrait le mieux à Pierre ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", "2015-01-06T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: ['Pierre', 'Jean'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tuesday 6 January 2015 at 12:00pm\n\nWhich time works best for Pierre, Jean?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Mardi 6 janvier 2015 à 12h00\n\nQuel horaire conviendrait le mieux à Pierre, Jean ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: [],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nJohn, Jack, which time works best for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nJohn, Jack, quel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00", "2015-01-01T14:00:00", "2015-01-04T12:00:00", moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: [],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm or 2:00pm\n - Sunday 4 January 2015 at 12:00pm\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nJohn, Jack, which time works best for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00 ou 14h00\n - Dimanche 4 janvier 2015 à 12h00\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nJohn, Jack, quel horaire vous conviendrait le mieux ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: ["2015-01-01T12:00:00"],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: [],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Thursday 1 January 2015 at 12:00pm\n\nJohn, Jack, would that work for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Jeudi 1 janvier 2015 à 12h00\n\nJohn, Jack, cela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: [],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nJohn, Jack, would that work for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nJohn, Jack, cela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas",
            other_clients: [],
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous",
                    en: "an appointment"
                },
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            attendees: ["John", "Jack"],
            assistedAttendees: [],
            unassistedAttendees: ['John', 'Jack'],
            expectedResults: {
                en: "Nicolas is available for an appointment at the office:\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nJohn, Jack, would that work for you?",
                fr: "Nicolas serait disponible pour un rendez-vous au bureau :\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nJohn, Jack, cela vous conviendrait-il ?"
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
                en: "a telephone appointment"
            },
            label: "call",
            appointment_kind_hash: {
                is_virtual: true
            }
        },
        assistedAttendees: [],
        unassistedAttendees: ['singleAttendee'],
        expectedResults: {
            en: "Sorry, Nicolas Marlier is no longer available at these times, but would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
            fr: "Désolée, Nicolas Marlier n'est plus disponible à ces horaires, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "suggested_multiple",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at these times, but would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à ces horaires, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "suggested_multiple",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at these times, but would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à ces horaires, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry none of these timeslots are open, but Nicolas Marlier would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, aucun de ces horaires ne convient, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "not_suggested_multiple",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry none of these timeslots are open, but Nicolas Marlier would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, aucun de ces horaires ne convient, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "not_suggested_multiple",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry none of these timeslots are open, but Nicolas Marlier would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, aucun de ces horaires ne convient, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at this time, but would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "suggested_single",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at this time, but would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "suggested_single",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at this time, but would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry this timeslot is not open, but Nicolas Marlier would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, cet horaire ne convient pas, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "not_suggested_single",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry this timeslot is not open, but Nicolas Marlier would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, cet horaire ne convient pas, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            noDateFits: "not_suggested_single",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry this timeslot is not open, but Nicolas Marlier would be available for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, cet horaire ne convient pas, mais Nicolas Marlier serait disponible pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                en: "a telephone appointment"
            },
            label: "call",
            appointment_kind_hash: {
                is_virtual: true
            }
        },
        assistedAttendees: [],
        unassistedAttendees: ['singleAttendee'],
        expectedResults: {
            en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you on Thursday 1 January 2015 8:00am.\n\nHere are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
            fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous jeudi 1 janvier 2015 à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0)
                }
            },
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.\n\nHere are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0).add(1, 'd')
                }
            },
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.\n\nHere are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you on Thursday 1 January 2015 8:00am.\n\nHere are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous jeudi 1 janvier 2015 à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0)
                }
            },
            attendeesAreNoticed: false,
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.\n\nHere are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0).add(1, 'd')
                }
            },
            attendeesAreNoticed: false,
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.\n\nHere are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00.\n\nVoici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
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
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at this time, but here are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Thursday 1 January 2015 at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais voici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Jeudi 1 janvier 2015 à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            attendeesAreNoticed: true,
            noDateFits: "suggested_single",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0)],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at this time, but here are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais voici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        },
        {
            action: "suggest_dates",
            client_agreement: true,
            client: "Nicolas Marlier",
            isPostpone: true,
            attendeesAreNoticed: true,
            noDateFits: "suggested_single",
            timeSlotsToSuggest: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            appointment: {
                title_in_email: {
                    fr: "un rendez-vous téléphonique",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Sorry, Nicolas Marlier is no longer available at this time, but here are some new availabilities for a telephone appointment:\n(Timezone: Europe/Paris)\n - Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould that work for you?",
                fr: "Désolée, Nicolas Marlier n'est plus disponible à cet horaire, mais voici de nouvelles disponibilités pour un rendez-vous téléphonique :\n(Fuseau horaire : Europe/Paris)\n - Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nCela vous conviendrait-il ?"
            }
        }],


    [{
        action: "suggest_dates",
        client_agreement: false,
        isPostpone: false,
        expectedResults: {
            en: "Would you like me to suggest some other availabilities?",
            fr: "Souhaitez-vous que je propose des disponibilités ?"
        }
    },
        {
            action: "suggest_dates",
            client_agreement: false,
            isPostpone: true,
            expectedResults: {
                en: "Would you like me to suggest other availabilities? I have cancelled the original event in the meantime.",
                fr: "Souhaitez-vous que je propose de nouvelles disponibilités ? J'ai annulé l'évènement en attendant."
            }
        }
    ],
    [{
        action: "suggest_dates",
        noDateFits: 'external_invitation',
        client_agreement: true,
        declining_previously_suggested_date: true,
        client: 'Fname Lname',
        invitation_start_date: "2016-04-04T14:15:00+02:00",
        timezoneId: "Europe/Paris",
        locale: 'en',
        timeSlotsToSuggest: ["2016-04-04T09:45:00+02:00", "2016-04-04T11:15:00+02:00", "2016-04-04T13:00:00+02:00"],
        expectedResults: {
            en: "Sorry but Fname Lname is no longer available Monday 4 April 2016 at 2:15pm.\n\nMay I suggest you one of the following time slot :\n(Timezone: Europe/Paris)\n - Monday 4 April 2016 at 9:45am, 11:15am or 1:00pm\n\nLet me know what would you prefer.",
            fr: "Désolée mais Fname Lname n'est finalement pas disponible lundi 4 avril 2016 à 14h15.\n\nPuis-je vous proposer l'une des dates suivantes :\n(Fuseau horaire : Europe/Paris)\n - Lundi 4 avril 2016 à 9h45, 11h15 ou 13h00\n\nMerci de m'indiquer votre préférence."
        }
    },
        {
            action: "suggest_dates",
            noDateFits: 'external_invitation',
            client_agreement: true,
            declining_previously_suggested_date: false,
            client: 'Fname Lname',
            invitation_start_date: "2016-04-04T14:15:00+02:00",
            timezoneId: "Europe/Paris",
            locale: 'en',
            timeSlotsToSuggest: ["2016-04-04T09:45:00+02:00", "2016-04-04T11:15:00+02:00", "2016-04-04T13:00:00+02:00"],
            expectedResults: {
                en: "Unfortunately Fname Lname is not available Monday 4 April 2016 at 2:15pm.\n\nMay I suggest you one of the following time slot :\n(Timezone: Europe/Paris)\n - Monday 4 April 2016 at 9:45am, 11:15am or 1:00pm\n\nLet me know what would you prefer.",
                fr: "Malheureusement Fname Lname n'est pas disponible lundi 4 avril 2016 à 14h15.\n\nPuis-je vous proposer l'une des dates suivantes :\n(Fuseau horaire : Europe/Paris)\n - Lundi 4 avril 2016 à 9h45, 11h15 ou 13h00\n\nMerci de m'indiquer votre préférence."
            }
        }

    ],
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
            label: "dinner",
            appointment_kind_hash: {
                is_virtual: false
            }
        },
        address: {
            address_in_template: {
                fr: "au bureau",
                en: "at the office"
            }
        },
        expectedResults: {
            en: "Perfect. I've sent invites for a dinner at the office:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)",
            fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)"
        }
        },{
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: "2015-01-01T12:00:00",
            suggestedDates: ["2015-01-01T12:00:00", "2015-01-02T12:00:00", "2015-01-03T12:00:00"],
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)",
                fr: "Parfait. J'ai envoyé les invitations pour un diner au bureau :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: "2015-01-01T12:00:00",
            suggestedDates: ["2015-01-05T12:00:00", "2015-01-02T12:00:00", "2015-01-03T12:00:00"],
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nToday" + ", " + window.helpers.capitalize(moment().tz("Europe/Paris").hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().tz("Europe/Paris").hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
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
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a Skype appointment:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un skype :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a Skype appointment:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un skype :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a Skype appointment:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un skype :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
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
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "an office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a Skype appointment:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un skype :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "an office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a Skype appointment:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un skype :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "an office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a Skype appointment:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un skype :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
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
                    fr: "un meeting",
                    en: "a meeting"
                },
                label: "meeting",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: "9 rue Dareau",
            expectedResults: {
                en: "Perfect. I've sent invites for a meeting:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)\nLocation: 9 rue Dareau",
                fr: "Très bien. J'ai envoyé les invitations pour un meeting :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)\nLieu : 9 rue Dareau"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un meeting",
                    en: "a meeting"
                },
                label: "meeting",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: "9 rue Dareau",
            expectedResults: {
                en: "Perfect. I've sent invites for a meeting:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\nLocation: 9 rue Dareau",
                fr: "Très bien. J'ai envoyé les invitations pour un meeting :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\nLieu : 9 rue Dareau"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un meeting",
                    en: "a meeting"
                },
                label: "meeting",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: "9 rue Dareau",
            expectedResults: {
                en: "Perfect. I've sent invites for a meeting:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\nLocation: 9 rue Dareau",
                fr: "Très bien. J'ai envoyé les invitations pour un meeting :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\nLieu : 9 rue Dareau"
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
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)\nThursday 1 January 2015 at 3:00am (Timezone: America/Los Angeles)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)\nJeudi 1 janvier 2015 à 3h00 (Fuseau horaire : America/Los Angeles)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris", "America/Los_Angeles"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00am (Timezone: America/Los Angeles)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 3h00 (Fuseau horaire : America/Los Angeles)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris", "America/Los_Angeles"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address_in_template: {
                    fr: "au bureau",
                    en: "at the office"
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner at the office:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00am (Timezone: America/Los Angeles)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner au bureau :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 3h00 (Fuseau horaire : America/Los Angeles)"
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
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "9 rue Dareau",
                address_in_template: {
                    fr: "",
                    en: ""
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)\nLocation: 9 rue Dareau",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)\nLieu : 9 rue Dareau"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "9 rue Dareau",
                address_in_template: {
                    fr: "",
                    en: ""
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\nLocation: 9 rue Dareau",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\nLieu : 9 rue Dareau"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "9 rue Dareau",
                address_in_template: {
                    fr: "",
                    en: ""
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\nLocation: 9 rue Dareau",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\nLieu : 9 rue Dareau"
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
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_client"
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location if you want me to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse si vous souhaitez que je l'ajoute à l'évènement ?"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_client"
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location if you want me to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse si vous souhaitez que je l'ajoute à l'évènement ?"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_client"
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location if you want me to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse si vous souhaitez que je l'ajoute à l'évènement ?"
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
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_interlocuter"
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse pour que je l'ajoute à l'évènement ?"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_interlocuter"
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse pour que je l'ajoute à l'évènement ?"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_interlocuter"
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse pour que je l'ajoute à l'évènement ?"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_interlocuter"
            },
            attendeesWithMissingInfos: [
                {guid: 1},
                {guid: 2}
            ],
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)\n\nPlease let me know the location to add it to the event.",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)\n\nPourriez-vous m'indiquer l'adresse pour que je l'ajoute à l'évènement ?"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un diner",
                    en: "a dinner"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            address: {
                address: "",
                address_in_template: {
                    fr: "",
                    en: ""
                },
                type: "ask_interlocuter"
            },
            attendeesWithMissingInfos: [
                {guid: 1},
                {guid: 2},
                {guid: 3}
            ],
            expectedResults: {
                en: "Perfect. I've sent invites for a dinner:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un diner :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
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
                    fr: "un call",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            address: {
                address: "890890809",
                address_in_template: {
                    fr: "",
                    en: ""
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a telephone appointment:\nThursday 1 January 2015 at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un call :\nJeudi 1 janvier 2015 à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un call",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            address: {
                address: "890890809",
                address_in_template: {
                    fr: "",
                    en: ""
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a telephone appointment:\nToday" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un call :\nAujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
            }
        },
        {
            action: "invites_sent",
            client_agreement: true,
            client: "Nicolas Marlier",
            timeSlotToCreate: moment().hour(12).minute(0).second(0).add(1, 'd'),
            defaultTimezoneId: "Europe/Paris",
            allTimezoneIds: ["Europe/Paris"],
            appointment: {
                title_in_email: {
                    fr: "un call",
                    en: "a telephone appointment"
                },
                label: "call",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            address: {
                address: "890890809",
                address_in_template: {
                    fr: "",
                    en: ""
                }
            },
            expectedResults: {
                en: "Perfect. I've sent invites for a telephone appointment:\nTomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm (Timezone: Europe/Paris)",
                fr: "Très bien. J'ai envoyé les invitations pour un call :\nDemain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00 (Fuseau horaire : Europe/Paris)"
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
            en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you on Thursday 1 January 2015 8:00am.",
            fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous jeudi 1 janvier 2015 à 8h00."
        }
    },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0)
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0).add(1, 'd')
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous demain" + ", "+ window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00."
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
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you on Wednesday 31 December 2014 11:00pm (Timezone: America/Los Angeles).",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous mercredi 31 décembre 2014 à 23h00 (Fuseau horaire : America/Los Angeles)."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().add(1, "d").hour(8).minute(0).second(0)
                }
            },
            timezoneId: "America/Los_Angeles",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 11:00pm (Timezone: America/Los Angeles).",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 23h00 (Fuseau horaire : America/Los Angeles)."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().add(2, "d").hour(8).minute(0).second(0)
                }
            },
            timezoneId: "America/Los_Angeles",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the meeting with you tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 11:00pm (Timezone: America/Los Angeles).",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le rendez-vous demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 23h00 (Fuseau horaire : America/Los Angeles)."
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
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the dinner appointment with you on Thursday 1 January 2015 8:00am.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le diner jeudi 1 janvier 2015 à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0)
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the dinner appointment with you today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le diner aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0).add(1, 'd')
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: false,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "Very sorry for the inconvenience, but something has come up and Nicolas Marlier won't be able to make the dinner appointment with you tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.",
                fr: "Désolée, mais suite à un contretemps, Nicolas Marlier ne pourra malheureusement pas assurer le diner demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00."
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
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "I have cancelled the dinner appointment scheduled for Thursday 1 January 2015 8:00am.",
                fr: "J'ai annulé le diner prévu jeudi 1 janvier 2015 à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0)
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: true,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "I have cancelled the dinner appointment scheduled today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.",
                fr: "J'ai annulé le diner prévu aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00."
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0).add(1, 'd')
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: true,
            attendeesAreNoticed: true,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "I have cancelled the dinner appointment scheduled tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am.",
                fr: "J'ai annulé le diner prévu demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00."
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
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "Should I cancel the dinner appointment scheduled for Thursday 1 January 2015 8:00am?",
                fr: "Ai-je votre approbation pour annuler le diner prévu jeudi 1 janvier 2015 à 8h00 ?"
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0)
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: false,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "Should I cancel the dinner appointment scheduled today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am?",
                fr: "Ai-je votre approbation pour annuler le diner prévu aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00 ?"
            }
        },
        {
            action: "cancel_event",
            client: "Nicolas Marlier",
            currentEventData: {
                start: {
                    dateTime: moment().hour(8).minute(0).second(0).add(1, 'd')
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            clientAgreement: false,
            appointment: {
                designation_in_email: {
                    fr: "le diner",
                    en: "the dinner appointment"
                },
                label: "dinner",
                appointment_kind_hash: {
                    is_virtual: false
                }
            },
            expectedResults: {
                en: "Should I cancel the dinner appointment scheduled tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 8:00am?",
                fr: "Ai-je votre approbation pour annuler le diner prévu demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 8h00 ?"
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
            en: "I have added the following to your calendar:\n- EVENT #1-: Thursday 1 January 2015, 12:00pm - 2:00pm (Europe/Paris)\n- EVENT #2-: Tuesday 6 January 2015 at 3:00am - Friday 9 January 2015 at 5:00am (America/Los Angeles)\n\nI have updated the following in your calendar:\n- EVENT #3-: Friday 2 January 2015\n\nI have deleted the following from your calendar:\n- EVENT #4-: Sunday 4 January 2015 - Monday 5 January 2015\n\n",
            fr: "J'ai ajouté à votre calendrier :\n- EVENT #1 : jeudi, 1 janvier 2015, 12h00 - 14h00 (Europe/Paris)\n- EVENT #2 : mardi, 6 janvier 2015 à 3h00 - vendredi, 9 janvier 2015 à 5h00 (America/Los Angeles)\n\nJ'ai mis à jour dans votre calendrier :\n- EVENT #3 : vendredi, 2 janvier 2015\n\nJ'ai supprimé de votre calendrier :\n- EVENT #4 : dimanche, 4 janvier 2015 - lundi, 5 janvier 2015\n\n"
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
                start: moment().hour(23).minute(0).second(0),
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
            en: "I have added the following to your calendar:\n- EVENT #1-: Thursday 1 January 2015, 12:00pm - 2:00pm (Europe/Paris)\n- EVENT #2-: today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.simplified_date_format"))) + " at 2:00pm - Friday 9 January 2015 at 5:00am (America/Los Angeles)\n\nI have updated the following in your calendar:\n- EVENT #3-: Friday 2 January 2015\n\nI have deleted the following from your calendar:\n- EVENT #4-: Sunday 4 January 2015 - Monday 5 January 2015\n\n",
            fr: "J'ai ajouté à votre calendrier :\n- EVENT #1 : jeudi, 1 janvier 2015, 12h00 - 14h00 (Europe/Paris)\n- EVENT #2 : aujourd'hui" + ", " + moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.simplified_date_format", {locale: 'fr'})) + " à 14h00 - vendredi, 9 janvier 2015 à 5h00 (America/Los Angeles)\n\nJ'ai mis à jour dans votre calendrier :\n- EVENT #3 : vendredi, 2 janvier 2015\n\nJ'ai supprimé de votre calendrier :\n- EVENT #4 : dimanche, 4 janvier 2015 - lundi, 5 janvier 2015\n\n"
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
                start: moment().hour(23).minute(0).second(0).add(1, 'd'),
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
            en: "I have added the following to your calendar:\n- EVENT #1-: Thursday 1 January 2015, 12:00pm - 2:00pm (Europe/Paris)\n- EVENT #2-: tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.simplified_date_format"))) + " at 2:00pm - Friday 9 January 2015 at 5:00am (America/Los Angeles)\n\nI have updated the following in your calendar:\n- EVENT #3-: Friday 2 January 2015\n\nI have deleted the following from your calendar:\n- EVENT #4-: Sunday 4 January 2015 - Monday 5 January 2015\n\n",
            fr: "J'ai ajouté à votre calendrier :\n- EVENT #1 : jeudi, 1 janvier 2015, 12h00 - 14h00 (Europe/Paris)\n- EVENT #2 : demain" + ", " + moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.simplified_date_format", {locale: 'fr'})) + " à 14h00 - vendredi, 9 janvier 2015 à 5h00 (America/Los Angeles)\n\nJ'ai mis à jour dans votre calendrier :\n- EVENT #3 : vendredi, 2 janvier 2015\n\nJ'ai supprimé de votre calendrier :\n- EVENT #4 : dimanche, 4 janvier 2015 - lundi, 5 janvier 2015\n\n"
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
                start: moment().hour(23).minute(0).second(0),
                end: moment().hour(24).minute(0).second(0),
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
            en: "I have added the following to your calendar:\n- EVENT #1-: Thursday 1 January 2015, 12:00pm - 2:00pm (Europe/Paris)\n- EVENT #2-: today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.simplified_date_format"))) + ", 2:00pm - 3:00pm (America/Los Angeles)\n\nI have updated the following in your calendar:\n- EVENT #3-: Friday 2 January 2015\n\nI have deleted the following from your calendar:\n- EVENT #4-: Sunday 4 January 2015 - Monday 5 January 2015\n\n",
            fr: "J'ai ajouté à votre calendrier :\n- EVENT #1 : jeudi, 1 janvier 2015, 12h00 - 14h00 (Europe/Paris)\n- EVENT #2 : aujourd'hui" + ", " + moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.simplified_date_format", {locale: 'fr'})) + ", 14h00 - 15h00 (America/Los Angeles)\n\nJ'ai mis à jour dans votre calendrier :\n- EVENT #3 : vendredi, 2 janvier 2015\n\nJ'ai supprimé de votre calendrier :\n- EVENT #4 : dimanche, 4 janvier 2015 - lundi, 5 janvier 2015\n\n"
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
                start: moment().hour(23).minute(0).second(0).add(1, 'd'),
                end: moment().hour(24).minute(0).second(0).add(1, 'd'),
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
            en: "I have added the following to your calendar:\n- EVENT #1-: Thursday 1 January 2015, 12:00pm - 2:00pm (Europe/Paris)\n- EVENT #2-: tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.simplified_date_format"))) + ", 2:00pm - 3:00pm (America/Los Angeles)\n\nI have updated the following in your calendar:\n- EVENT #3-: Friday 2 January 2015\n\nI have deleted the following from your calendar:\n- EVENT #4-: Sunday 4 January 2015 - Monday 5 January 2015\n\n",
            fr: "J'ai ajouté à votre calendrier :\n- EVENT #1 : jeudi, 1 janvier 2015, 12h00 - 14h00 (Europe/Paris)\n- EVENT #2 : demain" + ", " + moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.simplified_date_format", {locale: 'fr'})) + ", 14h00 - 15h00 (America/Los Angeles)\n\nJ'ai mis à jour dans votre calendrier :\n- EVENT #3 : vendredi, 2 janvier 2015\n\nJ'ai supprimé de votre calendrier :\n- EVENT #4 : dimanche, 4 janvier 2015 - lundi, 5 janvier 2015\n\n"
        }
    }],
    [{
        action: "client_agreement",
        dateTimesToCheck: [moment().hour(12).minute(0).second(0)],
        defaultTimezoneId: "Europe/Paris",
        timezoneId: "Europe/Paris",
        isPostpone: false,
        appointment: {
            title_in_email: {
                fr: "un skype",
                en: "a Skype appointment"
            },
            label: "skype",
            appointment_kind_hash: {
                is_virtual: true
            }
        },
        expectedResults: {
            en: "You are not available for a Skype appointment on this date:\n- Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould you like me to suggest a few other availabilities?",
            fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nVoulez-vous que je propose d'autres disponibilités ?"
        }
    }],
    [{
        action: "client_agreement",
        dateTimesToCheck: [moment().hour(12).minute(0).second(0).add(1, 'd')],
        defaultTimezoneId: "Europe/Paris",
        timezoneId: "Europe/Paris",
        isPostpone: false,
        appointment: {
            title_in_email: {
                fr: "un skype",
                en: "a Skype appointment"
            },
            label: "skype",
            appointment_kind_hash: {
                is_virtual: true
            }
        },
        expectedResults: {
            en: "You are not available for a Skype appointment on this date:\n- Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould you like me to suggest a few other availabilities?",
            fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nVoulez-vous que je propose d'autres disponibilités ?"
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
                en: "a Skype appointment"
            },
            label: "skype",
            appointment_kind_hash: {
                is_virtual: true
            }
        },
        expectedResults: {
            en: "You are not available for a Skype appointment on this date:\n- Thursday 1 January 2015 at 12:00pm\n\nWould you like me to suggest a few other availabilities?",
            fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- Jeudi 1 janvier 2015 à 12h00\n\nVoulez-vous que je propose d'autres disponibilités ?"
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
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on this date:\n- Thursday 1 January 2015 at 12:00pm\n\nWould you like me to suggest other availabilities to reschedule the appointment?",
                fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- Jeudi 1 janvier 2015 à 12h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: [moment().hour(12).minute(0).second(0)],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: true,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on this date:\n- Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould you like me to suggest other availabilities to reschedule the appointment?",
                fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: [moment().hour(12).minute(0).second(0).add(1, 'd')],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: true,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on this date:\n- Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm\n\nWould you like me to suggest other availabilities to reschedule the appointment?",
                fr: "Vous n'êtes pas disponible pour un skype à cette date :\n- Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
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
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on any of those dates:\n- Thursday 1 January 2015 at 12:00pm\n- Monday 2 February 2015 at 1:00pm\n\nWould you like me to suggest other availabilities to reschedule the appointment?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- Jeudi 1 janvier 2015 à 12h00\n- Lundi 2 février 2015 à 13h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00", moment().hour(13).minute(0).second(0)],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: true,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on any of those dates:\n- Thursday 1 January 2015 at 12:00pm\n- Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'})))  + " at 1:00pm\n\nWould you like me to suggest other availabilities to reschedule the appointment?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- Jeudi 1 janvier 2015 à 12h00\n- Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 13h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00", moment().hour(13).minute(0).second(0).add(1, 'd')],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: true,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on any of those dates:\n- Thursday 1 January 2015 at 12:00pm\n- Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 1:00pm\n\nWould you like me to suggest other availabilities to reschedule the appointment?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- Jeudi 1 janvier 2015 à 12h00\n- Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 13h00\n\nVoulez-vous que je propose d'autres disponibilités pour reporter l'évènement ?"
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
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on any of those dates:\n- Thursday 1 January 2015 at 12:00pm\n- Monday 2 February 2015 at 1:00pm\n\nWould you like me to suggest a few other availabilities?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- Jeudi 1 janvier 2015 à 12h00\n- Lundi 2 février 2015 à 13h00\n\nVoulez-vous que je propose d'autres disponibilités ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00", moment().hour(13).minute(0).second(0)],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: false,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on any of those dates:\n- Thursday 1 January 2015 at 12:00pm\n- Today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 1:00pm\n\nWould you like me to suggest a few other availabilities?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- Jeudi 1 janvier 2015 à 12h00\n- Aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 13h00\n\nVoulez-vous que je propose d'autres disponibilités ?"
            }
        },
        {
            action: "client_agreement",
            dateTimesToCheck: ["2015-01-01T12:00:00", moment().hour(13).minute(0).second(0).add(1, 'd')],
            defaultTimezoneId: "Europe/Paris",
            timezoneId: "Europe/Paris",
            isPostpone: false,
            appointment: {
                title_in_email: {
                    fr: "un skype",
                    en: "a Skype appointment"
                },
                label: "skype",
                appointment_kind_hash: {
                    is_virtual: true
                }
            },
            expectedResults: {
                en: "You are not available for a Skype appointment on any of those dates:\n- Thursday 1 January 2015 at 12:00pm\n- Tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 1:00pm\n\nWould you like me to suggest a few other availabilities?",
                fr: "Vous n'êtes disponible pour un skype à aucune de ces dates :\n- Jeudi 1 janvier 2015 à 12h00\n- Demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 13h00\n\nVoulez-vous que je propose d'autres disponibilités ?"
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
                en: "Duly noted. But I don't have the email addresses for this event:\n - Event #4 (Saturday 3 January 2015 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of it.",
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
                    title: "Event #4",
                    start: moment().hour(15).minute(0).second(0)
                }
            ],
            expectedResults: {
                en: "Duly noted. But I don't have the email addresses for this event:\n - Event #4 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of it.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour cet évènement :\n - Event #4 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    title: "Event #4",
                    start: moment().hour(15).minute(0).second(0).add(1, 'd')
                }
            ],
            expectedResults: {
                en: "Duly noted. But I don't have the email addresses for this event:\n - Event #4 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of it.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour cet évènement :\n - Event #4 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                en: "Duly noted. But I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (Saturday 3 January 2015 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(15).minute(0).second(0)
                }
            ],
            expectedResults: {
                en: "Duly noted. But I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(15).minute(0).second(0).add(1, 'd')
                }
            ],
            expectedResults: {
                en: "Duly noted. But I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. En revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                en: "Duly noted. I will cancel the event:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n",
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
                    start: moment().hour(12).minute(0).second(0)
                }
            ],
            selectedEventsNotToCancel: [],
            expectedResults: {
                en: "Duly noted. I will cancel the event:\n - Event #1 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm)\n",
                fr: "C'est bien noté. Je vais annuler l'évènement :\n - Event #1 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00)\n"
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
                    start: moment().hour(12).minute(0).second(0).add(1, 'd')
                }
            ],
            selectedEventsNotToCancel: [],
            expectedResults: {
                en: "Duly noted. I will cancel the event:\n - Event #1 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 12:00pm)\n",
                fr: "C'est bien noté. Je vais annuler l'évènement :\n - Event #1 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 12h00)\n"
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
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n",
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
                    start: moment().hour(14).minute(0).second(0)
                }
            ],
            selectedEventsNotToCancel: [],
            expectedResults: {
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 2:00pm)\n",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 14h00)\n"
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
                    start: moment().hour(14).minute(0).second(0).add(1, 'd')
                }
            ],
            selectedEventsNotToCancel: [],
            expectedResults: {
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 2:00pm)\n",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 14h00)\n"
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
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for this event:\n - Event #3 (Friday 2 January 2015 4:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of it.",
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
                    start: moment().hour(14).minute(0).second(0)
                }
            ],
            selectedEventsNotToCancel: [
                {
                    title: "Event #3",
                    start: "2015-01-02T16:00:00"
                }
            ],
            expectedResults: {
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 2:00pm)\n\nBut I don't have the email addresses for this event:\n - Event #3 (Friday 2 January 2015 4:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of it.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 14h00)\n\nEn revanche, je n'ai pas les contacts pour cet évènement :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(14).minute(0).second(0).add(1, 'd')
                }
            ],
            selectedEventsNotToCancel: [
                {
                    title: "Event #3",
                    start: "2015-01-02T16:00:00"
                }
            ],
            expectedResults: {
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 2:00pm)\n\nBut I don't have the email addresses for this event:\n - Event #3 (Friday 2 January 2015 4:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of it.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 14h00)\n\nEn revanche, je n'ai pas les contacts pour cet évènement :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (Saturday 3 January 2015 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(16).minute(0).second(0)
                },
                {
                    title: "Event #4",
                    start: "2015-01-03T15:00:00"
                }
            ],
            expectedResults: {
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 4:00pm)\n - Event #4 (Saturday 3 January 2015 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(16).minute(0).second(0).add(1, 'd')
                },
                {
                    title: "Event #4",
                    start: "2015-01-03T15:00:00"
                }
            ],
            expectedResults: {
                en: "Duly noted. I will cancel these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 4:00pm)\n - Event #4 (Saturday 3 January 2015 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais annuler les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                en: "Duly noted. I will reschedule these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (Saturday 3 January 2015 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais reporter les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (Samedi 3 janvier 2015 à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(15).minute(0).second(0)
                }
            ],
            expectedResults: {
                en: "Duly noted. I will reschedule these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais reporter les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(15).minute(0).second(0)
                }
            ],
            expectedResults: {
                en: "Duly noted. I will reschedule these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (today" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais reporter les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (aujourd'hui" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
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
                    start: moment().hour(15).minute(0).second(0).add(1, 'd')
                }
            ],
            expectedResults: {
                en: "Duly noted. I will reschedule these events:\n - Event #1 (Thursday 1 January 2015 at 12:00pm)\n - Event #2 (Thursday 1 January 2015 at 2:00pm)\n\nBut I don't have the email addresses for these events:\n - Event #3 (Friday 2 January 2015 4:00pm)\n - Event #4 (tomorrow" + ", " + window.helpers.capitalize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('en').format(localize("email_templates.common.only_date_format", {locale: 'en'}))) + " at 3:00pm)\n\nPlease provide the attendees' email addresses if you would like me to take care of them.",
                fr: "C'est bien noté. Je vais reporter les évènements :\n - Event #1 (Jeudi 1 janvier 2015 à 12h00)\n - Event #2 (Jeudi 1 janvier 2015 à 14h00)\n\nEn revanche, je n'ai pas les contacts pour ces évènements :\n - Event #3 (Vendredi 2 janvier 2015 à 16h00)\n - Event #4 (demain" + ", " + window.helpers.lowerize(moment().hour(12).minute(0).second(0).add(1, 'd').locale('fr').format(localize("email_templates.common.only_date_format", {locale: 'fr'}))) + " à 15h00)\n\nMerci de m'indiquer les adresses email des participants si vous souhaitez que je m'en occupe."
            }
        }],


    [{
        action: "send_confirmation",
        expectedResults: {
            en: "Duly noted!",
            fr: "Très bien, c'est noté."
        }
    }],
    [
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'client',
                targetInfos: {email: 'client@gmail.com', name: 'John Doe'},
                support: 'mobile',
                details: '06 02 02 02 02'
            },
            expectedResults: {
                en: "I have included the call instructions in the event.",
                fr: "J'ai inséré les instructions d'appel dans l'événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: {email: 'interlocutor@gmail.com', name: 'Samy Johnny'},
                support: 'mobile',
                details: '06 02 02 02 02'
            },
            expectedResults: {
                en: "I have included the call instructions in the event.",
                fr: "J'ai inséré les instructions d'appel dans l'événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'client',
                targetInfos: {email: 'client@gmail.com', name: 'John Doe'},
                support: 'landline',
                details: '06 02 02 02 02'
            },
            expectedResults: {
                en: "I have included the call instructions in the event.",
                fr: "J'ai inséré les instructions d'appel dans l'événement."

            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: {email: 'interlocutor@gmail.com', name: 'Samy Johnny'},
                support: 'mobile',
                details: '06 02 02 02 02'
            },
            expectedResults: {
                en: "I have included the call instructions in the event.",
                fr: "J'ai inséré les instructions d'appel dans l'événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'client',
                targetInfos: {email: 'client@gmail.com', name: 'John Doe'},
                support: 'confcall',
                details: 'confcall instructions to follow fzfzefezfzefzefezf'
            },
            expectedResults: {
                en: "I have included the call instructions in the event.",
                fr: "J'ai inséré les instructions d'appel dans l'événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: {email: 'interlocutor@gmail.com', name: 'Samy Johnny'},
                support: 'confcall',
                details: 'confcall instructions to follow fzfzefezfzefzefezf'
            },
            expectedResults: {
                en: "I have included the call instructions in the event.",
                fr: "J'ai inséré les instructions d'appel dans l'événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'client',
                targetInfos: {email: 'client@gmail.com', name: 'John Doe'},
                support: 'skype',
                details: 'ClientSkypeId'
            },
            expectedResults: {
                en: "I have noted John’s Skype ID in the event.",
                fr: "J’ai inséré l'identifiant Skype de John dans l’événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: {email: 'interlocutor@gmail.com', name: 'Samy Johnny'},
                support: 'skype',
                details: 'InterlocutorSkypeId'
            },
            expectedResults: {
                en: "I have noted Samy’s Skype ID in the event.",
                fr: "J’ai inséré l'identifiant Skype de Samy dans l’événement."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'client',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            expectedResults: {
                en: "",
                fr: ""
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: false,
            expectedResults: {
                en: "",
                fr: ""
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Please provide the number on which you will be reachable.",
                fr: "Merci de me faire parvenir le numéro sur lequel vous serez joignable."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide a number on which you will be reachable.",
                fr: "Merci également de me faire parvenir le numéro sur lequel vous serez joignable."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "Please provide your Skype ID.",
                fr: "Merci de me faire parvenir votre identifiant Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide your Skype ID.",
                fr: "Merci également de me faire parvenir votre identifiant Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            expectedResults: {
                en: "Please provide a number on which the conference call can be made.",
                fr: "Merci de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide a number on which the conference call can be made.",
                fr: "Merci également de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            expectedResults: {
                en: "Please provide your Skype IDs.",
                fr: "Merci de me faire parvenir vos identifiants Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide your Skype IDs.",
                fr: "Merci également de me faire parvenir vos identifiants Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide the number on which attendee1 will be reachable.",
                fr: "Merci de me faire parvenir le numéro sur lequel attendee1 sera joignable."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: [],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide a number on which attendee1 will be reachable.",
                fr: "Merci aussi de me faire parvenir le numéro sur lequel attendee1 sera joignable."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide attendee1’s Skype ID.",
                fr: "Merci de me faire parvenir l'identifiant Skype de attendee1."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: [],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide attendee1’s Skype ID.",
                fr: "Merci également de me faire parvenir l'identifiant Skype de attendee1."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide a number on which the conference call can be made.",
                fr: "Merci de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: [],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide a number on which the conference call can be made.",
                fr: "Merci également de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide Skype IDs accordingly.",
                fr: "Merci de me faire parvenir les identifiants Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: [],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide Skype IDs accordingly.",
                fr: "Merci également de me faire parvenir les identifiants Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: ['attendee3'],
            expectedResults: {
                en: "Please provide a number on which the conference call can be made.",
                fr: "Merci de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'mobile',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: ['attendee3'],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide a number on which the conference call can be made.",
                fr: "Merci également de me faire parvenir un numéro sur lequel la conférence téléphonique pourra avoir lieu."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: ['attendee3'],
            expectedResults: {
                en: "Please provide Skype IDs accordingly.",
                fr: "Merci de me faire parvenir les identifiants Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'interlocutor',
                targetInfos: '',
                support: 'skype',
                details: ''
            },
            askCallInstructions: true,
            assistedAttendees: ['attendee1', 'attendee2'],
            unassistedAttendees: ['attendee3'],
            askingEarly: true,
            expectedResults: {
                en: "Please also provide Skype IDs accordingly.",
                fr: "Merci également de me faire parvenir les identifiants Skype."
            }
        },
        {
            action: "send_call_instructions",
            callInstructions:{
                target: 'later',
                targetInfos: '',
                support: '',
                details: ''
            },
            expectedResults: {
                en: "",
                fr: ""
            }
        }
    ],
    [
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "landline_or_mobile",
            attendees: ["Attendee1"],
            multipleAttendees: true,
            redundantCourtesy: false,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "singleAttendee, please provide your phone number, just in case!",
                fr: "singleAttendee, merci de me faire parvenir le numéro sur lequel vous serez joignable."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "landline_or_mobile",
            attendees: ["Attendee1"],
            multipleAttendees: true,
            redundantCourtesy: true,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "singleAttendee, please also provide your phone number, just in case!",
                fr: "singleAttendee, merci aussi de me faire parvenir le numéro sur lequel vous serez joignable."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            multipleAttendees: true,
            redundantCourtesy: false,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "singleAttendee, please provide your Skype ID.",
                fr: "singleAttendee, merci de me faire parvenir votre identifiant Skype."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            multipleAttendees: true,
            redundantCourtesy: true,
            assistedAttendees: [],
            unassistedAttendees: ['singleAttendee'],
            expectedResults: {
                en: "singleAttendee, please also provide your Skype ID.",
                fr: "singleAttendee, merci aussi de me faire parvenir votre identifiant Skype."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            redundantCourtesy: false,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            expectedResults: {
                en: "attendee1, attendee2, please provide the number on which you will be reachable.",
                fr: "attendee1, attendee2, merci de me faire parvenir le numéro sur lequel vous serez joignable."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            redundantCourtesy: true,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            expectedResults: {
                en: "attendee1, attendee2, please also provide the number on which you will be reachable.",
                fr: "attendee1, attendee2, merci aussi de me faire parvenir le numéro sur lequel vous serez joignable."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            redundantCourtesy: false,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            expectedResults: {
                en: "attendee1, attendee2, please provide your Skype IDs.",
                fr: "attendee1, attendee2, merci de me faire parvenir vos identifiants Skype."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            redundantCourtesy: true,
            assistedAttendees: [],
            unassistedAttendees: ['attendee1', 'attendee2'],
            expectedResults: {
                en: "attendee1, attendee2, please also provide your Skype IDs.",
                fr: "attendee1, attendee2, merci aussi de me faire parvenir vos identifiants Skype."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: false,
            assistedAttendees: ['assistedAttendee'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide the number on which assistedAttendee will be reachable, just in case!",
                fr: "Merci de me faire parvenir le numéro sur lequel assistedAttendee sera joignable, au cas où."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: true,
            assistedAttendees: ['assistedAttendee'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please also provide the number on which assistedAttendee will be reachable, just in case!",
                fr: "Merci aussi de me faire parvenir le numéro sur lequel assistedAttendee sera joignable, au cas où."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: false,
            assistedAttendees: ['assistedAttendee'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide assistedAttendee’s Skype ID.",
                fr: "Merci de me faire parvenir l'identifiant Skype de assistedAttendee."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: true,
            assistedAttendees: ['assistedAttendee'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please also provide assistedAttendee’s Skype ID.",
                fr: "Merci aussi de me faire parvenir l'identifiant Skype de assistedAttendee."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: false,
            assistedAttendees: ['assistedAttendee1', 'assistedAttendee2'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide a number on which assistedAttendee1, assistedAttendee2 will be reachable, just in case!",
                fr: "Merci de me faire parvenir un numéro sur lequel assistedAttendee1, assistedAttendee2 seront joignables, au cas où."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: true,
            assistedAttendees: ['assistedAttendee1', 'assistedAttendee2'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please also provide a number on which assistedAttendee1, assistedAttendee2 will be reachable, just in case!",
                fr: "Merci aussi de me faire parvenir un numéro sur lequel assistedAttendee1, assistedAttendee2 seront joignables, au cas où."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: false,
            assistedAttendees: ['assistedAttendee1', 'assistedAttendee2'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please provide assistedAttendee1, assistedAttendee2 Skype IDs.",
                fr: "Merci de me faire parvenir les identifiants Skype de assistedAttendee1, assistedAttendee2."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            assisted: true,
            redundantCourtesy: true,
            assistedAttendees: ['assistedAttendee1', 'assistedAttendee2'],
            unassistedAttendees: [],
            expectedResults: {
                en: "Please also provide assistedAttendee1, assistedAttendee2 Skype IDs.",
                fr: "Merci aussi de me faire parvenir les identifiants Skype de assistedAttendee1, assistedAttendee2."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            redundantCourtesy: false,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: ['attendee2'],
            expectedResults: {
                en: "Please provide a number to reach, just in case!",
                fr: "Merci de me faire parvenir un numéro à joindre au cas où."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "mobile_only",
            attendees: ["Attendee1"],
            redundantCourtesy: true,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: ['attendee2'],
            expectedResults: {
                en: "Please also provide a number to reach, just in case!",
                fr: "Merci aussi de me faire parvenir un numéro à joindre au cas où."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            redundantCourtesy: false,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: ['attendee2'],
            expectedResults: {
                en: "Please provide Skype IDs accordingly.",
                fr: "Merci de me faire parvenir les identifiants Skype."
            }
        },
        {
            action: "ask_additional_informations",
            requiredAdditionalInformations: "skype_only",
            attendees: ["Attendee1"],
            redundantCourtesy: true,
            assistedAttendees: ['attendee1'],
            unassistedAttendees: ['attendee2'],
            expectedResults: {
                en: "Please also provide Skype IDs accordingly.",
                fr: "Merci aussi de me faire parvenir les identifiants Skype."
            }
        },
        {
            action: "forward_to_client",
            expectedResults: {
                en: "Please allow me to forward you this email.\nI remain at your disposal.",
                fr: "Permettez-moi de vous transférer cet email.\nJe reste à votre disposition."
            }
        },
        {
            action: "wait_for_contact",
            isPostpone: false,
            expectedResults: {
                en: "Pending your contact's response, I remain at your disposal if you need me to suggest your availabilities beforehand.",
                fr: "Je comprends que je dois attendre le retour de votre interlocuteur avant d'intervenir.\nJe reste à votre disposition si vous souhaitez que je propose des disponibilités en avance de phase."
            }
        },
        {
            action: "wait_for_contact",
            isPostpone: true,
            previousAppointment: {
                designation_in_email: {
                    "fr": "le verre",
                    "en": "the drinks appointment"
                }
            },
            currentEventData: {
                start: {
                    dateTime: "2015-01-05T12:00:00+00"
                }
            },
            timezoneId: "Europe/Paris",
            defaultTimezoneId: "Europe/Paris",
            expectedResults: {
                en: "Pending your contact's response, before rescheduling I will cancel the drinks appointment scheduled for Monday 5 January 2015 12:00pm.",
                fr: "Je comprends que je dois attendre le retour de votre interlocuteur avant de reprogrammer.\nJ'annule le verre prévu lundi 5 janvier 2015 à 12h00 en attendant."
            }
        }
    ],
    [
        {
            action: "invitation_already_sent",
            client: "Fname LName",
            invitation_start_date: "2016-03-31T13:00:00+02:00",
            timezoneId: "Europe/Paris",
            expectedResults: {
                en: "I take note of the invite in Fname LName's calendar for Thursday 31 March 2016 at 1:00pm.",
                fr: "Je prends note de l'invitation dans le calendrier de Fname LName pour le Jeudi 31 mars 2016 à 13h00."
            }
        },
    ]
];