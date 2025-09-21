import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat/widgets/user_images_picker.dart';

final _firebase = FirebaseAuth.instance;

// この画面ではログインのバリデーション、状態管理による表示内容変更（ログインモード、サインアップモード）といったこの画面内で動きを見せる必要があるのでStatefulWidget
// 逆に単なる画面遷移や値をStateに格納して単に次の画面にいくというような「この画面で動きを見せる必要がない」といったときはStatelessWidget

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key
  });

  @override
  State<AuthScreen> createState() {
    return _AuthScreen();
  }
}

class _AuthScreen extends State<AuthScreen> {

  // submitを押した時などの全体的なバリデーションはこのGlobalKey<FormState>()を使ったやり方をやる。(総合的なバリデーション)
  // 入力値個々のバリデーションは、FormTextFieldのvalidatorで行う。
  // なお、TextEditingControllerは入力値の取得・変更を行うためのものでバリデーションとは関係ない

  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enterEmail = '';
  var _enterPassword = '';

  // chatに表示する画像
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {

    // FormInputTextに設定したバリデーション（validator）がこのタイミングで呼ばれる。
    final isValid = _form.currentState!.validate();

  // バリデーションエラーがあった際はダイアログメッセージを出す。
  if (!isValid || (!_isLogin && _selectedImage == null)) {
    String errorMsg = '';
    if (!isValid) {
      errorMsg = '入力内容に誤りがあります。';
    } else if (!_isLogin && _selectedImage == null) {
      errorMsg = '画像を選択してください。';
    }
    // showDialogはFutureを返すが単に表示するだけならawaitしなくていい。
    // OKボタンで閉じた後に何かしたいのであれば、awaitにする。
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エラー'),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

    // 各FormコンポーネントのonSaveイベントを発動させる
    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if(_isLogin) {
        // log users in
        final _userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enterEmail, 
          password: _enterPassword
        );
        
      } else {
        // create user
        // これはAuthenticationで必要なのだが、画像情報やユーザー名といった付加属性を同じ場所に保存できない。
        // アプリの表示で使う情報はFirestoreを作って保存するのが通常のやり方
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enterEmail, 
          password: _enterPassword
        );

        // Firebaseに保存する画像インスタンスを生成する。
        final storageRef = FirebaseStorage.instance.ref()
          .child('user_images')
          .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);

        // アプリ上で画像を永続的に使用（表示）するには、ダウンロードURLが必要
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredentials.user!.uid)
          .set({
            'username': '',
            'email': _enterEmail,
            'imageUrl': imageUrl
          });

      }      
    } on FirebaseAuthException catch(error) {
      // 細かくエラー内容をハンドリングできる
      if(error.code == 'email-already-in-use') {
        // 
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Autentication Failed')));

      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        // 動的に高さとか変わる物ではなく、縦に並ばせるItemも決まっているので、
        // スクロールするほどItemがないのに、SingleChildScrollViewを使う理由は、
        // 画面がどれほど小さくなろうともこれで囲んでおくとオーバーフローエラーを起こさないし、入力項目が増えたとしても
        // スクロールをしてくれるといった自動調整の意味が多い。
        // 実際にinput画面やログイン画面で実装されているケースが多い。
        child: SingleChildScrollView(
          // 縦に並ばせる
          child: Column(
            // 縦方向に真ん中よりに配置
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 入力画面の上にだすイメージ画像
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              // ログイン情報入力エリア
              Card(
                margin: EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(!_isLogin) UserImagesPicker(
                          onPickImage: (pickedImage) {
                            _selectedImage = pickedImage;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                          ),
                          keyboardType: TextInputType.emailAddress,      
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if(value == null || value.isEmpty || !value.contains('@')) {
                              return 'Please Enter a valid email address';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // バリデーションでnullチェックをしているので!をつけてnullでないことを保証する必要がある
                            _enterEmail = value!;

                            // ここでstateを更新しないのは、このタイミングで画面変更とかをさせたくないし、そのトリガーを設定もしたくないから。
                            // まだパスワードの値の取り出しが残ってるし。。。
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if(value == null || value.isEmpty || value.trim().length < 6) {
                              return 'Password must be at least 6 character';
                            }
                            return null;                          
                          },
                          onSaved: (value) {
                            _enterPassword = value!;
                          },  
                        ),
                        const SizedBox(height: 12,),
                        if (_isAuthenticating)
                          CircularProgressIndicator(),
                        if (!_isAuthenticating)
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer
                            ),
                            child: Text(_isLogin ? 'Login' : 'Sign up'),
                          ),
                        // ログインモードとサインアップモードを切り替える 
                        if (!_isAuthenticating)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin; //現在のモードを切り替えるだけ
                              });
                            }, 
                            child: Text(_isLogin ? 'Create an account' : 'I already have an account')
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}