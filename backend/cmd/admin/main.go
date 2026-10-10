// CLI-утилита администрирования «Моё дело»
// Использование: go run cmd/admin/main.go [команда] [аргументы]
// Команды: list, orders, role <user_id> <new_role>, delete <user_id>
package main

import (
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
	"github.com/moe-delo/moe-delo/internal/orders"
	"github.com/moe-delo/moe-delo/internal/users"
	"github.com/moe-delo/moe-delo/pkg/db"
)

func main() {
	godotenv.Load()
	db.Init()

	if len(os.Args) < 2 {
		printUsage()
		return
	}

	switch os.Args[1] {
	case "list":
		listUsers()
	case "orders":
		listOrders()
	case "role":
		if len(os.Args) < 4 {
			fmt.Println("Использование: admin role <user_id> <customer|executor>")
			return
		}
		changeRole(os.Args[2], os.Args[3])
	case "delete":
		if len(os.Args) < 3 {
			fmt.Println("Использование: admin delete <user_id>")
			return
		}
		deleteUser(os.Args[2])
	default:
		printUsage()
	}
}

func printUsage() {
	fmt.Println("🔧 Админ-панель «Моё дело»")
	fmt.Println("Команды:")
	fmt.Println("  list                    — список всех пользователей")
	fmt.Println("  orders                  — список всех заказов")
	fmt.Println("  role <id> <role>        — сменить роль пользователя")
	fmt.Println("  delete <id>             — удалить пользователя")
}

func listUsers() {
	var allUsers []users.User
	db.DB.Find(&allUsers)

	fmt.Printf("👥 Пользователи (%d):\n", len(allUsers))
	fmt.Println("─" + "──────────────────────────────────────────")
	for _, u := range allUsers {
		role := "👴 Заказчик"
		if u.Role == "executor" {
			role = "🙋 Исполнитель"
		}
		fmt.Printf("  ID: %d | %s | %s | %s | ⭐ %.1f\n",
			u.ID, u.Phone, u.FirstName, role, u.Rating)
	}
}

func listOrders() {
	var allOrders []orders.Order
	db.DB.Order("created_at DESC").Find(&allOrders)

	fmt.Printf("📋 Заказы (%d):\n", len(allOrders))
	fmt.Println("─" + "──────────────────────────────────────────")
	for _, o := range allOrders {
		fmt.Printf("  ID: %d | %s | %s | %s | %s\n",
			o.ID, o.Category, statusEmoji(o.Status), o.Status, o.Address)
	}
}

func changeRole(userIDStr, newRole string) {
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		log.Fatal("Неверный ID пользователя")
	}

	if newRole != "customer" && newRole != "executor" {
		log.Fatal("Роль должна быть 'customer' или 'executor'")
	}

	var user users.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		log.Fatal("Пользователь не найден")
	}

	user.Role = newRole
	db.DB.Save(&user)
	fmt.Printf("✅ Роль пользователя %s изменена на %s\n", user.FirstName, newRole)
}

func deleteUser(userIDStr string) {
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		log.Fatal("Неверный ID пользователя")
	}

	var user users.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		log.Fatal("Пользователь не найден")
	}

	db.DB.Delete(&user)
	fmt.Printf("🗑 Пользователь %s (%s) удалён\n", user.FirstName, user.Phone)
}

func statusEmoji(status string) string {
	switch status {
	case "pending":
		return "⏳"
	case "accepted":
		return "✅"
	case "completed":
		return "✔️"
	case "cancelled":
		return "❌"
	default:
		return "?"
	}
}
