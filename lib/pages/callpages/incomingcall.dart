import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/src/matrixcall.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'connectedcall.dart';

class IncomingScreen extends StatefulWidget {
  final Room room;
  final RTCSessionDescription remoteSDP;
  IncomingScreen({this.remoteSDP, this.room});
  @override
  _IncomingScreenState createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  MatrixCall matrixCall = MatrixCall();
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  bool isConnected = false;
  @override
  void initState() {
    _initIncomingScreen();

    super.initState();
  }

  @override
  dispose() {
    _disposeIncomingScreen();
    super.dispose();
  }

  _initIncomingScreen() async {
    await _localRenderer.initialize();
    await matrixCall.initialize().then((value) {
      if (mounted)
        setState(() {
          _localRenderer.srcObject = matrixCall.localStream;
        });
    });
    matrixCall.room = widget.room;
    matrixCall.setRemoteSDP = widget.remoteSDP;
    matrixCall.state.listen((state) {
      _checkState(state);
    });
  }

  _disposeIncomingScreen() async {
    if (_localRenderer != null) _localRenderer.dispose();
  }

  _checkState(PeerConnectionState state) {
    // if (state == PeerConnectionState.RTC_CONNECTION_CONNECTING) {
    //   print("localrenderer set!!!!!!!!!!!!!");
    //   if (mounted)
    //     setState(() {
    //       _localRenderer.srcObject = matrixCall.localStream;
    //     });
    // } else
    if (state == PeerConnectionState.RTC_CONNECTION_CONNECTED) {
      if (mounted)
        setState(() {
          isConnected = true;
        });
    } //else if(state==PeerConnectionState.RTC_CONNECTION_FAILED)
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected)
      return Scaffold(
          body: ConnectedCallScreen(
        matrixCall: matrixCall,
        context: context,
        localRenderer: _localRenderer,
      ));
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
                child: RTCVideoView(
                  _localRenderer,
                ),
              ),
            ),
            Positioned(
              width: MediaQuery.of(context).size.width,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.call),
                    color: Colors.green,
                    onPressed: () async {
                      await matrixCall.answerCall();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.call_end),
                    color: Colors.red,
                    onPressed: () {
                      matrixCall.hangUp();
                      context.read<CallstateBloc>().add(NoCall());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
