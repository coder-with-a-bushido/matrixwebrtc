import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../main.dart';

class VideoCallPage extends StatefulWidget {
  VideoCallPage({Key key, this.room, this.type = '', this.session})
      : super(key: key);
  final Room room;
  final String type;
  final Map<String, dynamic> session;
  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _mute = false;
  bool _answered = false;
  RTCPeerConnection _peerConnection;
  MediaStream _localStream;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  var _remoteCandidates = [];
  final _sdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };
  @override
  void initState() {
    _initRenderers();
    _getUserMedia();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
      if (widget.type == 'CallInvite') {
        print('creating an offer');
        createOffer();
      }
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
        //{"url": "stun:stun.l.google.com:19302"},
        {
          'url': turnServerCredentials.uris[0].toString(),
          'credential': turnServerCredentials.password.toString(),
          'username': turnServerCredentials.username.toString()
        },
        {
          'url': turnServerCredentials.uris[1].toString(),
          'credential': turnServerCredentials.password.toString(),
          'username': turnServerCredentials.username.toString()
        }
      ]
    };
    // final Map<String, dynamic> offerSdpConstraints = {
    //   "mandatory": {
    //     "OfferToReceiveAudio": true,
    //     "OfferToReceiveVideo": true,
    //   },
    //   "optional": [],
    // };

    RTCPeerConnection pc = await createPeerConnection(configuration, {
      'mandatory': {},
      'optional': [],
    });
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
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    };

    return pc;
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStream = stream;
    if (mounted) {
      setState(() {
        _localRenderer.srcObject = _localStream;
      });
    }

    //return stream;
  }

  @override
  void dispose() {
    _localStream.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    //_peerConnection.dispose();
    super.dispose();
  }

  void createOffer() async {
    RTCSessionDescription description =
        await _peerConnection.createOffer(_sdpConstraints);
    await widget.room.inviteToCall(
      '${widget.room.id}call',
      30000,
      description.sdp.toString(),
    );
    print('offer created');

    await _peerConnection.setLocalDescription(description);
  }

  void _createAnswer(session) async {
    RTCSessionDescription remotedescription = new RTCSessionDescription(
        session['sdp'].toString(), session['type'].toString());

    print(session['sdp']);

    await _peerConnection.setRemoteDescription(remotedescription);
    RTCSessionDescription localdescription =
        await _peerConnection.createAnswer(_sdpConstraints);

    await widget.room.answerCall(
      '${widget.room.id}call',
      localdescription.sdp,
    );
    print('answered the call');
    setState(() {
      _answered = true;
    });
    await _peerConnection.setLocalDescription(localdescription);
  }

  void _setRemoteDescription(Map<String, dynamic> session) async {
    //var content=jsonDecode(source)
    RTCSessionDescription description = new RTCSessionDescription(
        session['sdp'].toString(), session['type'].toString());

    print(session['sdp']);

    await _peerConnection.setRemoteDescription(description);
  }

  void _addCandidate(List<dynamic> candidates) async {
    Map<String, dynamic> session = candidates.first;
    print('candidates are adding    ' +
        '${session['candidate']}   ${session['sdpMid']}    ${session['sdpMlineIndex'].runtimeType}');
    RTCIceCandidate candidate = RTCIceCandidate(session['candidate'].toString(),
        session['sdpMid'].toString(), session['sdpMlineIndex']);
    _peerConnection
        .addCandidate(candidate)
        .then((value) => print('successfully added'));
  }

  void _hangUp(timer) async {
    await timer.cancel();
    await _peerConnection.close();
    //_peerConnection.dispose();
    //await Future.delayed(Duration(seconds: 5));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var timer = Timer.periodic(Duration(milliseconds: 30000), (timer) {
      if (!_answered) {
        widget.room.hangupCall('${widget.room.id}call');
        _hangUp(timer);
      }
    });

    TalkDevTestApp.client.onCallAnswer.stream.listen((event) {
      _answered = true;
      if (event.senderId != TalkDevTestApp.client.userID)
        _setRemoteDescription(event.content['answer']);

      //widget.room.sendCallCandidates('${widget.room.id}call', candidates)
    });
    TalkDevTestApp.client.onCallCandidates.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID &&
          widget.type == 'CallInvite')
        _addCandidate(event.content['candidates']);
    });
    TalkDevTestApp.client.onCallHangup.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID) {
        //widget.room.hangupCall('${widget.room.id}call');
        _hangUp(timer);
      }
    });
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
          Positioned(
              width: MediaQuery.of(context).size.width,
              bottom: 20,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (widget.type == 'CallAnswer' && !_answered)
                      ? IconButton(
                          splashColor: Colors.green,
                          icon: Icon(Icons.call),
                          onPressed: () {
                            _createAnswer(widget.session);
                          })
                      : Container(),
                  _answered
                      ? IconButton(
                          splashColor: Colors.white,
                          color: Colors.red,
                          icon: Icon(Icons.mic_off),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _mute = !_mute;
                                _localStream
                                    ?.getAudioTracks()[0]
                                    .setMicrophoneMute(_mute);
                              });
                            }
                          })
                      : Container(),
                  IconButton(
                      splashColor: Colors.red,
                      icon: Icon(Icons.call_end),
                      onPressed: () {
                        widget.room.hangupCall('${widget.room.id}call');
                        _hangUp(timer);
                      })
                ],
              )),
        ]),
      );
    }));
  }
}
