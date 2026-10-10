// Утилита проверки здоровья сервера
// Использование: go run cmd/health/main.go [URL]
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

// HealthResponse — ответ от эндпоинта /health
type HealthResponse struct {
	Status   string `json:"status"`
	Database string `json:"database"`
	Service  string `json:"service"`
}

func main() {
	url := "http://localhost:8080/health"
	if len(os.Args) > 1 {
		url = os.Args[1] + "/health"
	}

	fmt.Printf("🔍 Проверяем сервер: %s\n", url)

	// Создаём HTTP-клиент с таймаутом
	client := &http.Client{Timeout: 5 * time.Second}

	resp, err := client.Get(url)
	if err != nil {
		fmt.Printf("❌ Сервер недоступен: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	// Парсим ответ
	var health HealthResponse
	if err := json.NewDecoder(resp.Body).Decode(&health); err != nil {
		fmt.Printf("❌ Неверный ответ: %v\n", err)
		os.Exit(1)
	}

	// Выводим результат
	fmt.Println("─" + "──────────────────────")
	fmt.Printf("  Статус:   %s\n", statusIcon(health.Status))
	fmt.Printf("  База:     %s\n", statusIcon(health.Database))
	fmt.Printf("  Сервис:   %s\n", health.Service)
	fmt.Println("─" + "──────────────────────")

	if health.Status == "ok" && health.Database == "ok" {
		fmt.Println("✅ Всё работает!")
	} else {
		fmt.Println("⚠️ Есть проблемы!")
		os.Exit(1)
	}
}

func statusIcon(status string) string {
	if status == "ok" {
		return "✅ " + status
	}
	return "❌ " + status
}
