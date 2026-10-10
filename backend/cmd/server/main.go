// Точка входа сервера «Моё дело»
package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/moe-delo/moe-delo/internal/auth"
	"github.com/moe-delo/moe-delo/internal/docs"
	"github.com/moe-delo/moe-delo/internal/orders"
	"github.com/moe-delo/moe-delo/internal/rating"
	"github.com/moe-delo/moe-delo/internal/stats"
	"github.com/moe-delo/moe-delo/internal/users"
	"github.com/moe-delo/moe-delo/pkg/db"
	"github.com/moe-delo/moe-delo/pkg/middleware"
)

func main() {
	// Загружаем переменные окружения
	godotenv.Load()

	// Инициализируем базу данных
	db.Init()

	// Автоматическая миграция — создаём таблицы если их нет
	db.DB.AutoMigrate(
		&users.User{},
		&orders.Order{},
		&rating.Review{},
		&docs.Document{},
	)
	log.Println("✅ Миграции выполнены")

	// Создаём роутер Gin
	r := gin.Default()

	// Разрешаем CORS для мобильного приложения
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// === ПУБЛИЧНЫЕ ЭНДПОИНТЫ ===
	r.POST("/auth/register", auth.Register)
	r.POST("/auth/login", auth.Login)

	// Проверка здоровья сервиса
	r.GET("/health", func(c *gin.Context) {
		// Проверяем подключение к БД
		sqlDB, err := db.DB.DB()
		dbStatus := "ok"
		if err != nil || sqlDB.Ping() != nil {
			dbStatus = "error"
		}

		c.JSON(200, gin.H{
			"status":   "ok",
			"database": dbStatus,
			"service":  "moe-delo",
		})
	})

	// === ЗАЩИЩЁННЫЕ ЭНДПОИНТЫ (требуют JWT) ===
	api := r.Group("/api")
	api.Use(middleware.AuthMiddleware())

	// Заказы
	api.POST("/orders", orders.CreateOrder)
	api.GET("/orders/my", orders.MyOrders)
	api.GET("/orders/nearby", orders.NearbyOrders)
	api.POST("/orders/:id/accept", orders.AcceptOrder)
	api.POST("/orders/:id/complete", orders.CompleteOrder)
	api.POST("/orders/:id/rate", rating.RateOrder)

	// Статистика
	api.GET("/stats/user", stats.GetUserStats)
	r.GET("/api/stats/platform", stats.GetPlatformStats) // Публичный эндпоинт

	// Документы
	api.POST("/docs/upload", docs.UploadDocument)

	// Запускаем сервер
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Сервер «Моё дело» запущен на порту %s", port)
	log.Printf("📡 API доступен по адресу http://localhost:%s", port)
	r.Run(":" + port)
}
