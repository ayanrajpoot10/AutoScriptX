<template>
  <div v-if="$route.name === 'Login'" class="app-container">
    <router-view />
  </div>
  <el-container v-else class="app-container">
    <!-- Mobile header with hamburger menu -->
    <el-header v-if="isMobile" class="mobile-header">
      <div class="mobile-header-content">
        <div class="logo-mobile">
          <h3>🚀 AutoScriptX</h3>
        </div>
        <div class="mobile-header-actions">
          <el-dropdown @command="handleCommand">
            <span class="user-dropdown">
              <el-icon><UserFilled /></el-icon>
              {{ username }}
              <el-icon class="el-icon--right"><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="changePassword">Change Password</el-dropdown-item>
                <el-dropdown-item command="logout" divided>Logout</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <el-button 
            type="text" 
            @click="mobileMenuVisible = !mobileMenuVisible"
            class="hamburger-btn"
          >
            <el-icon size="24"><Menu /></el-icon>
          </el-button>
        </div>
      </div>
    </el-header>

    <!-- Mobile drawer menu -->
    <el-drawer
      v-if="isMobile"
      v-model="mobileMenuVisible"
      direction="ltr"
      size="280px"
      class="mobile-drawer"
    >
      <template #header>
        <div class="mobile-drawer-header">
          <h3>🚀 AutoScriptX</h3>
          <p>Web Panel</p>
        </div>
      </template>
      
      <el-menu
        :default-active="$route.path"
        router
        background-color="#2c3e50"
        text-color="#ecf0f1"
        active-text-color="#3498db"
        class="mobile-menu"
        @select="mobileMenuVisible = false"
      >
        <el-menu-item index="/">
          <el-icon><Monitor /></el-icon>
          <span>Dashboard</span>
        </el-menu-item>
        
        <el-menu-item index="/users">
          <el-icon><User /></el-icon>
          <span>SSH Users</span>
        </el-menu-item>
        
        <el-menu-item index="/services">
          <el-icon><Setting /></el-icon>
          <span>Services</span>
        </el-menu-item>
        
        <el-menu-item index="/system">
          <el-icon><Tools /></el-icon>
          <span>System</span>
        </el-menu-item>
        
        <el-menu-item index="/slowdns">
          <el-icon><Connection /></el-icon>
          <span>SlowDNS</span>
        </el-menu-item>
      </el-menu>

      <div class="mobile-actions">
        <el-button type="danger" @click="restartSystem" :loading="restarting" size="small">
          <el-icon><Refresh /></el-icon>
          Restart System
        </el-button>
      </div>
    </el-drawer>

    <!-- Desktop sidebar -->
    <el-aside v-if="!isMobile" width="250px" class="sidebar">
      <div class="logo">
        <h2>🚀 AutoScriptX</h2>
        <p>Web Panel</p>
      </div>
      
      <el-menu
        :default-active="$route.path"
        router
        background-color="#2c3e50"
        text-color="#ecf0f1"
        active-text-color="#3498db"
        class="sidebar-menu"
      >
        <el-menu-item index="/">
          <el-icon><Monitor /></el-icon>
          <span>Dashboard</span>
        </el-menu-item>
        
        <el-menu-item index="/users">
          <el-icon><User /></el-icon>
          <span>SSH Users</span>
        </el-menu-item>
        
        <el-menu-item index="/services">
          <el-icon><Setting /></el-icon>
          <span>Services</span>
        </el-menu-item>
        
        <el-menu-item index="/system">
          <el-icon><Tools /></el-icon>
          <span>System</span>
        </el-menu-item>
        
        <el-menu-item index="/slowdns">
          <el-icon><Connection /></el-icon>
          <span>SlowDNS</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    
    <el-container>
      <!-- Desktop header -->
      <el-header v-if="!isMobile" class="header">
        <div class="header-content">
          <h3>{{ getPageTitle() }}</h3>
          <div class="header-actions">
            <el-dropdown @command="handleCommand" class="user-dropdown-desktop">
              <span class="user-dropdown">
                <el-icon><UserFilled /></el-icon>
                {{ username }}
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="changePassword">Change Password</el-dropdown-item>
                  <el-dropdown-item command="logout" divided>Logout</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-button type="danger" @click="restartSystem" :loading="restarting">
              <el-icon><Refresh /></el-icon>
              Restart System
            </el-button>
          </div>
        </div>
      </el-header>
      
      <!-- Mobile page title -->
      <div v-if="isMobile" class="mobile-page-title">
        <h3>{{ getPageTitle() }}</h3>
      </div>
      
      <el-main class="main-content" :class="{ 'mobile-main': isMobile }">
        <router-view />
      </el-main>
    </el-container>

    <!-- Change Password Dialog -->
    <el-dialog v-model="passwordDialogVisible" title="Change Password" width="400px">
      <el-form :model="passwordForm" :rules="passwordRules" ref="passwordFormRef">
        <el-form-item label="New Password" prop="newPassword">
          <el-input
            v-model="passwordForm.newPassword"
            type="password"
            show-password
            placeholder="Enter new password"
          />
        </el-form-item>
        <el-form-item label="Confirm Password" prop="confirmPassword">
          <el-input
            v-model="passwordForm.confirmPassword"
            type="password"
            show-password
            placeholder="Confirm new password"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="passwordDialogVisible = false">Cancel</el-button>
        <el-button type="primary" @click="changePassword" :loading="changingPassword">
          Change Password
        </el-button>
      </template>
    </el-dialog>
  </el-container>
