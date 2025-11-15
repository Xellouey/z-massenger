// Скрипт для очистки старых звонков из Firestore
// Запустите один раз: dart run cleanup_old_calls.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Инициализируем Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "YOUR_API_KEY",  // Замените на ваш ключ
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_SENDER_ID",
      projectId: "z-messenger-bc7fd",
    ),
  );

  final firestore = FirebaseFirestore.instance;

  print('========================================');
  print('Очистка старых звонков из Firestore');
  print('========================================\n');

  // ID вашего пользователя (Дмитрий)
  const String userId = '1PV0K8UblpVxRHvzmBOf4znKzWN2';

  try {
    // Получаем все активные звонки
    final callingSnapshot = await firestore
        .collection('calls')
        .doc(userId)
        .collection('calling')
        .get();

    print('Найдено активных звонков: ${callingSnapshot.docs.length}');

    if (callingSnapshot.docs.isEmpty) {
      print('✅ Нет активных звонков для удаления');
      return;
    }

    // Удаляем все активные звонки
    final batch = firestore.batch();
    int count = 0;

    for (var doc in callingSnapshot.docs) {
      final data = doc.data();
      print('\nУдаляем звонок:');
      print('  ID: ${doc.id}');
      print('  Caller: ${data['callerName']}');
      print('  Receiver: ${data['receiverName']}');
      print('  Timestamp: ${data['timestamp']}');
      print('  Channel: ${data['channelId']}');

      batch.delete(doc.reference);
      count++;
    }

    // Выполняем удаление
    await batch.commit();

    print('\n========================================');
    print('✅ Успешно удалено звонков: $count');
    print('========================================');

  } catch (e) {
    print('❌ Ошибка при очистке: $e');
  }
}
