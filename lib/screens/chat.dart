import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/widgets/chat_messages.dart';
import 'package:flutter_chat/widgets/new_message.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  void setupPushNotification() async {
    final fcm = FirebaseMessaging.instance;

    if (await Permission.notification.status == PermissionStatus.denied) {
      await Permission.notification.request();
    }

    await fcm.requestPermission();
    final token = await fcm.getToken();
    print("トークンは${token}");
    try {
      await fcm.subscribeToTopic('chat').timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('subscribeToTopic タイムアウト');
          return;
        },
      );
      print('Subscribed to topic: chat');
    } catch (e) {
      print('Subscriveエラー: $e');
    }
  }

  // このアプリではログインしている状態（一度ログインするとログイン状態を維持できる）でMessageを受け取りたいので、
  // ログイン後に確実に遷移するこの画面でPush通知の初期設定を行う。
  // 1つ注意なのが、initStateはFutureを返すことを想定してないので、initStateをasyncにすることはNG。
  // 代わりにasyncを返すメソッドを別途定義してそいつをinitState内部で呼んでやる。
  @override
  void initState() {
    super.initState();
    // setupPushNotification();
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('=== Push受信 ===');
    //   print('data: ${message.data}');
    //   final notification = message.notification;
    //   if (notification != null) {
    //     print('title: ${notification.title}');
    //     print('body: ${notification.body}');
    //   }
    // });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chat'),
        actions: [
          IconButton(
            onPressed: () {
              // main.dartでStreamBuilderで実装しているから画面がログイン状態を変えてやるだけで、
              // 自動でログイン/サインアップ画面へ切り替わる
              FirebaseAuth.instance.signOut();
            }, 
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.primary,
            )
          )
        ],
      ),
      body: Column(
        children: const [
          // lineっぽくみせたいのでChatMessagesは縦幅許す限りまで拡大する。
          Expanded(child: ChatMessages()),
          NewMessage()
        ],
      ),
    );
  }
}

