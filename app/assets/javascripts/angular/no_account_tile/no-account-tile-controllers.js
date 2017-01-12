(function () {
    var clientAccountTileApp = angular.module('no-account-tile-controllers', []);

    clientAccountTileApp.controller("no-account-tile-controller", ['$scope', '$interval', '$http', '$timeout', function ($scope, $interval, $http, $timeout) {
        $scope.accountIsAllowed = false;
        $scope.accountChangeTooltipMessage = "L'adresse email du client n'apparait pas dans le thread";
        $scope.accountsCandidates = [];
        $scope.searchTerm = '';

        $scope.accountsAutocompleteSource = window.accountsAutocompleteSource;
        $scope.threadToMerge = window.threadToMerge;

        $scope.inJulieAction = !!window.classification;

        $scope.$watch('searchTerm', function(newVal, oldVal) {
            if(newVal != oldVal) {
                $scope.filterAccountsCandidates();
            }
        });

        $scope.$watch(function($scope) {
            return $scope.accountsCandidates.map(function(obj) {
                return obj.highlighted
            });
        }, function (newVal) {
            $scope.canAssociate();
        }, true);
        
        $scope.init = function() {
            $scope.initiateAccountsCandidates();

            // if($scope.accountsAutocompleteSource.length == 0 && !$scope.inJulieAction) {
            //     $scope.clickOnNotEnoughInfos();
            // }
        };

        $scope.initiateAccountsCandidates = function() {
            $scope.filterAccountsCandidates();
        };

        $scope.filterAccountsCandidates = function() {
            $scope.resetHighlight();

            if($scope.searchTerm == '') {
                $scope.accountsCandidates = _.filter(window.accountsAutocompleteSource, function(source) { return source.email_alias === undefined; });
            } else {
                var currentSearchTerm = $scope.searchTerm.toLowerCase();

                $scope.accountsCandidates = _.union(
                    _.filter(window.accountsAutocompleteSource, function (contact) {
                        return (
                                (contact.name || '').toLowerCase().indexOf(currentSearchTerm) > -1 ||
                                (contact.email || '').toLowerCase().indexOf(currentSearchTerm) > -1 ||
                                (contact.company || '').toLowerCase().indexOf(currentSearchTerm) > -1
                            ) &&
                            contact.email_alias == null;
                    }),
                    _.filter(window.accountsAutocompleteSource, function (contact) {
                        return contact.email_alias &&
                            (contact.name || '').toLowerCase().indexOf(currentSearchTerm) == -1 &&
                            (contact.email || '').toLowerCase().indexOf(currentSearchTerm) == -1 &&
                            (contact.company || '').toLowerCase().indexOf(currentSearchTerm) == -1 &&
                            contact.email_alias.toLowerCase().indexOf(currentSearchTerm) > -1;
                    })
                );
            }
        };

        $scope.canAssociate = function() {
            var currentlyHighlightedCandidate = $scope.getHighlightedCandidate();
            $scope.accountIsAllowed = currentlyHighlightedCandidate && currentlyHighlightedCandidate.email && currentlyHighlightedCandidate.email.length > 0;
        };

        $scope.isNewAccountAllowed = function(accountEmail) {
            return window.allowedAccountsEmails.indexOf(accountEmail) > -1;
        };

        $scope.clickOnAssociate = function() {
            var currentlyHighlightedCandidate = $scope.getHighlightedCandidate();

            if(currentlyHighlightedCandidate && currentlyHighlightedCandidate.email) {
                $http.post("/messages_threads/" +  window.threadId + "/associate_to_account", JSON.stringify({
                    account_email: currentlyHighlightedCandidate.email
                })).then(function(response) {
                    window.location = window.location;
                }, function(error) {
                    console.log(error);
                });
            } else {
                alert('Choose an account');
            }
        };

        $scope.clickOnMergeThread = function() {
            var threadMergingPanel = $('#merging-panel').scope();

            threadMergingPanel.queryTags = [{text: $scope.accountsAutocompleteSource[0].email}];
            threadMergingPanel.$apply();

            $('.merge-into-thread-button').click();
        };

        $scope.clickOnNotEnoughInfos = function() {
            window.location = '/messages/' + $('.email').last().data('message-id') + '/classifying/unknown?started_at=' + window.startedAt + '&default_template=Demander%20quel%20est%20le%20client%20concerné';
        };

        $scope.getHighlightedCandidate = function() {
            return _.find($scope.accountsCandidates, function(candidate) {
                return candidate.highlighted;
            })
        };

        $scope.resetHighlight = function() {
            _.each($scope.accountsCandidates, function(c) { c.highlighted = false; });
        };

        $scope.highlightCandidate = function(candidate) {
            $scope.resetHighlight();
            candidate.highlighted = true;
        };

        $scope.init();
    }]);

    // function setupAutocompleteAssociateAccount() {
    //     var $changeAccountInput = $('#account-email-input');
    //
    //     $("#account-email-input").autocomplete({
    //         source: function (request, callback) {
    //             var candidates = _.union(
    //                 _.filter(window.accountsAutocompleteSource, function (contact) {
    //                     return (
    //                             contact.name.toLowerCase().indexOf(request.term.toLowerCase()) > -1 ||
    //                             contact.email.toLowerCase().indexOf(request.term.toLowerCase()) > -1 ||
    //                             contact.company.toLowerCase().indexOf(request.term.toLowerCase()) > -1
    //                         ) &&
    //                         contact.email_alias == null;
    //                 }),
    //                 _.filter(window.accountsAutocompleteSource, function (contact) {
    //                     return contact.email_alias &&
    //                         contact.email.toLowerCase().indexOf(request.term.toLowerCase()) == -1 &&
    //                         contact.name.toLowerCase().indexOf(request.term.toLowerCase()) == -1 &&
    //                         contact.company.toLowerCase().indexOf(request.term.toLowerCase()) == -1 &&
    //                         contact.email_alias.toLowerCase().indexOf(request.term.toLowerCase()) > -1;
    //                 })
    //             );
    //
    //             if(candidates.length == 0) {
    //                 candidates = [{emptyNode: true}];
    //             }
    //
    //             callback(candidates);
    //         },
    //         focus: function (event, ui) {
    //             $changeAccountInput.val(ui.item.email);
    //             window.noAccountTilesScope.newAccountEmail = ui.item.email;
    //             window.noAccountTilesScope.checkNewAccountValidity(ui.item.email);
    //             window.noAccountTilesScope.$apply();
    //             return false;
    //         },
    //         select: function (event, ui) {
    //             $changeAccountInput.val(ui.item.email);
    //             window.noAccountTilesScope.newAccountEmail = ui.item.email;
    //             window.noAccountTilesScope.checkNewAccountValidity(ui.item.email);
    //             window.noAccountTilesScope.$apply();
    //             return false;
    //         },
    //         delay: 0,
    //         minLength: 0
    //     }).data("ui-autocomplete")._renderItem = function (ul, item) {
    //         var html = $("<li>");
    //
    //         if(item.emptyNode) {
    //             html.addClass("contact-autocomplete-empty")
    //                 .append($("<div>").addClass("contact-autocomplete-name").html('Pas de résultats'))
    //         } else {
    //             html.addClass("contact-autocomplete-item")
    //                 .data("item.autocomplete", item)
    //                 .append($("<div>").addClass("contact-autocomplete-name").html(item.name))
    //                 .append($("<div>").addClass("contact-autocomplete-email").html(item.email))
    //                 .append($("<div>").addClass("contact-autocomplete-company").html(item.company))
    //                 .append($("<div>").addClass("contact-autocomplete-email-alias").html(item.email_alias));
    //         }
    //
    //         return html
    //             .appendTo(ul);
    //     };
    // };

})();


