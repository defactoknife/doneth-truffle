import Vue from 'vue'
import Router from 'vue-router'
import Home from '@/components/Home'
import Contract from '@/components/Contract'
import Deploy from '@/components/Deploy'

Vue.use(Router)

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'Home',
      component: Home
    },
    {
      path: '/deploy',
      name: 'Deploy',
      component: Deploy
    },
    {
      path: '/:address',
      name: 'Contract',
      component: Contract,
      props: true
    }
  ]
})
