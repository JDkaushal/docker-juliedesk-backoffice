function generateConstraintTileContainer() {
    return $("<div>").addClass("constraint-tile-container");
}

window.tests.constraint_tile = [
    {
        name: "Create constraint tile with no data",
        should: "create default constraint tile",
        test_result_async: function (callback) {
            mockHtml(generateConstraintTileContainer());
            var constraintTile = new ConstraintTile(
                $(".constraint-tile-container"),
                {
                    possible_attendees: [
                        {email: "john@doe.com"}
                    ]
                }
            );

            $(function () {
                var result = {
                    data: constraintTile.getData()
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            data: {
                attendee_email: "john@doe.com",
                constraint_nature: ConstraintTile.NATURE_CAN,
                constraint_when_nature: ConstraintTile.WHEN_NATURE_FROM_DATE,

                dates: [moment().format("YYYY-MM-DD")],

                start_time: null,
                end_time: null,
                timezone: "GMT",

                days_of_weeks: []
            }
        }
    },
    {
        name: "Create constraint tile with data #1",
        should: "create constraint tile with data #1",
        test_result_async: function (callback) {
            mockHtml(generateConstraintTileContainer());
            var constraintTile = new ConstraintTile(
                $(".constraint-tile-container"),
                {
                    possible_attendees: [
                        {email: "john@doe.com"},
                        {email: "julie@desk.com"}
                    ],
                    data: {
                        attendee_email: "john@doe.com",
                        constraint_nature: ConstraintTile.NATURE_CANT,
                        constraint_when_nature: ConstraintTile.WHEN_NATURE_ALWAYS,

                        dates: [],

                        start_time: "12:00",
                        end_time: "14:00",
                        timezone: "Europe/Paris",

                        days_of_weeks: [3, 5]
                    }
                }
            );

            $(function () {
                var result = {
                    data: constraintTile.getData()
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            data: {
                attendee_email: "john@doe.com",
                constraint_nature: ConstraintTile.NATURE_CANT,
                constraint_when_nature: ConstraintTile.WHEN_NATURE_ALWAYS,

                dates: [],

                start_time: "12:00",
                end_time: "14:00",
                timezone: "Europe/Paris",

                days_of_weeks: [3, 5]
            }
        }
    },
    {
        name: "Create constraint tile with data #2",
        should: "create constraint tile with data #2",
        test_result_async: function (callback) {
            mockHtml(generateConstraintTileContainer());
            var constraintTile = new ConstraintTile(
                $(".constraint-tile-container"),
                {
                    possible_attendees: [
                        {email: "john@doe.com"},
                        {email: "julie@desk.com"}
                    ],
                    data: {
                        attendee_email: "john@doe.com",
                        constraint_nature: ConstraintTile.NATURE_PREFERS,
                        constraint_when_nature: ConstraintTile.WHEN_NATURE_CUSTOM,
                        dates: ["2015-07-08", "2015-07-09"],
                        days_of_weeks: [],
                        timezone: "Europe/Paris"
                    }
                }
            );

            $(function () {
                var result = {
                    data: constraintTile.getData()
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            data: {
                attendee_email: "john@doe.com",
                constraint_nature: ConstraintTile.NATURE_PREFERS,
                constraint_when_nature: ConstraintTile.WHEN_NATURE_CUSTOM,

                dates: ["2015-07-08", "2015-07-09"],

                start_time: null,
                end_time: null,
                timezone: "Europe/Paris",

                days_of_weeks: []
            }
        }
    },
    {
        name: "Create constraint tile with data #3",
        should: "create constraint tile with data #3",
        test_result_async: function (callback) {
            mockHtml(generateConstraintTileContainer());
            var constraintTile = new ConstraintTile(
                $(".constraint-tile-container"),
                {
                    possible_attendees: [
                        {email: "john@doe.com"},
                        {email: "julie@desk.com"}
                    ],
                    data: {
                        attendee_email: "john@doe.com",
                        constraint_nature: ConstraintTile.NATURE_PREFERS,
                        constraint_when_nature: ConstraintTile.WHEN_NATURE_RANGE,
                        dates: ["2015-07-08", "2015-08-09"],
                        days_of_weeks: [],
                        timezone: "Europe/Paris"
                    }
                }
            );

            $(function () {
                var result = {
                    data: constraintTile.getData()
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            data: {
                attendee_email: "john@doe.com",
                constraint_nature: ConstraintTile.NATURE_PREFERS,
                constraint_when_nature: ConstraintTile.WHEN_NATURE_RANGE,

                dates: ["2015-07-08", "2015-08-09"],

                start_time: null,
                end_time: null,
                timezone: "Europe/Paris",

                days_of_weeks: []
            }
        }
    }
];