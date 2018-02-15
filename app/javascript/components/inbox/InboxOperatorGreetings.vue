<i18n>
{
    "en": {
        "hello_message": "Hey {operator_name}, I hope you are having a good day!",
        "volume_message": "You have dealt with <span class='metric'>{today_requests}</span> requests today, making <span class='metric'>{customers_count}</span> happy customers.",
        "productivity_message": "Your average productivity per hour today is <span class='metric'>{productivity}</span>."
    },
    "fr": {
        "hello_message": "Salut {operator_name}, j'espère que tu passes une bonne journée !",
        "volume_message": "Tu as géré <span class='metric'>{today_requests}</span> requêtes aujourd'hui, rendant <span class='metric'>{customers_count}</span> clients heureux.",
        "productivity_message": "Ta productivité moyenne par jour est de <span class='metric'>{productivity}</span>."
    }
}
</i18n>

<template>
    <div class="operator-greetings" v-if="operator">
        <p v-html="$t('hello_message', {operator_name: operator.name})"/>
        <p v-html="$t('volume_message', {today_requests: operatorDailyStats.requests_handled_today_count, customers_count: operatorDailyStats.happy_customer_count})"/>
        <p v-html="$t('productivity_message', {productivity: operatorDailyStats.productivity_per_hour_today })"/>
    </div>
</template>

<script>
    export default {
        props: {
            operator: {
                type: Object
            }
        },
        computed: {
            operatorDailyStats() {
                return this.operator ? (this.operator.daily_stats || {}) : {};
            }
        }
    }
</script>

<style lang="scss">
    .operator-greetings {
        width: 780px;
        margin: 20px auto 20px auto;

        text-align: center;
        font-size: 16px;
        font-weight: 200;
        line-height: 22px;
        color: #aaa;

        p {
            margin: 0;
        }

        .metric {
            font-size: 20px;
            font-weight: 800;
            color: #666;
        }
    }
</style>