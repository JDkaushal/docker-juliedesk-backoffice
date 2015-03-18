window.tests.ask_availabilities_classification_form = [
    {
        name: "Ask date suggestion classification form when postpone and no client agreement",
        should: "ask if others answers are expected",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
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
                    waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                    clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                    attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                    classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                    datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: true,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: false
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone, no client agreement",
        should: "ask if others answers are expected",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
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
                    waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                    clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                    attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                    classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                    datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0
                };
                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: true,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: false
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone, and client agreement",
        should: "ask if others answers are expected",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
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
                    waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                    clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                    attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                    classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                    datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0
                };
                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: true,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: false
        }
    },



    {
        name: "Ask date suggestion classification form when postpone and no client agreement click other responses expected",
        should: "show warner",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function () {
                $(".messages-thread-info-panel .waiting-for-others-panel .yes-button").click();
                $(function() {
                    var result = {
                        waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                        waitingForOthersWarnerVisible: $(".messages-thread-info-panel .waiting-for-others-warner:visible").length > 0,
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0
                    };

                    unMockHtml();
                    callback(result);
                });

            });
        },
        expected_result: {
            waitingForOthersPanelVisible: true,
            waitingForOthersWarnerVisible: true,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: false
        }
    },


    {
        name: "Ask date suggestion classification form when postpone and no client agreement click no other responses expected",
        should: "ask client agreement",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function () {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    var result = {
                        waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
                        clientAgreementData: $(".client-agreement-panel").data("client-agreement"),
                        attendeesAreNoticedData: $(".attendees-are-noticed-panel").data("attendees-are-noticed")
                    };

                    unMockHtml();
                    callback(result);
                });

            });
        },
        expected_result: {
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: true,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: false,
            clientAgreementData: false,
            attendeesAreNoticedData: false
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone, no client agreement click no other responses expected",
        should: "",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    var result = {
                        waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
                        clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                    };
                    unMockHtml();
                    callback(result);
                });
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: true,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: false,
            clientAgreementData: false
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone, and client agreement click no other responses expected",
        should: "",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: true,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    var result = {
                        waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                        clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                        attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                        classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                        datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
                        clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                    };
                    unMockHtml();
                    callback(result);
                });
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: true,
            clientAgreementData: true
        }
    },





    {
        name: "Ask date suggestion classification form when postpone and no client agreement click no other responses expected, click yes",
        should: "ask if attendees are noticed",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                    $(function() {
                        var result = {
                            waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                            clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                            attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                            classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                            datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
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
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: true,
            clientAgreementData: true,
            attendeesAreNoticedData: true
        }
    },
    {
        name: "Ask date suggestion classification form when postpone and no client agreement  click no other responses expected, click no",
        should: "show classic panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    $(".messages-thread-info-panel .client-agreement-panel .no-button").click();
                    $(function() {
                        var result = {
                            waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                            clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                            attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                            classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                            datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
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
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: true,
            clientAgreementData: false,
            attendeesAreNoticedData: true
        }
    },



    {
        name: "Ask date suggestion classification form when no postpone and no client agreement click no other responses expected, click yes",
        should: "display classic info panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: false,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    $(".messages-thread-info-panel .client-agreement-panel .yes-button").click();
                    $(function() {
                        var result = {
                            waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                            clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                            attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                            classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                            datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
                            clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                        };
                        unMockHtml();
                        callback(result);
                    });
                });
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: true,
            clientAgreementData: true
        }
    },
    {
        name: "Ask date suggestion classification form when no postpone and no client agreement click no other responses expected, click no",
        should: "show classic panel",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
                startedAt: 0,
                locale: "en",
                threadLocale: "en",
                isPostpone: true,
                messageId: "1234",
                clientAgreement: false,
                alreadySuggestedDates: []
            });
            $(function() {
                $(".messages-thread-info-panel .waiting-for-others-panel .no-button").click();
                $(function() {
                    $(".messages-thread-info-panel .client-agreement-panel .no-button").click();
                    $(function() {
                        var result = {
                            waitingForOthersPanelVisible: $(".messages-thread-info-panel .waiting-for-others-panel:visible").length > 0,
                            clientAgreementPanelVisible: $(".messages-thread-info-panel .client-agreement-panel:visible").length > 0,
                            attendeesAreNoticedVisible: $(".messages-thread-info-panel .attendees-are-noticed-panel:visible").length > 0,
                            classicInfoPanelVisible: $(".messages-thread-info-panel .classic-info-panel:visible").length > 0,
                            datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0,
                            clientAgreementData: $(".client-agreement-panel").data("client-agreement")
                        };
                        unMockHtml();
                        callback(result);
                    });
                });
            });
        },
        expected_result: {
            waitingForOthersPanelVisible: false,
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: false,
            datesIdentificationPanelVisible: true,
            clientAgreementData: false
        }
    },



/*
    {
        name: "Click validate",
        should: "send post with correct data",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "ask_availabilities",
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
                classification: "ask_availabilities",
                private: false,
                attendees: [],
                constraints_data: [],
                client_agreement: true,
                attendees_are_noticed: true,
                date_times:[],
                processed_in: "FILTERED"
            }
        }
    }*/
];

