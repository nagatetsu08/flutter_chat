import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/widgets/message_bubble.dart';

// Todo:投稿される度に内容変わるところだと思うけど、Statefulでなくていい？

// StreambBuilderはstremに設定したものの変更を監視し、変更があったら自動でUIを検知する仕組み。
// 指定したstreamにデータが流れてくるたびに「自動的にその子ウィジェットまるまる再描画」してくれるので、こちらが検知変更　→ UI操作ってのをしなくてOK
// Statefulが必要になってるのは、StreamBuilder以外にコンポーネントがあって、それがリアクティブに表現を変更したいとき。
// 例えば、StreambBuilderとTextコンポーネントがあって、streamBuilderの変更内容（snapshots.docChanges）をTextコンポーネントに表示したい時とかは
// snapshots.docChangesの結果をstate変数へSetStateを使って設定すると言った感じで利用する。

// つまり、データが刻一刻と変わり画面の見え方が変わるからと言って、必ずしもStatefulではない。問題は、Stateを使ってUIを「意図的」に変更させたいかどうか。
// 単にデータがStackされているだけならState使わんでもStreamでなんとなかる。stream以外のコンポーネントの状態を自由に扱いたいときにStatefulが重要
// 

// チャット履歴を表示するウィジェット
class ChatMessages extends StatelessWidget{
  const ChatMessages({
    super.key
  });
  
  @override
  Widget build(BuildContext context) {

    final authenticatedUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
        .collection('chat')
        .orderBy('createAt', descending: true)
        .snapshots(),
      builder: (ctx, chatSnapshots) {
        if(chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if(!chatSnapshots.hasData ||  chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No Message found!!'),
          );
        }

        if(chatSnapshots.hasError) {
          return const Center(
            child: Text('Something went wrong'),
          );          
        }

        final loadMessages = chatSnapshots.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40, 
            left: 30, 
            right: 30
          ),
          reverse: true, //画面の下から表示していく。
          itemCount: loadMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadMessages[index].data();

            // 次のメッセージが同じユーザからのものかどうかを判定（同じユーザーからなら見せ方を変えたい）
            // 次のメッセージがない場合はnullをいれておく
            final nextChatMessage = index + 1 < loadMessages.length ? loadMessages[index + 1].data() : null;

            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId = nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserSame = nextMessageUserId ==  currentMessageUserId;

            if (nextUserSame) {
              return MessageBubble.next(
                message: chatMessage['text'], 
                isMe: authenticatedUser!.uid == currentMessageUserId,
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage'], 
                username: chatMessage['username'], 
                message: chatMessage['text'], 
                isMe: authenticatedUser!.uid == currentMessageUserId,
              );
            }
          }
        );
      },
    );
  }
}