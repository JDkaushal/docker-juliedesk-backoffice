var AccountService = function() {

};

AccountService.prototype.checkSyncStatus = function(accountEmail) {
    $.get('/accounts/:account_email/sync_status'.replace(':account_email', accountEmail))
};