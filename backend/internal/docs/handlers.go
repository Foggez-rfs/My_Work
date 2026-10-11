// Пакет docs — обработчики загрузки документов
package docs

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/Foggez-rfs/My_Work/backend/pkg/db"
)

// UploadDocument — загрузка документа (паспорт, СНИЛС, согласие родителя)
func UploadDocument(c *gin.Context) {
	userID := c.GetUint("user_id")

	// Получаем файл из запроса
	file, err := c.FormFile("document")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Прикрепите файл документа"})
		return
	}

	// Получаем тип документа
	docType := c.PostForm("doc_type")
	if docType == "" {
		docType = "passport"
	}

	// Проверяем допустимые типы
	validTypes := map[string]bool{
		"passport":       true,
		"snils":          true,
		"bank":           true,
		"parent_consent": true,
	}
	if !validTypes[docType] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Недопустимый тип документа"})
		return
	}

	// Создаём директорию для загрузок
	uploadDir := "uploads/documents"
	os.MkdirAll(uploadDir, 0755)

	// Формируем имя файла (уникальное)
	filename := fmt.Sprintf("%d_%s_%s", userID, docType, time.Now().Format("20060102150405"))
	ext := filepath.Ext(file.Filename)
	filePath := filepath.Join(uploadDir, filename+ext)

	// Сохраняем файл
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения файла"})
		return
	}

	// Создаём запись в БД
	doc := Document{
		UserID:   userID,
		DocType:  docType,
		FilePath: filePath,
		Verified: false,
	}
	db.DB.Create(&doc)

	c.JSON(http.StatusCreated, gin.H{
		"document": doc,
		"message":  "Документ загружен. Ожидайте проверки.",
	})
}
