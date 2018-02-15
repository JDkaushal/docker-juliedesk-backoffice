<i18n>
{
    "en": {
        "message": "Your system time is not correct, please fix it. Please visit <a href='{correct_time_link}' target='_blank'>{correct_time_link}</a> to get the correct time, and <a href='{backoffice_home_link}'>reload the page</a>."
    },
    "fr": {
        "message": "L'horloge de votre système est incorrecte. merci d'y remédier. Visitez <a href='{correct_time_link}' target='_blank'>{correct_time_link}</a> pour obtenir l'heure correcte, et <a href='{backoffice_home_link}'>recharger la page</a>."
    }
}
</i18n>

<template>
    <div class="wrong-clock"
         v-if="showWrongClock"
         v-html="$t('message', {correct_time_link: 'http://time.is', backoffice_home_link: '/'})"/>
</template>

<script>

    export default {
        props: {
            serverDate: {
                type: Number
            },
            clientDate: {
                type: Number
            }
        },
        computed: {
            showWrongClock() {
                return this.clientDate &&
                    this.serverDate && (
                        this.clientDate > this.serverDate + 20 ||
                        this.clientDate < this.serverDate - 20
                    )
            }
        }
    }
</script>

<style lang="scss" scoped>
    .wrong-clock {
        position: fixed;
        z-index: 10;
        text-align: center;
        background-color: rgba(255, 255, 255, 0.8);
        padding: 200px 30%;
        font-size: 18px;
        top: 40px;
        left: 0;
        right: 0;
        bottom: 0;
    }
</style>