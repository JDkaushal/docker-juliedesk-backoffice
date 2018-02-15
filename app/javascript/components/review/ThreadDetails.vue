<template>
    <div>
        <the-header
                :paths="paths"
                :current-title="'Thread ' + this.messagesThreadId"
                action-button="Next"
                @clickActionButton="validate"
        />

        <div class="min-1200">

            <div class="subject">{{ messagesThread.subject }}</div>
            <div class="emails">
                <email v-for="message in messagesThread.messages"
                        :message="message"
                        :initiallyMinimized="true"
                ></email>
            </div>
        </div>
    </div>
</template>

<script>
    import TheHeader from '../common/TheHeader'
    import Email from '../common/Email.vue'
    import EmailServerInterfaceService from '../../services/EmailServerInterface.service.js'

    export default {
        props: ['messagesThreadId'],
        data() {
            return {
                emailServerInterfaceService: new EmailServerInterfaceService(),
                paths: [
                    {label: 'Review', path: '/review'},
                    {label: 'Anonymised threads', path: '/review/anonymised_messages_threads'}
                ],
                messagesThread: {
                    subject: "Michelle McIntyre",
                    messages: []
                }
            }
        },
        methods: {
            validate () {
                window.location = "/review/anonymised_messages_threads"
            },
            fetch () {
                let self = this;
                this.emailServerInterfaceService.getMessagesThread(this.messagesThreadId).then(function(messagesThread) {
                    self.messagesThread = messagesThread;
                });
            }

        },
        components: {
            TheHeader,
            Email
        },
        created() {
            this.fetch()
        }
    }
</script>

<style lang="scss" scoped>
    .subject {
        font-size: 20px;
        padding: 20px 0 30px 0;
    }
    .emails {
        border-bottom: 1px solid #ddd;
    }
    .min-1200 {
        width: 1200px;
        margin: 0 auto;
        padding: 0 20px;
    }
</style>