</template>

<script>
import { ElMessageBox, ElMessage } from 'element-plus'
import { ref, reactive } from 'vue'
import api from './utils/api'

export default {
  name: 'App',
  setup() {
    const restarting = ref(false)
    const mobileMenuVisible = ref(false)
    const isMobile = ref(false)
    const passwordDialogVisible = ref(false)
    const changingPassword = ref(false)
    const passwordFormRef = ref()
    const username = ref(localStorage.getItem('username') || 'Admin')
    
    const passwordForm = reactive({
      newPassword: '',
      confirmPassword: ''
    })
    
    const validateConfirmPassword = (rule, value, callback) => {
      if (value === '') {
        callback(new Error('Please confirm the password'))
      } else if (value !== passwordForm.newPassword) {
        callback(new Error('Passwords do not match'))
      } else {
        callback()
      }
    }
    
    const passwordRules = {
      newPassword: [
        { required: true, message: 'Please enter new password', trigger: 'blur' },
        { min: 6, message: 'Password must be at least 6 characters', trigger: 'blur' }
      ],
      confirmPassword: [
        { required: true, validator: validateConfirmPassword, trigger: 'blur' }
      ]
    }
    
    return {
      restarting,
      mobileMenuVisible,
      isMobile,
      passwordDialogVisible,
      changingPassword,
      passwordFormRef,
      username,
      passwordForm,
      passwordRules
    }
  },
  mounted() {
    this.checkIfMobile()
    window.addEventListener('resize', this.checkIfMobile)
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.checkIfMobile)
  },
  methods: {
    checkIfMobile() {
      this.isMobile = window.innerWidth <= 768
    },
    
    getPageTitle() {
      const route = this.$route
      const titleMap = {
        '/': 'System Dashboard',
        '/users': 'SSH User Management',
        '/services': 'Service Management',
        '/system': 'System Configuration',
        '/slowdns': 'SlowDNS Management'
      }
      return titleMap[route.path] || 'AutoScriptX Panel'
    },
    
    handleCommand(command) {
      if (command === 'logout') {
        this.logout()
      } else if (command === 'changePassword') {
        this.showChangePasswordDialog()
      }
    },
    
    showChangePasswordDialog() {
      this.passwordForm.newPassword = ''
      this.passwordForm.confirmPassword = ''
      this.passwordDialogVisible = true
    },
    
    async changePassword() {
      if (!this.passwordFormRef) return
      
      try {
        await this.passwordFormRef.validate()
        this.changingPassword = true
        
        await api.post('/api/auth/change-password', {
          new_password: this.passwordForm.newPassword
        })
        
        ElMessage.success('Password changed successfully')
        this.passwordDialogVisible = false
        
      } catch (error) {
        console.error('Password change error:', error)
      } finally {
        this.changingPassword = false
      }
    },
    
    logout() {
      ElMessageBox.confirm(
        'Are you sure you want to logout?',
        'Confirm Logout',
        {
          confirmButtonText: 'Logout',
          cancelButtonText: 'Cancel',
          type: 'warning',
        }
      ).then(() => {
        // Clear local storage
        localStorage.removeItem('token')
        localStorage.removeItem('username')
        
        ElMessage.success('Logged out successfully')
        
        // Redirect to login
        this.$router.push('/login')
      }).catch(() => {
        // User cancelled
      })
    },
    
    async restartSystem() {
      try {
        await ElMessageBox.confirm(
          'This will restart the entire system. Are you sure?',
          'Confirm System Restart',
          {
            confirmButtonText: 'Yes, Restart',
            cancelButtonText: 'Cancel',
            type: 'warning',
          }
        )
        
        this.restarting = true
        await api.post('/api/system/restart')
        
        ElMessage.success('System restart initiated. You will lose connection shortly.')
        
        // Show countdown message
        setTimeout(() => {
          ElMessage.info('System is restarting... Please wait a few minutes before reconnecting.')
        }, 2000)
        
      } catch (error) {
        if (error !== 'cancel') {
          ElMessage.error('Failed to restart system: ' + (error.response?.data?.error || error.message))
        }
      } finally {
        this.restarting = false
      }
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.app-container {
  height: 100vh;
  overflow: hidden;
}

/* Mobile Header */
.mobile-header {
  background-color: #2c3e50;
  border-bottom: 1px solid #34495e;
  padding: 0 15px;
  height: 60px !important;
}

.mobile-header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.mobile-header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-mobile h3 {
  color: #3498db;
  font-size: 18px;
  margin: 0;
}

.hamburger-btn {
  color: #ecf0f1 !important;
  padding: 8px;
}

.hamburger-btn:hover {
  background-color: #34495e !important;
}

/* Mobile Page Title */
.mobile-page-title {
  background-color: #f8f9fa;
  padding: 12px 16px;
  border-bottom: 1px solid #e6e6e6;
}

.mobile-page-title h3 {
  color: #2c3e50;
  font-size: 16px;
  font-weight: 600;
  margin: 0;
}

/* Mobile Drawer */
.mobile-drawer {
  background-color: #2c3e50;
}

.mobile-drawer-header {
  text-align: center;
  color: #ecf0f1;
  padding: 20px 0;
}

.mobile-drawer-header h3 {
  margin-bottom: 5px;
  color: #3498db;
  font-size: 20px;
}

.mobile-drawer-header p {
  font-size: 12px;
  opacity: 0.8;
  margin: 0;
}

.mobile-menu {
  border: none;
  background-color: #2c3e50 !important;
}

.mobile-menu .el-menu-item {
  border-radius: 0;
  margin: 0 10px;
  border-radius: 8px;
}

.mobile-menu .el-menu-item:hover {
  background-color: #34495e !important;
}

.mobile-actions {
  position: absolute;
  bottom: 20px;
  left: 20px;
  right: 20px;
}

.mobile-actions .el-button {
  width: 100%;
  font-size: 14px;
}

/* Desktop Styles */
.sidebar {
  background-color: #2c3e50;
  color: #ecf0f1;
}

.logo {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid #34495e;
  margin-bottom: 10px;
}

.logo h2 {
  margin-bottom: 5px;
  color: #3498db;
}

.logo p {
  font-size: 12px;
  opacity: 0.8;
}

.sidebar-menu {
  border: none;
}

.sidebar-menu .el-menu-item {
  border-radius: 0;
}

.header {
  background-color: #fff;
  border-bottom: 1px solid #e6e6e6;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  height: 60px !important;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.header-content h3 {
  color: #2c3e50;
  font-weight: 600;
  margin: 0;
}

.main-content {
  background-color: #f5f7fa;
  padding: 20px;
  overflow-y: auto;
  height: calc(100vh - 60px);
}

.mobile-main {
  padding: 12px;
  height: calc(100vh - 120px); /* Account for mobile header and page title */
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-dropdown {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background-color: #f8f9fa;
  border-radius: 6px;
  cursor: pointer;
  color: #2c3e50;
  font-size: 14px;
  border: 1px solid #e6e6e6;
  transition: all 0.2s ease;
}

.user-dropdown:hover {
  background-color: #e9ecef;
  border-color: #d6d9dc;
}

.user-dropdown-desktop .user-dropdown {
  background-color: #ffffff;
  border: 1px solid #d6d9dc;
}

.user-dropdown-desktop .user-dropdown:hover {
  background-color: #f8f9fa;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .main-content {
    padding: 12px;
  }
  
  /* Hide desktop elements on mobile */
  .sidebar {
    display: none;
  }
  
  .header {
    display: none;
  }
}

@media (min-width: 769px) {
  /* Hide mobile elements on desktop */
  .mobile-header,
  .mobile-page-title {
    display: none;
  }
}

/* Responsive tables */
@media (max-width: 768px) {
  .el-table {
    font-size: 12px;
  }
  
  .el-table .el-table__cell {
    padding: 8px 4px;
  }
  
  .el-button-group .el-button {
    padding: 6px 8px;
    font-size: 11px;
  }
}

/* Responsive cards */
@media (max-width: 576px) {
  .el-card {
    margin-bottom: 16px;
  }
  
  .el-card .el-card__header {
    padding: 12px 16px;
  }
  
  .el-card .el-card__body {
    padding: 12px 16px;
  }
}

/* Responsive forms */
@media (max-width: 768px) {
  .el-form-item {
    margin-bottom: 16px;
  }
  
  .el-form-item__label {
    line-height: 1.2;
    padding-bottom: 6px;
  }
}

/* Responsive dialogs */
@media (max-width: 768px) {
  .el-dialog {
    width: 95% !important;
    margin: 20px auto;
  }
  
  .el-dialog__header {
    padding: 16px 20px 12px;
  }
  
  .el-dialog__body {
    padding: 12px 20px;
  }
  
  .el-dialog__footer {
    padding: 12px 20px 16px;
  }
}

/* Responsive descriptions */
@media (max-width: 576px) {
  .el-descriptions {
    font-size: 12px;
  }
  
  .el-descriptions__label {
    font-weight: 600;
  }
}

/* Responsive stats */
@media (max-width: 576px) {
  .stat-info h3 {
    font-size: 14px;
  }
  
  .stat-info p {
    font-size: 11px;
  }
  
  .stat-icon {
    width: 40px !important;
    height: 40px !important;
    margin-right: 12px !important;
  }
}
</style>
