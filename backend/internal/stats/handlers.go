// Пакет stats — обработчики статистики
package stats

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/moe-delo/moe-delo/internal/orders"
	"github.com/moe-delo/moe-delo/internal/users"
	"github.com/moe-delo/moe-delo/pkg/db"
)

// GetUserStats — статистика текущего пользователя
func GetUserStats(c *gin.Context) {
	userID := c.GetUint("user_id")
	role := c.GetString("role")

	// Получаем информацию о пользователе
	var user users.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Пользователь не найден"})
		return
	}

	// Считаем выполненные заказы
	var completedOrders int64
	db.DB.Model(&orders.Order{}).
		Where("executor_id = ? AND status = ?", userID, "completed").
		Count(&completedOrders)

	// Считаем заказы для заказчика
	var customerOrders int64
	db.DB.Model(&orders.Order{}).
		Where("customer_id = ?", userID).
		Count(&customerOrders)

	// Считаем уникальных людей, которым помогли (для исполнителя)
	var peopleHelped int64
	if role == "executor" {
		db.DB.Model(&orders.Order{}).
			Where("executor_id = ? AND status = ?", userID, "completed").
			Distinct("customer_id").
			Count(&peopleHelped)
	}

	// Примерное количество часов (1 заказ ≈ 2 часа)
	totalHours := float64(completedOrders) * 2.0

	// Дата начала (дата регистрации)
	startDate := user.CreatedAt

	c.JSON(http.StatusOK, gin.H{
		"completed_orders": completedOrders,
		"customer_orders":  customerOrders,
		"total_hours":      totalHours,
		"people_helped":    peopleHelped,
		"rating":           user.Rating,
		"start_date":       startDate.Format(time.RFC3339),
	})
}

// GetPlatformStats — общая статистика платформы
func GetPlatformStats(c *gin.Context) {
	// Всего заказов
	var totalOrders int64
	db.DB.Model(&orders.Order{}).Count(&totalOrders)

	// Выполненных заказов
	var completedOrders int64
	db.DB.Model(&orders.Order{}).Where("status = ?", "completed").Count(&completedOrders)

	// Всего волонтёров (исполнителей)
	var totalVolunteers int64
	db.DB.Model(&users.User{}).Where("role = ?", "executor").Count(&totalVolunteers)

	// Всего пожилых людей (заказчиков)
	var totalElderly int64
	db.DB.Model(&users.User{}).Where("role = ?", "customer").Count(&totalElderly)

	// Часов помощи (примерно: выполненные заказы × 2 часа)
	totalHours := float64(completedOrders) * 2.0

	c.JSON(http.StatusOK, gin.H{
		"total_orders":     totalOrders,
		"completed_orders": completedOrders,
		"total_volunteers": totalVolunteers,
		"total_elderly":    totalElderly,
		"total_hours":      totalHours,
	})
}
