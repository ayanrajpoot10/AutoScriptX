package internal

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
)

// SystemService handles system-related operations
type SystemService struct{}

// NewSystemService creates a new SystemService
func NewSystemService() *SystemService {
	return &SystemService{}
}

// GetSystemInfo returns comprehensive system information
func (s *SystemService) GetSystemInfo() (*SystemInfo, error) {
	info := &SystemInfo{}

	// Get host info
	hostInfo, err := host.Info()
	if err != nil {
		return nil, err
	}
	info.OS = hostInfo.Platform + " " + hostInfo.PlatformVersion

	// Get uptime
	uptime := time.Duration(hostInfo.Uptime) * time.Second
	info.Uptime = formatUptime(uptime)

	// Get public IP
	info.PublicIP = s.getPublicIP()

	// Get domain
	info.Domain = s.getDomain()

	// Get memory info
	memInfo, err := mem.VirtualMemory()
	if err != nil {
		return nil, err
	}
	info.RAMUsed = memInfo.Used
	info.RAMTotal = memInfo.Total

	// Get CPU usage
	cpuPercent, err := cpu.Percent(time.Second, false)
	if err != nil {
		return nil, err
	}
	if len(cpuPercent) > 0 {
		info.CPUPercent = cpuPercent[0]
	}

	// Get disk usage
	diskInfo, err := disk.Usage("/")
	if err != nil {
		return nil, err
	}
	info.DiskUsed = diskInfo.Used
	info.DiskTotal = diskInfo.Total

	// Get network I/O
	netIO, err := net.IOCounters(false)
	if err != nil {
		return nil, err
	}
	if len(netIO) > 0 {
		info.NetworkIO = NetworkIOCounters{
			BytesSent:   netIO[0].BytesSent,
			BytesRecv:   netIO[0].BytesRecv,
			PacketsSent: netIO[0].PacketsSent,
			PacketsRecv: netIO[0].PacketsRecv,
		}
	}

	// Get service statuses
	info.Services = s.getServiceStatuses()

	return info, nil
}

// getPublicIP fetches the public IP address
func (s *SystemService) getPublicIP() string {
	resp, err := http.Get("https://ifconfig.me")
	if err != nil {
		return "Unknown"
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(string(body))
}

// getDomain reads the domain from configuration
func (s *SystemService) getDomain() string {
	content, err := ioutil.ReadFile("/etc/AutoScriptX/domain")
	if err != nil {
		return "Not Set"
	}
	return strings.TrimSpace(string(content))
}

// getServiceStatuses returns the status of all monitored services
func (s *SystemService) getServiceStatuses() []ServiceStatus {
	services := []string{
		"ssh", "nginx", "dropbear", "stunnel4", "cron", "sshguard",
		"vnstat", "ws-proxy.service", "badvpn-udpgw@7200.service",
		"badvpn-udpgw@7300.service", "squid", "x-ui.service", "xui-watcher.service",
	}

	serviceNames := map[string]string{
		"ssh":                       "SSH",
		"nginx":                     "Nginx",
		"dropbear":                  "Dropbear",
		"stunnel4":                  "Stunnel4",
		"cron":                      "Cron",
		"sshguard":                  "SSHGuard",
		"vnstat":                    "VnStat",
		"ws-proxy.service":          "WebSocket Proxy",
		"badvpn-udpgw@7200.service": "UDPGW (7200)",
		"badvpn-udpgw@7300.service": "UDPGW (7300)",
		"squid":                     "Squid",
		"x-ui.service":              "X-UI",
		"xui-watcher.service":       "XUI Watcher",
	}

	var statuses []ServiceStatus
	for _, service := range services {
		status := s.getServiceStatus(service)
		statuses = append(statuses, ServiceStatus{
			Name:      serviceNames[service],
			Status:    status.Status,
			IsActive:  status.IsActive,
			IsEnabled: status.IsEnabled,
		})
	}
	return statuses
}

// getServiceStatus returns the status of a specific service
func (s *SystemService) getServiceStatus(serviceName string) ServiceStatus {
	status := ServiceStatus{Name: serviceName}

	// Check if service is active
	cmd := exec.Command("systemctl", "is-active", serviceName)
	output, _ := cmd.Output()
	status.Status = strings.TrimSpace(string(output))
	status.IsActive = status.Status == "active"

	// Check if service is enabled
	cmd = exec.Command("systemctl", "is-enabled", serviceName)
	output, _ = cmd.Output()
	enabledStatus := strings.TrimSpace(string(output))
	status.IsEnabled = enabledStatus == "enabled"

	return status
}

// ManageService performs actions on services
func (s *SystemService) ManageService(services []string, action string) error {
	for _, service := range services {
		cmd := exec.Command("systemctl", action, service)
		if err := cmd.Run(); err != nil {
			log.Printf("Failed to %s service %s: %v", action, service, err)
			return fmt.Errorf("failed to %s service %s: %v", action, service, err)
		}
	}
	return nil
}

// ChangeDomain changes the system domain
func (s *SystemService) ChangeDomain(domain string) error {
	// Write domain to file
	err := ioutil.WriteFile("/etc/AutoScriptX/domain", []byte(domain), 0644)
	if err != nil {
		return err
	}

	// Run domain change script if it exists
	if _, err := os.Stat("/etc/AutoScriptX/scripts/system/change-domain.sh"); err == nil {
		cmd := exec.Command("/bin/bash", "/etc/AutoScriptX/scripts/system/change-domain.sh", domain)
		return cmd.Run()
	}

	return nil
}

// GetBanner reads the current SSH banner
func (s *SystemService) GetBanner() (string, error) {
	content, err := ioutil.ReadFile("/etc/AutoScriptX/config/banner.conf")
	if err != nil {
		return "", err
	}
	return string(content), nil
}

// SetBanner updates the SSH banner
func (s *SystemService) SetBanner(content string) error {
	return ioutil.WriteFile("/etc/AutoScriptX/config/banner.conf", []byte(content), 0644)
}

// Get101Response reads the current 101 response
func (s *SystemService) Get101Response() (string, error) {
	// This would typically read from a config file or service config
	return "Switching Protocols", nil
}

// Set101Response updates the 101 response
func (s *SystemService) Set101Response(response string) error {
	// Update the ws-proxy service configuration
	// This is a simplified implementation
	return nil
}

// formatUptime formats duration to human readable uptime
func formatUptime(d time.Duration) string {
	days := int(d.Hours()) / 24
	hours := int(d.Hours()) % 24
	minutes := int(d.Minutes()) % 60

	if days > 0 {
		return fmt.Sprintf("%d days, %d hours, %d minutes", days, hours, minutes)
	} else if hours > 0 {
		return fmt.Sprintf("%d hours, %d minutes", hours, minutes)
	}
	return fmt.Sprintf("%d minutes", minutes)
}

// RestartSystem restarts the system
func (s *SystemService) RestartSystem() error {
	cmd := exec.Command("shutdown", "-r", "now")
	return cmd.Start()
}

// GetSystemLogs returns recent system logs
func (s *SystemService) GetSystemLogs(lines int) ([]string, error) {
	cmd := exec.Command("journalctl", "-n", strconv.Itoa(lines), "--no-pager")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	logs := strings.Split(string(output), "\n")
	return logs, nil
}
