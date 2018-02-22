<i18n>
{
    "en": {
        "unknown_account": "Unknown account",
        "being_processed_by": "Being processed by {operator_name}",
        "today": "today",
        "n_requests_today": "1 request today | {count} requests today",
        "n_days": "1 day | {count} days"
    },
    "fr": {
        "unknown_account": "Compte non-identifié",
        "being_processed_by": "En cours de traitement par {operator_name}",
        "today": "Aujourd'hui",
        "n_requests_today": "1 requête aujourd'hui | {count} requêtes aujourd'hui",
        "n_days": "1 jour | {count} jours"
    }
}
</i18n>

<template>
    <div class="messages-thread-container">
        <a :href="'/messages_threads/' + messagesThread.id"
           class="messages-thread-item">
            <div class="messages-thread-lock-container"
                 v-if="messagesThread.locked_by_operator_id">
                <span class="locked-by-name">{{ $t('being_processed_by', {operator_name: messagesThread.locked_by_operator_name}) }}</span>
            </div>

            <div class="first-row">

                <span class="scheduled-for-today"
                     v-if="scheduledForToday">
                    <span class="fas fa-calendar"></span> {{ $t('today') }}
                </span>

                <div class="account-email">
                    <span v-if="messagesThread.account"
                          key="account-present">{{ messagesThread.account.full_name || messagesThread.account.email }}</span>
                    <span v-else
                          key="account-present">{{ $t('unknown_account') }}</span>
                </div>

                <div class="thread-label account-life-duration"
                     :class="'priority' + accountLifeDurationPriority"
                     v-if="messagesThread.account && messagesThread.account.current_life_duration_in_days && accountLifeDurationPriority < 4 && accountLifeDurationPriority <= todayRequestsCountPriority">
                    {{  $tc('n_days', messagesThread.account.current_life_duration_in_days, {count: messagesThread.account.current_life_duration_in_days}) }}
                </div>

                <div class="thread-label requests-count-for-today"
                     :class="'priority' + todayRequestsCountPriority"
                     v-if="messagesThread.account && messagesThread.account.threads_count_today && todayRequestsCountPriority < 4 && todayRequestsCountPriority <= accountLifeDurationPriority">
                    {{ $tc('n_requests_today', messagesThread.account.threads_count_today, {count: messagesThread.account.threads_count_today}) }}
                </div>

                <div class="thread-label thread-status"
                     :class="messagesThreadStatus | cssClassyize">{{ messagesThreadStatus | humanize | capitalize }}
                </div>

            </div>

            <div class="received-at">{{ messagesThread.request_date || '2020-01-01' | moment("from", "now") }}</div>

            <div class="subject-and-snippet">
                <div class="subject">{{ messagesThread.subject }}</div>
                <div class="snippet"> - {{ messagesThread.snippet}}</div>
            </div>


            <div v-if="mainTag"
                 class="tag-container">
                <div class="tag"
                     :class="mainTag.cssClass">
                    <span class="fas fa-code-branch"
                          v-if="mainTag.name === 'to_be_merged'"></span>
                    <span class="delegation-text">{{ mainTag.description }}</span>
                </div>
            </div>
        </a>
    </div>
</template>

<script>
    import InboxTagManagerService from '../../services/InboxTagManager.service'

    export default {
        props: {
            messagesThread: {
                type: Object
            }
        },
        computed: {
            messagesThreadStatus() {
                return this.messagesThread.status || 'new_request'
            },
            mainTag() {
                return InboxTagManagerService.sortedTags(this.messagesThread)[0];
            },
            accountLifeDurationPriority() {
                let accountLifeDurationInDays = this.messagesThread.account.current_life_duration_in_days;

                if (accountLifeDurationInDays <= 2) {
                    return 1;
                }
                else if (accountLifeDurationInDays <= 31) {
                    return 2;
                }
                else if (accountLifeDurationInDays <= 2 * 31) {
                    return 3;
                }
                else {
                    return 4;
                }
            },
            todayRequestsCountPriority() {
                let threadsCountToday = this.messagesThread.account.threads_count_today;

                if (threadsCountToday === 1) {
                    return 2;
                }
                else if (threadsCountToday === 2) {
                    return 3;
                }
                else {
                    return 4;
                }
            },
            scheduledForToday() {
                let self = this
                return this.messagesThread.status === 'scheduled' &&
                    this.messagesThread.event_booked_date &&
                    self.$moment(this.messagesThread.event_booked_date).isSame(self.$moment().tz('UTC').format(), 'd')
            }
        },
        filters: {
            humanize(str) {
                return str.split("_").join(" ")
            },
            capitalize(str) {
                return str.charAt(0).toUpperCase() + str.slice(1)
            },
            cssClassyize(str) {
                return str.split("_").join("-")
            }
        }
    }

