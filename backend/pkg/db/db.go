// Пакет db — подключение к PostgreSQL через GORM
package db

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB — глобальная переменная подключения к БД
var DB *gorm.DB

// Init инициализирует подключение к PostgreSQL
func Init() {
	// Загружаем переменные окружения из .env
	err := godotenv.Load()
	if err != nil {
		log.Println("⚠️ Файл .env не найден, используем переменные окружения")
	}

	// Формируем DSN для подключения
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "moe_user")
	password := getEnv("DB_PASSWORD", "moe_password")
	dbname := getEnv("DB_NAME", "moe_delo")

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	// Подключаемся к БД
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		log.Fatalf("❌ Ошибка подключения к БД: %v", err)
	}

	log.Println("✅ Подключение к PostgreSQL установлено")
}

// getEnv — получение переменной окружения с дефолтным значением
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
