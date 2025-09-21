import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _submit() async {
    // FormInputTextに設定したバリデーション（validator）がこのタイミングで呼ばれる。
    final isValid = _form.currentState!.validate(); 

    if(!isValid) {
      return;
    } 

    // 各FormコンポーネントのonSaveイベントを発動させる
    _form.currentState!.save();
    try {
      if(_isLogin) {
        // log users in
        final _userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enterEmail, 
          password: _enterPassword
        );
        
      } else {
        // create user
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enterEmail, 
          password: _enterPassword
        );
      }      
    } on FirebaseAuthException catch(error) {
      // 細かくエラー内容をハンドリングできる
      if(error.code == 'email-already-in-use') {
        // 
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Autentication Failed')));
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
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer
                          ),
                          child: Text(_isLogin ? 'Login' : 'Sign up'),
                        ),
                        // ログインモードとサインアップモードを切り替える 
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