</script>

<style lang="scss" scoped>
    .messages-thread-item {
        text-align: left;
        height: 50px;
        line-height: 30px;
        border-bottom: 1px solid #ccc;
        background: #f5f5f5;
        padding: 4px 10px;
        display: block;
        color: black;
        text-decoration: none;
        font-size: 13px;
        position: relative;
        box-sizing: border-box;

        .first-row {
            position: relative;
            top: -3px;
            display: inline-block;
        }

        .messages-thread-lock-container {
            display: block;
            position: absolute;
            top: 0px;
            left: 0;
            bottom: 1px;
            right: 0px;
            background-color: rgba(255, 255, 255, 0.90);
            text-align: center;
            z-index: 2;
            color: #666;;
            line-height: 50px;
            font-size: 14px;
            font-weight: 600;
        }

        .scheduled-for-today {
            color: #FA5555;
            font-style: italic;
            padding: 0 10px 0 0;
        }

        .account-email {
            display: inline-block;
            height: 40px;
            font-size: 14px;
            color: #797979;
            font-weight: bold;
        }

        .priority1 {
            background-color: #FA5555;
        }

        .priority2 {
            background-color: #FF712F;
        }

        .priority3 {
            background-color: #0099CC;
        }


        .thread-label {
            color: white;
            display: inline-block;
            padding-left: 5px;
            padding-right: 5px;
            border-radius: 5px;
            line-height: 18px;
            font-size: 12px;
            position: relative;
            top: -2px;
        }

        .thread-status {

            &.scheduling-waiting-for-client {
                background-color: rgba(196, 157, 93, 0.65);
            }

            &.scheduling-waiting-for-contact {
                background-color: rgba(196, 157, 93, 0.65);
            }

            &.scheduled {
                background-color: rgba(73, 201, 169, 0.66);
            }

            &.scheduling-aborted {
                background-color: rgba(200, 110, 110, 0.65);
            }

            &.does-not-concern-client {
                background-color: rgba(180, 180, 180, 0.65);
            }

            &.handled-in-other-threads {
                background-color: rgba(128, 109, 144, 0.66);
            }

            &.events-creation {
                background-color: rgba(122, 110, 99, 0.65);
            }

            &.new-request {
                background-color: rgba(245, 166, 35, 0.65);
            }

            &.other {
                background-color: rgba(180, 180, 180, 0.66);
            }
        }

        .subject-and-snippet {
            position: absolute;
            overflow: hidden;
            height: 30px;
            top: 20px;
            left: 10px;
            font-size: 14px;
            font-weight: 400;

            .subject {
                display: inline;
            }

            .snippet {
                display: inline;
                font-weight: 200;
            }
        }

        .tag-container {
            position: absolute;
            top: 20px;
            left: -105px;
            height: 18px;
            width: 100px;
            line-height: 16px;
            text-align: right;

            .tag {
                display: inline-block;
                padding: 1px 5px;
                border-radius: 4px;
                font-size: 12px;
                color: white;
                background: #0099CC;

                &.danger {
                    background-color: #CF3E3E;
                }

                &.warning {
                    background-color: #F19165;
                }
            }
        }

        .received-at {
            text-align: right;
            width: 150px;
            height: 40px;
            overflow: hidden;
            position: absolute;
            top: 0;
            right: 10px;
            font-size: 12px;
            font-weight: 400;
            color: #999;
        }


        &:hover {
            background: #f2f2f2;
        }

    }
</style>