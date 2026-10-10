// Пакет geo — геодезические расчёты
package geo

import "math"

// Haversine — расчёт расстояния между двумя точками на поверхности Земли
// Координаты в градусах, результат в метрах
// Используется для поиска заказов в радиусе N км
func Haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000.0 // Средний радиус Земли в метрах

	// Переводим градусы в радианы
	toRad := func(deg float64) float64 {
		return deg * math.Pi / 180
	}

	dLat := toRad(lat2 - lat1)
	dLon := toRad(lon2 - lon1)

	// Формула Haversine
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(toRad(lat1))*math.Cos(toRad(lat2))*
			math.Sin(dLon/2)*math.Sin(dLon/2)

	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return R * c // Расстояние в метрах
}

// IsWithinRadius — проверка, находится ли точка в заданном радиусе
func IsWithinRadius(lat1, lon1, lat2, lon2 float64, radiusMeters float64) bool {
	return Haversine(lat1, lon1, lat2, lon2) <= radiusMeters
}
