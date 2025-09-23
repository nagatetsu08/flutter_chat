import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_chat/widgets/chat_messages.dart';
import 'package:flutter_chat/widgets/new_message.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key
  });

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

