import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/src/callstatusprovider.dart';
import 'package:example/src/matrixcall.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

class OutgoingScreen extends StatefulWidget {
  final Room room;
  OutgoingScreen({this.room});
  @override
  _OutgoingScreenState createState() => _OutgoingScreenState();
}

class _OutgoingScreenState extends State<OutgoingScreen> {
  MatrixCall matrixCall = MatrixCall();
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();

  @override
  void initState() {
    _initOutgoingScreen();

    super.initState();
  }

  @override
  dispose() {
    matrixCall.hangUp();
    _disposeOutgoingScreen();
    super.dispose();
  }

  _initOutgoingScreen() async {
    await _localRenderer.initialize();
    matrixCall.room = widget.room;
    matrixCall.startCall();
    _localRenderer.srcObject = matrixCall.localStream;
  }

  _disposeOutgoingScreen() async {
    if (_localRenderer != null) _localRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0.0,
              right: 0.0,
              top: 0.0,
              bottom: 0.0,
              child: Container(
                margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: _localRenderer != null
                    ? RTCVideoView(
                        _localRenderer,
                      )
                    : Center(child: Text("NULL")),
              ),
            ),
            Positioned(
              width: MediaQuery.of(context).size.width,
              bottom: 20,
              child: IconButton(
                icon: Icon(Icons.call_end),
                color: Colors.red,
                onPressed: () {
                  context.read<CallstateBloc>().add(NoCall());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
