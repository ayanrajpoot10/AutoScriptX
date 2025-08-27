<template>
  <div class="system-page">
    <el-row :gutter="isMobile ? 10 : 20">
      <!-- Domain Management -->
      <el-col :xs="24" :lg="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">Domain Configuration</span>
            </div>
          </template>
          
          <el-form 
            :model="domainForm" 
            :label-width="isMobile ? '80px' : '100px'"
            :label-position="isMobile ? 'top' : 'right'"
          >
            <el-form-item label="Current Domain">
              <el-input v-model="currentDomain" readonly />
            </el-form-item>
            <el-form-item label="New Domain">
              <el-input v-model="domainForm.domain" placeholder="Enter new domain" />
            </el-form-item>
            <el-form-item>
              <el-button 
                type="primary" 
                @click="changeDomain" 
                :loading="changingDomain"
                :size="isMobile ? 'small' : 'default'"
                :style="isMobile ? 'width: 100%;' : ''"
              >
                Change Domain
              </el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <!-- Banner Management -->
      <el-col :xs="24" :lg="12" :style="isMobile ? 'margin-top: 10px;' : ''">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">SSH Banner</span>
              <el-button :size="isMobile ? 'small' : 'small'" @click="loadBanner">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </template>
          
          <el-input 
            v-model="bannerContent" 
            type="textarea" 
            :rows="isMobile ? 4 : 6"
            placeholder="SSH banner content..."
          />
          
          <div :style="{ 'margin-top': '10px', 'text-align': isMobile ? 'center' : 'right' }">
            <el-button 
              type="primary" 
              @click="saveBanner" 
              :loading="savingBanner"
              :size="isMobile ? 'small' : 'default'"
              :style="isMobile ? 'width: 100%;' : ''"
            >
              Save Banner
            </el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="isMobile ? 10 : 20" :style="{ 'margin-top': isMobile ? '10px' : '20px' }">
      <!-- System Actions -->
      <el-col :xs="24" :lg="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">System Actions</span>
            </div>
          </template>
          
          <div class="system-actions">
            <el-button 
              type="warning" 
              :size="isMobile ? 'default' : 'large'"
              @click="restartSystem"
              :loading="restarting"
              style="width: 100%; margin-bottom: 10px;"
            >
              <el-icon><Refresh /></el-icon>
              Restart System
            </el-button>
            
            <el-button 
              type="info" 
              :size="isMobile ? 'default' : 'large'"
              @click="showSystemLogs"
              style="width: 100%;"
            >
              <el-icon><Document /></el-icon>
              View System Logs
            </el-button>
          </div>
        </el-card>
      </el-col>

      <!-- Quick Stats -->
      <el-col :xs="24" :lg="12" :style="isMobile ? 'margin-top: 10px;' : ''">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">Quick Statistics</span>
            </div>
          </template>
          
          <el-descriptions :column="1" border v-if="systemInfo" :size="isMobile ? 'small' : 'default'">
            <el-descriptions-item label="Operating System">
              {{ systemInfo.os }}
            </el-descriptions-item>
            <el-descriptions-item label="System Uptime">
              {{ systemInfo.uptime }}
            </el-descriptions-item>
            <el-descriptions-item label="Public IP">
              {{ systemInfo.public_ip }}
            </el-descriptions-item>
            <el-descriptions-item label="Current Domain">
              {{ systemInfo.domain }}
            </el-descriptions-item>
            <el-descriptions-item label="CPU Usage">
              {{ systemInfo.cpu_percent?.toFixed(1) }}%
            </el-descriptions-item>
            <el-descriptions-item label="RAM Usage">
              {{ formatBytes(systemInfo.ram_used) }} / {{ formatBytes(systemInfo.ram_total) }}
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <!-- System Logs Dialog -->
    <el-dialog 
      v-model="showLogsDialog" 
      title="System Logs" 
      :width="isMobile ? '95%' : '80%'" 
      :top="isMobile ? '5vh' : '5vh'"
    >
      <div class="logs-container">
        <div class="logs-header" :class="{ 'mobile-logs-header': isMobile }">
          <el-button @click="loadSystemLogs" :loading="loadingLogs" :size="isMobile ? 'small' : 'default'">
            <el-icon><Refresh /></el-icon>
            <span v-if="!isMobile">Refresh</span>
          </el-button>
          <div class="logs-controls">
            <el-input-number 
              v-model="logLines" 
              :min="10" 
              :max="1000" 
              :step="10"
              :size="isMobile ? 'small' : 'small'"
              :style="{ width: isMobile ? '100px' : '120px' }"
            />
            <span :style="{ 'margin-left': '10px', 'font-size': isMobile ? '11px' : '12px' }">lines</span>
          </div>
        </div>
        
        <el-scrollbar :height="isMobile ? '300px' : '400px'" class="logs-scrollbar">
          <pre class="logs-content" :class="{ 'mobile-logs': isMobile }">{{ systemLogs.join('\n') }}</pre>
        </el-scrollbar>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../utils/api'

