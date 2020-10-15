var ClientAgreementLevelManager = (function(params){
    var instance;

    function init() {
        const AUTHORIZED_REQUEST = 'authorized_request';
        const TRUSTED_REQUEST = 'trusted_request';
        const UNAUTHORIZED_REQUEST = 'unauthorized_request';
        const UNAUTHORIZED_ALIAS = 'unauthorized_alias';

        const DISPLAY_NODES_CLASSES = [AUTHORIZED_REQUEST, TRUSTED_REQUEST, UNAUTHORIZED_REQUEST, UNAUTHORIZED_ALIAS];
        
        function displayAgreementStatus() {
            var agreementLevel = computeAgreementLevel();
            showCorrectAgreementLevelTile(agreementLevel);
            //postAgreementLevelComputingCallback(agreementLevel);
        }

        function postAgreementLevelComputingCallback(agreementLevel) {

            // When request is unauthorized, we only allow the operator to access the free reply flow
            if(agreementLevel == UNAUTHORIZED_REQUEST) {
                _.each($('.actions-menu .action'), function(node) {
                    if($(node).data('actionNature') != 'unknown') {
                        $(node).hide()
                    }
                });
            }
        }

        function showCorrectAgreementLevelTile(agreementLevel) {
            $('.client-agreement-level-container ' + '.' + agreementLevel ).show();
        }

        function computeAgreementLevel() {
            var emailSenders = allEmailsSenders();
            var clientCircleOfTrust = window.threadAccount.circle_of_trust;
            var clientEmails = _.uniq(window.threadAccount.email_aliases.concat(window.threadAccount.email));
            var correct_alias = window.threadAccount.unpermitted_common_aliases.indexOf(window.currentJulieAlias.email);
            var agreementLevel = UNAUTHORIZED_REQUEST;

            if(clientIsInSenders(clientEmails, emailSenders) || (clientCircleOfTrust && emailInCircleOfTrust(clientCircleOfTrust, emailSenders))) {
                agreementLevel = AUTHORIZED_REQUEST;
            } else if(clientCircleOfTrust && clientTrustingEveryone(clientCircleOfTrust)) {
                agreementLevel = TRUSTED_REQUEST;
            }
            if(correct_alias !== -1){
                agreementLevel = UNAUTHORIZED_ALIAS;
            }
            return agreementLevel;
        }

        function arrayPartOfOtherArray(array1, array2) {
            return _.intersection(array1, array2).length > 0;
        }

        function clientIsInSenders(clientEmails, emailSenders) {
            return arrayPartOfOtherArray(clientEmails, emailSenders);
        }

        function emailInCircleOfTrust(circleOfTrust, emails) {
            var trustedEmails = circleOfTrust.trusted_emails;
            var trustedDomains = circleOfTrust.trusted_domains;
            var emailDomains = [];

            _.each(emails, function(email) {
                var emailDomainSplit = email.split('@');
                emailDomains.push(emailDomainSplit[emailDomainSplit.length - 1]);
            });

            return arrayPartOfOtherArray(trustedEmails, emails) || arrayPartOfOtherArray(trustedDomains, emailDomains);
        }

        function clientTrustingEveryone(circleOfTrust) {
            return circleOfTrust.trusting_everyone
        }

        return {
            displayAgreementStatus: function() {
                return displayAgreementStatus();
            }
        };
    }

    return {
        getInstance: function() {
            if(!instance) {
                instance = init();
            }

            return instance;
        }
    };
})();