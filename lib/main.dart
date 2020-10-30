import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';

import 'pages/loginview.dart';

void main() {
  runApp(TalkDevTestApp());
}

class TalkDevTestApp extends StatelessWidget {
  static Client client = Client('Talk Dev Client');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talk Dev',
      home: LoginView(),
    );
  }
}
