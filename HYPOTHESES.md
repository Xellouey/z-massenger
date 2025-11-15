# HYPOTHESES - Возможные причины проблем

## ПРОБЛЕМА #1: Неверное отображение информации звонящего

### Гипотеза 1.1: Неверная логика определения направления звонка
**Описание:** В `pick_up_body.dart:363` всегда отображается `call!.receiverName` без проверки направления звонка

**Затронутые файлы:**
- `lib/screens/app_screens/pick_up_call/pick_up_body.dart:363`

**Вероятность:** ВЫСОКАЯ ⭐⭐⭐

**Доказательства:**
```dart
// Строка 363 - для аудио звонков
Text('${call!.receiverName} Audio Call')

// Строки 224-228 - для видео звонков (ПРАВИЛЬНАЯ логика!)
Text(
    call!.isGroup == true
        ? call!.groupName!
        : call!.callerId == appCtrl.user["id"]
            ? call!.receiverName!  // Я звоню → показать получателя
            : call!.callerName!,   // Мне звонят → показать звонящего
)
```

**5 Whys:**
1. Почему показывается неверное имя? → Используется receiverName вместо проверки направления
2. Почему не проверяется направление? → Разработчик скопировал логику с другого места без проверки
3. Почему в видео есть проверка, а в аудио нет? → Видео код был исправлен позже, аудио забыли
4. Почему не заметили при тестировании? → Возможно тестировали только исходящие звонки
5. Почему не было code review? → Возможно отсутствие систематического review процесса

**Связь с другими проблемами:** Нет прямой связи

---

### Гипотеза 1.2: Неверные данные в Call модели
**Описание:** Возможно Call.fromMap() неправильно парсит данные из Firebase

**Затронутые файлы:**
- `lib/models/call_model.dart`
- `lib/screens/app_screens/pick_up_call/pick_up_call.dart:152`

**Вероятность:** НИЗКАЯ ⭐

**Доказательства:**
- В логах видно что FCM notification содержит правильное имя "Пашка"
- Push уведомление показывает "Пашка звонит!" корректно
- Значит данные поступают правильно

**5 Whys:**
1. Почему могут быть неверные данные? → Если fromMap() меняет местами caller/receiver
2. Почему push работает правильно? → Push использует данные напрямую из notification
3. Почему тогда в Call model они могут быть неверны? → Маловероятно, т.к. используются те же данные
4. Как проверить? → Нужно логировать Call объект после fromMap()
5. Если данные верны, почему проблема? → См. Гипотезу 1.1 - проблема в UI логике

**Связь с другими проблемами:** Нет

---

## ПРОБЛЕМА #2: Продолжение воспроизведения мелодии

### Гипотеза 2.1: Уведомление не отменяется при принятии звонка
**Описание:** В `pick_up_body.dart` при нажатии "Accept" отменяется вибрация, но не уведомление

**Затронутые файлы:**
- `lib/screens/app_screens/pick_up_call/pick_up_body.dart:124-199`
- `lib/controllers/common_controllers/notification_controller.dart:787`

**Вероятность:** ОЧЕНЬ ВЫСОКАЯ ⭐⭐⭐⭐

**Доказательства:**
```dart
// pick_up_body.dart:126
await Vibration.cancel(); ✓

// НО отсутствует:
// await flutterLocalNotificationsPlugin.cancel(notificationId); ❌
```

```dart
// notification_controller.dart:765-766
ongoing: true,        // Уведомление постоянное
autoCancel: false,    // Не отменяется автоматически
```

**5 Whys:**
1. Почему мелодия продолжает играть? → Уведомление с ongoing:true не отменяется
2. Почему уведомление не отменяется? → Нет кода для отмены в обработчике "Accept"
3. Почему вибрация останавливается, а звук нет? → Vibration.cancel() вызывается, cancel notification - нет
4. Почему помогает открытие шторки? → Пользователь вручную смахивает уведомление
5. Почему ongoing:true? → Для звонков нужно persistent notification, но забыли отменить программно

**Связь с другими проблемами:** Нет прямой связи

---

### Гипотеза 2.2: Дублирующиеся уведомления
**Описание:** В логах видно что уведомление показывается дважды с одинаковым ID

