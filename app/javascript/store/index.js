import Vue from 'vue/dist/vue.esm'
import VueEx from 'vuex/dist/vuex.esm'
import _ from 'lodash'

Vue.use(VueEx)

import TrackingInterfaceService from '../services/TrackingInterface.service'

export default new VueEx.Store({
    state: {
        currentOperator: null
    },
    getters: {
        currentOperator: (state) => state.currentOperator
    },
    mutations: {
        setCurrentOperator: (state, currentOperator) => state.currentOperator = currentOperator
    },
    actions: {
        track(context, trackingData) {
            return (new TrackingInterfaceService()).track(trackingData.event, _.merge(trackingData.data || {}, {
                current_operator_id: (context.getters.currentOperator || {}).id
            }))
        }
    }
})

