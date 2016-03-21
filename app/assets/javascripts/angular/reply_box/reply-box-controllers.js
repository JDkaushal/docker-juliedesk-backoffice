(function(){

    var app = angular.module('reply-box-controllers', []);

    app.controller('recipientsManager', ['$scope', '$filter', function($scope, $filter) {
        $scope.attendeesApp = $scope.attendeesApp || undefined;
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
            setDefaultRecipientsOther();

            if(window.afterReplyBoxInitCallback){
                window.afterReplyBoxInitCallback();
            }
        };

        $scope.setReplyRecipients = function(recipients, otherRecipients) {
            $scope.clearRecipients();

            if (recipients == "only_client") {
                $scope.tos.push(window.clientRecipient());
                if(otherRecipients) {
                    _.each(otherRecipients, function(otherRecipient) {
                        $scope.ccs.push({name: otherRecipient});
                    });
                }
            }else {
                var presentAttendees = $scope.attendeesApp.getAttendeesWithoutThreadOwner();
                // When there are 2 attendees, we will check if it is an assistant and its assisted
                if(presentAttendees.length == 2){
                    manageSingleAssistedWithAssistant(presentAttendees, otherRecipients);
                }else{
                    $scope.setDefaultRecipients(otherRecipients, presentAttendees);
                }
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

            $toTokenNode.tokenInput("clear");
            $ccTokenNode.tokenInput("clear");
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

            var attendees = $scope.attendeesApp.getAttendeesOnPresence(true);
            var partitionnedAttendeesWithThreadOwner = _.partition(attendees, function(a) {
                return a.isThreadOwner;
            });

            var threadOwner = partitionnedAttendeesWithThreadOwner[0][0];
            var attendeesWIthoutThreadOwner = partitionnedAttendeesWithThreadOwner[1];
            var partitionnedAttendees = _.partition(attendeesWIthoutThreadOwner, function(a) {
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
            $scope.ccs.push({name: threadOwner.email});

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
            $scope.tos = [window.emailSender()];
            $scope.ccs = [{name: window.threadAccount.email}].concat(window.initialToRecipients().concat(window.initialCcRecipients()));
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

            $scope.attendeesApp.$on('attendeesFetched', function(attendees) {
                $scope.init();
            });

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