(function(){

    var app = angular.module('reply-box-controllers', []);

    app.controller('recipientsManager', ['$scope', '$filter', function($scope, $filter) {
        $scope.attendeesApp = $scope.attendeesApp || undefined;
        $scope.initiated = false;
        $scope.ccs = [];
        $scope.tos = [];

        var $ccTokenNode = $("#recipients-cc-input");
        var $toTokenNode = $("#recipients-to-input");
        var $messagesContainer = $('#messages_container');
        var $replyBoxNode = $('#reply-box');

        $scope.actionNature = $replyBoxNode.data('action-nature');

        $scope.init = function() {
            // Maybe define this function directly here
            initTokenInputs();

            if(window.threadAccount)
                setDefaultRecipientsOther();

            if(window.afterReplyBoxInitCallback){
                window.afterReplyBoxInitCallback();
            }
            $scope.initiated = true;
        };

        $scope.setReplyRecipients = function(recipients, otherRecipients) {
            $scope.clearRecipients();

            if (recipients == "only_client") {
                var client = window.clientRecipient();

                if(client.name == '') {
                    client = window.emailSender();
                }

                $scope.tos.push(client);
                if(otherRecipients) {
                    _.each(otherRecipients, function(otherRecipient) {
                        $scope.ccs.push({name: otherRecipient});
                    });
                }
            }else {
                var presentAttendees = $scope.attendeesApp.getAttendeesWithoutThreadOwner();
                $scope.setDefaultRecipients(otherRecipients, presentAttendees);
            }

            $scope.setRecipients();
        };

        $scope.setRecipients = function() {

            $scope.sanitizeRecipients();

            _.each($scope.tos, function (recipient) {
                $toTokenNode.tokenInput("add", recipient);
            });
            _.each($scope.ccs, function (recipient) {
                $ccTokenNode.tokenInput("add", recipient);
            });
        };

        $scope.sanitizeRecipients = function() {
            // Ensure we have no emails duplicates in Tos and Ccs
            $scope.tos = _.uniq($scope.tos, function(r) {return r.name;});
            $scope.ccs = _.uniq($scope.ccs, function(r) {return r.name;});

            // Reject double already present in tos
            $scope.ccs = _.reject($scope.ccs, function(a) {
                return _.find($scope.tos, function(att) {
                    return  att.name == a.name;
                });
            });
        };

        $scope.setDefaultRecipients = function(otherRecipients, presentAttendees) {

            if(['ask_date_suggestions', 'ask_availabilities'].indexOf($scope.actionNature) > -1) {
                setDefaultRecipientsAskOrVerifyAvailabilities(presentAttendees);
            }else {
                setDefaultRecipientsOther();
            }
        };

        $scope.clearRecipients = function() {
            $scope.ccs = [];
            $scope.tos = [];

            try {
                $toTokenNode.tokenInput("clear");
                $ccTokenNode.tokenInput("clear");
            } catch(e) {
                console.log(e);
            }

        };

        function manageSingleAssistedWithAssistant(presentAttendees, otherRecipients) {

            var assistant;
            var assisted;
            assisted = _.find(presentAttendees, function(a){
                return a.assistedBy && a.assistedBy.guid;
            });

            if(assisted){
                assistant = $scope.attendeesApp.getAssistant(assisted);
            }

            if(assistant && assisted){
                setAssistantAndAssistedInRecipients(assistant, assisted);
                $scope.ccs.push(window.clientRecipient());
            }else{
                $scope.setDefaultRecipients(otherRecipients, presentAttendees);
            }
        };

        function setDefaultRecipientsAskOrVerifyAvailabilities() {

            var attendees = $scope.attendeesApp.getAttendeesWithEmailOnPresence(true);
            var partitionnedAttendeesWithThreadOwner = _.partition(attendees, function(a) {
                return a.isThreadOwner;
            });

            var threadOwner = partitionnedAttendeesWithThreadOwner[0][0];
            var attendeesWithoutThreadOwner = partitionnedAttendeesWithThreadOwner[1];
            var partitionnedAttendees = _.partition(attendeesWithoutThreadOwner, function(a) {
               return a.isClient;
            });

            var clientsAttendees = partitionnedAttendees[0];
            var nonClientAttendees = partitionnedAttendees[1];
            var partitionnedNonClientAttendees = _.partition(nonClientAttendees, function(a) {
               return a.assisted && a.assistedBy && a.assistedBy.email;
            });

            var assistedNonClientAttendees = partitionnedNonClientAttendees[0];
            var unassistedNonClientAttendees = partitionnedNonClientAttendees[1];

            $scope.tos = _.map(unassistedNonClientAttendees, function(a) {
                return {name: a.email};
            });

            $scope.tos = $scope.tos.concat(_.map(assistedNonClientAttendees, function(a) {
                return {name: a.assistedBy.email};
            }));

            $scope.ccs = _.map(clientsAttendees, function(a) {
                return {name: a.email};
            });


            $scope.ccs = $scope.ccs.concat([window.emailSender()].concat(window.initialToRecipients().concat(window.initialCcRecipients())));

            if(threadOwner.email != 'pierre-louis@juliedesk.com') {
                // We don't add the client email if we are already responding to one of its aliases
                if(_.intersection(_.map($scope.ccs, function(cc){return cc.name;}), window.threadAccount.email_aliases).length == 0) {
                    $scope.ccs.push({name: threadOwner.email});
                }
            }

            $scope.tos = _.flatten($scope.tos);
            $scope.ccs = _.flatten($scope.ccs);

            $scope.tos = _.map($scope.tos, function(a) {
                return {name: $filter('lowercase')(a.name)};
            });
            $scope.ccs = _.map($scope.ccs, function(a) {
                return {name: $filter('lowercase')(a.name)};
            });
        };

        function setDefaultRecipientsOther() {
            var clientEmails = [window.threadAccount.email].concat(window.threadAccount.email_aliases);

            $scope.tos = [window.emailSender()];
            $scope.ccs = window.initialToRecipients().concat(window.initialCcRecipients());

            $scope.tos = _.compact($scope.tos);
            $scope.ccs = _.compact($scope.ccs);

            if(window.threadAccount.email != 'pierre-louis@juliedesk.com') {

                var clientAliasInTos = _.intersection(_.map($scope.tos, function(recipient) {return recipient.name;}), clientEmails);
                var clientAliasInCcs = _.intersection(_.map($scope.ccs, function(recipient) {return recipient.name;}), clientEmails);

                if(clientAliasInTos.length == 0 && clientAliasInCcs.length == 0) {
                    $scope.ccs.push({name: window.threadAccount.email});
                } else if(clientAliasInTos.length >= 1) {
                    // If we are responding to the client, make sure we don't use one of its aliases in ccs
                    $scope.ccs = _.reject($scope.ccs, function(recipient) {
                        return clientEmails.indexOf(recipient.name) >= 0;
                    });
                }
            }
        };

        function setAssistantAndAssistedInRecipients(assistant, assisted){
            if(!!assistant.email)
                $scope.tos.push({name: assistant.email});

            if(!!assisted.email)
                $scope.ccs.push({name: assisted.email});
        };

        function initTokenInputs() {

            trackEvent("Julie_action_is_open", {
                distinct_id: $replyBoxNode.data('tracking-id'),
                thread_id: $messagesContainer.data('messages-thread-id'),
                thread_messages_count: $messagesContainer.data('messages-count'),
                bo_message_id: $replyBoxNode.data('bo-message-id'),
                action_nature: $scope.actionNature
            });

            if (window.tokenInputsInitialized) {
                return;
            }

            window.tokenInputsInitialized = true;
            $toTokenNode.tokenInput(
                window.possibleRecipients(),
                {
                    searchDelay: 0,
                    enableFreeInput: true,
                    hintText: '',
                    noResultsText: '',
                    searchingText: '',
                    animateDropdown: false,
                    prePopulate: window.initialToRecipients(),
                    preventDuplicates: true,
                    theme: 'facebook',
                    onAdd: function (item) {
                        window.toRecipientAdded(item);
                    },
                    onDelete: function (item) {
                        window.toRecipientDeleted(item);
                    }
                });
            $ccTokenNode.tokenInput(
                window.possibleRecipients(),
                {
                    searchDelay: 0,
                    enableFreeInput: true,
                    hintText: '',
                    noResultsText: '',
                    searchingText: '',
                    animateDropdown: false,
                    prePopulate: window.initialCcRecipients(),
                    preventDuplicates: true,
                    theme: 'facebook',
                    onAdd: function (item) {
                        window.ccRecipientAdded(item);
                    },
                    onDelete: function (item) {
                        window.ccRecipientDeleted(item);
                    }

                });
        };

        angular.element(document).ready(function () {

            $scope.attendeesApp = $scope.attendeesApp || angular.element($('#attendeesCtrl')).scope();

            if(!!$scope.attendeesApp) {
                $scope.attendeesApp.$on('attendeesFetched', function(attendees) {
                    $scope.init();
                });
            } else {
                $scope.init();
            }


        });
    }]);

    app.controller('replyBuilder', ['$scope', function($scope) {
        $scope.replyMessage = '';
        $scope.attendeesApp = $scope.attendeesApp || undefined;

        $scope.generateReply = function(params) {
            var notClientAttendees;
            if(params.action == 'ask_additional_informations')
                notClientAttendees = $scope.attendeesApp.getNonClientAndNonAssistantWithMissingInfosAttendees();
            else
                notClientAttendees = $scope.attendeesApp.getNonClientAndNonAssistantAttendees();

            var partitionnedAttendees = _.partition(notClientAttendees, function(a) {
                return a.assisted;
            });

            params['assistedAttendees'] = _.map(partitionnedAttendees[0], function(a) {
                return a.usageName;
            });
            params['unassistedAttendees'] = _.map(partitionnedAttendees[1], function(a) {
                return a.usageName;
            });

            $scope.replyMessage = window.generateEmailTemplate(params);

            return $scope.replyMessage;
        };

        angular.element(document).ready(function() {

            $scope.attendeesApp = $scope.attendeesApp || angular.element($('#attendeesCtrl')).scope();

        });

    }]);

})();