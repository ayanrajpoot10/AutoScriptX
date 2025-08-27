package internal

import (
	"time"
)

// User represents an SSH user account
type User struct {
	Username  string    `json:"username"`
	Password  string    `json:"password,omitempty"`
	ExpiresAt time.Time `json:"expires_at"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateUserRequest represents the request to create a new user
type CreateUserRequest struct {
	Username   string `json:"username" binding:"required"`
	Password   string `json:"password" binding:"required"`
	ExpireDays int    `json:"expire_days" binding:"required"`
}

// ServiceStatus represents the status of a system service
type ServiceStatus struct {
	Name      string `json:"name"`
	Status    string `json:"status"`
	IsActive  bool   `json:"is_active"`
	IsEnabled bool   `json:"is_enabled"`
}

// SystemInfo represents system information
type SystemInfo struct {
	OS         string            `json:"os"`
	Uptime     string            `json:"uptime"`
	PublicIP   string            `json:"public_ip"`
	Domain     string            `json:"domain"`
	RAMUsed    uint64            `json:"ram_used"`
	RAMTotal   uint64            `json:"ram_total"`
	CPUPercent float64           `json:"cpu_percent"`
	DiskUsed   uint64            `json:"disk_used"`
	DiskTotal  uint64            `json:"disk_total"`
	Services   []ServiceStatus   `json:"services"`
	NetworkIO  NetworkIOCounters `json:"network_io"`
}

// NetworkIOCounters represents network I/O statistics
type NetworkIOCounters struct {
	BytesSent   uint64 `json:"bytes_sent"`
	BytesRecv   uint64 `json:"bytes_recv"`
	PacketsSent uint64 `json:"packets_sent"`
	PacketsRecv uint64 `json:"packets_recv"`
}

// DomainChangeRequest represents a domain change request
type DomainChangeRequest struct {
	Domain string `json:"domain" binding:"required"`
}

// BannerUpdateRequest represents a banner update request
type BannerUpdateRequest struct {
	Content string `json:"content" binding:"required"`
}

// ResponseMessage represents response with message
type ResponseMessage struct {
	Message string `json:"message"`
	Success bool   `json:"success"`
}

// ServiceAction represents an action to perform on services
type ServiceAction struct {
	Services []string `json:"services" binding:"required"`
	Action   string   `json:"action" binding:"required,oneof=start stop restart"`
}

// SlowDNSConfig represents SlowDNS configuration
type SlowDNSConfig struct {
	Domain    string `json:"domain"`
	PublicKey string `json:"public_key"`
	IsActive  bool   `json:"is_active"`
}