**Затронутые файлы:**
- `lib/controllers/common_controllers/notification_controller.dart:562-639`

**Вероятность:** СРЕДНЯЯ ⭐⭐

**Доказательства:**
```
I/NotificationManager(23877): notify(508096619, ...)
I/flutter (23877): ✅ Notification shown successfully with ID: 508096619
I/flutter (23877): ✅ Notification shown successfully with ID: 508096619
```

**5 Whys:**
1. Почему показывается дважды? → handleMessage() вызывается дважды
2. Почему вызывается дважды? → FCM может отправлять два сообщения (data + notification)
3. Почему это проблема? → Создаются два источника звука
4. Почему один ID? → Используется notification.hashCode, который одинаковый
5. Как это влияет на звук? → Возможно создаются два потока воспроизведения

**Связь с другими проблемами:** Усиливает Гипотезу 2.1

---

### Гипотеза 2.3: Звук воспроизводится не через notification channel
**Описание:** Возможно мелодия запускается отдельно через другой механизм

**Затронутые файлы:**
- `lib/controllers/common_controllers/notification_controller.dart`
- Закомментированный код с `flutter_ringtone_player` (строки 904-1288)

**Вероятность:** НИЗКАЯ ⭐

**Доказательства:**
- Весь код с `FlutterRingtonePlayer` закомментирован
- Текущий код использует только notification channel sound
- Нет других источников воспроизведения звука в активном коде

**5 Whys:**
1. Почему может быть отдельный источник? → Раньше использовался flutter_ringtone_player
2. Почему он закомментирован? → Был refactoring для использования notification sounds
3. Остался ли работающий код? → Нет, весь закомментирован
4. Что воспроизводит звук? → Только notification через RawResourceAndroidNotificationSound
5. Почему тогда не останавливается? → См. Гипотезу 2.1 - уведомление не отменяется

**Связь с другими проблемами:** История рефакторинга, но не активная причина

---

## ПРОБЛЕМА #3: Неверная навигация после звонка

### Гипотеза 3.1: Отсутствие обязательного параметра 'message' в navigation arguments
**Описание:** `_navigateToChat()` передает только `chatId` и `data`, но ChatController ожидает также `message`

**Затронутые файлы:**
- `lib/controllers/app_pages_controllers/audio_call_controller.dart:709-712`
- `lib/controllers/app_pages_controllers/chat_controller.dart:319-335`

**Вероятность:** ОЧЕНЬ ВЫСОКАЯ ⭐⭐⭐⭐

**Доказательства:**
```dart
// audio_call_controller.dart:709-712
Get.toNamed(routeName.chatLayout, arguments: {
  'chatId': '0',
  'data': userContact,
  // ❌ НЕТ 'message': ...
});

// chat_controller.dart:143
data = Get.arguments;

// chat_controller.dart:319
if (data["message"] != null && data['message'] != "") {
  // ❌ CRASH: data не содержит ключ "message"
```

**Стек-трейс:**
```
NoSuchMethodError: The method '[]' was called on null.
#1 ChatController.getChatData (chat_controller.dart:319:13)
```

**5 Whys:**
1. Почему ошибка? → Обращение к несуществующему ключу data["message"]
2. Почему ключ отсутствует? → _navigateToChat() не передает его в arguments
3. Почему не передает? → Функция создана для простой навигации, без автоотправки сообщения
4. Почему getChatData() требует его? → Код проверяет наличие для автоотправки после звонка
5. Как должно быть? → Либо всегда передавать (может быть null), либо проверять существование ключа

**Связь с другими проблемами:** Прямая причина краша

---

### Гипотеза 3.2: Неверная точка возврата после звонка
**Описание:** После звонка должен открываться dashboard, а не конкретный чат

**Затронутые файлы:**
- `lib/controllers/app_pages_controllers/audio_call_controller.dart:681-717`
- `lib/screens/app_screens/pick_up_call/pick_up_body.dart:31-85`

**Вероятность:** ВЫСОКАЯ ⭐⭐⭐

