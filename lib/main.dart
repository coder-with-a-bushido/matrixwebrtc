import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/pages/callpage.dart';
import 'package:example/src/matrixcall.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'pages/loginview.dart';
import 'src/callstatusprovider.dart';

//MatrixCall matrixCall = MatrixCall();
void main() {
  runApp(BlocProvider(
      create: (context) => CallstateBloc(), child: TalkDevTestApp()));
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
