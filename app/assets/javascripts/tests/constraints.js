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
        should: "returns deployed when ALWAYS is set, no times",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    timezone: "Europe/Paris",
                    constraint_when_nature: "always",
                    days_of_weeks: ["1", "4"],
                    constraint_nature: "can"
                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2015-01-01T00:00+01:00",
                end_date: "2015-01-01T23:59+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-05T00:00+01:00",
                end_date: "2015-01-05T23:59+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-08T00:00+01:00",
                end_date: "2015-01-08T23:59+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-12T00:00+01:00",
                end_date: "2015-01-12T23:59+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-15T00:00+01:00",
                end_date: "2015-01-15T23:59+01:00",
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when ALWAYS is set, times set",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_time: "12:00",
                    end_time: "14:00",
                    timezone: "Europe/Paris",
                    constraint_when_nature: "always",
                    days_of_weeks: ["1", "4"],
                    constraint_nature: "can"

                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2015-01-01T12:00+01:00",
                end_date: "2015-01-01T14:00+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-05T12:00+01:00",
                end_date: "2015-01-05T14:00+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-08T12:00+01:00",
                end_date: "2015-01-08T14:00+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-12T12:00+01:00",
                end_date: "2015-01-12T14:00+01:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-15T12:00+01:00",
                end_date: "2015-01-15T14:00+01:00",
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when ALWAYS is set, times set, different timezone",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_time: "05:00",
                    end_time: "14:00",
                    timezone: "America/Los_Angeles",
                    constraint_when_nature: "always",
                    days_of_weeks: ["1", "4"],
                    constraint_nature: "can"
                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2015-01-01T05:00-08:00",
                end_date: "2015-01-01T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-05T05:00-08:00",
                end_date: "2015-01-05T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-08T05:00-08:00",
                end_date: "2015-01-08T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-12T05:00-08:00",
                end_date: "2015-01-12T14:00-08:00",
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when FROM DATE is set, times sets, timezone set",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_time: "05:00",
                    end_time: "14:00",
                    dates: ["2015-01-10"],
                    timezone: "America/Los_Angeles",
                    constraint_when_nature: "from_date",
                    constraint_nature: "can"
                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2015-01-10T05:00-08:00",
                end_date: "2015-01-10T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-11T05:00-08:00",
                end_date: "2015-01-11T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-12T05:00-08:00",
                end_date: "2015-01-12T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-13T05:00-08:00",
                end_date: "2015-01-13T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-14T05:00-08:00",
                end_date: "2015-01-14T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-15T05:00-08:00",
                end_date: "2015-01-15T14:00-08:00",
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when RANGE is set, times sets, timezone set",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_time: "05:00",
                    end_time: "14:00",
                    dates: ["2015-01-10", "2015-01-08"],
                    timezone: "America/Los_Angeles",
                    constraint_when_nature: "range",
                    constraint_nature: "can"
                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2015-01-08T05:00-08:00",
                end_date: "2015-01-08T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-09T05:00-08:00",
                end_date: "2015-01-09T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-10T05:00-08:00",
                end_date: "2015-01-10T14:00-08:00",
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when CUSTOM is set, times sets, timezone set",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_time: "05:00",
                    end_time: "14:00",
                    dates: ["2015-01-10", "2015-01-08", "2015-01-09", "2015-01-12"],
                    timezone: "America/Los_Angeles",
                    constraint_when_nature: "custom",
                    constraint_nature: "can"
                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2015-01-08T05:00-08:00",
                end_date: "2015-01-08T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-09T05:00-08:00",
                end_date: "2015-01-09T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-10T05:00-08:00",
                end_date: "2015-01-10T14:00-08:00",
                constraint_nature: "can"
            },
            {
                start_date: "2015-01-12T05:00-08:00",
                end_date: "2015-01-12T14:00-08:00",
                constraint_nature: "can"
            }
        ]
    },
    {
        name: "Deploy constraints",
        should: "returns deployed when CUSTOM is set, times sets, timezone set, out of viewing window",
        test_result: function () {
            return ConstraintTile.deployConstraints([
                {
                    start_time: "05:00",
                    end_time: "14:00",
                    dates: ["2014-01-10"],
                    timezone: "America/Los_Angeles",
                    constraint_when_nature: "custom",
                    constraint_nature: "can"
                }
            ], moment.tz("2015-01-02", "Europe/Paris"), moment.tz("2015-01-15T23:59:00", "Europe/Paris"));
        },
        expected_result: [
            {
                start_date: "2014-01-10T05:00-08:00",
                end_date: "2014-01-10T14:00-08:00",
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
        name: "getEventsFromDataFromDeployedConstraints",
        should: "returns events when cant constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromDataFromDeployedConstraints([
                {
                    start_date: moment("2015-01-01T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-01T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "cant"
                },
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "cant"
                },
                {
                    start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
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
        name: "getEventsFromDataFromDeployedConstraints",
        should: "returns events when can constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromDataFromDeployedConstraints([
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
                },
                {
                    start_date: moment("2015-01-01").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-05").format("YYYY-MM-DDTHH:mm"),
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
        name: "getEventsFromDataFromDeployedConstraints",
        should: "returns events when prefers constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromDataFromDeployedConstraints([
                {
                    start_date: moment("2015-01-01T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-01T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-02T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-01").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-05").format("YYYY-MM-DDTHH:mm"),
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
        name: "getEventsFromDataFromDeployedConstraints",
        should: "returns event when complex can constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromDataFromDeployedConstraints([
                {
                    start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T18:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "can"
                },
                {
                    start_date: moment("2015-01-02T16:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "can"
                },
                {
                    start_date: moment("2015-01-01T00:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
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
        name: "getEventsFromDataFromDeployedConstraints",
        should: "returns event when complex can constraints",
        test_result: function () {
            return ConstraintTile.getEventsFromDataFromDeployedConstraints([
                {
                    start_date: moment("2015-01-03T12:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T18:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-02T16:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-03T14:00").format("YYYY-MM-DDTHH:mm"),
                    constraint_nature: "prefers"
                },
                {
                    start_date: moment("2015-01-01T00:00").format("YYYY-MM-DDTHH:mm"),
                    end_date: moment("2015-01-02T14:00").format("YYYY-MM-DDTHH:mm"),
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