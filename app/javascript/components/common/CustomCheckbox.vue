<template>
    <div class="custom-checkbox" @click="changeValue"  v-bind:class="{active: value, 'red-green': colors == 'red-green'}">
        <div class="background"></div>
        <div class="tick"></div>
    </div>
</template>
<script>
    export default {
        props: {
            initialValue: {
                type: Boolean,
                default: false
            },
            colors: {
                type: String,
                default: ''
            }
        },
        data: function() {
            return {
                value: this.initialValue,
            }
        },
        methods: {
            changeValue: function() {
                this.value = !this.value;
                this.$emit("valueChanged", this.value);
            }
        }
    }
</script>


<style lang="scss" scoped>
    .custom-checkbox {
        width: 42px;
        height: 24px;
        display: inline-block;
        vertical-align: middle;
        border-radius: 12px;
        border: 2px solid rgba(102, 102, 102, 0.4);
        position: relative;
        cursor: pointer;
        transition: border-color 0.3s;



        .tick {
            position: absolute;
            border-radius: 8px;
            width: 16px;
            height: 16px;
            background-color: rgba(102, 102, 102, 1.0);
            top: 2px;
            left: 2px;
            transition: left 0.2s, background-color 0.3s;
        }

        &.active {
            border-color: rgba(51, 172, 230, 0.4);

            .tick {
                left: 20px;
                background-color: rgba(51, 172, 230, 1.0);
            }
        }

        &.red-green {
            border-color: rgba(208,0,0, 0.4);
            .tick {
                background-color: rgba(208,0,0, 1.0);
            }
            &.active {
                border-color: rgba(130, 206, 48, 0.4);
                .tick {
                    background-color: rgba(130, 206, 48, 1.0);
                }
            }
        }
    }
</style>
