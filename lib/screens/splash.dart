import 'package:flutter/material.dart';
import 'package:flutter_chat/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chat')
      ),
      body: const Center(
        child: Text('loading'),
      ),
    );
  }
}

