<i18n>
{
    "en": {
        "nothing_to_do": "Nothing to process for now!"
    },
    "fr": {
        "nothing_to_do": "Rien à traiter pour l'instant !"
    }
}
</i18n>

<template>
    <div class="action-to-do-container">
        <div class="nothing-to-do">
            <span class="fas fa-smile smiley"/>
            <div>{{ $t('nothing_to_do') }}</div>
        </div>
    </div>
</template>

<script>
    export default {

    }
</script>

<style lang="scss" scoped>
    .nothing-to-do {
        text-align: center;
        font-size: 20px;
        font-weight: 400;
        color: #ccc;

        .smiley {
            font-size: 120px;
            color: #7bec85;
            margin: 40px 0 20px 0;
        }
    }
</style>