<template>
  <div class="dashboard">
    <el-row :gutter="20" class="overview-cards">
      <el-col :xs="12" :sm="12" :md="6">
        <el-card class="stat-card system-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon :size="isMobile ? 20 : 30"><Monitor /></el-icon>
            </div>
            <div class="stat-info">
              <h3>{{ truncateText(systemInfo?.os || 'Loading...', isMobile ? 10 : 20) }}</h3>
              <p>Operating System</p>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="12" :sm="12" :md="6">
        <el-card class="stat-card uptime-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon :size="isMobile ? 20 : 30"><Clock /></el-icon>
            </div>
            <div class="stat-info">
              <h3>{{ truncateText(systemInfo?.uptime || 'Loading...', isMobile ? 8 : 15) }}</h3>
              <p>System Uptime</p>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="12" :sm="12" :md="6">
        <el-card class="stat-card ip-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon :size="isMobile ? 20 : 30"><Position /></el-icon>
            </div>
            <div class="stat-info">
              <h3>{{ systemInfo?.public_ip || 'Loading...' }}</h3>
              <p>Public IP</p>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="12" :sm="12" :md="6">
        <el-card class="stat-card domain-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon :size="isMobile ? 20 : 30"><Link /></el-icon>
            </div>
            <div class="stat-info">
              <h3>{{ truncateText(systemInfo?.domain || 'Loading...', isMobile ? 10 : 20) }}</h3>
              <p>Domain</p>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="charts-row">
      <el-col :xs="24" :md="12">
        <el-card class="resource-card">
          <template #header>
            <div class="card-header">
              <span :style="{ fontSize: isMobile ? '14px' : '16px' }">System Resources</span>
              <el-button type="text" @click="loadSystemInfo" :size="isMobile ? 'small' : 'default'">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </template>
          
          <div class="resource-info">
            <div class="resource-item">
              <div class="resource-header">
                <span>RAM Usage</span>
                <span>{{ formatBytes(systemInfo?.ram_used) }} / {{ formatBytes(systemInfo?.ram_total) }}</span>
              </div>
              <el-progress 
                :percentage="ramPercentage" 
                :color="getProgressColor(ramPercentage)"
                :show-text="false"
              />
            </div>
            
            <div class="resource-item">
              <div class="resource-header">
                <span>CPU Usage</span>
                <span>{{ systemInfo?.cpu_percent?.toFixed(1) || 0 }}%</span>
              </div>
              <el-progress 
                :percentage="systemInfo?.cpu_percent || 0" 
                :color="getProgressColor(systemInfo?.cpu_percent || 0)"
                :show-text="false"
              />
            </div>
            
            <div class="resource-item">
              <div class="resource-header">
                <span>Disk Usage</span>
                <span>{{ formatBytes(systemInfo?.disk_used) }} / {{ formatBytes(systemInfo?.disk_total) }}</span>
              </div>
              <el-progress 
                :percentage="diskPercentage" 
                :color="getProgressColor(diskPercentage)"
                :show-text="false"
              />
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="24" :md="12">
        <el-card class="network-card">
          <template #header>
            <div class="card-header">
              <span :style="{ fontSize: isMobile ? '14px' : '16px' }">Network Statistics</span>
            </div>
          </template>
          
          <div class="network-stats" :class="{ 'mobile-network': isMobile }">
            <div class="network-item">
              <div class="network-icon" :class="{ 'mobile-icon': isMobile }">
                <el-icon :size="isMobile ? 16 : 20"><ArrowDown /></el-icon>
              </div>
              <div class="network-info">
                <p class="network-label">Bytes Received</p>
                <h3 :style="{ fontSize: isMobile ? '14px' : '16px' }">{{ formatBytes(systemInfo?.network_io?.bytes_recv) }}</h3>
              </div>
            </div>
            
            <div class="network-item">
              <div class="network-icon" :class="{ 'mobile-icon': isMobile }">
                <el-icon :size="isMobile ? 16 : 20"><ArrowUp /></el-icon>
              </div>
              <div class="network-info">
                <p class="network-label">Bytes Sent</p>
                <h3 :style="{ fontSize: isMobile ? '14px' : '16px' }">{{ formatBytes(systemInfo?.network_io?.bytes_sent) }}</h3>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="24">
        <el-card class="services-card">
          <template #header>
            <div class="card-header">
              <span :style="{ fontSize: isMobile ? '14px' : '16px' }">Service Status</span>
              <el-button type="text" @click="loadSystemInfo" :size="isMobile ? 'small' : 'default'">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </template>
          
          <div class="services-grid" :class="{ 'mobile-services': isMobile }">
            <div 
              v-for="service in systemInfo?.services" 
              :key="service.name"
              class="service-item"
              :class="{ 'active': service.is_active, 'mobile-service': isMobile }"
            >
              <div class="service-status">
                <el-icon 
                  :class="service.is_active ? 'status-active' : 'status-inactive'"
                  :size="isMobile ? 14 : 16"
                >
                  <CircleCheckFilled v-if="service.is_active" />
                  <CircleCloseFilled v-else />
                </el-icon>
                <span class="service-name" :style="{ fontSize: isMobile ? '12px' : '14px' }">
                  {{ truncateServiceName(service.name) }}
                </span>
              </div>
              <span 
                class="service-status-text" 
                :style="{ fontSize: isMobile ? '10px' : '12px' }"
              >
                {{ service.status }}
              </span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import api from '../utils/api'

