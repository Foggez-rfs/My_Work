// Пакет users — модели пользователей
package users

import (
	"time"

	"gorm.io/gorm"
)

// User — модель пользователя системы
type User struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	Phone        string         `gorm:"uniqueIndex;size:20;not null" json:"phone"`
	PasswordHash string         `gorm:"size:255;not null" json:"-"` // Не отдаём хеш в JSON
	Role         string         `gorm:"size:20;not null;default:customer" json:"role"` // customer или executor
	FirstName    string         `gorm:"size:100;not null" json:"first_name"`
	LastName     string         `gorm:"size:100" json:"last_name"`
	Rating       float64        `gorm:"default:5.0" json:"rating"`
	Skills       string         `gorm:"type:text" json:"skills"`
	Lat          float64        `gorm:"default:0" json:"lat"`
	Lon          float64        `gorm:"default:0" json:"lon"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName — имя таблицы в БД
func (User) TableName() string {
	return "users"
}
