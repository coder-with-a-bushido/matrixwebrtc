import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/src/matrixcall.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ConnectedCallScreen extends StatefulWidget {
  final BuildContext context;
  final MatrixCall matrixCall;
  final RTCVideoRenderer localRenderer;
  ConnectedCallScreen({this.matrixCall, this.context, this.localRenderer});
  @override
  _ConnectedCallScreenState createState() => _ConnectedCallScreenState();
}

class _ConnectedCallScreenState extends State<ConnectedCallScreen> {
  //RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
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
    //await _localRenderer.initialize();
    await _remoteRenderer.initialize();
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
    if (widget.localRenderer != null) widget.localRenderer.dispose();
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
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _remoteRenderer,
                    )
                  : Center(child: Text("NULL")),
              //decoration: BoxDecoration(color: Colors.black54),
            )),
        Positioned(
          left: 20.0,
          top: 20.0,
          child: Container(
            width: orientation == Orientation.portrait ? 90.0 : 120.0,
            height: orientation == Orientation.portrait ? 120.0 : 90.0,
            child: widget.localRenderer.srcObject != null
                ? RTCVideoView(
                    widget.localRenderer,
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
              widget.matrixCall.hangUp();
              context.read<CallstateBloc>().add(NoCall());
            },
          ),
        ),
      ]));
    });
  }
}
