(function () {
    var clientAccountTileApp = angular.module('client-account-tile-app', []);

    clientAccountTileApp.controller("client-account-tile-controller", ['$scope', '$interval', '$http', '$timeout', function ($scope, $interval, $http, $timeout) {
        $scope.changeAccountLoading = false;
        $scope.julieCanWorkNow = true;
        $scope.newAccountEmail = null;
        $scope.accountChangeTooltipMessage = '';
        $scope.accountIsAllowed = false;

        var $changeAccountButton = $('.change-account-button');
        var $changeAccountInput = $('#change-account-input');

        $scope.processAccount = function (account) {
            account.infoExtended = false;

            account.creation_distance_days = moment().diff(moment(account.created_at), 'days');

            account.setCurrentTime = function () {
                var thisAccount = this;
                thisAccount.currentTime = moment().tz(thisAccount.default_timezone_id).format("ddd, MMM D, HH:mm:ss") + " (" + thisAccount.default_timezone_id.split("/")[1].replace("_", " ") + ")";
            };

            account.hasMeetingRooms = function() {
                return this.addresses.filter(function(address) {
                    return !!address.meeting_rooms_enabled;
                }).length > 0
            };


            account.has_meeting_rooms = account.hasMeetingRooms();
            account.isMain = window.threadAccount.email == account.email;

            account.displayDetails = account.configured && account.subscribed;

            if(account.isMain) {
                $scope.julieCanWorkNow = $scope.canJulieWorkNowForAccount(account);
            }

            account.setCurrentTime();
            $interval(function() {
                account.setCurrentTime();
            }, 1000);

            // To refresh allowed attendees with eventual emails present in their current notes
            // Now done in backend
            // Used as fallback for retrocompatibility purposes
            if(window.addAllowedAttendeesEmailsFromCurrentNotes && allowedAttendeesAreComputed && !allowedAttendeesAreComputed()) {
                window.addAllowedAttendeesEmailsFromCurrentNotes(account.current_notes);
                window.addAllowedAttendeesEmailsFromCurrentNotes(account.awaiting_current_notes);
            }
        };

        $scope.$watch('accountIsAllowed', function(newVal, oldVal) {
            if(!newVal) {
                $scope.accountChangeTooltipMessage = "L'adresse email du client n'apparait pas dans le thread";
            }
        });

        $scope.checkNewAccountValidity = function() {
            $scope.accountIsAllowed = $scope.isNewAccountAllowed($changeAccountInput.val());
        };

        $scope.isNewAccountAllowed = function(accountEmail) {
          return window.allowedAccountsEmails.indexOf(accountEmail) > -1;
        };

        $scope.canJulieWorkNowForAccount = function(mainAccount) {
            if(mainAccount.company_hash) {
                var mDate = moment().tz(mainAccount.company_hash.timezone);
                var localizedDayString = mDate.format("ddd").toLowerCase();
                var workingHours = mainAccount.company_hash.working_hours[localizedDayString];
                if(workingHours) {
                    var hourInteger = parseInt(mDate.format("HHmm"), 10);
                    return _.some(workingHours, function(workingHourArray) {
                        var minHour = parseInt(workingHourArray[0], 10);
                        var maxHour = parseInt(workingHourArray[1], 10);
                        return (minHour <= hourInteger && hourInteger <= maxHour);
                    });
                }
                else {
                    return false;
                }
            }
            else {
                return true;
            }
        };

        $scope.changeMainAccount = function () {
            $scope.changeAccountLoading = true;

            $http.post("/messages_threads/" + window.threadId + "/associate_to_account", {
                account_email: $scope.newAccountEmail
            }, {withCredentials: true}).then(function successCallback(response) {
                    window.location = window.location;
                }, function errorCallback(response) {
                    window.location = window.location;
                }
            );

        };

        $scope.initiateChangeAccount = function() {
            $scope.changingAccount = true;
        };



        $scope.accounts = [window.threadAccount];
        $scope.changingAccount = $scope.accounts.length == 0;
        _.each($scope.accounts, function(account) {
            $scope.processAccount(account);
        });

        $scope.fetchOtherAccounts = function() {
            var otherAccountsCount = window.otherAccountEmails.length;
            var accountsFetchedCount = 0;

            if(otherAccountsCount > 0) {
                _.each(window.otherAccountEmails, function(otherAccountEmail) {
                    $.get("/accounts?email=" + otherAccountEmail).then(function (response) {
                        accountsFetchedCount++;
                        var account = response.data.account;
                        $scope.processAccount(account);
                        $scope.accounts.push(account);

                        if(accountsFetchedCount >= otherAccountsCount) {
                            $scope.broadcastAllAccountsFetched();
                        }
                    }, function (response) {
                        console.log("Error while getting account " + otherAccountEmail + " : " + response.message)
                    });
                });
            } else {
                $scope.broadcastAllAccountsFetched();
            }

        };

        $scope.broadcastAllAccountsFetched = function() {
            $scope.$broadcast('allAccountsFetched', {accounts: $scope.accounts});
        };

        $scope.computeAccountGender = function(account) {
            var result = '';

            if(account.gender) {
                result = localize("gender_reference.account_tile." + account.gender);
            }

            return result;
        };

        $scope.computeAccountDisplayName = function(account) {
            return [$scope.computeAccountGender(account), account.full_name].join(' ');
        };

        $scope.getAccount = function(accountEmail) {
          return _.find($scope.accounts, function(account) {
            return account.email === accountEmail;
          });
        };
    }]);

    $(function () {
        var setupAutocompleteAssociateAccount = function () {

            $("#change-account-input").autocomplete({
                source: function (request, callback) {
                    callback(_.union(
                        _.filter(window.accountsAutocompleteSource, function (contact) {
                            return (
                                    contact.name.toLowerCase().indexOf(request.term.toLowerCase()) > -1 ||
                                    contact.email.toLowerCase().indexOf(request.term.toLowerCase()) > -1 ||
                                    contact.company.toLowerCase().indexOf(request.term.toLowerCase()) > -1
                                ) &&
                                contact.email_alias == null;
                        }),
                        _.filter(window.accountsAutocompleteSource, function (contact) {
                            return contact.email_alias &&
                                contact.email.toLowerCase().indexOf(request.term.toLowerCase()) == -1 &&
                                contact.name.toLowerCase().indexOf(request.term.toLowerCase()) == -1 &&
                                contact.company.toLowerCase().indexOf(request.term.toLowerCase()) == -1 &&
                                contact.email_alias.toLowerCase().indexOf(request.term.toLowerCase()) > -1;
                        })
                    ));
                },
                focus: function (event, ui) {
                    $("#change-account-input").val(ui.item.email);
                    window.clientAccountTilesScope.newAccountEmail = ui.item.email;
                    window.clientAccountTilesScope.checkNewAccountValidity(ui.item.email);
                    return false;
                },
                select: function (event, ui) {
                    $("#change-account-input").val(ui.item.email);
                    window.clientAccountTilesScope.newAccountEmail = ui.item.email;
                    window.clientAccountTilesScope.checkNewAccountValidity(ui.item.email);
                    return false;
                },
                delay: 0,
                minLength: 0
            }).data("ui-autocomplete")._renderItem = function (ul, item) {
                return $("<li>")
                    .addClass("contact-autocomplete-item")
                    .data("item.autocomplete", item)
                    .append($("<div>").addClass("contact-autocomplete-name").html(item.name))
                    .append($("<div>").addClass("contact-autocomplete-email").html(item.email))
                    .append($("<div>").addClass("contact-autocomplete-company").html(item.company))
                    .append($("<div>").addClass("contact-autocomplete-email-alias").html(item.email_alias))
                    .appendTo(ul);
            };
        };
        setupAutocompleteAssociateAccount();
    })
})();


