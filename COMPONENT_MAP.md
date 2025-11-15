# COMPONENT INTERACTION MAP

## Поток входящего звонка

```
Firebase Cloud Messaging (FCM)
    │
    ├─→ notification_controller.dart::handleMessage()
    │       │
    │       ├─→ Определяет isCall = true
    │       └─→ showNotification()
    │               │
    │               ├─→ Создает notification с ID (hashCode)
    │               ├─→ Канал: call_channel
    │               └─→ Звук: callsound.wav
    │
    └─→ pick_up_call.dart::StreamBuilder
            │
            ├─→ Слушает: /calls/{userId}/calling
            ├─→ Проверяет: call.receiverId == currentUserId (входящий?)
            ├─→ Запускает вибрацию для входящих
            │
            └─→ pick_up_body.dart
                    │
                    ├─→ ОТОБРАЖАЕТ: '${call!.receiverName} Audio Call' ❌ БАГ #1
                    │   (должно быть: call!.callerName для входящих)
                    │
                    └─→ При нажатии "Accept":
                            │
                            ├─→ Vibration.cancel() ✓
                            ├─→ Запрос разрешений
                            ├─→ cameraController?.dispose()
                            └─→ Get.toNamed(routeName.audioCall, arguments: data)
```

## Поток звонка в процессе

```
audio_call_controller.dart
    │
    ├─→ initAgora()
    │       │
    │       ├─→ Создает Agora RTC Engine
    │       ├─→ Регистрирует event handlers:
    │       │       ├─→ onJoinChannelSuccess
    │       │       ├─→ onUserJoined → startTimerNow()
    │       │       ├─→ onUserOffline → onCallEnd()
    │       │       └─→ onLeaveChannel → _dispose() → _closeCallView()
    │       │
    │       └─→ joinChannel()
    │
    └─→ Обработка событий:
            │
            └─→ onUserOffline():
                    │
                    ├─→ isAlreadyEnded = true
                    └─→ onCallEnd(context) ⚠️
```

## Поток завершения звонка

```
audio_call_controller.dart::onCallEnd()
    │
    ├─→ Проверка: if (_isEnding) return
    ├─→ _isEnding = true
    ├─→ isAlreadyEnded = true
    │
    ├─→ endCall(call) - удаляет calling documents из Firebase
    │       │
    │       ├─→ Удаляет: /calls/{callerId}/calling
    │       └─→ Удаляет: /calls/{receiverId}/calling
    │
    ├─→ Обновляет историю звонков
    │
    ├─→ _dispose() - cleanup Agora
    │
    └─→ _navigateToChat() ❌ БАГ #3
            │
            ├─→ Создает UserContactModel
            ├─→ Get.back() - закрывает экран звонка
            ├─→ Delay 100ms
            └─→ Get.toNamed(routeName.chatLayout, arguments: {
                    'chatId': '0', ⚠️
                    'data': userContact,
                    // НЕТ 'message' ключа! ❌
                })
```

## Поток открытия чата

```
Get.toNamed(routeName.chatLayout)
    │
    └─→ chat_controller.dart
            │
            ├─→ onReady()
            │       │
            │       ├─→ data = Get.arguments ⚠️
            │       ├─→ chatId = data["chatId"] (= "0")
            │       ├─→ userContactModel = data["data"]
            │       └─→ getChatData()
            │
            └─→ getChatData()
                    │
                    ├─→ if (chatId != "0") { ... } else { ... }
                    │
                    ├─→ Подписка на обновления пользователя
                    │
                    └─→ if (data["message"] != null && data['message'] != "") ❌
                            │
                            └─→ ОШИБКА: NoSuchMethodError
                                data не содержит ключ "message"
```

## Поток уведомлений (Проблема #2)

```
FCM Message → handleMessage()
    │
    └─→ showNotification()
            │
            ├─→ Создает AndroidNotificationDetails:
            │       ├─→ channel: call_channel
            │       ├─→ sound: RawResourceAndroidNotificationSound('callsound')
            │       ├─→ ongoing: true (для звонков) ⚠️
            │       ├─→ autoCancel: false (для звонков) ⚠️
            │       └─→ timeoutAfter: 60000ms
            │
            └─→ show(notificationId, title, body, details)
                    │
                    └─→ notificationId = notification?.hashCode
                        или DateTime.now().millisecondsSinceEpoch
```

