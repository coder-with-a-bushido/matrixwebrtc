import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/pages/callpages/connectedcall.dart';
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
  bool isConnected = false;
  @override
  void initState() {
    _initOutgoingScreen();

    super.initState();
  }

  @override
  dispose() {
    _disposeOutgoingScreen();
    super.dispose();
  }

  _initOutgoingScreen() async {
    await _localRenderer.initialize();
    await matrixCall.initialize().then((value) {
      if (mounted)
        setState(() {
          _localRenderer.srcObject = matrixCall.localStream;
        });
    });
    matrixCall.room = widget.room;
    matrixCall.state.listen((state) {
      _checkState(state);
    });
    matrixCall.startCall();
  }

  _disposeOutgoingScreen() async {
    if (_localRenderer != null) _localRenderer.dispose();
  }

  _checkState(PeerConnectionState state) {
    if (state == PeerConnectionState.RTC_CONNECTION_PENDING) {
      print("localrenderer set!!!!!!!!!!!!!");
      if (mounted)
        setState(() {
          _localRenderer.srcObject = matrixCall.localStream;
        });
    } else if (state == PeerConnectionState.RTC_CONNECTION_CONNECTED) {
      if (mounted)
        setState(() {
          isConnected = true;
        });
    } //else if(state==PeerConnectionState.RTC_CONNECTION_FAILED)
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected)
      return ConnectedCallScreen(
        matrixCall: matrixCall,
        context: context,
      );
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
                child: _localRenderer.srcObject != null
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
                  matrixCall.hangUp();
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
