// Пакет docs — модели документов
package docs

import (
	"time"

	"gorm.io/gorm"
)

// Document — модель загруженного документа
type Document struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	UserID    uint           `gorm:"not null;index" json:"user_id"`
	DocType   string         `gorm:"size:50;not null" json:"doc_type"` // passport, snils, bank, parent_consent
	FilePath  string         `gorm:"size:500;not null" json:"file_path"`
	Verified  bool           `gorm:"default:false" json:"verified"`
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName — имя таблицы в БД
func (Document) TableName() string {
	return "documents"
}
