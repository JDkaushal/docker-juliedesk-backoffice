<template>
    <div class="header">
        <a href="/">Backoffice <span class="tenant-tag" :class="tenant | cssClassyize">{{ tenant | humanize | capitalize }}</span></a>
        <a v-for="path in paths"
           :href="path.path"
           class="sub-menu">{{ path.label }}</a>
        <span v-if="currentTitle"
              class="sub-menu">{{ currentTitle }}</span>

        <div v-if="actionButton"
             class="action-button btn btn-success btn-sm"
             @click="clickActionButton">{{ actionButton }}</div>
        <div class="training-env" v-if="currentOperator.privilege == 'super_operator_level_T'">
            <span class="">Training Environment</span></div>

        <div class="session-container" v-if="currentOperator">
            <a class="current-user-name"
               href="/review/operators/my_stats">{{ currentOperator.name }} <span class="notification" v-if="currentOperator.requests_to_learn_count">{{ currentOperator.requests_to_learn_count }}</span></a>
            <a href="/logout">
                <span class="logout-button fas fa-sign-out-alt"/>
            </a>
        </div>
    </div>
</template>

<script>
    export default {
        props: [
            'paths',
            'currentTitle',
            'actionButton',
            'currentOperator'
        ],
        data() {
            return {
                tenant: process.env.SPECIFIC_TENANT || "common"
            }
        },
        methods: {
            clickActionButton() {
                this.$emit('clickActionButton')
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
    * {
        box-sizing: border-box;
    }
    .header {
        height: 40px;
        background: #fff;
        color: #444;
        padding: 5px 20px;
        line-height: 30px;
        vertical-align: top;
        position: relative;
        z-index: 2;
        box-shadow: 0 0 20px rgba(0,0,0,0.2);

        a {
            color: #444;
            text-decoration: none;
            opacity: 0.9;
            outline: none;
            &:hover {
                opacity: 1.0;
            }

            .tenant-tag {
                padding: 5px;
                border-radius: 4px;
                color: white;

                &.common {
                    background: #6199da;
                }

                &.ey {
                    background: #ffad00;
                }

                &.sg {
                    background: #ff003a;
                }
            }
        }

        .sub-menu {
            font-size: 14px;

            &::before {
                content: "►";
                padding: 0 20px;
                opacity: 0.2;
            }

        }
        .action-button {
            position: absolute;
            top: 4px;
            right: 20px;
        }

        .session-container {
            float: right;
            font-size: 12px;

            .current-user-name {
                display: inline-block;

                .notification {
                    background: #ff2e2e;
                    color: white;
                    padding: 0 5px;
                    font-size: 8px;
                    border-radius: 20px;
                    line-height: 16px;
                    display: inline-block;
                    vertical-align: text-bottom;
                }
            }
            .logout-button {
                display: inline-block;
                font-size: 18px;
                margin: 0 0 0 10px;
                vertical-align: text-top;
            }
        }
        .training-env{
            display: inline-flex;
            background-color: #9c7e97;
            color: white;
            //display: flex;
            justify-content: center;
            width:87%;
        }

    }

</style>
