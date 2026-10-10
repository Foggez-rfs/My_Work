// Пакет orders — модели заказов
package orders

import (
	"time"

	"gorm.io/gorm"
)

// Order — модель заказа на помощь
type Order struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	CustomerID  uint           `gorm:"not null;index" json:"customer_id"`
	ExecutorID  *uint          `gorm:"index" json:"executor_id"`
	Description string         `gorm:"type:text;not null" json:"description"`
	Category    string         `gorm:"size:100;default:Прочее" json:"category"`
	Priority    int            `gorm:"default:3" json:"priority"` // 1=срочно, 2=средний, 3=плановый
	Address     string         `gorm:"size:500;not null" json:"address"`
	Lat         float64        `gorm:"default:0" json:"lat"`
	Lon         float64        `gorm:"default:0" json:"lon"`
	Status      string         `gorm:"size:20;default:pending" json:"status"` // pending, accepted, completed, cancelled
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	// Виртуальные поля для отображения (не в БД)
	CustomerName string `gorm:"-" json:"customer_name,omitempty"`
	ExecutorName string `gorm:"-" json:"executor_name,omitempty"`
}

// TableName — имя таблицы в БД
func (Order) TableName() string {
	return "orders"
}

// CreateOrderRequest — запрос на создание заказа
type CreateOrderRequest struct {
	Description string  `json:"description" binding:"required"`
	Address     string  `json:"address" binding:"required"`
	Lat         float64 `json:"lat"`
	Lon         float64 `json:"lon"`
}

// RateOrderRequest — запрос на оценку заказа
type RateOrderRequest struct {
	Score   int    `json:"score" binding:"required,min=1,max=5"`
	Comment string `json:"comment"`
}
