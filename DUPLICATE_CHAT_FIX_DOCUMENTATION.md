# Исправление дублирования чатов - Документация

## Дата исправления
15 ноября 2025

## Описание проблемы

Пользователи сталкивались с проблемой дублирования чатов с одним и тем же контактом. При отправке сообщений одному пользователю создавалось несколько отдельных чатов вместо одного единого.

![Проблема - множество дубликатов чата](./docs/duplicate_chats_issue.png)

## Корневые причины

### Проблема #1: Некорректная логика проверки существования чата
**Файл:** `lib/screens/app_screens/chat_message/chat_message_api.dart`

**Было:**
```dart
.where("chatId", isEqualTo: newChatId)
```

**Проблема:**
- Функция искала существующий чат по `chatId`
- При первом сообщении `chatId = "0"`, поэтому поиск НЕ находил существующие чаты
- Использование `.add()` создавало новый документ с автогенерируемым ID
- Каждое новое сообщение могло создавать новую запись

**Стало:**
```dart
.where("isOneToOne", isEqualTo: true)
// + проверка участников чата (senderId/receiverId)
```

---

### Проблема #2: Неправильный параметр receiverId
**Файлы:**
- `lib/controllers/app_pages_controllers/chat_controller.dart` (4 вхождения)
- `lib/controllers/app_pages_controllers/forward_controller.dart` (1 вхождение)
- `lib/controllers/app_pages_controllers/broadcast_chat_controller.dart` (2 вхождения)

**Было:**
```dart
await ChatMessageApi().saveMessageInUserCollection(
    pId,              // id (владелец коллекции - получатель)
    pId,              // receiverId ← ОШИБКА! Должен быть отправитель
    chatId,
    ...
);
```

**Проблема:**
- В документе чата у получателя сохранялся `receiverId = pId` (самого себя)
- Это нарушало логику поиска чатов по участникам
- Дополнительно способствовало созданию дубликатов

**Стало:**
```dart
await ChatMessageApi().saveMessageInUserCollection(
    pId,              // id (владелец коллекции - получатель)
    userData["id"],   // receiverId (с кем чат - отправитель) ✅
    chatId,
    ...
);
```

---

## Внесённые изменения

### 1. Исправлена логика поиска существующих чатов

**Файл:** `lib/screens/app_screens/chat_message/chat_message_api.dart`

**Изменения:**
- Изменён запрос поиска с `where("chatId", isEqualTo: newChatId)` на `where("isOneToOne", isEqualTo: true)`
- Добавлена проверка участников чата (по `senderId` и `receiverId`)
- Чат теперь ищется по комбинации участников, а не по `chatId`

**Код:**
```dart
// Find existing chat with this user by checking participants
var existingChat = value.docs.where((doc) {
  var data = doc.data();
  // Check if participants match (in any order)
  return (data["senderId"] == receiverId || data["receiverId"] == receiverId) &&
         (data["senderId"] == senderId || data["receiverId"] == senderId);
}).toList();

if (existingChat.isNotEmpty) {
  // UPDATE existing chat
  ...
} else {
  // CREATE new chat only if not found
  ...
}
```

---

### 2. Исправлен параметр receiverId во всех вызовах

#### 2.1. ChatController (4 исправления)
**Файл:** `lib/controllers/app_pages_controllers/chat_controller.dart`

**Строки:** 960, 1048, 1239, 1320

**Было:**
```dart
await ChatMessageApi().saveMessageInUserCollection(pId, pId, chatId, ...)
```

**Стало:**
```dart
await ChatMessageApi().saveMessageInUserCollection(pId, userData["id"], chatId, ...)
```

---

#### 2.2. ForwardController (1 исправление)
**Файл:** `lib/controllers/app_pages_controllers/forward_controller.dart`

**Строка:** 128

**Было:**
```dart
await ChatMessageApi().saveMessageInUserCollection(sendTo, sendTo, id, ...)
```

**Стало:**
```dart
await ChatMessageApi().saveMessageInUserCollection(sendTo, appCtrl.user["id"], id, ...)
```

---

#### 2.3. BroadcastChatController (2 исправления)
**Файл:** `lib/controllers/app_pages_controllers/broadcast_chat_controller.dart`

**Строки:** 560, 590

