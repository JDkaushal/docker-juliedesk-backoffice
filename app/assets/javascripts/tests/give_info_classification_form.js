window.tests.give_info_classification_form = [
    {
        name: "Ask date suggestion classification form when postpone and no client agreement",
        should: "ask client agreement",
        test_result_async: function (callback) {
            mockHtml(generateInfoPanel());
            window.classificationForms.createClassificationForm({
                classification: "give_info",
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
                    datesIdentificationPanelVisible: $(".messages-thread-info-panel .dates-identification-panel:visible").length > 0
                };

                unMockHtml();
                callback(result);
            });
        },
        expected_result: {
            clientAgreementPanelVisible: false,
            attendeesAreNoticedVisible: false,
            classicInfoPanelVisible: true,
            datesIdentificationPanelVisible: false
        }
    }];