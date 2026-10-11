// Пакет orders — обработчики заказов
package orders

import (
	"math"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/Foggez-rfs/My_Work/backend/internal/ai"
	"github.com/Foggez-rfs/My_Work/backend/internal/users"
	"github.com/Foggez-rfs/My_Work/backend/pkg/db"
)

// CreateOrder — создание нового заказа
func CreateOrder(c *gin.Context) {
	var req CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Опишите, что нужно сделать, и укажите адрес"})
		return
	}

	userID := c.GetUint("user_id")

	// ИИ-классификация: определяем категорию и приоритет
	category, priority := ai.ClassifyOrder(req.Description)

	// Создаём заказ
	order := Order{
		CustomerID:  userID,
		Description: req.Description,
		Category:    category,
		Priority:    priority,
		Address:     req.Address,
		Lat:         req.Lat,
		Lon:         req.Lon,
		Status:      "pending",
	}

	if err := db.DB.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания заказа"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"order":    order,
		"category": category,
		"priority": priority,
		"message":  "Заказ создан! Исполнители рядом получат уведомление.",
	})
}

// MyOrders — список моих заказов (как заказчик или исполнитель)
func MyOrders(c *gin.Context) {
	userID := c.GetUint("user_id")
	role := c.GetString("role")

	var orders []Order
	query := db.DB.Order("created_at DESC")

	if role == "customer" {
		query = query.Where("customer_id = ?", userID)
	} else {
		query = query.Where("executor_id = ? OR customer_id = ?", userID, userID)
	}

	query.Find(&orders)

	// Добавляем имена
	for i := range orders {
		var customer, executor users.User
		db.DB.First(&customer, orders[i].CustomerID)
		orders[i].CustomerName = customer.FirstName
		if orders[i].ExecutorID != nil {
			db.DB.First(&executor, *orders[i].ExecutorID)
			orders[i].ExecutorName = executor.FirstName
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"orders": orders,
		"count":  len(orders),
	})
}

// NearbyOrders — поиск заказов рядом (геопоиск через Haversine)
func NearbyOrders(c *gin.Context) {
	latStr := c.Query("lat")
	lonStr := c.Query("lon")
	radiusStr := c.DefaultQuery("radius", "1000") // По умолчанию 1 км

	lat, _ := strconv.ParseFloat(latStr, 64)
	lon, _ := strconv.ParseFloat(lonStr, 64)
	radius, _ := strconv.ParseFloat(radiusStr, 64)

	if lat == 0 || lon == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Укажите координаты (lat, lon)"})
		return
	}

	// Получаем все открытые заказы
	var orders []Order
	db.DB.Where("status = ?", "pending").Find(&orders)

	// Фильтруем по расстоянию (формула Haversine)
	var nearby []Order
	for _, order := range orders {
		distance := haversine(lat, lon, order.Lat, order.Lon)
		if distance <= radius {
			// Добавляем имя заказчика
			var customer users.User
			db.DB.First(&customer, order.CustomerID)
			order.CustomerName = customer.FirstName
			nearby = append(nearby, order)
		}
	}

	// Сортируем по приоритету (срочные первыми)
	sortByPriority(nearby)

	c.JSON(http.StatusOK, gin.H{
		"orders": nearby,
		"count":  len(nearby),
	})
}

// AcceptOrder — исполнитель принимает заказ
func AcceptOrder(c *gin.Context) {
	orderID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")

	var order Order
	if err := db.DB.First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Заказ не найден"})
		return
	}

	if order.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Этот заказ уже принят или завершён"})
		return
	}

	// Назначаем исполнителя
	executorID := uint(userID)
	order.ExecutorID = &executorID
	order.Status = "accepted"
	db.DB.Save(&order)

	c.JSON(http.StatusOK, gin.H{"message": "Вы приняли заказ! Приступайте к выполнению."})
}

// CompleteOrder — завершение заказа
func CompleteOrder(c *gin.Context) {
	orderID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")

	var order Order
	if err := db.DB.First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Заказ не найден"})
		return
	}

	if order.ExecutorID == nil || *order.ExecutorID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Вы не являетесь исполнителем этого заказа"})
		return
	}

	if order.Status != "accepted" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Заказ уже завершён или не принят"})
		return
	}

	order.Status = "completed"
	db.DB.Save(&order)

	c.JSON(http.StatusOK, gin.H{"message": "Заказ завершён! Попросите заказчика оценить работу."})
}

// haversine — расчёт расстояния между двумя точками на Земле (в метрах)
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000.0 // Радиус Земли в метрах
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

// sortByPriority — сортировка заказов: срочные первыми
func sortByPriority(orders []Order) {
	for i := 0; i < len(orders); i++ {
		for j := i + 1; j < len(orders); j++ {
			if orders[j].Priority < orders[i].Priority {
				orders[i], orders[j] = orders[j], orders[i]
			}
		}
	}
}
