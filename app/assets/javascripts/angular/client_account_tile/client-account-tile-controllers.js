(function () {
    var clientAccountTileApp = angular.module('client-account-tile-app', []);

    clientAccountTileApp.controller("client-account-tile-controller", ['$scope', '$interval', '$http', function ($scope, $interval, $http) {
        $scope.changeAccountLoading = false;
        $scope.processAccount = function (account) {
            account.infoExtended = false;

            account.creation_distance_days = moment().diff(moment(account.created_at), 'days');

            account.setCurrentTime = function () {
                var thisAccount = this;
                thisAccount.currentTime = moment().tz(thisAccount.default_timezone_id).format("ddd, MMM d, HH:mm:ss") + " (" + thisAccount.default_timezone_id.split("/")[1].replace("_", " ") + ")";
            };


            account.isMain = window.threadAccount.email == account.email;

            account.setCurrentTime();
            $interval(function() {
                account.setCurrentTime();
            }, 1000);
        };

        $scope.changeMainAccount = function () {
            $scope.changeAccountLoading = true;

            $http.post("/messages_threads/" + window.threadId + "/associate_to_account", {
                account_email: $scope.newAccountEmail
            }).then(function successCallback(response) {
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
            _.each(window.otherAccountEmails, function(otherAccountEmail) {
                $.get("/accounts?email=" + otherAccountEmail).then(function (response) {
                    var account = response.data.account;
                    $scope.processAccount(account);
                    $scope.accounts.push(account);

                }, function (response) {
                    console.log("Error while getting account " + otherAccountEmail + " : " + response.message)
                });
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
                    angular.element($("#change-account-input")[0]).scope().newAccountEmail = ui.item.email;
                    return false;
                },
                select: function (event, ui) {
                    $("#change-account-input").val(ui.item.email);
                    angular.element($("#change-account-input")[0]).scope().newAccountEmail = ui.item.email;
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


