// Пакет auth — обработчики регистрации и входа
package auth

import (
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/moe-delo/moe-delo/internal/users"
	"github.com/moe-delo/moe-delo/pkg/db"
	"github.com/moe-delo/moe-delo/pkg/middleware"
	"golang.org/x/crypto/bcrypt"
)

// RegisterRequest — запрос на регистрацию
type RegisterRequest struct {
	Phone     string `json:"phone" binding:"required,min=10"`
	Password  string `json:"password" binding:"required,min=4"`
	Role      string `json:"role" binding:"required,oneof=customer executor"`
	FirstName string `json:"first_name" binding:"required"`
}

// LoginRequest — запрос на вход
type LoginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Register — регистрация нового пользователя
func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверные данные: " + err.Error()})
		return
	}

	// Проверяем, не зарегистрирован ли уже этот телефон
	var count int64
	db.DB.Model(&users.User{}).Where("phone = ?", req.Phone).Count(&count)
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Этот телефон уже зарегистрирован"})
		return
	}

	// Хешируем пароль через bcrypt
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания пароля"})
		return
	}

	// Создаём пользователя
	user := users.User{
		Phone:        req.Phone,
		PasswordHash: string(hash),
		Role:         req.Role,
		FirstName:    req.FirstName,
		Rating:       5.0,
	}

	if err := db.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания пользователя"})
		return
	}

	// Генерируем JWT-токен
	token := generateToken(user.ID, user.Role)

	c.JSON(http.StatusCreated, gin.H{
		"token":   token,
		"user_id": user.ID,
		"role":    user.Role,
		"name":    user.FirstName,
	})
}

// Login — вход в систему
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Введите телефон и пароль"})
		return
	}

	// Ищем пользователя по телефону
	var user users.User
	if err := db.DB.Where("phone = ?", req.Phone).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный телефон или пароль"})
		return
	}

	// Проверяем пароль через bcrypt
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный телефон или пароль"})
		return
	}

	// Генерируем JWT-токен
	token := generateToken(user.ID, user.Role)

	c.JSON(http.StatusOK, gin.H{
		"token":   token,
		"user_id": user.ID,
		"role":    user.Role,
		"name":    user.FirstName,
	})
}

// generateToken — создание JWT-токена
func generateToken(userID uint, role string) string {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "default-secret-change-me"
	}

	claims := middleware.Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(72 * time.Hour)), // 3 дня
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, _ := token.SignedString([]byte(secret))
	return tokenString
}