**Доказательства:**
```dart
// audio_call_controller.dart:807-810
log("endCall: Cleanup complete, navigating to chat");
await _navigateToChat();  // ❌ Навигация на чат

// Но пользователь ожидает:
// Get.offAllNamed(routeName.dashboard);  // ✓ Навигация на dashboard
```

**Логи:**
```
[log] endCall: Cleanup complete, navigating to chat
[GETX] GOING TO ROUTE /chatLayout  // ❌ Неверный route
```

**5 Whys:**
1. Почему открывается чат? → Вызывается _navigateToChat()
2. Почему не dashboard? → Разработчик предположил, что после звонка хотят написать
3. Почему это неверно? → Нарушает привычный UX (WhatsApp, Telegram возвращают на список чатов)
4. Как определить правильное поведение? → По требованиям пользователя: "давай будем открывать окно всех чатов"
5. Как это связано с крашем? → Попытка открыть чат без полных данных вызывает ошибку

**Связь с другими проблемами:** Связана с Гипотезой 3.1 - неполные данные для навигации

---

### Гипотеза 3.3: Конфликт между pick_up_body и audio_call_controller навигацией
**Описание:** `pick_up_body._navigateToChat()` и `audio_call_controller._navigateToChat()` имеют разную логику

**Затронутые файлы:**
- `lib/screens/app_screens/pick_up_call/pick_up_body.dart:31-85`
- `lib/controllers/app_pages_controllers/audio_call_controller.dart:681-717`

**Вероятность:** СРЕДНЯЯ ⭐⭐

**Доказательства:**
```dart
// pick_up_body.dart:71-83 - при отклонении звонка
if (isExistingChat) {
  Get.toNamed(routeName.chatLayout, arguments: {
    'chatId': userData[index]['chatId'],  // ✓ Реальный chatId
    'data': userContact,
    'message': appFonts.callYouLater.tr,  // ✓ Есть message
    'isCallEnd': true,
  });
} else {
  Get.toNamed(routeName.chatLayout, arguments: {
    'chatId': '0',
    'data': userContact,
    'message': appFonts.callYouLater.tr,  // ✓ Есть message
    'isCallEnd': true,
  });
}

// audio_call_controller.dart:709-712 - после завершения звонка
Get.toNamed(routeName.chatLayout, arguments: {
  'chatId': '0',
  'data': userContact,
  // ❌ НЕТ 'message'
  // ❌ НЕТ 'isCallEnd'
});
```

**5 Whys:**
1. Почему разная логика? → Функции писались в разное время разными разработчиками
2. Почему не унифицированы? → Отсутствие code review или недостаточная документация API
3. Какая правильная? → pick_up_body более полная (передает все нужные параметры)
4. Почему это важно? → ChatController ожидает определенную структуру arguments
5. Как исправить? → Унифицировать обе функции или использовать общую утилиту навигации

**Связь с другими проблемами:** Подтверждает Гипотезу 3.1

---

### Гипотеза 3.4: Небезопасное обращение к аргументам в ChatController
**Описание:** ChatController не проверяет существование ключей перед обращением

**Затронутые файлы:**
- `lib/controllers/app_pages_controllers/chat_controller.dart:319-335`

**Вероятность:** ВЫСОКАЯ ⭐⭐⭐

**Доказательства:**
```dart
// chat_controller.dart:319 - НЕБЕЗОПАСНО
if (data["message"] != null && data['message'] != "") {
  // Crash если ключ "message" не существует
}

// Должно быть:
if (data != null && data.containsKey("message") && data["message"] != null && data["message"] != "") {
  // Безопасная проверка
}
```

**5 Whys:**
1. Почему происходит crash? → Обращение к несуществующему ключу
2. Почему нет проверки? → Предполагалось что аргументы всегда полные
3. Почему предположение неверно? → Разные источники навигации передают разные аргументы
4. Как должно работать? → Defensive programming - проверка наличия ключа
5. Где еще может быть проблема? → Строки 337-348 (forwardMessage) имеют ту же проблему

**Связь с другими проблемами:** Общая проблема архитектуры - отсутствие валидации входных данных

---

## ДОПОЛНИТЕЛЬНЫЕ ГИПОТЕЗЫ

