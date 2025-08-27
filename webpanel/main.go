package main

import (
	"embed"
	"io/fs"
	"log"
	"net/http"
	"strings"

	"autoscriptx-webpanel/internal"

	"github.com/gin-gonic/gin"
)

//go:embed web/dist/*
var webFiles embed.FS

func main() {
	// Initialize services
	userService := internal.NewUserService()
	systemService := internal.NewSystemService()
	slowDNSService := internal.NewSlowDNSService()
	authService := internal.NewAuthService()

	// Create Gin router
	r := gin.Default()

	// Add CORS middleware for development
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	})

	// Authentication middleware
	authMiddleware := func() gin.HandlerFunc {
		return func(c *gin.Context) {
			// Skip auth for login endpoint
			if c.Request.URL.Path == "/api/auth/login" {
				c.Next()
				return
			}

			// Get token from Authorization header
			authHeader := c.GetHeader("Authorization")
			if authHeader == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
				c.Abort()
				return
			}

			// Check Bearer format
			tokenParts := strings.Split(authHeader, " ")
			if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
				c.Abort()
				return
			}

			// Validate token
			username, err := authService.ValidateToken(tokenParts[1])
			if err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
				c.Abort()
				return
			}

			// Add username to context
			c.Set("username", username)
			c.Next()
		}
	}

	// Serve embedded static files from web/dist
	staticFS, err := fs.Sub(webFiles, "web/dist")
	if err != nil {
		log.Fatal("Failed to create sub filesystem:", err)
	}

	// Create a sub filesystem for assets
	assetsFS, err := fs.Sub(staticFS, "assets")
	if err != nil {
		log.Fatal("Failed to create assets sub filesystem:", err)
	}

	// Serve assets
	r.StaticFS("/assets", http.FS(assetsFS))

	// Handle favicon
	r.GET("/favicon.ico", func(c *gin.Context) {
		data, err := webFiles.ReadFile("web/dist/favicon.ico")
		if err != nil {
			c.Status(http.StatusNotFound)
			return
		}
		c.Data(http.StatusOK, "image/x-icon", data)
	})

	// Serve index.html for SPA
	r.GET("/", func(c *gin.Context) {
		data, err := webFiles.ReadFile("web/dist/index.html")
		if err != nil {
			c.String(http.StatusInternalServerError, "Failed to read index.html")
			return
		}
		c.Data(http.StatusOK, "text/html; charset=utf-8", data)
	})

	// Authentication routes (no middleware required)
	auth := r.Group("/api/auth")
	{
		auth.POST("/login", func(c *gin.Context) {
			var req internal.LoginRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			response, err := authService.Login(req.Username, req.Password)
			if err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, response)
		})

		auth.POST("/change-password", authMiddleware(), func(c *gin.Context) {
			username := c.GetString("username")
			var req struct {
				NewPassword string `json:"new_password" binding:"required,min=6"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := authService.ChangePassword(username, req.NewPassword); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "Password changed successfully",
				Success: true,
			})
		})

		auth.GET("/validate", authMiddleware(), func(c *gin.Context) {
			username := c.GetString("username")
			c.JSON(http.StatusOK, gin.H{
				"valid":    true,
				"username": username,
			})
		})
	}

	// Protected API routes
	api := r.Group("/api", authMiddleware())
	{
		// System routes
		api.GET("/system/info", func(c *gin.Context) {
			info, err := systemService.GetSystemInfo()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, info)
		})

		api.POST("/system/domain", func(c *gin.Context) {
			var req internal.DomainChangeRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := systemService.ChangeDomain(req.Domain); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "Domain changed successfully",
				Success: true,
			})
		})

		api.GET("/system/banner", func(c *gin.Context) {
			banner, err := systemService.GetBanner()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, gin.H{"content": banner})
		})

		api.POST("/system/banner", func(c *gin.Context) {
			var req internal.BannerUpdateRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := systemService.SetBanner(req.Content); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "Banner updated successfully",
				Success: true,
			})
		})

		api.POST("/system/services", func(c *gin.Context) {
			var req internal.ServiceAction
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := systemService.ManageService(req.Services, req.Action); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "Service action completed successfully",
				Success: true,
			})
		})

		api.POST("/system/restart", func(c *gin.Context) {
			if err := systemService.RestartSystem(); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "System restart initiated",
				Success: true,
			})
		})

		// User routes
		api.GET("/users", func(c *gin.Context) {
			users, err := userService.GetUsers()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, users)
		})

		api.POST("/users", func(c *gin.Context) {
			var req internal.CreateUserRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := userService.CreateUser(req.Username, req.Password, req.ExpireDays); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusCreated, internal.ResponseMessage{
				Message: "User created successfully",
				Success: true,
			})
		})

		api.DELETE("/users/:username", func(c *gin.Context) {
			username := c.Param("username")
			if err := userService.DeleteUser(username); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "User deleted successfully",
				Success: true,
			})
		})

		api.POST("/users/:username/renew", func(c *gin.Context) {
			username := c.Param("username")
			var req struct {
				Days int `json:"days" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := userService.RenewUser(username, req.Days); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "User renewed successfully",
				Success: true,
			})
		})

		api.POST("/users/:username/lock", func(c *gin.Context) {
			username := c.Param("username")
			if err := userService.LockUser(username); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "User locked successfully",
				Success: true,
			})
		})

		api.POST("/users/:username/unlock", func(c *gin.Context) {
			username := c.Param("username")
			if err := userService.UnlockUser(username); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "User unlocked successfully",
				Success: true,
			})
		})

		api.GET("/users/connection-info", func(c *gin.Context) {
			info, err := userService.GetUserConnectionInfo()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, info)
		})

		api.POST("/users/clean-expired", func(c *gin.Context) {
			if err := userService.CleanExpiredUsers(); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "Expired users cleaned successfully",
				Success: true,
			})
		})

		// SlowDNS routes
		api.GET("/slowdns/config", func(c *gin.Context) {
			config, err := slowDNSService.GetSlowDNSConfig()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, config)
		})

		api.POST("/slowdns/setup", func(c *gin.Context) {
			var req struct {
				Domain string `json:"domain" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			if err := slowDNSService.SetupSlowDNS(req.Domain); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "SlowDNS setup completed",
				Success: true,
			})
		})

		api.POST("/slowdns/:action", func(c *gin.Context) {
			action := c.Param("action")
			var err error

			switch action {
			case "start":
				err = slowDNSService.StartSlowDNS()
			case "stop":
				err = slowDNSService.StopSlowDNS()
			case "restart":
				err = slowDNSService.RestartSlowDNS()
			default:
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid action"})
				return
			}

			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}

			c.JSON(http.StatusOK, internal.ResponseMessage{
				Message: "SlowDNS " + action + " completed",
				Success: true,
			})
		})

		api.GET("/slowdns/status", func(c *gin.Context) {
			status, err := slowDNSService.GetSlowDNSStatus()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, gin.H{"status": status})
		})
	}

	// Serve static files for SPA
	r.NoRoute(func(c *gin.Context) {
		data, err := webFiles.ReadFile("web/dist/index.html")
		if err != nil {
			c.String(http.StatusNotFound, "Page not found")
			return
		}
		c.Data(http.StatusOK, "text/html; charset=utf-8", data)
	})

	log.Println("AutoScriptX Web Panel starting on :8080")
	log.Fatal(r.Run(":8080"))
}
