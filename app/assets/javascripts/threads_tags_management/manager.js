// Tags Manager is responsible for computing the right Tag for a given messages thread

// A Tag is composed of 3 attributes (atm) :
 // - name
 // - text_to_display
 // - css_class

var TagsManager = (function() {
    const ADMIN_TAG = 'sent_to_admin';
    const ADMIN_ONLY_TAG = 'only_admin_can_process';
    const MULTI_CLIENT_TAG = 'is_multi_clients';
    // Legacy Code SUPPORT_TAG
    const SUPPORT_TAG = 'delegated_to_support';
    const UNKNOWN_CLIENT_TAG = 'unknown_client';
    const VIP_TAG = 'only_support_can_process';
    const TO_MERGE_TAG = 'to_be_merged';
    const TOKEN_EXPIRED_TAG = 'office_365_refresh_token_expired';
    const CALENDAR_ACCESS_EXPIRED_TAG = 'thread_blocked';

    const THREAD_TAGS = [ADMIN_TAG, MULTI_CLIENT_TAG, TO_MERGE_TAG, SUPPORT_TAG, CALENDAR_ACCESS_EXPIRED_TAG];
    const ACCOUNT_TAGS = [ADMIN_ONLY_TAG, VIP_TAG, TOKEN_EXPIRED_TAG];

    const TAGS_PRIORITY = {};

    TAGS_PRIORITY[CALENDAR_ACCESS_EXPIRED_TAG] = 1;
    TAGS_PRIORITY[ADMIN_TAG] = 1;
    TAGS_PRIORITY[ADMIN_ONLY_TAG] = 2;
    TAGS_PRIORITY[TOKEN_EXPIRED_TAG] = 3;
    TAGS_PRIORITY[TO_MERGE_TAG] = 4;
    TAGS_PRIORITY[MULTI_CLIENT_TAG] = 5;
    TAGS_PRIORITY[VIP_TAG] = 6;
    TAGS_PRIORITY[SUPPORT_TAG] = 7;

    var Tag = function(params) {

        var that = this;
        that.name = params.name;
        that.textToDisplay = '';
        that.cssClass = '';
        that.priority = 1;

        that.computeText = function() {
            switch(that.name) {
                case ADMIN_TAG:
                    that.textToDisplay = 'Admin';
                    break;
                case ADMIN_ONLY_TAG:
                    that.textToDisplay = 'Admin Only';
                    break;
                case MULTI_CLIENT_TAG:
                    that.textToDisplay = 'Multi clients';
                    break;
                // Legacy Code SUPPORT_TAG
                case SUPPORT_TAG:
                    that.textToDisplay = 'Support';
                    break;
                case UNKNOWN_CLIENT_TAG:
                    that.textToDisplay = 'Unknown Client';
                    break;
                case TO_MERGE_TAG:
                    that.textToDisplay = 'To merge';
                    break;
                case TOKEN_EXPIRED_TAG:
                    that.textToDisplay = 'Token Expired';
                    break;
                case VIP_TAG:
                    that.textToDisplay = 'VIP';
                    break;
                case CALENDAR_ACCESS_EXPIRED_TAG:
                    that.textToDisplay = 'Lost Access';
                    break;
            }
        };

        that.computeCssClass = function() {
            that.cssClass = that.name;
        };

        that.computeTagInfos = function() {
            that.computeText();
            that.computeCssClass();
            that.computePriority();
        };

        that.computePriority = function() {
            that.priority = TAGS_PRIORITY[that.name];
        };

        that.computeTagInfos();

      return {
        name: that.name,
        textToDisplay: that.textToDisplay,
        cssClass: that.cssClass,
        priority: that.priority
      };
    };

    var instance;

    function init() {

        function handleThread(messagesThread) {
            messagesThread.tags = determineTags(messagesThread);

            return messagesThread;
        }

        function determineTags(messagesThread) {
            var tags = [];

            if(messagesThread.account) {
                _.each(THREAD_TAGS, function(tag) {
                    if(messagesThread[tag]) {
                        tags.push(new Tag({name: tag}));
                    }
                });

                _.each(ACCOUNT_TAGS, function(tag) {
                    if(messagesThread.account[tag]) {
                        tags.push(new Tag({name: tag}));
                    }
                });
            } else {
                tags.push(new Tag({name: UNKNOWN_CLIENT_TAG}));
            }

            return _.sortBy(tags, function(tag) {return tag.priority;});
        }

        return {
            handleThread: function(messagesThread) {
                return handleThread(messagesThread);
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