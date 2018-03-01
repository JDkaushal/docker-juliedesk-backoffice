import Vue from 'vue/dist/vue.esm'

import VueI18n from 'vue-i18n'
import Inbox from '../components/inbox/Inbox'
import VueMoment from 'vue-moment'
import moment from 'moment'
import 'moment/locale/fr'
import 'moment-timezone'

import store from '../store'



document.addEventListener('DOMContentLoaded', () => {

    let locale = 'fr';

    moment.locale(locale)
    Vue.use(VueI18n);
    Vue.use(VueMoment, {
        moment
    });



    new Vue({
        i18n: new VueI18n({locale: locale}),
        el: "#inbox-app",
        components: {
            Inbox
        },
        store: store
    })
});