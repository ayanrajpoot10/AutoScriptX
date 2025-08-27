package internal

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"strings"
)

// SlowDNSService handles SlowDNS operations
type SlowDNSService struct{}

// NewSlowDNSService creates a new SlowDNSService
func NewSlowDNSService() *SlowDNSService {
	return &SlowDNSService{}
}

// GetSlowDNSConfig returns the current SlowDNS configuration
func (s *SlowDNSService) GetSlowDNSConfig() (*SlowDNSConfig, error) {
	config := &SlowDNSConfig{}

	// Read domain
	domainBytes, err := ioutil.ReadFile("/etc/AutoScriptX/slowdns/domain")
	if err == nil {
		config.Domain = strings.TrimSpace(string(domainBytes))
	}

	// Read public key
	keyBytes, err := ioutil.ReadFile("/etc/AutoScriptX/slowdns/server.pub")
	if err == nil {
		config.PublicKey = strings.TrimSpace(string(keyBytes))
	}

	// Check if SlowDNS is active
	cmd := exec.Command("systemctl", "is-active", "slowdns")
	output, _ := cmd.Output()
	config.IsActive = strings.TrimSpace(string(output)) == "active"

	return config, nil
}

// SetupSlowDNS sets up SlowDNS with the given domain
func (s *SlowDNSService) SetupSlowDNS(domain string) error {
	// Run the setup script if it exists
	cmd := exec.Command("/bin/bash", "/etc/AutoScriptX/scripts/system/setup-slowdns.sh", domain)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to setup SlowDNS: %v", err)
	}

	return nil
}

// StartSlowDNS starts the SlowDNS service
func (s *SlowDNSService) StartSlowDNS() error {
	cmd := exec.Command("systemctl", "start", "slowdns")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to start SlowDNS: %v", err)
	}
	return nil
}

// StopSlowDNS stops the SlowDNS service
func (s *SlowDNSService) StopSlowDNS() error {
	cmd := exec.Command("systemctl", "stop", "slowdns")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to stop SlowDNS: %v", err)
	}
	return nil
}

// RestartSlowDNS restarts the SlowDNS service
func (s *SlowDNSService) RestartSlowDNS() error {
	cmd := exec.Command("systemctl", "restart", "slowdns")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to restart SlowDNS: %v", err)
	}
	return nil
}

// GetSlowDNSStatus returns the status of SlowDNS service
func (s *SlowDNSService) GetSlowDNSStatus() (string, error) {
	cmd := exec.Command("systemctl", "status", "slowdns", "--no-pager")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return string(output), nil
}
