window.tests.ask_date_suggestions_classification_form = [
    {
        name: "Ask date suggestion classification form when postpone and no client agreement",
        should: "ask client agreement",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
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
        name: "Ask date suggestion classification form when no postpone, no client agreement",
        should: "",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                var result = {
                    clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                    attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                    classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                    clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                };
                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            clientAgreementPanelVisible: true,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            clientAgreementData: false
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone, and client agreement",
        should: "",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: true,
                alreadySuggestedDates: []
            });
            $(function() {
                var result = {
                    clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                    attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                    classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                    clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                };
                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            clientAgreementData: true
        }
    },





    {
        name: "Ask date suggestion classification form when postpone and no client agreement click yes",
        should: "ask if attendees are noticed",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
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
        name: "Ask date suggestion classification form when postpone and no client agreement click no",
        should: "show classic panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .client-agreement-panel .no-button").click();
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
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            clientAgreementData: false,
            attendeesAreNoticedData: true
        }
    },



    {
        name: "Ask date suggestion classification form when no postpone and no client agreement click yes",
        should: "display classic info panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                $(function() {
                    var result = {
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                    };
                    unMockHtml();
                    callback(result);
                });
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            clientAgreementData: true
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone and no client agreement click no",
        should: "show classic panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .client-agreement-panel .no-button").click();
                $(function() {
                    var result = {
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                    };
                    unMockHtml();
                    callback(result);
                });
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            clientAgreementData: false
        }
    },


    {
        name: "Ask date suggestion classification form when postpone and no client agreement click yes, then yes",
        should: "show classic panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                $(function() {
                    $(".messages-thread-info-panel .attendees-are-noticed-panel .yes-button").click();
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
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            clientAgreementData: true,
            attendeesAreNoticedData: true
        }
    },
    {
        name: "Ask date suggestion classification form when postpone and no client agreement click yes, then no",
        should: "show classic panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                $(function() {
                    $(".messages-thread-info-panel .attendees-are-noticed-panel .no-button").click();
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
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            clientAgreementData: true,
            attendeesAreNoticedData: false
        }
    },




    {
        name: "Click validate",
        should: "send post with correct data",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_date_suggestions",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: true,
                alreadySuggestedDates: []
            });
            $(function() {
                window.getInfoPanelAttendees = function(){
                    return [];
                };
                $.ajax = function(params) {
                    params.data.processed_in = "FILTERED";
                    unMockHtml();
                    callback(params);
                };

                $(function() {
                    window.submitClassification();
                });
            });
        },
        expected_result: {
            url: "/messages/1234/classify",
            type: "POST",
            data: {
                classification: "ask_date_suggestions",
                private: false,
                attendees: [],
                constraints_data: [],
                client_agreement: true,
                attendees_are_noticed: true,
                date_times:[],
                processed_in: "FILTERED"
            }
        }
    }
];