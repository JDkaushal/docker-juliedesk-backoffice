<template>
    <div class="backoffice-header">
        <a href="/">Backoffice</a>
        <a v-for="path in paths" v-bind:href="path.path" class="sub-menu">{{ path.label }}</a>
        <span v-if="currentTitle" class="sub-menu">{{ currentTitle }}</span>

        <div v-if="actionButton" class="action-button btn btn-success btn-sm" v-on:click="clickActionButton">{{ actionButton }}</div>
    </div>
</template>

<script>
    export default {
        props: [
            'paths',
            'currentTitle',
            'actionButton'
        ],
        methods: {
            clickActionButton: function() {
                this.$emit('clickActionButton')
            }
        }
    }
</script>

<style lang="scss" scoped>
    .backoffice-header {
        height: 40px;
        background: #444;
        color: white;
        padding: 5px 20px;
        line-height: 30px;
        vertical-align: top;
        position: relative;
        z-index: 2;

        a {
            color: white;
            text-decoration: none;
            opacity: 0.9;
            &:hover {
                opacity: 1.0;
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

    }

</style>
