window.tests = {};
window.testsData = {};

function unMockHtml() {
    $("#mock-panel").remove();
}
function mockHtml($html) {
    if($("#mock-panel").length == 0) {
        $("body").append($("<div>").attr("id", "mock-panel"));
    }
    $("#mock-panel").append($html);
}

function generateInfoPanel() {
    var $infoPanel = $("<div>").addClass("messages-thread-info-panel");

    var $waitingForOthersPanel = $("<div>").addClass("waiting-for-others-panel");
    var $waitingForOthersYesNoButtonsContainer = $("<div>").addClass("yes-no-buttons-container");
    var $waitingForOthersNoButton = $("<div>").addClass("no-button").html("yes");
    var $waitingForOthersYesButton = $("<div>").addClass("yes-button").html("yes");
    var $waitingForOthersWarner = $("<div>").addClass("waiting-for-others-warner").html("Warning");

    $waitingForOthersYesNoButtonsContainer.append($waitingForOthersNoButton);
    $waitingForOthersYesNoButtonsContainer.append($waitingForOthersYesButton);
    $waitingForOthersPanel.append($waitingForOthersYesNoButtonsContainer);
    $waitingForOthersPanel.append($waitingForOthersWarner);
    $infoPanel.append($waitingForOthersPanel);

    var $clientAgreementPanel = $("<div>").addClass("client-agreement-panel");
    var $clientAgreementYesNoButtonsContainer = $("<div>").addClass("yes-no-buttons-container");
    var $clientAgreementNoButton = $("<div>").addClass("no-button").html("yes");
    var $clientAgreementYesButton = $("<div>").addClass("yes-button").html("yes");

    $clientAgreementYesNoButtonsContainer.append($clientAgreementNoButton);
    $clientAgreementYesNoButtonsContainer.append($clientAgreementYesButton);
    $clientAgreementPanel.append($clientAgreementYesNoButtonsContainer);
    $infoPanel.append($clientAgreementPanel);

    var $attendeesAreNoticedPanel = $("<div>").addClass("attendees-are-noticed-panel");
    var $attendeesAreNoticedYesNoButtonsContainer = $("<div>").addClass("yes-no-buttons-container");
    var $attendeesAreNoticedNoButton = $("<div>").addClass("no-button").html("yes");
    var $attendeesAreNoticedYesButton = $("<div>").addClass("yes-button").html("yes");

    $attendeesAreNoticedYesNoButtonsContainer.append($attendeesAreNoticedNoButton);
    $attendeesAreNoticedYesNoButtonsContainer.append($attendeesAreNoticedYesButton);
    $attendeesAreNoticedPanel.append($attendeesAreNoticedYesNoButtonsContainer);
    $infoPanel.append($attendeesAreNoticedPanel);

    var $datesIdentificationPanel = $("<div>").addClass("dates-identification-panel");
    var $alreadySuggestedDatesContainer = $("<div>").addClass("already-suggested-dates-container");
    $datesIdentificationPanel.append($alreadySuggestedDatesContainer);
    var $detectedDatesContainer = $("<div>").addClass("detected-dates-container");
    $datesIdentificationPanel.append($detectedDatesContainer);
    $infoPanel.append($datesIdentificationPanel);

    var $classicInfoPanel = $("<div>").addClass("classic-info-panel");
    $infoPanel.append($classicInfoPanel);

    return $infoPanel;

}