**Проблема:** При принятии звонка уведомление НЕ отменяется явно!
- В pick_up_body.dart:126 есть `Vibration.cancel()` ✓
- НО нет `flutterLocalNotificationsPlugin.cancel(notificationId)` ❌

## Зависимости компонентов

### Прямые зависимости:

```
pick_up_call.dart
    ├─→ pick_up_body.dart
    ├─→ Call (model)
    ├─→ FirebaseFirestore
    ├─→ Camera (camera package)
    └─→ Vibration (vibration package)

pick_up_body.dart
    ├─→ Call (model)
    ├─→ RecentChatController (Provider)
    ├─→ VideoCallController (Get)
    ├─→ PermissionHandlerController (Get)
    ├─→ UserContactModel (model)
    ├─→ Vibration
    └─→ Navigation (Get.toNamed)

audio_call_controller.dart
    ├─→ RtcEngine (Agora)
    ├─→ Call (model)
    ├─→ FirebaseFirestore
    ├─→ UserContactModel (model)
    ├─→ AudioPlayer (audioplayers)
    └─→ Navigation (Get.toNamed, Get.back)

chat_controller.dart
    ├─→ FirebaseFirestore
    ├─→ UserContactModel (model)
    ├─→ MessageModel (model)
    ├─→ Get.arguments (navigation params)
    └─→ ChatMessageApi

notification_controller.dart
    ├─→ FirebaseMessaging
    ├─→ FlutterLocalNotificationsPlugin
    ├─→ UserContactModel (model)
    └─→ Navigation (Get.toNamed)
```

### Поток данных Call Model:

```
FCM Notification Data
    │
    ├─→ pick_up_call.dart: Call.fromMap(callData)
    │       │
    │       └─→ Call object содержит:
    │               ├─→ callerId (ID звонящего)
    │               ├─→ callerName (имя звонящего)
    │               ├─→ callerPic (фото звонящего)
    │               ├─→ receiverId (ID получателя)
    │               ├─→ receiverName (имя получателя)
    │               ├─→ receiverPic (фото получателя)
    │               ├─→ channelId (Agora channel)
    │               ├─→ agoraToken
    │               └─→ isVideoCall
    │
    └─→ Передается через navigation arguments
            │
            ├─→ В audio_call_controller (через Get.arguments)
            └─→ В pick_up_body (через widget params)
```

## Критические точки взаимодействия

### 1. Навигация после звонка (БАГ #3)
**Поток:**
```
AudioCallController.onCallEnd()
    → _navigateToChat()
        → Get.toNamed(routeName.chatLayout, arguments)
            → ChatController.onReady()
                → data = Get.arguments
                    → getChatData()
                        → data["message"] ❌ CRASH
```

**Проблема:** Аргументы не содержат обязательный ключ "message"

### 2. Отображение звонящего (БАГ #1)
**Логика определения направления:**
```
call.receiverId == appCtrl.user["id"]
    → TRUE: Входящий звонок (я - получатель)
        → Показывать: call.callerName ✓
    → FALSE: Исходящий звонок (я - звонящий)
        → Показывать: call.receiverName ✓
```

**Текущая реализация:**
```dart
// pick_up_body.dart:363
Text('${call!.receiverName} Audio Call')
```
❌ Всегда показывает receiverName, независимо от направления!

### 3. Остановка мелодии (БАГ #2)
**Текущие попытки остановки:**
```
pick_up_body.dart:126 → Vibration.cancel() ✓
pick_up_body.dart:??? → flutterLocalNotificationsPlugin.cancel() ❌ ОТСУТСТВУЕТ
```

**Notification настройки:**
```dart
ongoing: true,        // Уведомление не удаляется автоматически
autoCancel: false,    // Не отменяется при клике
sound: RawResourceAndroidNotificationSound('callsound')
```

**Проблема:** Уведомление создается с `ongoing: true` и `autoCancel: false`,
но никогда не отменяется программно при принятии звонка!