### Гипотеза 4.1: Отсутствие единой точки навигации после звонков
**Описание:** Нет централизованного метода для обработки навигации после окончания звонков

**Затронутые файлы:**
- Несколько мест с дублированной логикой навигации

**Вероятность:** СРЕДНЯЯ ⭐⭐

**Доказательства:**
- `pick_up_body.dart` имеет свою `_navigateToChat()`
- `audio_call_controller.dart` имеет свою `_navigateToChat()`
- `video_call_controller.dart` вероятно тоже имеет похожую логику
- Нет общего CallNavigationService или подобного

**5 Whys:**
1. Почему дублируется код? → Нет общего сервиса навигации
2. Почему это проблема? → Разная логика в разных местах
3. Как это приводит к багам? → Исправление в одном месте не применяется в другом
4. Как должно быть? → Один метод в shared service
5. Какие риски? → Другие места могут иметь те же баги

**Связь с другими проблемами:** Архитектурная причина всех проблем навигации

---

### Гипотеза 4.2: Race condition при обновлении UI после звонка
**Описание:** Возможен конфликт между удалением calling doc и показом pickup screen

**Затронутые файлы:**
- `lib/controllers/app_pages_controllers/audio_call_controller.dart:733`
- `lib/screens/app_screens/pick_up_call/pick_up_call.dart:140`

**Вероятность:** НИЗКАЯ ⭐

**Доказательства:**
```dart
// audio_call_controller.dart:733
await endCall(call: call!);  // Удаляет calling documents
log("endCall: Calling documents deleted");

// pick_up_call.dart:140
if (callData['status'] == 'ended') {
  return widget.scaffold;
}
```

**5 Whys:**
1. Есть ли race condition? → Возможно, но малове вероятно
2. Как проявлялось бы? → Мерцание pickup screen после endCall
3. Наблюдается ли это? → В логах есть упоминания про "flash of incoming call screen"
4. Но исправлено ли? → Да, commit 8930a60 "Fix: Resolve call end navigation issues and prevent pickup screen flash"
5. Тогда почему еще проблемы? → Flash исправлен, но навигация после endCall всё еще неверная

**Связь с другими проблемами:** Уже исправленная, но связанная проблема

---

## ИТОГОВАЯ ТАБЛИЦА ГИПОТЕЗ

| ID | Описание | Вероятность | Файлы | Связь |
|---|---|---|---|---|
| 1.1 | Неверная логика отображения имени в аудио звонках | ВЫСОКАЯ ⭐⭐⭐ | pick_up_body.dart:363 | - |
| 1.2 | Неверный парсинг Call model | НИЗКАЯ ⭐ | call_model.dart | - |
| 2.1 | Уведомление не отменяется при принятии | ОЧЕНЬ ВЫСОКАЯ ⭐⭐⭐⭐ | pick_up_body.dart, notification_controller.dart | 2.2 |
| 2.2 | Дублирующиеся уведомления | СРЕДНЯЯ ⭐⭐ | notification_controller.dart | 2.1 |
| 2.3 | Отдельный источник звука | НИЗКАЯ ⭐ | - | - |
| 3.1 | Отсутствие параметра 'message' | ОЧЕНЬ ВЫСОКАЯ ⭐⭐⭐⭐ | audio_call_controller.dart, chat_controller.dart | 3.2, 3.3 |
| 3.2 | Неверная точка возврата (чат вместо dashboard) | ВЫСОКАЯ ⭐⭐⭐ | audio_call_controller.dart | 3.1 |
| 3.3 | Конфликт между разными _navigateToChat | СРЕДНЯЯ ⭐⭐ | pick_up_body.dart, audio_call_controller.dart | 3.1 |
| 3.4 | Небезопасное обращение к аргументам | ВЫСОКАЯ ⭐⭐⭐ | chat_controller.dart:319 | 3.1 |
| 4.1 | Отсутствие единой точки навигации | СРЕДНЯЯ ⭐⭐ | Множество файлов | 3.1-3.3 |
| 4.2 | Race condition (уже исправлено) | НИЗКАЯ ⭐ | audio_call_controller.dart, pick_up_call.dart | - |
