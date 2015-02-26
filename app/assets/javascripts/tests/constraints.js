window.tests.constraints = [
    {
        name: "Deploy constraints",
        should: "returns empty when given empty",
        test_result: function () {
            return ConstraintTile.deployConstraints([], moment("2015-01-01"), moment("2015-01-05"));
        },
        expected_result: []
    },
    {
        name: "Deploy constraints",
        should: "returns only dataEntry when no repeat",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_date: moment("2015-01-02").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "can"
                },
                {
                    start_date: moment("2015-01-05T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-05T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "cant"
                },
                {
                    start_date: moment("2015-01-07T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-15T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "prefers"
                }
            ], moment("2015-01-01"), moment("2015-01-05"));
        },
        expected_result: [
            {
                start_date: moment("2015-01-02").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-04").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-05T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-05T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "cant"
            },
            {
                start_date: moment("2015-01-07T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-15T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "prefers"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when dayly repeat",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "dayly",
                    constraint_nature: "can"
                }
            ], moment("2015-01-02"), moment("2015-01-03T23:59:00"));
        },
        expected_result: [

            {
                start_date: moment("2015-01-01T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-01T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when dayly repeat, start_recurring and end_recurring set",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "dayly",
                    constraint_nature: "can",
                    start_recurring: moment("2015-01-05T00:00:00").format("YYYY-MM-DDTHH:mm"),
                    end_recurring: moment("2015-01-07T00:00:00").format("YYYY-MM-DDTHH:mm")
                }
            ], moment("2015-01-02"), moment("2015-01-10T23:59:00"));
        },
        expected_result: [

            {
                start_date: moment("2015-01-05T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-05T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-06T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-06T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-07T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-07T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when weekly repeat",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "weekly",
                    days_of_weeks: ["0", "3"],
                    constraint_nature: "can"
                }
            ], moment("2015-01-02"), moment("2015-01-15T23:59:00"));
        },
        expected_result: [
            {
                start_date: moment("2015-01-01T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-01T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-05T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-05T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-08T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-08T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-12T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-12T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-15T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-15T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when weekly repeat, start_recurring and end_recurring set",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "weekly",
                    days_of_weeks: ["0", "3"],
                    constraint_nature: "can",
                    start_recurring: moment("2015-01-08T00:00:00").format("YYYY-MM-DDTHH:mm"),
                    end_recurring: moment("2015-01-12T00:00:00").format("YYYY-MM-DDTHH:mm")
                }
            ], moment("2015-01-02"), moment("2015-01-15T23:59:00"));
        },
        expected_result: [
            {
                start_date: moment("2015-01-08T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-08T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            },
            {
                start_date: moment("2015-01-12T12:00").format("YYYY-MM-DDTHH:mm"),
                end_date: moment("2015-01-12T14:00").format("YYYY-MM-DDTHH:mm"),
                constraint_nature: "can"
            }
        ]
    },

    {
        name: "GetEventsFromData",
        should: "returns events when no constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromData([
            ], moment("2015-01-02"), moment("2015-01-15T23:59:00"));
        },
        expected_result: {
            cant: [],
            dontPrefer: []
        }
    },
    {
        name: "GetEventsFromData",
        should: "returns events when cant constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromData([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "dayly",
                    constraint_nature: "cant"
                }
            ], moment("2015-01-01"), moment("2015-01-04"));
        },
        expected_result: {
            cant: [
                {
                    start: moment("2015-01-01T12:00"),
                    end: moment("2015-01-01T14:00")
                },
                {
                    start: moment("2015-01-02T12:00"),
                    end: moment("2015-01-02T14:00")
                },
                {
                    start: moment("2015-01-03T12:00"),
                    end: moment("2015-01-03T14:00")
                }
            ],
            dontPrefer: []
        }
    },
    {
        name: "GetEventsFromData",
        should: "returns events when can constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromData([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "dayly",
                    constraint_nature: "can"
                },
                {
                    start_date: moment("2015-01-01").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-05").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "cant"
                }
            ], moment("2015-01-01"), moment("2015-01-04"));
        },
        expected_result: {
            cant: [
                {
                    start: moment("2015-01-01T00:00"),
                    end: moment("2015-01-01T12:00")
                },
                {
                    start: moment("2015-01-01T14:00"),
                    end: moment("2015-01-02T12:00")
                },
                {
                    start: moment("2015-01-02T14:00"),
                    end: moment("2015-01-03T12:00")
                },
                {
                    start: moment("2015-01-03T14:00"),
                    end: moment("2015-01-04T00:00")
                }
            ],
            dontPrefer: []
        }
    },
    {
        name: "GetEventsFromData",
        should: "returns events when prefers constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromData([
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-04T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "dayly",
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-01").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-05").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "cant"
                }
            ], moment("2015-01-01"), moment("2015-01-04"));
        },
        expected_result: {
            cant: [
                {
                    start: moment("2015-01-01T00:00"),
                    end: moment("2015-01-04T00:00")
                }
            ],
            dontPrefer: [
                {
                    start: moment("2015-01-01T00:00"),
                    end: moment("2015-01-01T12:00")
                },
                {
                    start: moment("2015-01-01T14:00"),
                    end: moment("2015-01-02T12:00")
                },
                {
                    start: moment("2015-01-02T14:00"),
                    end: moment("2015-01-03T12:00")
                },
                {
                    start: moment("2015-01-03T14:00"),
                    end: moment("2015-01-04T00:00")
                }]
        }
    },

    {
        name: "GetEventsFromData",
        should: "returns event when complex can constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromData([
                {
                    start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T18:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "can"
                },
                {
                    start_date: moment("2015-01-02T16:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "can"
                },
                {
                    start_date: moment("2015-01-01T00:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "can"
                }
            ], moment("2015-01-01T12:00"), moment("2015-01-04"));
        },
        expected_result: {
            cant: [
                {
                    start: moment("2015-01-02T14:00"),
                    end: moment("2015-01-02T16:00")
                },
                {
                    start: moment("2015-01-03T18:00"),
                    end: moment("2015-01-04")
                }],
            dontPrefer: []
        }
    },

    {
        name: "GetEventsFromData",
        should: "returns event when complex can constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromData([
                {
                    start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T18:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-02T16:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-01T00:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
                    repeat: "never",
                    constraint_nature: "prefers"
                }
            ], moment("2015-01-01T12:00"), moment("2015-01-04"));
        },
        expected_result: {
            cant: [],
            dontPrefer: [
                {
                    start: moment("2015-01-02T14:00"),
                    end: moment("2015-01-02T16:00")
                },
                {
                    start: moment("2015-01-03T18:00"),
                    end: moment("2015-01-04")
                }
            ]
        }
    }
];