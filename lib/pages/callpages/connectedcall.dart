import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/src/matrixcall.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ConnectedCallScreen extends StatefulWidget {
  final BuildContext context;
  final MatrixCall matrixCall;

  ConnectedCallScreen({
    this.matrixCall,
    this.context,
  });
  @override
  _ConnectedCallScreenState createState() => _ConnectedCallScreenState();
}

class _ConnectedCallScreenState extends State<ConnectedCallScreen> {
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  @override
  void initState() {
    initVideoRenderers();
    super.initState();
  }

  @override
  void dispose() {
    disposeVideoRenderers();
    super.dispose();
  }

  initVideoRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    setState(() {
      _localRenderer.srcObject = widget.matrixCall.localStream;
    });
    widget.matrixCall.remoteStream.listen((stream) {
      setState(() {
        print('remotestream changed.');
        _remoteRenderer.srcObject = stream;
      });
    });
    // _localRenderer.srcObject = widget.matrixCall.localStream;
    // if (widget.matrixCall.hasRemoteSdp()) {
    //   print('setting remotestream.');
    //   _remoteRenderer.srcObject = widget.matrixCall.remoteStream;
    // }
  }

  disposeVideoRenderers() async {
    if (_localRenderer != null) _localRenderer.dispose();
    if (_remoteRenderer != null) _remoteRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Container(
          child: Stack(children: <Widget>[
        Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            bottom: 0.0,
            child: Container(
              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child:
                  (_remoteRenderer != null && _remoteRenderer.srcObject != null)
                      ? RTCVideoView(
                          _remoteRenderer,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Center(
                          child: Icon(Icons.supervised_user_circle),
                        ),
              //decoration: BoxDecoration(color: Colors.black54),
            )),
        Positioned(
          left: 20.0,
          top: 20.0,
          child: Container(
            width: orientation == Orientation.portrait ? 90.0 : 120.0,
            height: orientation == Orientation.portrait ? 120.0 : 90.0,
            child: (_localRenderer != null && _localRenderer.srcObject != null)
                ? RTCVideoView(
                    _localRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Center(
                    child: Icon(Icons.supervised_user_circle),
                  ),
          ),
        ),
        Positioned(
          width: MediaQuery.of(context).size.width,
          bottom: 20,
          child: Center(
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    child: Icon(Icons.mic_off),
                    onPressed: () => widget.matrixCall.muteMic(),
                    backgroundColor: Colors.pink,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  FloatingActionButton(
                    child: Icon(Icons.flip_camera_ios),
                    onPressed: () => widget.matrixCall.switchCamera(),
                    backgroundColor: Colors.blue,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  FloatingActionButton(
                    child: Icon(
                      Icons.call_end,
                    ),
                    backgroundColor: Colors.red,
                    onPressed: () {
                      widget.matrixCall.hangUp();
                      context.read<CallstateBloc>().add(NoCall());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ]));
    });
  }
}
