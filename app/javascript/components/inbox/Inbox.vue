<i18n>
{
    "en": {
        "inbox_names": {
            "priority": "Priority",
            "priority_follow_up": "Priority follow-up",
            "main": "Main",
            "to_process_later": "To process later",
            "follow_up": "Follow-up"
        }
    },
    "fr": {
        "inbox_names": {
            "priority": "Prioritaire",
            "priority_follow_up": "Relance prioritaire",
            "main": "Principale",
            "to_process_later": "A traiter plus tard",
            "follow_up": "A relancer"
        }
    }
}
</i18n>

<template>

    <div>
        <the-header :current-operator="currentOperator"/>
        <div class="inbox">

            <inbox-wrong-clock
                    :serverDate="lastCallServerDate"
                    :clientDate="lastCallClientDate"/>

            <inbox-operator-greetings :operator="currentOperator"/>

            <div class="spinner-container">
                <span class="fas fa-spinner fa-spin"
                     v-if="backofficeInterfaceService.loading"/>
            </div>

            <inbox-empty-message v-if="allMessagesThreads.length === 0 && !backofficeInterfaceService.loading"/>

            <inbox-sub-inbox :name="$t('inbox_names.priority')"
                             :messagesThreads="priorityMessagesThreads"/>

            <inbox-sub-inbox :name="$t('inbox_names.priority_follow_up')"
                             :messagesThreads="priorityToFollowUpMessagesThreads"/>

            <inbox-sub-inbox :name="$t('inbox_names.main')"
                             :messagesThreads="messagesThreads"/>

            <inbox-sub-inbox :name="$t('inbox_names.to_process_later')"
                             :messagesThreads="toProcessLaterMessagesThreads"/>

            <inbox-sub-inbox :name="$t('inbox_names.follow_up')"
                             :messagesThreads="normalToFollowUpmessagesThreads"/>
        </div>
    </div>
</template>

<script>
    import TheHeader from '../common/TheHeader'
    import InboxOperatorGreetings from './InboxOperatorGreetings'
    import InboxEmptyMessage from './InboxEmptyMessage'
    import InboxSubInbox from './InboxSubInbox'
    import InboxWrongClock from "./InboxWrongClock"

    import BackofficeInterfaceService from '../../services/BackofficeInterface.service'
    import RedsockClient from '../../services/RedsockClient'


    export default {
        data() {
            return {
                allMessagesThreads: [],
                backofficeInterfaceService: new BackofficeInterfaceService(),
                currentOperator: {},
                redsockClient: null,
                lastCallServerDate: null,
                lastCallClientDate: null,
                lockedThreadsData: []
            }
        },
        computed: {
            priorityMessagesThreads() {
                return _.filter(this.allMessagesThreads, messagesThread => messagesThread.sortedInboxTags === 'priority');
            },
            priorityToFollowUpMessagesThreads() {
                return _.filter(this.allMessagesThreads, messagesThread => messagesThread.sortedInboxTags === 'follow_up|priority');
            },
            messagesThreads() {
                return _.filter(this.allMessagesThreads, messagesThread => messagesThread.sortedInboxTags === '');
            },
            toProcessLaterMessagesThreads() {
                return _.filter(this.allMessagesThreads, messagesThread => messagesThread.sortedInboxTags.indexOf('to_process_later') > -1);
            },
            normalToFollowUpmessagesThreads() {
                return _.filter(this.allMessagesThreads, messagesThread => messagesThread.sortedInboxTags === 'follow_up');
            }
        },
        methods: {
            updateLockStatuses() {
                let self = this;
                _.each(this.allMessagesThreads, (messageThread) => {
                    let threadToLock = _.find(self.lockedThreadsData, (lockedThread) => lockedThread.threadId == messageThread.id);
                    messageThread.locked_by_operator_id = threadToLock ? threadToLock.operatorIdentifier : null;
                    messageThread.locked_by_operator_name = threadToLock ? threadToLock.operatorName : null;
                })
            },
            setupRedsock() {
                console.log("Setup redsock");
                return;
                let self = this;
                this.redsockClient = new RedsockClient({
                    url: process.env.RED_SOCK_URL,
                    member_id: this.currentOperator.id,
                    member_name: this.currentOperator.name,
                    member_email: this.currentOperator.email
                });

                this.redsockClient.subscribeToChannel('lockedThreads');
                this.redsockClient.bindMessage('lockedThreads', 'subscription_success', (data) => {
                    self.lockedThreadsData = data;
                    self.updateLockStatuses();
                });

                this.redsockClient.bindMessage('lockedThreads', 'update', (data) => {
                    self.lockedThreadsData = data;
                    self.updateLockStatuses();
                });

                this.redsockClient.subscribeToChannel('presence-global');
                this.redsockClient.subscribeToChannel('private-global-chat');
                this.redsockClient.bindMessage('private-global-chat', 'archive', () => self.refreshInbox());
                this.redsockClient.bindMessage('private-global-chat', 'new-email', () => self.refreshInbox());
            },
            computeMessageThreadsSortedInboxTags(messagesThreads) {
                return _.map(messagesThreads, messagesThread => {
                    let inboxTags = [];
                    if(messagesThread.should_follow_up && !messagesThread.in_inbox) {
                        inboxTags.push("follow_up")
                    }
                    if(messagesThread.account && messagesThread.account.have_priority) {
                        inboxTags.push("priority")
                    }
                    if(!messagesThread.can_be_processed_now) {
                        inboxTags.push("to_process_later")
                    }
                    messagesThread.sortedInboxTags = _.sortBy(inboxTags).join('|');
                    return messagesThread;
                });
            },
            refreshInbox() {
                let self = this;
                return this.backofficeInterfaceService.listMessagesThreads().then(function (response) {
                    self.allMessagesThreads = self.computeMessageThreadsSortedInboxTags(response.data);
                    self.currentOperator = response.current_operator;
                    self.lastCallServerDate = response.date;
                    self.lastCallClientDate = parseInt(self.$moment().format("X"), 10);
                    self.updateLockStatuses();
                });
            }
        },
        components: {
            TheHeader,
            InboxWrongClock,
            InboxOperatorGreetings,
            InboxEmptyMessage,
            InboxSubInbox
        },
        created() {
            let self = this;
            this.refreshInbox().then(function() {
                self.$store.commit('setCurrentOperator', self.currentOperator)
                self.setupRedsock()
                self.$store.dispatch('track', {event: 'Home_is_open'})
            });
        }
    }
</script>

<style lang="scss">
    @import url('https://fonts.googleapis.com/css?family=Open+Sans:300,400');
    @import url('https://use.fontawesome.com/releases/v5.0.6/css/all.css');

    body, html {
        padding: 0;
        margin: 0;
    }

    * {
        font-family: 'Open Sans', sans-serif;
    }

    .spinner-container {
        height: 24px;
        text-align: center;
        font-size: 24px;
        color: #999;
    }


    .inbox {
        padding: 0 100px;
    }

</style>