**Было:**
```dart
await ChatMessageApi().saveMessageInUserCollection(element.value["id"], element.value["id"], ...)
```

**Стало:**
```dart
await ChatMessageApi().saveMessageInUserCollection(element.value["id"], userData["id"], ...)
```

---

### 3. Создан скрипт очистки дубликатов

**Файл:** `lib/controllers/bottom_controllers/dashboard_controller.dart`

**Добавлена функция:** `cleanupDuplicateChats()`

**Функциональность:**
- Ищет все чаты пользователя с флагом `isOneToOne = true`
- Группирует чаты по другому участнику
- Для каждого участника оставляет только самый свежий чат (по `updateStamp`)
- Удаляет все дубликаты
- Показывает уведомление с количеством удалённых дубликатов

**Как запустить:**
1. Откройте файл `lib/controllers/bottom_controllers/dashboard_controller.dart`
2. Найдите строку `// await cleanupDuplicateChats();` (строка ~261)
3. Раскомментируйте её: `await cleanupDuplicateChats();`
4. Запустите приложение **ОДИН РАЗ**
5. После очистки **закомментируйте** строку обратно

**Или запустите вручную:**
```dart
final dashCtrl = Get.find<DashboardController>();
await dashCtrl.cleanupDuplicateChats();
```

---

## Результат

### До исправления:
- ❌ Множество дубликатов чатов с одним контактом
- ❌ Каждое новое сообщение могло создавать новый чат
- ❌ Неправильные метаданные чата (receiverId)

### После исправления:
- ✅ Один единый чат с каждым контактом
- ✅ Поиск чата по участникам (надёжный метод)
- ✅ Правильные метаданные чата
- ✅ Автоматическая очистка существующих дубликатов

---

## Тестирование

### Шаги тестирования:

1. **Создание нового чата:**
   - Откройте список контактов
   - Выберите контакт
   - Отправьте сообщение
   - ✅ Должен создаться **ОДИН** чат

2. **Отправка нескольких сообщений:**
   - Отправьте несколько сообщений подряд
   - Закройте чат
   - Снова откройте список чатов
   - ✅ Должен быть **ОДИН** чат с последним сообщением

3. **Повторное открытие чата:**
   - Откройте существующий чат
   - Отправьте сообщение
   - ✅ Сообщение должно добавиться в существующий чат

4. **Проверка после очистки:**
   - Запустите скрипт очистки
   - Проверьте список чатов
   - ✅ Дубликаты должны быть удалены

---

## Потенциальные побочные эффекты

### Минимальные риски:
- ✅ Изменения затрагивают только логику поиска/создания чатов
- ✅ Все существующие чаты остаются без изменений (кроме дубликатов)
- ✅ Обратная совместимость сохранена

### Что может произойти:
- При первом запуске после обновления старые чаты будут корректно найдены
- Скрипт очистки безопасно удаляет только дубликаты (оставляет самый свежий)

---

## Рекомендации

1. **Протестируйте на тестовом аккаунте:**
   - Создайте новый чат
   - Отправьте несколько сообщений
   - Убедитесь, что дубликаты не создаются

2. **Запустите очистку дубликатов:**
   - Раскомментируйте строку в `dashboard_controller.dart:261`
   - Запустите приложение **ОДИН РАЗ**
   - Проверьте лог на наличие сообщения "✅ Cleanup complete"
   - Закомментируйте строку обратно

3. **Мониторинг:**
   - Проверьте логи на наличие ошибок
   - Убедитесь, что новые чаты создаются корректно
   - Проверьте, что существующие чаты работают

---

## Версионирование

**Версия до исправления:** 1.0.0+1
**Версия после исправления:** 1.0.1+2 (рекомендуется)

---

## Контакты для вопросов

При возникновении проблем:
1. Проверьте логи Flutter
2. Убедитесь, что все изменения применены корректно
3. Проверьте, что скрипт очистки выполнился успешно

---

## Changelog

### 15.11.2025 - Исправление дублирования чатов
- ✅ Исправлена логика поиска существующих чатов (по участникам)
- ✅ Исправлен параметр receiverId в 7 местах
- ✅ Добавлен скрипт автоматической очистки дубликатов
- ✅ Добавлена документация

---

**Статус:** ✅ Исправлено и готово к тестированию
