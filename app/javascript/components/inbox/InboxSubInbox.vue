<template>
    <div v-if="messagesThreads.length > 0">
        <div class="category-title">{{ name }}</div>
        <div class="messages-threads-container">
            <div v-for="messagesThread in messagesThreads"
                 :key="messagesThread.id">
                <inbox-sub-inbox-thread-item :messagesThread="messagesThread"/>
            </div>
        </div>
    </div>
</template>

<script>
    import InboxSubInboxThreadItem from "./InboxSubInboxThreadItem";

    export default {
        props: {
            messagesThreads: {
                type: Array
            },
            name: {
                type: String
            }
        },
        components: {
            InboxSubInboxThreadItem
        }
    }
</script>

<style lang="scss" scoped>
    .category-title {
        color: #aaa;
        padding: 5px 0 10px 0;
        font-size: 18px;
        font-weight: 400;
    }

    .messages-threads-container {
        margin: 0px 0 60px 0;
        border-top: 1px solid #ccc;
    }

</style>