export default {
  name: 'Dashboard',
  data() {
    return {
      systemInfo: null,
      loading: false,
      isMobile: false
    }
  },
  computed: {
    ramPercentage() {
      if (!this.systemInfo?.ram_total) return 0
      return Math.round((this.systemInfo.ram_used / this.systemInfo.ram_total) * 100)
    },
    diskPercentage() {
      if (!this.systemInfo?.disk_total) return 0
      return Math.round((this.systemInfo.disk_used / this.systemInfo.disk_total) * 100)
    }
  },
  mounted() {
    this.checkIfMobile()
    window.addEventListener('resize', this.checkIfMobile)
    this.loadSystemInfo()
    // Auto refresh every 30 seconds
    this.refreshInterval = setInterval(this.loadSystemInfo, 30000)
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.checkIfMobile)
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  },
  methods: {
    checkIfMobile() {
      this.isMobile = window.innerWidth <= 768
    },
    
    truncateText(text, maxLength) {
      if (!text || text.length <= maxLength) return text
      return text.substring(0, maxLength) + '...'
    },
    
    truncateServiceName(name) {
      if (!this.isMobile) return name
      if (name.length <= 12) return name
      return name.substring(0, 12) + '...'
    },
    async loadSystemInfo() {
      try {
        this.loading = true
        this.systemInfo = await api.get('/api/system/info')
      } catch (error) {
        console.error('Failed to load system info:', error)
      } finally {
        this.loading = false
      }
    },
    
    formatBytes(bytes) {
      if (!bytes) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },
    
    getProgressColor(percentage) {
      if (percentage < 50) return '#67c23a'
      if (percentage < 80) return '#e6a23c'
      return '#f56c6c'
    }
  }
}
</script>

<style scoped>
.dashboard {
  max-width: 1200px;
  margin: 0 auto;
}

.overview-cards {
  margin-bottom: 20px;
}

.stat-card {
  height: auto;
  min-height: 100px;
  cursor: pointer;
  transition: all 0.3s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.stat-content {
  display: flex;
  align-items: center;
  padding: 15px;
  height: 100%;
}

.stat-icon {
  margin-right: 15px;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.system-card .stat-icon {
  background-color: #e3f2fd;
  color: #1976d2;
}

.uptime-card .stat-icon {
  background-color: #f3e5f5;
  color: #7b1fa2;
}

.ip-card .stat-icon {
  background-color: #e8f5e8;
  color: #388e3c;
}

.domain-card .stat-icon {
  background-color: #fff3e0;
  color: #f57c00;
}

.stat-info {
  flex: 1;
  overflow: hidden;
}

.stat-info h3 {
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 5px;
  word-break: break-all;
  line-height: 1.2;
}

.stat-info p {
  font-size: 11px;
  color: #7f8c8d;
  margin: 0;
}

.charts-row {
  margin-bottom: 20px;
}

.resource-card,
.network-card,
.services-card {
  height: auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.resource-info .resource-item {
  margin-bottom: 16px;
}

.resource-item:last-child {
  margin-bottom: 0;
}

.resource-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 13px;
  color: #606266;
}

.network-stats {
  display: flex;
  justify-content: space-around;
  text-align: center;
  flex-wrap: wrap;
  gap: 20px;
}

.mobile-network {
  flex-direction: column;
  gap: 15px;
}

.network-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
}

.network-icon {
  width: 45px;
  height: 45px;
  border-radius: 50%;
  background-color: #f5f7fa;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 10px;
  color: #409eff;
}

.mobile-icon {
  width: 35px;
  height: 35px;
}

.network-label {
  font-size: 11px;
  color: #909399;
  margin: 0 0 5px 0;
}

.network-info h3 {
  font-size: 14px;
  margin: 0;
  color: #2c3e50;
}

.services-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 12px;
}

.mobile-services {
  grid-template-columns: 1fr;
  gap: 8px;
}

.service-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #ddd;
  transition: all 0.3s;
}

.mobile-service {
  padding: 10px 12px;
}

.service-item.active {
  border-left-color: #67c23a;
  background-color: #f0f9ff;
}

.service-status {
  display: flex;
  align-items: center;
  flex: 1;
  overflow: hidden;
}

.status-active {
  color: #67c23a;
  margin-right: 8px;
  flex-shrink: 0;
}

.status-inactive {
  color: #f56c6c;
  margin-right: 8px;
  flex-shrink: 0;
}

.service-name {
  font-weight: 500;
  color: #2c3e50;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.service-status-text {
  font-size: 11px;
  color: #909399;
  text-transform: uppercase;
  flex-shrink: 0;
  margin-left: 8px;
}

/* Mobile responsive adjustments */
@media (max-width: 768px) {
  .overview-cards {
    margin-bottom: 16px;
  }
  
  .charts-row {
    margin-bottom: 16px;
  }
  
  .stat-card {
    min-height: 80px;
    margin-bottom: 12px;
  }
  
  .stat-content {
    padding: 12px;
  }
  
  .stat-icon {
    width: 40px;
    height: 40px;
    margin-right: 12px;
  }
  
  .stat-info h3 {
    font-size: 13px;
  }
  
  .stat-info p {
    font-size: 10px;
  }
  
  .services-grid {
    grid-template-columns: 1fr;
  }
  
  .network-stats {
    flex-direction: column;
    gap: 15px;
  }
  
  .network-item {
    flex-direction: row;
    text-align: left;
  }
  
  .network-icon {
    margin-right: 15px;
    margin-bottom: 0;
  }
}

/* Extra small devices */
@media (max-width: 480px) {
  .stat-content {
    padding: 10px;
  }
  
  .stat-icon {
    width: 35px;
    height: 35px;
    margin-right: 10px;
  }
  
  .stat-info h3 {
    font-size: 12px;
  }
  
  .resource-header {
    font-size: 12px;
  }
  
  .service-item {
    padding: 8px 12px;
  }
}</style>
