import 'package:example/src/matrixcall.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class IncomingScreen extends StatefulWidget {
  final RTCSessionDescription remoteSDP;
  IncomingScreen({this.remoteSDP});
  @override
  _IncomingScreenState createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  MatrixCall matrixCall = MatrixCall();
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();

  @override
  void initState() {
    _initRenderer();
    super.initState();
  }

  _initRenderer() async {
    await _localRenderer.initialize();
    _localRenderer.srcObject = matrixCall.localStream;
  }

  _disposeRenderer() async {
    _localRenderer.dispose();
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
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.call_end),
                    color: Colors.red,
                    onPressed: () {},
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
