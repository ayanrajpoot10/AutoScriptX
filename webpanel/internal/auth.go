package internal

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

const (
	jwtSecret     = "autoscriptx-webpanel-secret-key-2024"
	tokenDuration = 24 * time.Hour
)

// AuthService handles authentication
type AuthService struct{}

// NewAuthService creates a new AuthService
func NewAuthService() *AuthService {
	return &AuthService{}
}

// AdminUser represents an admin user
type AdminUser struct {
	Username string `json:"username"`
	Password string `json:"-"`
}

// LoginRequest represents a login request
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse represents the login response
type LoginResponse struct {
	Token    string `json:"token"`
	Username string `json:"username"`
	Message  string `json:"message"`
	Success  bool   `json:"success"`
}

// Claims represents JWT claims
type Claims struct {
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// Login authenticates a user and returns a JWT token
func (a *AuthService) Login(username, password string) (*LoginResponse, error) {
	// Check if user exists and password is correct
	admin, err := a.getAdminUser(username)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Check password
	if err := bcrypt.CompareHashAndPassword([]byte(admin.Password), []byte(password)); err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Generate JWT token
	token, err := a.generateToken(username)
	if err != nil {
		return nil, errors.New("failed to generate token")
	}

	return &LoginResponse{
		Token:    token,
		Username: username,
		Message:  "Login successful",
		Success:  true,
	}, nil
}

// ValidateToken validates a JWT token and returns the username
func (a *AuthService) ValidateToken(tokenString string) (string, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(jwtSecret), nil
	})

	if err != nil {
		return "", err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims.Username, nil
	}

	return "", errors.New("invalid token")
}

// generateToken generates a JWT token for a user
func (a *AuthService) generateToken(username string) (string, error) {
	expirationTime := time.Now().Add(tokenDuration)
	claims := &Claims{
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// getAdminUser retrieves admin user from config file
func (a *AuthService) getAdminUser(username string) (*AdminUser, error) {
	// Ensure config directory exists
	configDir := "/etc/AutoScriptX"
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return nil, err
	}

	configFile := configDir + "/webpanel_admin.conf"

	// Create default admin user if config doesn't exist
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		if err := a.createDefaultAdmin(); err != nil {
			return nil, err
		}
	}

	// Read config file
	content, err := ioutil.ReadFile(configFile)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 && parts[0] == username {
			return &AdminUser{
				Username: parts[0],
				Password: parts[1],
			}, nil
		}
	}

	return nil, errors.New("user not found")
}

// createDefaultAdmin creates a default admin user
func (a *AuthService) createDefaultAdmin() error {
	defaultPassword := "admin123"
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(defaultPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	configContent := fmt.Sprintf("# AutoScriptX WebPanel Admin Configuration\n# Format: username:bcrypt_hashed_password\nadmin:%s\n", string(hashedPassword))

	configFile := "/etc/AutoScriptX/webpanel_admin.conf"
	if err := ioutil.WriteFile(configFile, []byte(configContent), 0600); err != nil {
		return err
	}

	return nil
}

// ChangePassword changes the password for a user
func (a *AuthService) ChangePassword(username, newPassword string) error {
	// Ensure the user exists
	_, err := a.getAdminUser(username)
	if err != nil {
		return err
	}

	// Hash the new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// Read current config
	configFile := "/etc/AutoScriptX/webpanel_admin.conf"
	content, err := ioutil.ReadFile(configFile)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	var newLines []string
	userFound := false

	for _, line := range lines {
		if strings.TrimSpace(line) == "" || strings.HasPrefix(line, "#") {
			newLines = append(newLines, line)
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 && parts[0] == username {
			newLines = append(newLines, fmt.Sprintf("%s:%s", username, string(hashedPassword)))
			userFound = true
		} else {
			newLines = append(newLines, line)
		}
	}

	if !userFound {
		return errors.New("user not found")
	}

	newContent := strings.Join(newLines, "\n")
	return ioutil.WriteFile(configFile, []byte(newContent), 0600)
}

// GetAdminUsers returns list of admin usernames (for management)
func (a *AuthService) GetAdminUsers() ([]string, error) {
	configFile := "/etc/AutoScriptX/webpanel_admin.conf"
	content, err := ioutil.ReadFile(configFile)
	if err != nil {
		return nil, err
	}

	var usernames []string
	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 {
			usernames = append(usernames, parts[0])
		}
	}

	return usernames, nil
}
