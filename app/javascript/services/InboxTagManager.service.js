// Tags Manager is responsible for computing the right Tag for a given messages thread

// A Tag is composed of 3 attributes (atm) :
 // - name
 // - text_to_display
 // - css_class

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
const CONFIGURATION_NEEDED_TAG = 'configuration_needed';
const SYNCING_TAG = 'syncing';

const THREAD_TAGS = [ADMIN_TAG, SYNCING_TAG, MULTI_CLIENT_TAG, TO_MERGE_TAG, SUPPORT_TAG, CALENDAR_ACCESS_EXPIRED_TAG];
const ACCOUNT_TAGS = [ADMIN_ONLY_TAG, VIP_TAG, TOKEN_EXPIRED_TAG, CONFIGURATION_NEEDED_TAG];

const TAGS_DEFINITIONS = {};

TAGS_DEFINITIONS[ADMIN_TAG] = {
    priority: 1,
    description: 'Admin',
    cssClass: 'danger'
};
TAGS_DEFINITIONS[CALENDAR_ACCESS_EXPIRED_TAG] = {
    priority: 2,
    description: 'Lost Access',
    cssClass: 'danger'
};
TAGS_DEFINITIONS[SYNCING_TAG] = {
    priority: 3,
    description: 'Syncing...',
    cssClass: 'danger'
};
TAGS_DEFINITIONS[CONFIGURATION_NEEDED_TAG]= {
    priority: 4,
    description: 'Configuration Needed',
    cssClass: 'warning'
};
TAGS_DEFINITIONS[ADMIN_ONLY_TAG] = {
    priority: 5,
    description: 'Admin only',
    cssClass: 'standard'
};
TAGS_DEFINITIONS[TOKEN_EXPIRED_TAG] = {
    priority: 6,
    description: 'Token Expired',
    cssClass: 'standard'
};
TAGS_DEFINITIONS[TO_MERGE_TAG] = {
    priority: 7,
    description: 'To merge',
    cssClass: 'warning'
};
TAGS_DEFINITIONS[MULTI_CLIENT_TAG] = {
    priority: 8,
    description: 'Multi clients',
    cssClass: 'standard'
};
TAGS_DEFINITIONS[VIP_TAG] = {
    priority: 9,
    description: 'VIP',
    cssClass: 'standard'
};
TAGS_DEFINITIONS[SUPPORT_TAG]  = {
    priority: 10,
    description: 'Support',
    cssClass: 'standard'
};
TAGS_DEFINITIONS[UNKNOWN_CLIENT_TAG]  = {
    priority: 11,
    description: 'Unknown client',
    cssClass: 'standard'
};

class Tag {
    constructor(params) {
        this.name = params.name;
        this.description = TAGS_DEFINITIONS[this.name].description;
        this.cssClass = TAGS_DEFINITIONS[this.name].cssClass;
        this.priority = TAGS_DEFINITIONS[this.name].priority;
    }
}

class InboxTagsManagerService {

    static sortedTags(messagesThread) {
        let tags = [];

        _.each(THREAD_TAGS, function(tag) {
            if(messagesThread[tag] || (messagesThread.tags && messagesThread.tags.indexOf(tag) > -1)) {
                tags.push(new Tag({name: tag}));
            }
        });

        if(messagesThread.account) {
            _.each(ACCOUNT_TAGS, function(tag) {
                if(messagesThread.account[tag]) {
                    tags.push(new Tag({name: tag}));
                }
            });
        } else {
            tags.push(new Tag({name: UNKNOWN_CLIENT_TAG}));
        }

        return _.sortBy(tags, tag =>  tag.priority)
    }
}

export default InboxTagsManagerService