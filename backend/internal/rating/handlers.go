// Пакет rating — обработчики оценок
package rating

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/Foggez-rfs/My_Work/backend/internal/orders"
	"github.com/Foggez-rfs/My_Work/backend/internal/users"
	"github.com/Foggez-rfs/My_Work/backend/pkg/db"
)

// RateOrder — оценка выполненного заказа
func RateOrder(c *gin.Context) {
	orderID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")

	var req orders.RateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Укажите оценку от 1 до 5"})
		return
	}

	// Находим заказ
	var order orders.Order
	if err := db.DB.First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Заказ не найден"})
		return
	}

	// Проверяем, что заказчик — текущий пользователь
	if order.CustomerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Только заказчик может оценить работу"})
		return
	}

	if order.Status != "completed" && order.Status != "accepted" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Заказ ещё не выполнен"})
		return
	}

	if order.ExecutorID == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "У заказа нет исполнителя"})
		return
	}

	// Создаём отзыв
	review := Review{
		OrderID:    uint(orderID),
		ExecutorID: *order.ExecutorID,
		CustomerID: userID,
		Score:      req.Score,
		Comment:    req.Comment,
	}
	db.DB.Create(&review)

	// Обновляем средний рейтинг исполнителя
	var executor users.User
	db.DB.First(&executor, *order.ExecutorID)

	var avgResult struct {
		Avg float64
	}
	db.DB.Model(&Review{}).Where("executor_id = ?", executor.ID).Select("AVG(score)").Scan(&avgResult)
	executor.Rating = avgResult.Avg
	db.DB.Save(&executor)

	// Обновляем статус заказа
	order.Status = "completed"
	db.DB.Save(&order)

	c.JSON(http.StatusOK, gin.H{
		"message":    "Спасибо за оценку!",
		"new_rating": executor.Rating,
	})
}
