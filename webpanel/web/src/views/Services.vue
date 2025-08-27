<template>
  <div class="services-page">
    <div class="page-header" :class="{ 'mobile-header': isMobile }">
      <el-button @click="loadServices" :size="isMobile ? 'small' : 'default'">
        <el-icon><Refresh /></el-icon>
        <span v-if="!isMobile">Refresh Status</span>
      </el-button>
    </div>

    <el-card>
      <template #header>
        <div class="card-header" :class="{ 'mobile-card-header': isMobile }">
          <span :style="isMobile ? 'font-size: 14px;' : ''">Service Management</span>
          <div class="header-actions">
            <el-button-group v-if="!isMobile">
              <el-button 
                type="success" 
                @click="performServiceAction('start')"
                :disabled="selectedServices.length === 0"
                size="small"
              >
                <el-icon><VideoPlay /></el-icon>
                Start
              </el-button>
              <el-button 
                type="warning" 
                @click="performServiceAction('stop')"
                :disabled="selectedServices.length === 0"
                size="small"
              >
                <el-icon><VideoPause /></el-icon>
                Stop
              </el-button>
              <el-button 
                type="primary" 
                @click="performServiceAction('restart')"
                :disabled="selectedServices.length === 0"
                size="small"
              >
                <el-icon><Refresh /></el-icon>
                Restart
              </el-button>
            </el-button-group>
            
            <!-- Mobile bulk actions -->
            <div v-else class="mobile-actions">
              <el-dropdown @command="performServiceAction" :disabled="selectedServices.length === 0">
                <el-button size="small" type="primary">
                  Actions
                  <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="start">
                      <el-icon><VideoPlay /></el-icon>
                      Start
                    </el-dropdown-item>
                    <el-dropdown-item command="stop">
                      <el-icon><VideoPause /></el-icon>
                      Stop
                    </el-dropdown-item>
                    <el-dropdown-item command="restart">
                      <el-icon><Refresh /></el-icon>
                      Restart
                    </el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>
        </div>
      </template>

      <!-- Desktop Table -->
      <el-table 
        v-if="!isMobile"
        :data="services" 
        v-loading="loading" 
        @selection-change="handleSelectionChange"
        stripe
      >
        <el-table-column type="selection" width="55" />
        
        <el-table-column prop="name" label="Service Name" min-width="200">
          <template #default="scope">
            <div class="service-name-cell">
              <el-icon 
                :class="scope.row.is_active ? 'status-active' : 'status-inactive'"
                style="margin-right: 8px;"
              >
                <CircleCheckFilled v-if="scope.row.is_active" />
                <CircleCloseFilled v-else />
              </el-icon>
              {{ scope.row.name }}
            </div>
          </template>
        </el-table-column>
        
        <el-table-column label="Status" width="120">
          <template #default="scope">
            <el-tag 
              :type="scope.row.is_active ? 'success' : 'danger'" 
              size="small"
            >
              {{ scope.row.status }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="Auto Start" width="100">
          <template #default="scope">
            <el-tag 
              :type="scope.row.is_enabled ? 'success' : 'info'" 
              size="small"
            >
              {{ scope.row.is_enabled ? 'Enabled' : 'Disabled' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="Actions" width="200" fixed="right">
          <template #default="scope">
            <el-button-group>
              <el-button 
                size="small" 
                :type="scope.row.is_active ? 'warning' : 'success'"
                @click="toggleService(scope.row)"
                :loading="actionLoading === scope.row.name"
              >
                {{ scope.row.is_active ? 'Stop' : 'Start' }}
              </el-button>
              <el-button 
                size="small" 
                type="primary"
                @click="restartService(scope.row)"
                :loading="actionLoading === scope.row.name"
              >
                Restart
              </el-button>
            </el-button-group>
          </template>
        </el-table-column>
      </el-table>

      <!-- Mobile Service Cards -->
      <div v-else v-loading="loading" class="mobile-services">
        <div 
          v-for="service in services" 
          :key="service.name" 
          class="service-card"
          :class="{ 'active': service.is_active }"
        >
          <div class="service-header">
            <el-checkbox 
              v-model="selectedServiceNames" 
              :label="service.name"
              @change="updateSelectedServices"
            />
            <el-tag 
              :type="service.is_active ? 'success' : 'danger'" 
              size="small"
            >
              {{ service.status }}
            </el-tag>
          </div>

          <div class="service-name">
            <el-icon 
              :class="service.is_active ? 'status-active' : 'status-inactive'"
            >
              <CircleCheckFilled v-if="service.is_active" />
              <CircleCloseFilled v-else />
            </el-icon>
            {{ service.name }}
          </div>

          <div class="service-info">
            <span class="auto-start-label">Auto Start:</span>
            <el-tag 
              :type="service.is_enabled ? 'success' : 'info'" 
              size="small"
            >
              {{ service.is_enabled ? 'Enabled' : 'Disabled' }}
            </el-tag>
          </div>

          <div class="service-actions">
            <el-button 
              size="small" 
              :type="service.is_active ? 'warning' : 'success'"
              @click="toggleService(service)"
              :loading="actionLoading === service.name"
            >
              {{ service.is_active ? 'Stop' : 'Start' }}
            </el-button>
            <el-button 
              size="small" 
              type="primary"
              @click="restartService(service)"
              :loading="actionLoading === service.name"
            >
              Restart
            </el-button>
          </div>
        </div>
      </div>
    </el-card>

    <el-row :gutter="20" class="service-stats">
      <el-col :xs="24" :sm="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-number active-services">{{ activeServicesCount }}</div>
            <div class="stat-label">Active Services</div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="24" :sm="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-number inactive-services">{{ inactiveServicesCount }}</div>
            <div class="stat-label">Inactive Services</div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="24" :sm="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-number total-services">{{ services.length }}</div>
            <div class="stat-label">Total Services</div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../utils/api'

export default {
  name: 'Services',
  data() {
    return {
      services: [],
      loading: false,
      actionLoading: null,
      selectedServices: [],
      selectedServiceNames: []
    }
  },
  computed: {
    isMobile() {
      return window.innerWidth <= 768
    },
    activeServicesCount() {
      return this.services.filter(s => s.is_active).length
    },
    inactiveServicesCount() {
      return this.services.filter(s => !s.is_active).length
    }
  },
  mounted() {
    this.loadServices()
    // Auto refresh every 10 seconds
    this.refreshInterval = setInterval(this.loadServices, 10000)
  },
  beforeUnmount() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  },
  methods: {
    async loadServices() {
      try {
        this.loading = true
        const systemInfo = await api.get('/api/system/info')
        this.services = systemInfo.services || []
      } catch (error) {
        console.error('Failed to load services:', error)
      } finally {
        this.loading = false
      }
    },

    handleSelectionChange(selection) {
      this.selectedServices = selection.map(s => this.getServiceKey(s.name))
    },

    updateSelectedServices() {
      this.selectedServices = this.selectedServiceNames.map(name => this.getServiceKey(name))
    },

    getServiceKey(serviceName) {
      // Map display names back to service keys
      const serviceMap = {
        'SSH': 'ssh',
        'Nginx': 'nginx',
        'Dropbear': 'dropbear',
        'Stunnel4': 'stunnel4',
        'Cron': 'cron',
        'SSHGuard': 'sshguard',
        'VnStat': 'vnstat',
        'WebSocket Proxy': 'ws-proxy.service',
        'UDPGW (7200)': 'badvpn-udpgw@7200.service',
        'UDPGW (7300)': 'badvpn-udpgw@7300.service',
        'Squid': 'squid',
        'X-UI': 'x-ui.service',
        'XUI Watcher': 'xui-watcher.service'
      }
      return serviceMap[serviceName] || serviceName.toLowerCase()
    },

    async performServiceAction(action) {
      if (this.selectedServices.length === 0) {
        ElMessage.warning('Please select at least one service')
        return
      }

      try {
        await api.post('/api/system/services', {
          services: this.selectedServices,
          action: action
        })

        ElMessage.success(`Service ${action} completed successfully`)
        setTimeout(this.loadServices, 1000) // Refresh after a delay
      } catch (error) {
        console.error(`Failed to ${action} services:`, error)
      }
    },

    async toggleService(service) {
      const action = service.is_active ? 'stop' : 'start'
      const serviceKey = this.getServiceKey(service.name)
      
      try {
        this.actionLoading = service.name
        await api.post('/api/system/services', {
          services: [serviceKey],
          action: action
        })

        ElMessage.success(`${service.name} ${action}ed successfully`)
        setTimeout(this.loadServices, 1000)
      } catch (error) {
        console.error(`Failed to ${action} service:`, error)
      } finally {
        this.actionLoading = null
      }
    },

    async restartService(service) {
      const serviceKey = this.getServiceKey(service.name)
      
      try {
        this.actionLoading = service.name
        await api.post('/api/system/services', {
          services: [serviceKey],
          action: 'restart'
        })

        ElMessage.success(`${service.name} restarted successfully`)
        setTimeout(this.loadServices, 1000)
      } catch (error) {
        console.error('Failed to restart service:', error)
      } finally {
        this.actionLoading = null
      }
    }
  }
}
</script>

<style scoped>
.services-page {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mobile-header {
  margin-bottom: 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mobile-card-header {
  flex-direction: column;
  align-items: flex-start;
  gap: 12px;
}

.service-name-cell {
  display: flex;
  align-items: center;
}

.status-active {
  color: #67c23a;
}

.status-inactive {
  color: #f56c6c;
}

.mobile-services {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.service-card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  background-color: #fff;
  transition: all 0.3s;
  border-left: 4px solid #ddd;
}

.service-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.service-card.active {
  border-left-color: #67c23a;
  background-color: #f0f9ff;
}

.service-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.service-name {
  display: flex;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 10px;
}

.service-name .el-icon {
  margin-right: 8px;
}

.service-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.auto-start-label {
  font-size: 13px;
  color: #666;
  font-weight: 500;
}

.service-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.mobile-actions {
  display: flex;
  gap: 8px;
}

.service-stats {
  margin-top: 20px;
}

.stat-card {
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.stat-content {
  padding: 20px 0;
}

.stat-number {
  font-size: 32px;
  font-weight: bold;
  margin-bottom: 8px;
}

.active-services {
  color: #67c23a;
}

.inactive-services {
  color: #f56c6c;
}

.total-services {
  color: #409eff;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

/* Mobile responsive adjustments */
@media (max-width: 768px) {
  .page-header {
    margin-bottom: 16px;
  }
  
  .mobile-services {
    gap: 10px;
  }
  
  .service-card {
    padding: 12px;
  }
  
  .service-header {
    margin-bottom: 10px;
  }
  
  .service-name {
    font-size: 15px;
    margin-bottom: 8px;
  }
  
  .service-info {
    margin-bottom: 12px;
  }
  
  .service-actions {
    gap: 6px;
  }
  
  .stat-content {
    padding: 15px 0;
  }
  
  .stat-number {
    font-size: 24px;
  }
  
  .stat-label {
    font-size: 13px;
  }
}

/* Extra small devices */
@media (max-width: 480px) {
  .service-card {
    padding: 10px;
  }
  
  .service-name {
    font-size: 14px;
  }
  
  .service-actions {
    gap: 4px;
  }
  
  .auto-start-label {
    font-size: 12px;
  }
  
  .stat-content {
    padding: 12px 0;
  }
  
  .stat-number {
    font-size: 20px;
  }
  
  .stat-label {
    font-size: 12px;
  }
}
</style>
