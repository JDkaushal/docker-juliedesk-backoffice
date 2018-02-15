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
                        <td>{{ errored_reviewed_threads_count }} ({{ errored_reviewed_threads_count / threads_count | percentage
                            }})
                        </td>
                    </tr>
                    </tbody>
                </table>

                <div class="text-center">
                    <button class="btn btn-success" @click="goToThreadsPairs">Thread pairs</button>
                    <button class="btn btn-primary" @click="goToThreadsImpairs">Thread impairs</button>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
    import TheHeader from '../common/TheHeader.vue'

    export default {
        data() {
            return {
                paths: [
                    {label: 'Review', path: '/review'},
                ],
                threads_count: 2371,
                reviewed_threads_count: 237,
                errored_reviewed_threads_count: 2
            }
        },
        methods: {
            goToThreadsPairs: function () {
                window.location = "/review/anonymised_messages_threads/489574"
            },
            goToThreadsImpairs: function () {
                window.location = "/review/anonymised_messages_threads/486444"
            }
        },
        components: {
            TheHeader
        }
    }
</script>
