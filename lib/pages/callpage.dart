import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import '../main.dart';

class VideoCallPage extends StatefulWidget {
  Room room;
  EventTypes type;
  VideoCallPage({this.room, this.type});
  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RTCPeerConnection _peerConnection;
  MediaStream _localStream;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  @override
  void initState() {
    _initRenderers();
    _getUserMedia();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    TurnServerCredentials turnServerCredentials =
        await TalkDevTestApp.client.requestTurnServerCredentials();
    Map<String, dynamic> configuration = {
      'iceServers': [
        {"url": "stun:stun.l.google.com:19302"},
        // {
        //   'url': turnServerCredentials.uris.first.toString(),
        //   'credential': turnServerCredentials.password.toString(),
        //   'username': turnServerCredentials.username.toString()
        // }
      ]
    };
    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);
    pc.addStream(_localStream);
    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        widget.room.sendCallCandidates('${widget.room.id}call', [
          {
            'candidate': e.candidate.toString(),
            'sdpMid': e.sdpMid.toString(),
            'sdpMlineIndex': e.sdpMlineIndex,
          }
        ]);
        // print(json.encode());
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };

    return pc;
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
      },
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    print(stream.id);
    _localStream = stream;
    _localRenderer.srcObject = _localStream;

    //return stream;
  }

  @override
  void dispose() {
    _localStream.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: OrientationBuilder(builder: (context, orientation) {
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
                child: RTCVideoView(
                  _remoteRenderer,
                ),
                //decoration: BoxDecoration(color: Colors.black54),
              )),
          Positioned(
            left: 20.0,
            top: 20.0,
            child: Container(
              width: orientation == Orientation.portrait ? 90.0 : 120.0,
              height: orientation == Orientation.portrait ? 120.0 : 90.0,
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
              ),
              //decoration: BoxDecoration(color: Colors.black54),
            ),
          ),
        ]),
      );
    }));
  }
}