export default {
  name: 'System',
  data() {
    return {
      systemInfo: null,
      currentDomain: '',
      domainForm: {
        domain: ''
      },
      bannerContent: '',
      changingDomain: false,
      savingBanner: false,
      restarting: false,
      showLogsDialog: false,
      systemLogs: [],
      loadingLogs: false,
      logLines: 100
    }
  },
  mounted() {
    this.loadSystemInfo()
    this.loadBanner()
  },
  computed: {
    isMobile() {
      return window.innerWidth <= 768
    }
  },
  methods: {
    async loadSystemInfo() {
      try {
        this.systemInfo = await api.get('/api/system/info')
        this.currentDomain = this.systemInfo.domain
      } catch (error) {
        console.error('Failed to load system info:', error)
      }
    },

    async loadBanner() {
      try {
        const response = await api.get('/api/system/banner')
        this.bannerContent = response.content
      } catch (error) {
        console.error('Failed to load banner:', error)
      }
    },

    async changeDomain() {
      if (!this.domainForm.domain.trim()) {
        ElMessage.warning('Please enter a domain name')
        return
      }

      try {
        await ElMessageBox.confirm(
          `Change domain to "${this.domainForm.domain}"? This will update SSL certificates and configurations.`,
          'Confirm Domain Change',
          {
            confirmButtonText: 'Change Domain',
            cancelButtonText: 'Cancel',
            type: 'warning',
          }
        )

        this.changingDomain = true
        await api.post('/api/system/domain', this.domainForm)
        
        ElMessage.success('Domain changed successfully')
        this.domainForm.domain = ''
        this.loadSystemInfo()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Failed to change domain:', error)
        }
      } finally {
        this.changingDomain = false
      }
    },

    async saveBanner() {
      try {
        this.savingBanner = true
        await api.post('/api/system/banner', {
          content: this.bannerContent
        })
        
        ElMessage.success('Banner saved successfully')
      } catch (error) {
        console.error('Failed to save banner:', error)
      } finally {
        this.savingBanner = false
      }
    },

    async restartSystem() {
      try {
        await ElMessageBox.confirm(
          'This will restart the entire system. You will lose connection. Are you sure?',
          'Confirm System Restart',
          {
            confirmButtonText: 'Yes, Restart',
            cancelButtonText: 'Cancel',
            type: 'warning',
          }
        )

        this.restarting = true
        await api.post('/api/system/restart')
        
        ElMessage.success('System restart initiated. Connection will be lost shortly.')
        
        // Show countdown or reconnection info
        setTimeout(() => {
          ElMessage.info('System is restarting... Please wait 2-3 minutes before reconnecting.')
        }, 2000)
        
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Failed to restart system:', error)
        }
      } finally {
        this.restarting = false
      }
    },

    showSystemLogs() {
      this.showLogsDialog = true
      this.loadSystemLogs()
    },

    async loadSystemLogs() {
      try {
        this.loadingLogs = true
        // This would need to be implemented in the backend
        // For now, we'll simulate it
        this.systemLogs = [
          'System log loading is not implemented yet.',
          'This feature will show recent system logs.',
          'You can implement this by adding a /api/system/logs endpoint.'
        ]
      } catch (error) {
        console.error('Failed to load system logs:', error)
      } finally {
        this.loadingLogs = false
      }
    },

    formatBytes(bytes) {
      if (!bytes) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    }
  }
}
</script>

<style scoped>
.system-page {
  max-width: 1200px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.system-actions .el-button {
  margin-bottom: 10px;
}

.system-actions .el-button:last-child {
  margin-bottom: 0;
}

.logs-container {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
}

.logs-header {
  padding: 10px;
  border-bottom: 1px solid #dcdfe6;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #f5f7fa;
}

.mobile-logs-header {
  flex-direction: column;
  align-items: stretch;
  gap: 10px;
}

.logs-controls {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logs-scrollbar {
  background-color: #1e1e1e;
}

.logs-content {
  color: #d4d4d4;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.4;
  margin: 0;
  padding: 15px;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.mobile-logs {
  font-size: 10px;
  padding: 10px;
}

/* Mobile responsive adjustments */
@media (max-width: 768px) {
  .system-page {
    padding: 0;
  }
  
  .logs-header {
    padding: 8px;
  }
  
  .logs-content {
    font-size: 10px;
    padding: 10px;
  }
}

/* Extra small devices */
@media (max-width: 480px) {
  .logs-header {
    padding: 6px;
  }
  
  .logs-controls {
    gap: 6px;
  }
  
  .logs-content {
    font-size: 9px;
    padding: 8px;
  }
}
</style>
