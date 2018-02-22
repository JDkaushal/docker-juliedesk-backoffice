/* eslint no-console: 0 */
// Run this example by adding <%= javascript_pack_tag 'hello_vue' %> (and
// <%= stylesheet_pack_tag 'hello_vue' %> if you have styles in your component)
// to the head of your layout file,
// like app/views/layouts/application.html.erb.
// All it does is render <div>Hello Vue</div> at the bottom of the page.

import Vue from 'vue/dist/vue.esm'
import BackofficeHeader from '../components/common/BackofficeHeader.vue'

import ThreadsList from '../components/review/ThreadsList.vue'
import ThreadDetails from '../components/review/ThreadDetails.vue'

Vue.filter('percentage', function (value) {
    return Math.round(value * 100, 2) + '%';
});

document.addEventListener('DOMContentLoaded', () => {
  new Vue({
      el: "#vue-review-app",
      components: {
          BackofficeHeader,

          ThreadsList,
          ThreadDetails
      }
  })
});