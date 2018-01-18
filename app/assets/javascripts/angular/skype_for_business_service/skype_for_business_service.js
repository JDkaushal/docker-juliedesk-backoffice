angular.module('skypeForBusiness', []).service("skypeForBusinessService", [function() {

    this.shouldCreateMeetingIfPossible = function() {
        return window.threadComputedData.call_instructions && window.threadComputedData.call_instructions.support == 'skype_for_business';
    };

    this.canCreateMeeting = function() {
        return window.threadAccount.skype_for_business_meeting_generation_active;
    };


}]);