import axios from 'axios'
import { ElMessage } from 'element-plus'

// Create axios instance
const api = axios.create({
  timeout: 30000,
})

// Request interceptor
api.interceptors.request.use(
  config => {
    // Add authentication token if available
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    const message = error.response?.data?.error || error.message || 'Unknown error'
    
    // Handle authentication errors
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('username')
      // Redirect to login if not already there
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
      return Promise.reject(error)
    }
    
    ElMessage.error(message)
    return Promise.reject(error)
  }
)

export default api
