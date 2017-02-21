var ClientAgreementLevelManager = (function(params){
    var instance;

    function init() {
        const AUTHORIZED_REQUEST = 'authorized_request';
        const TRUSTED_REQUEST = 'trusted_request';
        const UNAUTHORIZED_REQUEST = 'unauthorized_request';

        const DISPLAY_NODES_CLASSES = [AUTHORIZED_REQUEST, TRUSTED_REQUEST, UNAUTHORIZED_REQUEST];

        var $nodesStatus = $('.client-agreement-level-container ' + _.map(DISPLAY_NODES_CLASSES, function(nodeClass){return '.' + nodeClass}).join(','));

        function displayAgreementStatus() {
            var agreementLevel = computeAgreementLevel();
            showCorrectAgreementLevelTile(agreementLevel);
            postAgreementLevelComputingCallback(agreementLevel);
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
            var emailSender = firstEmailSender().name;
            var clientCircleOfTrust = window.threadAccount.circle_of_trust;
            var clientEmails = _.uniq(window.threadAccount.email_aliases.concat(window.threadAccount.email));
            var agreementLevel = UNAUTHORIZED_REQUEST;
            
            if(clientIsSender(clientEmails, emailSender) || emailInCircleOfTrust(clientCircleOfTrust, emailSender)) {
                agreementLevel = AUTHORIZED_REQUEST;
            } else if(clientTrustingEveryone(clientCircleOfTrust)) {
                agreementLevel = TRUSTED_REQUEST;
            }
            
            return agreementLevel;
        }

        function clientIsSender(clientEmails, emailSender) {
            return clientEmails.indexOf(emailSender) > -1;
        }

        function emailInCircleOfTrust(circleOfTrust, email) {
            var trustedEmails = circleOfTrust.trusted_emails;
            var trustedDomains = circleOfTrust.trusted_domains;
            var emailDomainSplit = email.split('@');
            var emailDomain = emailDomainSplit[emailDomainSplit.length - 1];

            return (trustedEmails.indexOf(email) > -1) || (trustedDomains.indexOf(emailDomain) > -1)
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