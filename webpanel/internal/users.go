package internal

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"time"
)

// UserService handles user account operations
type UserService struct{}

// NewUserService creates a new UserService
func NewUserService() *UserService {
	return &UserService{}
}

// GetUsers returns all SSH users created by AutoScriptX
func (u *UserService) GetUsers() ([]User, error) {
	var users []User

	// Read /etc/passwd to find users
	file, err := os.Open("/etc/passwd")
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Split(line, ":")
		if len(fields) >= 7 {
			username := fields[0]
			shell := fields[6]

			// Skip system users and users with valid shells
			if shell == "/bin/false" && u.isAutoScriptXUser(username) {
				userInfo, err := u.getUserInfo(username)
				if err != nil {
					continue
				}
				users = append(users, userInfo)
			}
		}
	}

	return users, scanner.Err()
}

// CreateUser creates a new SSH user
func (u *UserService) CreateUser(username, password string, expireDays int) error {
	// Calculate expiration date
	expireDate := time.Now().AddDate(0, 0, expireDays)
	expireDateStr := expireDate.Format("2006-01-02")

	// Create user with expiration
	cmd := exec.Command("useradd", "-e", expireDateStr, "-s", "/bin/false", "-M", username)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create user: %v", err)
	}

	// Set password
	cmd = exec.Command("bash", "-c", fmt.Sprintf("echo -e '%s\n%s' | passwd %s", password, password, username))
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to set password: %v", err)
	}

	// Mark user as AutoScriptX managed
	u.markAsAutoScriptXUser(username)

	return nil
}

// DeleteUser deletes an SSH user
func (u *UserService) DeleteUser(username string) error {
	cmd := exec.Command("userdel", username)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to delete user: %v", err)
	}

	u.unmarkAutoScriptXUser(username)
	return nil
}

// RenewUser extends user expiration
func (u *UserService) RenewUser(username string, days int) error {
	newExpireDate := time.Now().AddDate(0, 0, days)
	expireDateStr := newExpireDate.Format("2006-01-02")

	cmd := exec.Command("chage", "-E", expireDateStr, username)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to renew user: %v", err)
	}

	return nil
}

// LockUser locks a user account
func (u *UserService) LockUser(username string) error {
	cmd := exec.Command("passwd", "-l", username)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to lock user: %v", err)
	}
	return nil
}

// UnlockUser unlocks a user account
func (u *UserService) UnlockUser(username string) error {
	cmd := exec.Command("passwd", "-u", username)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to unlock user: %v", err)
	}
	return nil
}

// getUserInfo gets detailed information about a user
func (u *UserService) getUserInfo(username string) (User, error) {
	userInfo := User{
		Username: username,
	}

	// Get user details using id command
	cmd := exec.Command("id", username)
	if err := cmd.Run(); err != nil {
		return userInfo, fmt.Errorf("user not found")
	}

	// Get expiration date using chage
	cmd = exec.Command("chage", "-l", username)
	output, err := cmd.Output()
	if err != nil {
		return userInfo, err
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "Account expires") {
			parts := strings.Split(line, ":")
			if len(parts) > 1 {
				dateStr := strings.TrimSpace(parts[1])
				if dateStr != "never" {
					if expireTime, err := time.Parse("Jan 02, 2006", dateStr); err == nil {
						userInfo.ExpiresAt = expireTime
					}
				}
			}
		}
	}

	// Check if account is locked
	cmd = exec.Command("passwd", "-S", username)
	output, err = cmd.Output()
	if err == nil {
		status := strings.Fields(string(output))
		if len(status) > 1 {
			userInfo.IsActive = status[1] != "L"
		}
	}

	return userInfo, nil
}

// isAutoScriptXUser checks if user is managed by AutoScriptX
func (u *UserService) isAutoScriptXUser(username string) bool {
	// Check if username exists in AutoScriptX users file
	content, err := ioutil.ReadFile("/etc/AutoScriptX/users")
	if err != nil {
		return false
	}

	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		if strings.TrimSpace(line) == username {
			return true
		}
	}
	return false
}

// markAsAutoScriptXUser marks user as managed by AutoScriptX
func (u *UserService) markAsAutoScriptXUser(username string) {
	// Ensure directory exists
	os.MkdirAll("/etc/AutoScriptX", 0755)

	// Add username to users file
	file, err := os.OpenFile("/etc/AutoScriptX/users", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return
	}
	defer file.Close()

	file.WriteString(username + "\n")
}

// unmarkAutoScriptXUser removes user from AutoScriptX management
func (u *UserService) unmarkAutoScriptXUser(username string) {
	content, err := ioutil.ReadFile("/etc/AutoScriptX/users")
	if err != nil {
		return
	}

	lines := strings.Split(string(content), "\n")
	var newLines []string
	for _, line := range lines {
		if strings.TrimSpace(line) != username {
			newLines = append(newLines, line)
		}
	}

	newContent := strings.Join(newLines, "\n")
	ioutil.WriteFile("/etc/AutoScriptX/users", []byte(newContent), 0644)
}

// GetUserConnectionInfo returns connection information for payloads
func (u *UserService) GetUserConnectionInfo() (map[string]interface{}, error) {
	systemService := NewSystemService()
	domain := systemService.getDomain()
	publicIP := systemService.getPublicIP()

	info := map[string]interface{}{
		"domain":    domain,
		"public_ip": publicIP,
		"ports": map[string]interface{}{
			"ssh_ws":     80,
			"ssh_ssl_ws": 443,
			"ssl_tls":    443,
			"squid":      8080,
			"udpgw":      []int{7200, 7300},
		},
		"payloads": map[string]string{
			"wss": fmt.Sprintf("GET wss://example.com HTTP/1.1[crlf]Host: %s[crlf]Upgrade: websocket[crlf][crlf]", domain),
			"ws":  fmt.Sprintf("GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: websocket[crlf][crlf]", domain),
		},
	}

	return info, nil
}

// CleanExpiredUsers removes expired user accounts
func (u *UserService) CleanExpiredUsers() error {
	users, err := u.GetUsers()
	if err != nil {
		return err
	}

	now := time.Now()
	for _, user := range users {
		if !user.ExpiresAt.IsZero() && user.ExpiresAt.Before(now) {
			if err := u.DeleteUser(user.Username); err != nil {
				continue // Continue with other users if one fails
			}
		}
	}

	return nil
}
