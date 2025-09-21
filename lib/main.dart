import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat/screens/chat.dart';
import 'package:flutter_chat/screens/splash.dart';
import 'firebase_options.dart';


import 'package:flutter_chat/screens/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      // home: const AuthScreen()
      /**
       * StreamBuilderの役割は「指定されたストリームから流れてくるデータに応じて、自動的にウィジェットの再描画を行う」こと
       * 使い方はFutureBuilderに似ているが、FutureBuilderが1度解決したら終わりなのに対し、
       * StreamBuiladerは絶えず状態の監視を続けること。
       *  
       */
      home: StreamBuilder(
        /**
         * FirebaseAuth.instance.authStateChanges()はユーザーがログインした時にユーザークレデンシャルを、
         * ログアウトした時にnullを返す。
         *  
         * 公式ガイドに「認証状態に応じて UIを更新する必要がある場合は、StreamBuilder を使用します」とあり、
         * Widgetを構築していく中にFirebaseAuth.instance.authStateChanges().listenを使ってはだめらしい。（理由は以下）
         * 
         * .listen() はDartのストリームを購読しコールバックで値を受け取りますが、Widgetツリーの build メソッド内に直接 .listen() を書くと、ビルドごとにサブスクリプションが増え、バグにつながります。
         * サブスクリプションというのはイベントのようなもので、すでに有効になっているイベント処理があるのに、再描画のたびに同じものが新規イベントとして作成されるので、意図しない動作をしたり、メモリ不足になったりする。
 
         * Flutterアプリでは、画面の自動切り替え・リアクティブなUIの実現には StreamBuilder を利用するのが王道です。
         * 
         */ 
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (ctx, snapshot) {
          // ローカルデバイスからトークンを読み取り、FirebaseでのAuthenticatinを完了するまでラグがあって、
          // 端末によっては一瞬だけ認証画面のちらつきが見えてしまう。それを防ぐためにスプラッシュスクリーンを用意して、
          // 準備が整うまでそれを見せることとする。
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if(snapshot.hasData) {
            return const ChatScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}