<template>
    <div class="message-container" :class="{minimized: minimized, validated: validated}">
        <div class="message" @click="minimized = !minimized">
            <div class="date">{{ message.date }}</div>
            <div class="from">{{ message.from }}</div>
            <div class="to">To: {{ message.to }}</div>
            <div class="cc" v-if="message.cc">Cc: {{ message.cc }}</div>

            <div v-html="message.parsed_html" class="body"></div>
        </div>
        <div class="action-button">
            <custom-checkbox
                    colors="red-green"
                    @valueChanged="checkboxChanged"
            ></custom-checkbox>

            <div class="validation-status correct" v-if="validated">Ce mail est bien anonymisé</div>
            <div class="validation-status incorrect" v-if="!validated">Ce mail est mal anonymisé</div>
            <div class="textarea-instructions" :class="{understood: error_description != ''}">
                Merci de préciser en quoi le mail est mal anonymisé ci-dessous.<br>
                Sinon, placer le curseur sur 'vert'.</div>
            <textarea rows="6" v-model="error_description"></textarea>
        </div>
    </div>
</template>
<script>
    import CustomCheckbox from '../common/CustomCheckbox.vue';

    export default {
        props: {
            'message': {

            },
            'initiallyMinimized': {
                default: false
            }
        },
        data: function() {
            return {
                validated: false,
                error_description: '',
                minimized: this.initiallyMinimized
            }
        },
        components: {
            CustomCheckbox
        },
        methods: {
            checkboxChanged: function(value) {
                console.log("checkbox changed", value);
                this.validated = value
            }
        }
    }
</script>


<style lang="scss" scoped>
    .message-container {
        border-top: 1px solid #ccc;
        position: relative;
        padding: 0 242px 0 0;
        min-height: 280px;


        .message {
            line-height: 1.0;
            position: relative;
            padding: 10px 0 10px 0;
            //border-right: 1px solid rgba(0,0,0,0.04);
            transition: border-color 0.3s;

            font-size: 14px;
            background: #fff;

            .from, .to, .cc {
                padding: 2px 130px 2px 20px;

                &.from {
                    font-weight: 600;
                }
            }

            .date {
                position: absolute;
                top: 10px;
                right: 10px;
                color: #999;
                font-size: 10px;
            }
            .body {
                padding: 20px;
            }

        }

        &.minimized {
            min-height: unset;

            .message {
                background: #f5f5f5;
                cursor: pointer;
            }


            .message .body {
                display: none;
            }
            .action-button textarea, .action-button .textarea-instructions {
                display: none;
            }
        }



        .message {
            border-right: 2px solid rgba(208,0,0, 0.3);
        }

        //background-color: rgba(208,0,0, 0.1);
        &.validated {
            .message {
                border-right: 2px solid rgba(130, 206, 48, 0.3);
            }


            .action-button textarea, .action-button .textarea-instructions {
                opacity: 0;
            }

            //background-color: rgba(130, 206, 48, 0.1);
        }

        .action-button {
            position: absolute;
            top: 0;
            right: 0;
            width: 242px;
            padding: 20px 20px;
            text-align: center;

            textarea  {
                width: 100%;
                resize: none;
                border: 1px solid rgba(0,0,0,0.2);
                border-radius: 3px;
                outline: none;
                font-size: 12px;
                padding: 5px;
                transition: opacity 0.3s;
            }
            .textarea-instructions {
                font-size: 10px;
                color: #999;
                margin: 10px 0;
                transition: opacity 0.3s;

                &.understood {
                    opacity: 0.0;
                }
            }
            .validation-status {
                font-size: 12px;
                padding: 5px 0;
                &.correct {
                    color: rgba(130, 206, 48, 0.8);
                }
                &.incorrect {
                    color: rgba(208,0,0, 0.8);
                }
            }
        }

    }


</style>
