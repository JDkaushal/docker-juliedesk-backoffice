window.tests.ask_cancel_appointment_classification_form = [
    {
        name: "Ask cancel appointment classification form",
        should: "ask client agreement",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_cancel_appointment",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234"
            });
            $(function () {
                var result = {
                    clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                    attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                    classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                    clientAgreementData: $(".client-agreement-panel").data("client-agreement"),
                    attendeesAreNoticedData: $(".attendees-are-noticed-panel").data("attendees-are-noticed")
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            clientAgreementPanelVisible: true,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            clientAgreementData: false,
            attendeesAreNoticedData: false
        }
    },
    {
        name: "Ask cancel appointment classification form click yes",
        should: "ask attendees are noticed agreement",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_cancel_appointment",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234"
            });
            $(function () {
                $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                $(function() {
                    var result = {
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        clientAgreementData: $(".client-agreement-panel").data("client-agreement"),
                        attendeesAreNoticedData: $(".attendees-are-noticed-panel").data("attendees-are-noticed")
                    };
                    unMockHtml();
                    callback(result);
                });
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: true,
            classicInfoPanelVisible: false,
            clientAgreementData: true,
            attendeesAreNoticedData: false
        }
    },
    {
        name: "Ask cancel appointment classification form click no",
        should: "send form",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_cancel_appointment",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234"
            });
            $(function () {
                $.ajax = function(params) {
                    params.data.processed_in = "FILTERED";
                    unMockHtml();
                    callback(params);
                };

                $(".messages-thread-info-panel .client-agreement-panel .no-button").click();
            });
        },
        expected_result: {
            url: "/messages/1234/classify",
            type: "POST",
            data: {
                classification: "ask_cancel_appointment",
                private: false,
                attendees: [],
                constraints_data: [],
                client_agreement: false,
                attendees_are_noticed: true,
                date_times:[],
                processed_in: "FILTERED"
            }
        }
    },
    {
        name: "Ask cancel appointment classification form click yes then yes",
        should: "send form",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_cancel_appointment",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234"
            });
            $(function () {
                $.ajax = function(params) {
                    params.data.processed_in = "FILTERED";
                    unMockHtml();
                    callback(params);
                };

                $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                $(function() {
                    $(".messages-thread-info-panel .attendees-are-noticed-panel .yes-button").click();
                });
            });
        },
        expected_result: {
            url: "/messages/1234/classify",
            type: "POST",
            data: {
                classification: "ask_cancel_appointment",
                private: false,
                attendees: [],
                constraints_data: [],
                client_agreement: true,
                attendees_are_noticed: true,
                date_times:[],
                processed_in: "FILTERED"
            }
        }
    },
    {
        name: "Ask cancel appointment classification form click yes then no",
        should: "send form",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_cancel_appointment",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234"
            });
            $(function () {
                $.ajax = function(params) {
                    params.data.processed_in = "FILTERED";
                    unMockHtml();
                    callback(params);
                };

                $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                $(function() {
                    $(".messages-thread-info-panel .attendees-are-noticed-panel .no-button").click();
                });
            });
        },
        expected_result: {
            url: "/messages/1234/classify",
            type: "POST",
            data: {
                classification: "ask_cancel_appointment",
                private: false,
                attendees: [],
                constraints_data: [],
                client_agreement: true,
                attendees_are_noticed: false,
                date_times:[],
                processed_in: "FILTERED"
            }
        }
    }
];