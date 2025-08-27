<template>
  <div class="users-page">
    <div class="page-header" :class="{ 'mobile-header': isMobile }">
      <el-button type="primary" @click="showCreateDialog = true" :size="isMobile ? 'small' : 'default'">
        <el-icon><Plus /></el-icon>
        <span v-if="!isMobile">Create User</span>
      </el-button>
      <el-button @click="loadUsers" :size="isMobile ? 'small' : 'default'">
        <el-icon><Refresh /></el-icon>
        <span v-if="!isMobile">Refresh</span>
      </el-button>
      <el-button type="warning" @click="cleanExpiredUsers" :size="isMobile ? 'small' : 'default'">
        <el-icon><Delete /></el-icon>
        <span v-if="!isMobile">Clean Expired</span>
      </el-button>
    </div>

    <el-card>
      <!-- Desktop Table -->
      <el-table 
        v-if="!isMobile" 
        :data="users" 
        v-loading="loading" 
        stripe
      >
        <el-table-column prop="username" label="Username" min-width="120" />
        <el-table-column label="Status" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.is_active ? 'success' : 'danger'" size="small">
              {{ scope.row.is_active ? 'Active' : 'Locked' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Expires At" min-width="150">
          <template #default="scope">
            <span v-if="scope.row.expires_at">
              {{ formatDate(scope.row.expires_at) }}
            </span>
            <span v-else>Never</span>
          </template>
        </el-table-column>
        <el-table-column label="Days Left" width="100">
          <template #default="scope">
            <el-tag 
              :type="getDaysLeftType(scope.row)" 
              size="small"
              v-if="scope.row.expires_at"
            >
              {{ getDaysLeft(scope.row.expires_at) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Actions" width="300" fixed="right">
          <template #default="scope">
            <el-button-group>
              <el-button 
                size="small" 
                :type="scope.row.is_active ? 'warning' : 'success'"
                @click="toggleUserLock(scope.row)"
              >
                {{ scope.row.is_active ? 'Lock' : 'Unlock' }}
              </el-button>
              <el-button size="small" @click="showRenewDialog(scope.row)">
                Renew
              </el-button>
              <el-button 
                size="small" 
                type="danger" 
                @click="deleteUser(scope.row.username)"
              >
                Delete
              </el-button>
              <el-button 
                size="small" 
                type="info" 
                @click="showConnectionInfo(scope.row)"
              >
                Info
              </el-button>
            </el-button-group>
          </template>
        </el-table-column>
      </el-table>

      <!-- Mobile Cards -->
      <div v-else v-loading="loading" class="mobile-users">
        <div 
          v-for="user in users" 
          :key="user.username" 
          class="user-card"
        >
          <div class="user-header">
            <h4 class="username">{{ user.username }}</h4>
            <el-tag :type="user.is_active ? 'success' : 'danger'" size="small">
              {{ user.is_active ? 'Active' : 'Locked' }}
            </el-tag>
          </div>
          
          <div class="user-info">
            <div class="info-row">
              <span class="label">Expires:</span>
              <span>{{ user.expires_at ? formatDate(user.expires_at) : 'Never' }}</span>
            </div>
            <div class="info-row" v-if="user.expires_at">
              <span class="label">Days Left:</span>
              <el-tag :type="getDaysLeftType(user)" size="small">
                {{ getDaysLeft(user.expires_at) }}
              </el-tag>
            </div>
          </div>

          <div class="user-actions">
            <el-button 
              size="small" 
              :type="user.is_active ? 'warning' : 'success'"
              @click="toggleUserLock(user)"
            >
              {{ user.is_active ? 'Lock' : 'Unlock' }}
            </el-button>
            <el-button size="small" @click="showRenewDialog(user)">
              Renew
            </el-button>
            <el-button 
              size="small" 
              type="danger" 
              @click="deleteUser(user.username)"
            >
              Delete
            </el-button>
            <el-button 
              size="small" 
              type="info" 
              @click="showConnectionInfo(user)"
            >
              Info
            </el-button>
          </div>
        </div>
      </div>
    </el-card>

    <!-- Create User Dialog -->
    <el-dialog 
      v-model="showCreateDialog" 
      title="Create SSH User" 
      :width="isMobile ? '95%' : '500px'"
      :style="isMobile ? 'margin-top: 5vh' : ''"
    >
      <el-form 
        :model="createForm" 
        :rules="createRules" 
        ref="createFormRef" 
        :label-width="isMobile ? '100px' : '120px'"
        :label-position="isMobile ? 'top' : 'right'"
      >
        <el-form-item label="Username" prop="username">
          <el-input v-model="createForm.username" placeholder="Enter username" />
        </el-form-item>
        <el-form-item label="Password" prop="password">
          <el-input 
            v-model="createForm.password" 
            type="password" 
            placeholder="Enter password"
            show-password 
          />
        </el-form-item>
        <el-form-item label="Expire Days" prop="expire_days">
          <el-input-number 
            v-model="createForm.expire_days" 
            :min="1" 
            :max="365" 
            placeholder="Days until expiration"
          />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="showCreateDialog = false" :size="isMobile ? 'small' : 'default'">
          Cancel
        </el-button>
        <el-button 
          type="primary" 
          @click="createUser" 
          :loading="creating"
          :size="isMobile ? 'small' : 'default'"
        >
          Create User
        </el-button>
      </template>
    </el-dialog>

    <!-- Renew User Dialog -->
    <el-dialog 
      v-model="showRenewDialog" 
      title="Renew User" 
      :width="isMobile ? '95%' : '400px'"
      :style="isMobile ? 'margin-top: 5vh' : ''"
    >
      <el-form 
        :model="renewForm" 
        :label-width="isMobile ? '80px' : '100px'"
        :label-position="isMobile ? 'top' : 'right'"
      >
        <el-form-item label="Username">
          <el-input v-model="renewForm.username" readonly />
        </el-form-item>
        <el-form-item label="Days">
          <el-input-number v-model="renewForm.days" :min="1" :max="365" />
        </el-form-item>
      </el-form>
      
      <template #footer>
        <el-button @click="showRenewDialog = false" :size="isMobile ? 'small' : 'default'">
          Cancel
        </el-button>
        <el-button 
          type="primary" 
          @click="renewUser" 
          :loading="renewing"
          :size="isMobile ? 'small' : 'default'"
        >
          Renew
        </el-button>
      </template>
    </el-dialog>

    <!-- Connection Info Dialog -->
    <el-dialog 
      v-model="showInfoDialog" 
      title="Connection Information" 
      :width="isMobile ? '95%' : '600px'"
      :style="isMobile ? 'margin-top: 5vh' : ''"
    >
      <div v-if="connectionInfo">
        <el-descriptions :column="isMobile ? 1 : 2" border>
          <el-descriptions-item label="Domain">{{ connectionInfo.domain }}</el-descriptions-item>
          <el-descriptions-item label="Public IP">{{ connectionInfo.public_ip }}</el-descriptions-item>
          <el-descriptions-item label="SSH WS">{{ connectionInfo.ports.ssh_ws }}</el-descriptions-item>
          <el-descriptions-item label="SSH SSL WS">{{ connectionInfo.ports.ssh_ssl_ws }}</el-descriptions-item>
          <el-descriptions-item label="SQUID">{{ connectionInfo.ports.squid }}</el-descriptions-item>
          <el-descriptions-item label="UDPGW">{{ connectionInfo.ports.udpgw.join(', ') }}</el-descriptions-item>
        </el-descriptions>

        <h4 style="margin: 20px 0 10px 0;">Payloads</h4>
        
        <el-card class="payload-card">
          <template #header>WSS Payload</template>
          <el-input 
            type="textarea" 
            :model-value="connectionInfo.payloads.wss"
            readonly
            :rows="isMobile ? 2 : 3"
          />
        </el-card>
        
        <el-card class="payload-card">
          <template #header>WS Payload</template>
          <el-input 
            type="textarea" 
            :model-value="connectionInfo.payloads.ws"
            readonly
            :rows="isMobile ? 2 : 3"
          />
        </el-card>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../utils/api'

export default {
  name: 'Users',
  data() {
    return {
      users: [],
      loading: false,
      creating: false,
      renewing: false,
      showCreateDialog: false,
      showRenewDialog: false,
      showInfoDialog: false,
      connectionInfo: null,
      createForm: {
        username: '',
        password: '',
        expire_days: 30
      },
      renewForm: {
        username: '',
        days: 30
      },
      createRules: {
        username: [
          { required: true, message: 'Username is required', trigger: 'blur' },
          { min: 3, message: 'Username must be at least 3 characters', trigger: 'blur' }
        ],
        password: [
          { required: true, message: 'Password is required', trigger: 'blur' },
          { min: 6, message: 'Password must be at least 6 characters', trigger: 'blur' }
        ],
        expire_days: [
          { required: true, message: 'Expire days is required', trigger: 'blur' }
        ]
      }
    }
  },
  mounted() {
    this.loadUsers()
    this.loadConnectionInfo()
  },
  computed: {
    isMobile() {
      return window.innerWidth <= 768
    }
  },
  methods: {
    async loadUsers() {
      try {
        this.loading = true
        this.users = await api.get('/api/users')
      } catch (error) {
        console.error('Failed to load users:', error)
      } finally {
        this.loading = false
      }
    },

    async loadConnectionInfo() {
      try {
        this.connectionInfo = await api.get('/api/users/connection-info')
      } catch (error) {
        console.error('Failed to load connection info:', error)
      }
    },

    async createUser() {
      try {
        await this.$refs.createFormRef.validate()
        this.creating = true
        
        await api.post('/api/users', this.createForm)
        
        ElMessage.success('User created successfully')
        this.showCreateDialog = false
        this.createForm = { username: '', password: '', expire_days: 30 }
        this.loadUsers()
      } catch (error) {
        console.error('Failed to create user:', error)
      } finally {
        this.creating = false
      }
    },

    async deleteUser(username) {
      try {
        await ElMessageBox.confirm(
          `Are you sure you want to delete user "${username}"?`,
          'Confirm Delete',
          {
            confirmButtonText: 'Delete',
            cancelButtonText: 'Cancel',
            type: 'warning',
          }
        )

        await api.delete(`/api/users/${username}`)
        ElMessage.success('User deleted successfully')
        this.loadUsers()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Failed to delete user:', error)
        }
      }
    },

    async toggleUserLock(user) {
      try {
        const action = user.is_active ? 'lock' : 'unlock'
        await api.post(`/api/users/${user.username}/${action}`)
        
        ElMessage.success(`User ${action}ed successfully`)
        this.loadUsers()
      } catch (error) {
        console.error(`Failed to ${action} user:`, error)
      }
    },

    showRenewDialog(user) {
      this.renewForm.username = user.username
      this.showRenewDialog = true
    },

    async renewUser() {
      try {
        this.renewing = true
        await api.post(`/api/users/${this.renewForm.username}/renew`, {
          days: this.renewForm.days
        })
        
        ElMessage.success('User renewed successfully')
        this.showRenewDialog = false
        this.loadUsers()
      } catch (error) {
        console.error('Failed to renew user:', error)
      } finally {
        this.renewing = false
      }
    },

    showConnectionInfo() {
      this.showInfoDialog = true
    },

    async cleanExpiredUsers() {
      try {
        await ElMessageBox.confirm(
          'This will delete all expired user accounts. Are you sure?',
          'Confirm Clean Expired Users',
          {
            confirmButtonText: 'Clean',
            cancelButtonText: 'Cancel',
            type: 'warning',
          }
        )

        await api.post('/api/users/clean-expired')
        ElMessage.success('Expired users cleaned successfully')
        this.loadUsers()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Failed to clean expired users:', error)
        }
      }
    },

    formatDate(dateString) {
      if (!dateString) return 'Never'
      return new Date(dateString).toLocaleDateString()
    },

    getDaysLeft(expiresAt) {
      if (!expiresAt) return 'Never'
      const now = new Date()
      const expiry = new Date(expiresAt)
      const diffTime = expiry - now
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      return diffDays > 0 ? `${diffDays} days` : 'Expired'
    },

    getDaysLeftType(user) {
      if (!user.expires_at) return 'info'
      const days = this.getDaysLeft(user.expires_at)
      if (days === 'Expired') return 'danger'
      const numDays = parseInt(days)
      if (numDays <= 3) return 'danger'
      if (numDays <= 7) return 'warning'
      return 'success'
    }
  }
}
</script>

<style scoped>
.users-page {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.mobile-header {
  gap: 8px;
}

.mobile-users {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.user-card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  background-color: #fff;
  transition: box-shadow 0.3s;
}

.user-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.user-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.username {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.user-info {
  margin-bottom: 16px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.info-row:last-child {
  margin-bottom: 0;
}

.label {
  font-size: 13px;
  color: #666;
  font-weight: 500;
}

.user-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.payload-card {
  margin-bottom: 15px;
}

.payload-card:last-child {
  margin-bottom: 0;
}

/* Mobile responsive adjustments */
@media (max-width: 768px) {
  .page-header {
    margin-bottom: 16px;
  }
  
  .mobile-users {
    gap: 12px;
  }
  
  .user-card {
    padding: 12px;
  }
  
  .user-actions {
    gap: 6px;
  }
  
  .username {
    font-size: 15px;
  }
  
  .info-row {
    margin-bottom: 6px;
  }
  
  .label {
    font-size: 12px;
  }
}

/* Extra small devices */
@media (max-width: 480px) {
  .page-header {
    gap: 6px;
  }
  
  .user-card {
    padding: 10px;
  }
  
  .user-header {
    margin-bottom: 10px;
  }
  
  .user-info {
    margin-bottom: 12px;
  }
  
  .username {
    font-size: 14px;
  }
  
  .user-actions {
    gap: 4px;
  }
}
</style>
