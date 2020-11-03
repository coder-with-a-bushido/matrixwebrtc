import 'dart:async';

import 'dart:math';

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
  List<Map<String, dynamic>> _localCandidates = [];
  bool _first = true;
  bool _inCalling = false;
  int _localCandidateSendTries = 0;
  bool _hangedup = false;
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
        _createOffer();
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
      print('onicecandy - ${e.candidate}');
      if (e.candidate != null) {
        _localCandidates.add({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex,
        });
        if (_first) {
          Timer(Duration(milliseconds: 100), () {
            _sendCandidateQueue();
          });
          _first = false;
        }
      }
    };
    pc.onIceGatheringState = (e) {
      switch (e) {
        case RTCIceGatheringState.RTCIceGatheringStateGathering:
          print('gathering');
          break;
        case RTCIceGatheringState.RTCIceGatheringStateComplete:
          _sendCandidateQueue();
          break;
        default:
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);

      _remoteRenderer.srcObject = stream;
    };
    pc.onRemoveStream = (stream) {
      _remoteRenderer.srcObject = null;
    };
    setState(() {
      _inCalling = true;
    });
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

  void _sendCandidateQueue() async {
    var cands = _localCandidates;
    try {
      if (_localCandidates.length == 0) {
        return;
      }
      print('attempting to send candidates');

      await widget.room.sendCallCandidates('${widget.room.id}call', cands);

      setState(() {
        _localCandidates.clear();
        ++_localCandidateSendTries;
      });
    } on Exception catch (e) {
      _localCandidates.addAll(cands);
      if (_localCandidateSendTries > 5) {
        print(
            'Failed to send candidates for the $_localCandidateSendTries time. Giving up for now!');
        _localCandidateSendTries = 0;
        return;
      }
      var delayMs = 500 * pow(2, _localCandidateSendTries);
      ++_localCandidateSendTries;
      print("Failed to send candidates. Retrying in $delayMs ms");
      Timer(Duration(milliseconds: delayMs), () {
        _sendCandidateQueue();
      });
    }
  }

  @override
  void dispose() {
    if (_inCalling) {
      _hangUp();
    }
    //_localStream.dispose();
    // _localRenderer.dispose();
    // _remoteRenderer.dispose();
    //_peerConnection.close();
    //_peerConnection.dispose();
    super.dispose();
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection.createOffer(_sdpConstraints);
    await _peerConnection.setLocalDescription(description);
    await widget.room.inviteToCall(
      '${widget.room.id}call',
      30000,
      description.sdp.toString(),
    );
    print('offer created');
  }

  void _createAnswer(session) async {
    RTCSessionDescription remotedescription = new RTCSessionDescription(
        session['sdp'].toString(), session['type'].toString());

    print(session['sdp']);

    await _peerConnection.setRemoteDescription(remotedescription);
    RTCSessionDescription localdescription =
        await _peerConnection.createAnswer(_sdpConstraints);
    await _peerConnection.setLocalDescription(localdescription);
    await widget.room.answerCall(
      '${widget.room.id}call',
      localdescription.sdp,
    );
    print('answered the call');
    setState(() {
      _answered = true;
    });
  }

  void _setRemoteDescription(Map<String, dynamic> session) async {
    //var content=jsonDecode(source)
    RTCSessionDescription description = new RTCSessionDescription(
        session['sdp'].toString(), session['type'].toString());

    print(session['sdp']);

    await _peerConnection.setRemoteDescription(description);
  }

  void _addCandidate(List<dynamic> candidates) async {
    candidates.forEach((session) {
      print('candidates are adding    ' +
          '${session['candidate']}   ${session['sdpMid']}    ${session['sdpMlineIndex'].runtimeType}');
      RTCIceCandidate candidate = RTCIceCandidate(
          session['candidate'].toString(),
          session['sdpMid'].toString(),
          session['sdpMlineIndex']);
      _peerConnection
          .addCandidate(candidate)
          .then((value) => print('successfully added'));
    });
  }

  void _hangUp() async {
    try {
      await _localStream.dispose();
      await _peerConnection.close();
      _peerConnection = null;
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
      _localRenderer.dispose();
      _remoteRenderer.dispose();
    } catch (e) {
      print(e.toString());
    }
    setState(() {
      _inCalling = false;
      _hangedup = true;
    });
    //_timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var timer = Timer(Duration(milliseconds: 30000), () {
      if (!_answered) {
        _hangUp();
        // widget.room.hangupCall('${widget.room.id}call');
        // _hangUp();
      }
    });
    if (_hangedup) {
      timer.cancel();
      Navigator.of(context).pop();
    }
    TalkDevTestApp.client.onCallAnswer.stream.listen((event) {
      setState(() {
        _answered = true;
      });

      if (event.senderId != TalkDevTestApp.client.userID)
        _setRemoteDescription(event.content['answer']);

      //widget.room.sendCallCandidates('${widget.room.id}call', candidates)
    });
    TalkDevTestApp.client.onCallCandidates.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID)
        _addCandidate(event.content['candidates']);
    });
    TalkDevTestApp.client.onCallHangup.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID) {
        _hangUp();
        //widget.room.hangupCall('${widget.room.id}call');
        //if (mounted) Navigator.pop(context);
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
                      onPressed: () async {
                        await widget.room.hangupCall('${widget.room.id}call');
                        _hangUp();
                      })
                ],
              )),
        ]),
      );
    }));
  }
}
