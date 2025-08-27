import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'
import Users from '../views/Users.vue'
import Services from '../views/Services.vue'
import System from '../views/System.vue'
import SlowDNS from '../views/SlowDNS.vue'
import Login from '../views/Login.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: Dashboard,
    meta: { requiresAuth: true }
  },
  {
    path: '/users',
    name: 'Users',
    component: Users,
    meta: { requiresAuth: true }
  },
  {
    path: '/services',
    name: 'Services',
    component: Services,
    meta: { requiresAuth: true }
  },
  {
    path: '/system',
    name: 'System',
    component: System,
    meta: { requiresAuth: true }
  },
  {
    path: '/slowdns',
    name: 'SlowDNS',
    component: SlowDNS,
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Authentication guard
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  const requiresAuth = to.meta.requiresAuth !== false

  if (requiresAuth && !token) {
    // Redirect to login if authentication required but no token
    next('/login')
  } else if (to.path === '/login' && token) {
    // Redirect to dashboard if already logged in and trying to access login
    next('/')
  } else {
    next()
  }
})

export default router
