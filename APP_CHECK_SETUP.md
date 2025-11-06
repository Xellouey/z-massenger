# Firebase App Check - Настройка для разработки

## Проблема
Ошибка: `[firebase_auth/missing-client-identifier]` или `Error code:39`

Причина: Play Integrity требует регистрации приложения в Google Play Console, что не подходит для разработки.

## Решение: Использовать Debug Provider

### Шаг 1: Получить Debug Token

После запуска приложения с debug provider, в логах появится:

```
D/FirebaseAppCheck: App Check debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

**Как запустить и получить токен:**

```bash
cd D:\Projects\chatzy_regular\chatzy_New
flutter clean
flutter pub get
flutter run
```

Откройте Android Studio Logcat и найдите строку с "App Check debug token"

### Шаг 2: Добавить Debug Token в Firebase Console

1. Откройте Firebase Console: https://console.firebase.google.com/
2. Выберите проект: **z-messenger-bc7fd**
3. Перейдите в **App Check** (слева в меню)
4. Выберите приложение: **com.webiots.chatzy**
5. Нажмите на три точки (...) → **Manage debug tokens**
6. Нажмите **Add debug token**
7. Вставьте токен из логов
8. Нажмите **Save**

### Шаг 3: Перезапустить приложение

```bash
flutter run --uninstall-first
```

## Как это работает

- **Debug Mode** (при разработке): используется `AndroidProvider.debug`
- **Release Mode** (в продакшене): используется `AndroidProvider.playIntegrity`

Код автоматически переключается между ними через `kDebugMode`.

## Для продакшена

Перед релизом нужно:

1. Загрузить APK в Google Play Console (Internal Testing track)
2. Включить Play Integrity API в Firebase Console
3. Убедиться что SHA-256 отпечатки добавлены (уже добавлены ✅)

## Важно

⚠️ Debug токены работают **ТОЛЬКО** в debug сборках!
⚠️ Для release сборки нужен Play Integrity
