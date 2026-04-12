import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteInAppBanner {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool openInForeground;
  final String? imageUrl; // URL da imagem (opcional)

  const RemoteInAppBanner({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.openInForeground,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'openInForeground': openInForeground,
      'imageUrl': imageUrl,
    };
  }

  factory RemoteInAppBanner.fromJson(Map<String, dynamic> json) {
    return RemoteInAppBanner(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Nova mensagem',
      body: json['body']?.toString() ?? '',
      receivedAt: DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      openInForeground: json['openInForeground'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 [BG] Push recebido: ${message.messageId}');
}

class RemoteMessagingService {
  static const String _pendingBannerKey = 'pending_remote_banner';
  static const String _lastSeenFirestoreBannerIdKey =
      'last_seen_firestore_banner_id';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<RemoteInAppBanner?> inAppBannerNotifier =
      ValueNotifier<RemoteInAppBanner?>(null);

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'remote_messages_channel',
    'Mensagens remotas',
    description: 'Canal para mensagens remotas enviadas pelo painel',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static StreamSubscription<QuerySnapshot>? _firestoreListener;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermissions();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) async {
      await _handleForegroundMessage(message);
      await _publishBannerFromMessage(
        message,
        openInForeground: false,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      debugPrint('📨 Push aberto pelo usuário: ${message.messageId}');
      await _publishBannerFromMessage(
        message,
        openInForeground: true,
      );
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App aberto via push: ${initialMessage.messageId}');
      await _publishBannerFromMessage(
        initialMessage,
        openInForeground: true,
      );
    }

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔑 FCM token: $token');

    // Firestore listener ativo para suportar banners remotos em qualquer
    // plataforma mesmo sem push em background.
    await _initializeFirestoreListener();

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 Permissão push: ${settings.authorizationStatus.name}');
  }

  static Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _localNotifications.initialize(initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    const androidDetails = AndroidNotificationDetails(
      'remote_messages_channel',
      'Mensagens remotas',
      channelDescription: 'Canal para mensagens remotas enviadas pelo painel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title ?? 'Nova mensagem',
      body ?? '',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );

    debugPrint('📲 [FG] Push exibido: ${message.messageId}');
  }

  static Future<void> _publishBannerFromMessage(
    RemoteMessage message, {
    required bool openInForeground,
  }) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Nova mensagem';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    final imageUrl = message.data['imageUrl']?.toString();

    final banner = RemoteInAppBanner(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      openInForeground: openInForeground,
      imageUrl: imageUrl,
    );

    await _savePendingBanner(banner);
    inAppBannerNotifier.value = banner;
    debugPrint('🪧 Banner remoto publicado: ${banner.id}');
  }

  static Future<void> _savePendingBanner(RemoteInAppBanner banner) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingBannerKey, jsonEncode(banner.toJson()));
  }

  static Future<bool> _isFirestoreBannerSeen(String bannerId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_lastSeenFirestoreBannerIdKey);
    return lastSeen == bannerId;
  }

  static Future<void> _markFirestoreBannerSeen(String bannerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenFirestoreBannerIdKey, bannerId);
  }

  static Future<void> _markFirestoreBannerViewedRemotely(String bannerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('remote_banners')
          .doc(bannerId)
          .set(
        {
          'vista': true,
          'vistaEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('⚠️ Falha ao marcar banner como visto no Firestore ($bannerId): $e');
    }
  }

  static Future<RemoteInAppBanner?> loadPendingBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingBannerKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final banner = RemoteInAppBanner.fromJson(decoded);
      inAppBannerNotifier.value = banner;
      return banner;
    } catch (e) {
      debugPrint('Erro ao carregar banner remoto pendente: $e');
      return null;
    }
  }

  static Future<void> markBannerAsViewed(String bannerId) async {
    if (bannerId.isEmpty) return;
    await _markFirestoreBannerSeen(bannerId);
    await _markFirestoreBannerViewedRemotely(bannerId);
  }

  static Future<void> _initializeFirestoreListener() async {
    try {
      debugPrint('📡 Inicializando listener Firestore para notificações...');

      _firestoreListener = FirebaseFirestore.instance
          .collection('remote_banners')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen(
        (snapshot) async {
          if (snapshot.docs.isEmpty) return;

          final doc = snapshot.docs.first;
          if (await _isFirestoreBannerSeen(doc.id)) return;
          final data = doc.data();

          // Verifica se é uma notificação nova (não vista ainda)
          final vista = data['vista'] as bool? ?? false;
          if (vista) return;

          // Extrai dados do documento
          final titulo = data['titulo']?.toString() ?? 'Nova mensagem';
          final corpo = data['corpo']?.toString() ?? '';
          final imageUrl = data['imageUrl']?.toString();

          final banner = RemoteInAppBanner(
            id: doc.id,
            title: titulo,
            body: corpo,
            receivedAt: DateTime.now(),
            openInForeground: false, // Será true se app abriu do push
            imageUrl: imageUrl,
          );

          await _savePendingBanner(banner);
          inAppBannerNotifier.value = banner;

          debugPrint('🪧 Banner do Firestore: ${banner.id}');
        },
        onError: (e) {
          debugPrint('❌ Erro no listener Firestore: $e');
        },
      );
    } catch (e, s) {
      debugPrint('❌ Erro ao inicializar listener Firestore: $e\n$s');
    }
  }

  static Future<void> dispose() async {
    await _firestoreListener?.cancel();
    inAppBannerNotifier.dispose();
  }

  static Future<void> dismissPendingBanner() async {
    final current = inAppBannerNotifier.value;
    if (current != null) {
      await markBannerAsViewed(current.id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingBannerKey);
    inAppBannerNotifier.value = null;
  }
}
