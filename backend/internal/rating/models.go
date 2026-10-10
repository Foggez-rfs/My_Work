// Пакет rating — модели отзывов
package rating

import (
	"time"

	"gorm.io/gorm"
)

// Review — модель оценки работы исполнителя
type Review struct {
	ID         uint           `gorm:"primaryKey" json:"id"`
	OrderID    uint           `gorm:"not null;index" json:"order_id"`
	ExecutorID uint           `gorm:"not null;index" json:"executor_id"`
	CustomerID uint           `gorm:"not null;index" json:"customer_id"`
	Score      int            `gorm:"not null" json:"score"` // 1–5 звёзд
	Comment    string         `gorm:"type:text" json:"comment"`
	CreatedAt  time.Time      `json:"created_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName — имя таблицы в БД
func (Review) TableName() string {
	return "reviews"
}
