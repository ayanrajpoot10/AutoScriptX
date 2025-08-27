<template>
  <div class="slowdns-page">
    <el-row :gutter="isMobile ? 10 : 20">
      <!-- SlowDNS Status -->
      <el-col :xs="24" :lg="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">SlowDNS Status</span>
              <el-button :size="isMobile ? 'small' : 'small'" @click="loadSlowDNSConfig">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </div>
          </template>
          
          <div class="status-info" v-if="slowDNSConfig">
            <el-descriptions :column="1" border :size="isMobile ? 'small' : 'default'">
              <el-descriptions-item label="Status">
                <el-tag 
                  :type="slowDNSConfig.is_active ? 'success' : 'danger'" 
                  :size="isMobile ? 'small' : 'large'"
                >
                  {{ slowDNSConfig.is_active ? 'Active' : 'Inactive' }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="Domain">
                <span :style="isMobile ? 'font-size: 12px; word-break: break-all;' : ''">
                  {{ slowDNSConfig.domain || 'Not configured' }}
                </span>
              </el-descriptions-item>
              <el-descriptions-item label="Public Key">
                <el-input 
                  v-model="slowDNSConfig.public_key" 
                  readonly 
                  placeholder="Not configured"
                  :style="{ 'font-family': 'monospace', 'font-size': isMobile ? '10px' : '12px' }"
                  :size="isMobile ? 'small' : 'default'"
                />
              </el-descriptions-item>
            </el-descriptions>
          </div>

          <div class="service-actions" :style="{ 'margin-top': '20px' }">
            <el-button-group v-if="!isMobile">
              <el-button 
                :type="slowDNSConfig?.is_active ? 'warning' : 'success'"
                @click="toggleSlowDNS"
                :loading="actionLoading === 'toggle'"
                size="small"
              >
                {{ slowDNSConfig?.is_active ? 'Stop' : 'Start' }}
              </el-button>
              <el-button 
                type="primary"
                @click="restartSlowDNS"
                :loading="actionLoading === 'restart'"
                size="small"
              >
                Restart
              </el-button>
              <el-button 
                type="info"
                @click="showSlowDNSStatus"
                :loading="actionLoading === 'status'"
                size="small"
              >
                View Status
              </el-button>
            </el-button-group>
            
            <!-- Mobile buttons -->
            <div v-else class="mobile-actions">
              <el-button 
                :type="slowDNSConfig?.is_active ? 'warning' : 'success'"
                @click="toggleSlowDNS"
                :loading="actionLoading === 'toggle'"
                size="small"
                style="flex: 1;"
              >
                {{ slowDNSConfig?.is_active ? 'Stop' : 'Start' }}
              </el-button>
              <el-button 
                type="primary"
                @click="restartSlowDNS"
                :loading="actionLoading === 'restart'"
                size="small"
                style="flex: 1;"
              >
                Restart
              </el-button>
              <el-button 
                type="info"
                @click="showSlowDNSStatus"
                :loading="actionLoading === 'status'"
                size="small"
                style="flex: 1;"
              >
                Status
              </el-button>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- SlowDNS Setup -->
      <el-col :xs="24" :lg="12" :style="isMobile ? 'margin-top: 10px;' : ''">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">SlowDNS Setup</span>
            </div>
          </template>
          
          <el-form 
            :model="setupForm" 
            :rules="setupRules" 
            ref="setupFormRef" 
            :label-width="isMobile ? '80px' : '100px'"
            :label-position="isMobile ? 'top' : 'right'"
          >
            <el-form-item label="Domain" prop="domain">
              <el-input 
                v-model="setupForm.domain" 
                placeholder="Enter SlowDNS domain (e.g., dns.yourdomain.com)"
                :size="isMobile ? 'small' : 'default'"
              />
            </el-form-item>
            <el-form-item>
              <el-button 
                type="primary" 
                @click="setupSlowDNS" 
                :loading="settingUp"
                :size="isMobile ? 'small' : 'default'"
                style="width: 100%;"
              >
                Setup SlowDNS
              </el-button>
            </el-form-item>
          </el-form>

          <el-alert
            title="Setup Instructions"
            type="info"
            :closable="false"
            :style="{ 'margin-top': '15px', 'font-size': isMobile ? '12px' : '14px' }"
          >
            <template #default>
              <ol :style="{ margin: '10px 0', 'padding-left': '20px', 'font-size': isMobile ? '12px' : '14px' }">
                <li>Create a subdomain (e.g., dns.yourdomain.com)</li>
                <li>Point it to your server's IP address</li>
                <li>Enter the subdomain above and click Setup</li>
                <li>Configure your SSH client with the generated key</li>
              </ol>
            </template>
          </el-alert>
        </el-card>
      </el-col>
    </el-row>

    <!-- Usage Instructions -->
    <el-row :style="{ 'margin-top': isMobile ? '10px' : '20px' }">
      <el-col :span="24">
        <el-card>
          <template #header>
            <div class="card-header">
              <span :style="isMobile ? 'font-size: 14px;' : ''">SlowDNS Usage Instructions</span>
            </div>
          </template>
          
          <el-tabs v-model="activeTab" :tab-position="isMobile ? 'top' : 'top'">
            <el-tab-pane label="Android" name="android">
              <div class="instruction-content">
                <h4 :style="isMobile ? 'font-size: 14px;' : ''">For HTTP Injector / HTTP Custom / similar apps:</h4>
                <el-input 
                  type="textarea" 
                  readonly
                  :rows="isMobile ? 4 : 6"
                  :model-value="androidConfig"
                  :style="{ 'font-family': 'monospace', 'font-size': isMobile ? '10px' : '12px' }"
                  :size="isMobile ? 'small' : 'default'"
                />
                <el-button 
                  type="primary" 
                  :size="isMobile ? 'small' : 'small'"
                  :style="{ 'margin-top': '10px', width: isMobile ? '100%' : 'auto' }"
                  @click="copyToClipboard(androidConfig)"
                >
                  Copy Configuration
                </el-button>
              </div>
            </el-tab-pane>
            
            <el-tab-pane label="Windows/Linux" name="desktop">
              <div class="instruction-content">
                <h4 :style="isMobile ? 'font-size: 14px;' : ''">For SlowDNS Client:</h4>
                <el-input 
                  type="textarea" 
                  readonly
                  :rows="isMobile ? 3 : 4"
                  :model-value="desktopConfig"
                  :style="{ 'font-family': 'monospace', 'font-size': isMobile ? '10px' : '12px' }"
                  :size="isMobile ? 'small' : 'default'"
                />
                <el-button 
                  type="primary" 
                  :size="isMobile ? 'small' : 'small'"
                  :style="{ 'margin-top': '10px', width: isMobile ? '100%' : 'auto' }"
                  @click="copyToClipboard(desktopConfig)"
                >
                  Copy Command
                </el-button>
              </div>
            </el-tab-pane>
            
            <el-tab-pane label="iOS" name="ios">
              <div class="instruction-content">
                <h4 :style="isMobile ? 'font-size: 14px;' : ''">For Shadowrocket / Quantumult X:</h4>
                <div :style="{ 'font-size': isMobile ? '12px' : '14px' }">
                  <p>1. Add a new server configuration</p>
                  <p>2. Select SlowDNS protocol</p>
                  <p>3. Enter server details:</p>
                  <ul>
                    <li><strong>Server:</strong> {{ systemInfo?.public_ip || 'Your Server IP' }}</li>
                    <li><strong>Port:</strong> 53</li>
                    <li><strong>Domain:</strong> {{ slowDNSConfig?.domain || 'Your SlowDNS domain' }}</li>
                    <li><strong>Public Key:</strong> 
                      <span :style="{ 'word-break': 'break-all', 'font-family': 'monospace', 'font-size': isMobile ? '10px' : '12px' }">
                        {{ slowDNSConfig?.public_key || 'Generated public key' }}
                      </span>
                    </li>
                  </ul>
                </div>
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>

    <!-- SlowDNS Status Dialog -->
    <el-dialog 
      v-model="showStatusDialog" 
      title="SlowDNS Service Status" 
      :width="isMobile ? '95%' : '70%'"
      :style="isMobile ? 'margin-top: 5vh' : ''"
    >
      <el-scrollbar :height="isMobile ? '300px' : '400px'">
        <pre class="status-content" :class="{ 'mobile-status': isMobile }">{{ slowDNSStatus }}</pre>
      </el-scrollbar>
      
      <template #footer>
        <el-button @click="showStatusDialog = false" :size="isMobile ? 'small' : 'default'">
          Close
        </el-button>
        <el-button type="primary" @click="loadSlowDNSStatus" :size="isMobile ? 'small' : 'default'">
          Refresh
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../utils/api'

export default {
  name: 'SlowDNS',
  data() {
    return {
      slowDNSConfig: null,
      systemInfo: null,
      actionLoading: null,
      settingUp: false,
      showStatusDialog: false,
      slowDNSStatus: '',
      activeTab: 'android',
      setupForm: {
        domain: ''
      },
      setupRules: {
        domain: [
          { required: true, message: 'Domain is required', trigger: 'blur' },
          { pattern: /^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/, message: 'Please enter a valid domain', trigger: 'blur' }
        ]
      }
    }
  },
  computed: {
    isMobile() {
      return window.innerWidth <= 768
    },
    androidConfig() {
      return `[SlowDNS Configuration]
Server: ${this.systemInfo?.public_ip || 'YOUR_SERVER_IP'}
Port: 53
Domain: ${this.slowDNSConfig?.domain || 'YOUR_SLOWDNS_DOMAIN'}
Public Key: ${this.slowDNSConfig?.public_key || 'PUBLIC_KEY_HERE'}

Payload:
GET / HTTP/1.1[crlf]
Host: ${this.slowDNSConfig?.domain || 'YOUR_SLOWDNS_DOMAIN'}[crlf]
Connection: Upgrade[crlf]
Upgrade: websocket[crlf][crlf]`
    },
    desktopConfig() {
      return `./slowdns-client \\
  -server ${this.systemInfo?.public_ip || 'YOUR_SERVER_IP'} \\
  -pubkey ${this.slowDNSConfig?.public_key || 'PUBLIC_KEY_HERE'} \\
  -domain ${this.slowDNSConfig?.domain || 'YOUR_SLOWDNS_DOMAIN'} \\
  -local 127.0.0.1:1080`
    }
  },
  mounted() {
    this.loadSlowDNSConfig()
    this.loadSystemInfo()
  },
  methods: {
    async loadSlowDNSConfig() {
      try {
        this.slowDNSConfig = await api.get('/api/slowdns/config')
      } catch (error) {
        console.error('Failed to load SlowDNS config:', error)
      }
    },

    async loadSystemInfo() {
      try {
        this.systemInfo = await api.get('/api/system/info')
      } catch (error) {
        console.error('Failed to load system info:', error)
      }
    },

    async setupSlowDNS() {
      try {
        await this.$refs.setupFormRef.validate()
        
        await ElMessageBox.confirm(
          `Setup SlowDNS with domain "${this.setupForm.domain}"? This will generate new keys and configure the service.`,
          'Confirm SlowDNS Setup',
          {
            confirmButtonText: 'Setup',
            cancelButtonText: 'Cancel',
            type: 'warning',
          }
        )

        this.settingUp = true
        await api.post('/api/slowdns/setup', this.setupForm)
        
        ElMessage.success('SlowDNS setup completed successfully')
        this.setupForm.domain = ''
        this.loadSlowDNSConfig()
      } catch (error) {
        if (error !== 'cancel') {
          console.error('Failed to setup SlowDNS:', error)
        }
      } finally {
        this.settingUp = false
      }
    },

    async toggleSlowDNS() {
      const action = this.slowDNSConfig?.is_active ? 'stop' : 'start'
      
      try {
        this.actionLoading = 'toggle'
        await api.post(`/api/slowdns/${action}`)
        
        ElMessage.success(`SlowDNS ${action}ed successfully`)
        this.loadSlowDNSConfig()
      } catch (error) {
        console.error(`Failed to ${action} SlowDNS:`, error)
      } finally {
        this.actionLoading = null
      }
    },

    async restartSlowDNS() {
      try {
        this.actionLoading = 'restart'
        await api.post('/api/slowdns/restart')
        
        ElMessage.success('SlowDNS restarted successfully')
        this.loadSlowDNSConfig()
      } catch (error) {
        console.error('Failed to restart SlowDNS:', error)
      } finally {
        this.actionLoading = null
      }
    },

    async showSlowDNSStatus() {
      this.showStatusDialog = true
      this.loadSlowDNSStatus()
    },

    async loadSlowDNSStatus() {
      try {
        this.actionLoading = 'status'
        const response = await api.get('/api/slowdns/status')
        this.slowDNSStatus = response.status
      } catch (error) {
        console.error('Failed to load SlowDNS status:', error)
        this.slowDNSStatus = 'Failed to load status'
      } finally {
        this.actionLoading = null
      }
    },

    copyToClipboard(text) {
      navigator.clipboard.writeText(text).then(() => {
        ElMessage.success('Configuration copied to clipboard')
      }).catch(() => {
        ElMessage.error('Failed to copy to clipboard')
      })
    }
  }
}
</script>

<style scoped>
.slowdns-page {
  max-width: 1200px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-info .el-descriptions {
  margin-bottom: 0;
}

.service-actions {
  display: flex;
  justify-content: center;
}

.mobile-actions {
  display: flex;
  gap: 8px;
  width: 100%;
}

.instruction-content {
  padding: 10px 0;
}

.instruction-content h4 {
  color: #2c3e50;
  margin-bottom: 15px;
}

.instruction-content ul {
  margin: 15px 0;
  padding-left: 20px;
}

.instruction-content li {
  margin-bottom: 8px;
  line-height: 1.5;
}

.status-content {
  color: #d4d4d4;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.4;
  margin: 0;
  padding: 15px;
  background-color: #1e1e1e;
  border-radius: 4px;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.mobile-status {
  font-size: 10px;
  padding: 10px;
}

/* Mobile responsive adjustments */
@media (max-width: 768px) {
  .slowdns-page {
    padding: 0;
  }
  
  .mobile-actions {
    gap: 6px;
  }
  
  .instruction-content {
    padding: 8px 0;
  }
  
  .instruction-content h4 {
    margin-bottom: 10px;
  }
  
  .instruction-content ul {
    margin: 10px 0;
    padding-left: 16px;
  }
  
  .instruction-content li {
    margin-bottom: 6px;
  }
  
  .status-content {
    font-size: 10px;
    padding: 10px;
  }
}

/* Extra small devices */
@media (max-width: 480px) {
  .mobile-actions {
    gap: 4px;
  }
  
  .instruction-content {
    padding: 6px 0;
  }
  
  .instruction-content h4 {
    margin-bottom: 8px;
  }
  
  .instruction-content ul {
    margin: 8px 0;
    padding-left: 12px;
  }
  
  .instruction-content li {
    margin-bottom: 4px;
  }
  
  .status-content {
    font-size: 9px;
    padding: 8px;
  }
}
</style>
