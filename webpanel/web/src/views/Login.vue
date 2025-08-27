<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h2>AutoScriptX WebPanel</h2>
        <p>Please login to continue</p>
      </div>
      
      <el-form 
        :model="loginForm" 
        :rules="rules" 
        ref="loginFormRef" 
        class="login-form"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginForm.username"
            placeholder="Username"
            size="large"
            :prefix-icon="User"
            clearable
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="Password"
            size="large"
            :prefix-icon="Lock"
            show-password
            clearable
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button 
            type="primary" 
            size="large" 
            :loading="loading"
            @click="handleLogin"
            class="login-button"
          >
            {{ loading ? 'Logging in...' : 'Login' }}
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="login-footer">
        <p>Default credentials: admin / admin123</p>
        <p><small>Change password after first login</small></p>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import api from '../utils/api'

export default {
  name: 'Login',
  setup() {
    const router = useRouter()
    const loading = ref(false)
    const loginFormRef = ref()
    
    const loginForm = reactive({
      username: '',
      password: ''
    })
    
    const rules = {
      username: [
        { required: true, message: 'Please enter username', trigger: 'blur' }
      ],
      password: [
        { required: true, message: 'Please enter password', trigger: 'blur' },
        { min: 3, message: 'Password must be at least 3 characters', trigger: 'blur' }
      ]
    }
    
    const handleLogin = async () => {
      if (!loginFormRef.value) return
      
      try {
        await loginFormRef.value.validate()
        loading.value = true
        
        const response = await api.post('/api/auth/login', {
          username: loginForm.username,
          password: loginForm.password
        })
        
        if (response.success) {
          // Store token and user info
          localStorage.setItem('token', response.token)
          localStorage.setItem('username', response.username)
          
          ElMessage.success(response.message || 'Login successful')
          
          // Redirect to dashboard
          router.push('/')
        } else {
          ElMessage.error(response.message || 'Login failed')
        }
      } catch (error) {
        console.error('Login error:', error)
        ElMessage.error(error.response?.data?.error || 'Login failed')
      } finally {
        loading.value = false
      }
    }
    
    return {
      loginForm,
      rules,
      loading,
      loginFormRef,
      handleLogin,
      User,
      Lock
    }
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
  padding: 40px;
  width: 100%;
  max-width: 400px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h2 {
  color: #2c3e50;
  margin-bottom: 8px;
  font-weight: 600;
}

.login-header p {
  color: #7f8c8d;
  margin: 0;
}

.login-form .el-form-item {
  margin-bottom: 20px;
}

.login-button {
  width: 100%;
  height: 45px;
  font-size: 16px;
  border-radius: 8px;
}

.login-footer {
  text-align: center;
  margin-top: 25px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.login-footer p {
  margin: 5px 0;
  color: #95a5a6;
  font-size: 14px;
}

.login-footer small {
  color: #bdc3c7;
  font-size: 12px;
}

@media (max-width: 480px) {
  .login-card {
    padding: 30px 20px;
  }
  
  .login-header h2 {
    font-size: 1.5rem;
  }
}
</style>
