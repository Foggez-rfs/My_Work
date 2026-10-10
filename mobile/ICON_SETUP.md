# 📱 Настройка иконки приложения

## Автоматическая генерация иконок

Для генерации иконок всех размеров используйте пакет `flutter_launcher_icons`:

### 1. Добавьте в `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#1E3A8A"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

### 2. Поместите иконку в `assets/icon/app_icon.png` (1024×1024 px)

### 3. Запустите генерацию:

```bash
flutter pub get
dart run flutter_launcher_icons
```

---

## Ручная настройка (если не работает автоматическая)

### Android

Поместите иконку в следующие директории:

```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      (48×48)
├── mipmap-hdpi/ic_launcher.png      (72×72)
├── mipmap-xhdpi/ic_launcher.png     (96×96)
├── mipmap-xxhdpi/ic_launcher.png    (144×144)
└── mipmap-xxxhdpi/ic_launcher.png   (192×192)
```

### iOS

Используйте Xcode Asset Catalog:

```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png  (20×20)
├── Icon-App-20x20@2x.png  (40×40)
├── Icon-App-20x20@3x.png  (60×60)
├── Icon-App-29x29@1x.png  (29×29)
├── Icon-App-29x29@2x.png  (58×58)
├── Icon-App-29x29@3x.png  (87×87)
├── Icon-App-40x40@1x.png  (40×40)
├── Icon-App-40x40@2x.png  (80×80)
├── Icon-App-40x40@3x.png  (120×120)
├── Icon-App-60x60@2x.png  (120×120)
├── Icon-App-60x60@3x.png  (180×180)
└── Icon-App-1024x1024@1x.png (1024×1024)
```

---

## Онлайн-генераторы иконок

Если нет возможности использовать `flutter_launcher_icons`:

1. **https://icon.kitchen/** — генератор адаптивных иконок
2. **https://appicon.co/** — генератор для iOS и Android
3. **https://www.appiconbuilder.com/** — универсальный генератор

Загрузите PNG 1024×1024 → скачайте архив → распакуйте в нужные директории.

---

## Требования к иконке

- **Размер:** 1024×1024 px (исходник)
- **Формат:** PNG с прозрачностью (для адаптивных иконок)
- **Содержимое:** Логотип без текста (текст добавится автоматически)
- **Цвета:** Синий фон #1E3A8A, белый логотип 🤝

---

## Проверка

После настройки иконки:

```bash
flutter clean
flutter pub get
flutter run
```

Иконка должна появиться:
- На главном экране устройства
- В списке приложений
- В настройках телефона

---

## Troubleshooting

### Иконка не меняется

```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### Ошибка при сборке

Проверьте, что все размеры иконок присутствуют в соответствующих директориях.

### Адаптивная иконка не работает (Android 8+)

Убедитесь, что в `AndroidManifest.xml` есть:

```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round">
```
