// Заполнение БД тестовыми данными
package main

import (
	"log"

	"github.com/joho/godotenv"
	"github.com/Foggez-rfs/My_Work/backend/internal/orders"
	"github.com/Foggez-rfs/My_Work/backend/internal/rating"
	"github.com/Foggez-rfs/My_Work/backend/internal/users"
	"github.com/Foggez-rfs/My_Work/backend/pkg/db"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	godotenv.Load()
	db.Init()

	// Миграция
	db.DB.AutoMigrate(&users.User{}, &orders.Order{}, &rating.Review{})

	log.Println("🌱 Заполняем БД тестовыми данными...")

	// Создаём тестовых пользователей
	hash1, _ := bcrypt.GenerateFromPassword([]byte("demo1"), bcrypt.DefaultCost)
	hash2, _ := bcrypt.GenerateFromPassword([]byte("demo2"), bcrypt.DefaultCost)
	hash3, _ := bcrypt.GenerateFromPassword([]byte("demo3"), bcrypt.DefaultCost)

	customer := users.User{
		Phone:        "+79001112233",
		PasswordHash: string(hash1),
		Role:         "customer",
		FirstName:    "Мария Ивановна",
		Rating:       5.0,
		Lat:          55.7558,
		Lon:          37.6173,
	}
	db.DB.FirstOrCreate(&customer, users.User{Phone: customer.Phone})

	executor1 := users.User{
		Phone:        "+79004445566",
		PasswordHash: string(hash2),
		Role:         "executor",
		FirstName:    "Алексей Петров",
		Rating:       4.8,
		Skills:       "сантехника,электрика,ремонт",
		Lat:          55.7560,
		Lon:          37.6180,
	}
	db.DB.FirstOrCreate(&executor1, users.User{Phone: executor1.Phone})

	executor2 := users.User{
		Phone:        "+79007778899",
		PasswordHash: string(hash3),
		Role:         "executor",
		FirstName:    "Дмитрий Сидоров",
		Rating:       4.5,
		Skills:       "уборка,доставка,сопровождение",
		Lat:          55.7540,
		Lon:          37.6150,
	}
	db.DB.FirstOrCreate(&executor2, users.User{Phone: executor2.Phone})

	// Создаём тестовые заказы
	exec1ID := executor1.ID
	exec2ID := executor2.ID

	order1 := orders.Order{
		CustomerID:  customer.ID,
		Description: "Прорвало кран на кухне, вода льётся",
		Category:    "Сантехника 🔧",
		Priority:    1,
		Address:     "ул. Ленина, д. 15, кв. 3",
		Lat:         55.7558,
		Lon:         37.6173,
		Status:      "pending",
	}
	db.DB.FirstOrCreate(&order1, orders.Order{Description: order1.Description})

	order2 := orders.Order{
		CustomerID:  customer.ID,
		ExecutorID:  &exec1ID,
		Description: "Нужно помочь дойти до поликлиники",
		Category:    "Сопровождение 🚶",
		Priority:    3,
		Address:     "ул. Мира, д. 7, кв. 12",
		Lat:         55.7560,
		Lon:         37.6180,
		Status:      "accepted",
	}
	db.DB.FirstOrCreate(&order2, orders.Order{Description: order2.Description})

	order3 := orders.Order{
		CustomerID:  customer.ID,
		ExecutorID:  &exec2ID,
		Description: "Нужно купить продукты в магазине",
		Category:    "Доставка 📦",
		Priority:    3,
		Address:     "пр. Победы, д. 22, кв. 5",
		Lat:         55.7540,
		Lon:         37.6150,
		Status:      "completed",
	}
	db.DB.FirstOrCreate(&order3, orders.Order{Description: order3.Description})

	// Создаём отзыв
	review := rating.Review{
		OrderID:    order3.ID,
		ExecutorID: exec2ID,
		CustomerID: customer.ID,
		Score:      5,
		Comment:    "Спасибо большое, всё купил быстро!",
	}
	db.DB.FirstOrCreate(&review, rating.Review{OrderID: order3.ID})

	log.Println("✅ Тестовые данные загружены!")
	log.Println("📱 Тестовые аккаунты:")
	log.Println("   Заказчик:    +79001112233 / demo1")
	log.Println("   Исполнитель: +79004445566 / demo2")
	log.Println("   Исполнитель: +79007778899 / demo3")
}
