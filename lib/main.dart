import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:beritain/firebase_options.dart';
import 'package:beritain/l10n/app_localizations.dart';
import 'package:beritain/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:beritain/screens/home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Izin notifikasi sementara diberikan');
  } else {
    print('Izin notifikasi ditolak');
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  final android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: 'Notifikasi masuk dari FCM',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(0, title, body, platform);
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['title'] ?? 'Pesan Baru';
  final body = data['body'] ?? '';
  final sender = data['senderName'] ?? 'Pengirim tidak diketahui';
  final time = data['sentAt'] ?? '';
  final photoUrl = data['senderPhotoUrl'] ?? '';

  ByteArrayAndroidBitmap? largeIconBitmap;
  if (photoUrl.isNotEmpty) {
    final base64 = await _networkImageToBase64(photoUrl);
    if (base64 != null) {
      largeIconBitmap = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }

  final styleInfo =
      largeIconBitmap != null
          ? BigPictureStyleInformation(
            largeIconBitmap,
            contentTitle: title,
            summaryText: '$body\n\nDari: $sender - $time',
            largeIcon: largeIconBitmap,
            hideExpandedLargeIcon: true,
          )
          : BigTextStyleInformation(
            '$body\n\nDari: $sender\nWaktu: $time',
            contentTitle: title,
          );

  final simpleStyleInfo = BigTextStyleInformation(
    '$body\n\nDari: $sender\nWaktu: $time',
    contentTitle: title,
  );

  final androidDetails = AndroidNotificationDetails(
    'detailed_channel',
    'Notifikasi Detail',
    channelDescription: 'Notifikasi dengan detail tambahan',
    styleInformation: simpleStyleInfo,
    largeIcon: largeIconBitmap,
    importance: Importance.max,
    priority: Priority.max,
  );

  final platform = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(1, title, body, platform);
}

Future<String?> _networkImageToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {}
  return null;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification!.title,
      message.notification!.body,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await requestNotificationPermission();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings settings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(settings);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AdaptiveThemeMode? savedThemeMode;
  String status = "Memulai...";
  String topic = "berita-terikini";

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
    loadThemeMode();
  }

    Future<void> loadThemeMode() async {
    final mode = await AdaptiveTheme.getThemeMode();
    setState(() {
      savedThemeMode = mode ?? AdaptiveThemeMode.light;
    });
  }

  void setupFirebaseMessaging() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic(topic);
    setState(() => status = "Subscribed to topic: $topic");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        showNotificationFromData(message.data);
      } else {
        showBasicNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return AdaptiveTheme(
      
       light: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFF87CEEB),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.blue,
        ),
      ),
      dark: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.deepPurple,
        ),
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
