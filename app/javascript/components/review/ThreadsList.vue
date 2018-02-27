<template>
    <div>
        <the-header
                :paths="paths"
                current-title="Anonymised threads"
        />
        <div class="row justify-content-md-center">
            <div class="col-md-8">
                <br>
                <h1>Anonymisation review</h1>
                <br>

                <table class="table table-striped">
                    <thead>
                    <tr>
                        <th>Threads</th>
                        <th>Reviewed</th>
                        <th>Errors</th>
                    </tr>
                    </thead>
                    <tbody>
                    <tr>
                        <td>{{ threads_count }}</td>
                        <td>{{ reviewed_threads_count }} ({{ reviewed_threads_count / threads_count | percentage }})</td>
                        <td>{{ incorrect_reviewed_threads_count }} ({{ incorrect_reviewed_threads_count / threads_count | percentage
                            }})
                        </td>
                    </tr>
                    </tbody>
                </table>

                <div class="text-center">
                    <button class="btn btn-success" @click="goToNextThread">Review next thread</button>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
    import TheHeader from '../common/TheHeader.vue'
    import ConscienceInterfaceService from '../../services/ConscienceInterface.service.js'

    export default {
        data() {
            return {
                paths: [
                    {label: 'Review', path: '/review'},
                ],
                threads_count: null,
                reviewed_threads_count: null,
                incorrect_reviewed_threads_count: null,
                conscienceInterfaceService: new ConscienceInterfaceService()
            }
        },
        methods: {
            goToNextThread() {
                this.conscienceInterfaceService.listAnonymisedMessagesThreads().then(data => {
                    let threadId = data.threads[0].thread_id
                    window.location = `/review/anonymised_messages_threads/${threadId}`
                })
            },
            fetch() {
                let self = this
                this.conscienceInterfaceService.getStatsAnonymisedMessagesThreads().then(data => {
                    self.threads_count = data.stats.threads_count
                    self.reviewed_threads_count = data.stats.reviewed_threads_count
                    self.incorrect_reviewed_threads_count = data.stats.incorrect_reviewed_threads_count
                })
            }
        },
        components: {
            TheHeader
        },
        created() {
            this.fetch();
        }
    }
</script>