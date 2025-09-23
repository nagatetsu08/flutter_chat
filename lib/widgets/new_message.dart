import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Todo::新しいメッセージ入力中は状態変化させる必要ある？
// TextEditingControllerがStateを使うことが前提の機能だから

class NewMessage extends StatefulWidget{
  const NewMessage({
    super.key
  });

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {

  final _messageController = TextEditingController();

  // TextEditingControllerを使うときの必須
  // ウィジェットを使い終わった後のお作法(メモリリリース)
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if(enteredMessage.trim().isEmpty) {
      return;
    }

    // /validationが終わったらフォーカスを外してキーボードを引っ込める
    // 保存される前に二重クリックとかさせないようにこのタイミングでメッセージを消去
    FocusScope.of(context).unfocus();
    _messageController.clear();

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    //Todo::send message to Firebase
    FirebaseFirestore.instance.collection('chat').add({
      'text': enteredMessage,
      'createAt': Timestamp.now(),
      'userId'  : user.uid,
      'userName': userData.data()!['username'],
      'userImage': userData.data()!['imageUrl'],
    });

    // buildContextをasync/await処理の後に持ってくるなというのがFlutterのルールなのでここではコメントアウト
    // FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        bottom: 14
      ),
      child: Row(
        children: [
          // Rowは子ウィジェットに明確な幅の制約を与えないため、TextFieldが必要なスペースを無限大に要求するらしい。
          // 従って明示的にwidthを指定するか、Expandedを使って許される限りの幅を使う。
          // 子ウィジェットが新たに追加されればされるほど、Expandedの幅が狭まっていく感じ
          Expanded(

            /**
             * TextFormFieldを使わない理由はおそらく以下。（perplexityに聞いた）
             * 
             * 項目が1個しかなく、フォームの一括バリデーション、一括保存（onSaved発動）、一括クリアが必要ないから
             * 
             * 【補足】
             * 通常、TextFormFieldはFormウィジェット配下で複数のForm項目を保持する場合に利用される。それらを一括で管理したいときに使う。
             * 一方で今回はMessageだけの管理でよいのでウィジェット数を少なくする目的で、TextField + TextEditingControllerで対応した。
             * 別にForm + TextFormFieldを使ってやってもよい。
             * 
             */

            child: TextField(
              controller: _messageController,
              // 勝手に変換しないようにする。
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: true,
              decoration: InputDecoration(
                labelText: 'Send a message!!'
              ),
            ),
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            onPressed: _submitMessage, 
            icon: const Icon(Icons.send)
          )
        ],
      ),
    );
  }
}