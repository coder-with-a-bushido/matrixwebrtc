import 'dart:async';
import 'dart:math';

import 'package:example/src/utils/usermedia.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../main.dart';
import 'utils/specs.dart';

Random random = new Random();

class MatrixCall {
  Room room;
  final String callId = "c" +
      new DateTime.now().toIso8601String() +
      random.nextInt(1000).toString();
  RTCPeerConnection _peerConnection;
  List<RTCIceCandidate> _remoteCandidates = [];
  List<Map<String, dynamic>> _queuedLocalCandidates = [];
  int _localCandidateSendTries = 0;
  MediaStream _localMediaStream;
  MediaStream _remoteMediaStream;
  RTCSessionDescription _remoteSdp;
  set setRemoteSDP(RTCSessionDescription sdp) {
    this._remoteSdp = sdp;
  }

  // MatrixPeerConnectionStateCallback _peerConnectionStateCallback;
  PeerConnectionState _signalingState = PeerConnectionState.RTC_CONNECTION_NEW;
  bool _canSendCandidates = true;
  Timer _candidateTimer;
  Timer _diallingTimer;
  int _startConnectionTime;
  bool remoteDescriptionSet = false;
  final bool useCallingTimer;
  final _stateController = StreamController<PeerConnectionState>();
  Stream<PeerConnectionState> get state => _stateController.stream;
  final _remoteStreamController = StreamController<MediaStream>();
  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  //final _localStreamController = StreamController<MediaStream>();
  MediaStream get localStream => _localMediaStream;
  // MediaStream get remoteStream => _remoteMediaStream;

  MatrixCall({this.useCallingTimer = true}) {
    // onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CLOSED);

    TalkDevTestApp.client.onCallCandidates.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID) {
        if (remoteDescriptionSet) {
          event.content['candidates'].forEach((session) {
            RTCIceCandidate candidate = RTCIceCandidate(
                session['candidate'].toString(),
                session['sdpMid'].toString(),
                session['sdpMlineIndex']);
            _remoteCandidates.add(candidate);
          });
          _addCandidate();
        } else {
          event.content['candidates'].forEach((session) {
            RTCIceCandidate candidate = RTCIceCandidate(
                session['candidate'].toString(),
                session['sdpMid'].toString(),
                session['sdpMlineIndex']);
            _remoteCandidates.add(candidate);
          });
        }
      }
    });
    TalkDevTestApp.client.onCallAnswer.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID) {
        _remoteSdp = new RTCSessionDescription(
            event.content['answer']['sdp'].toString(),
            event.content['answer']['type'].toString());

        _setRemoteDescription();
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CONNECTING);
      }
    });
    TalkDevTestApp.client.onCallHangup.stream.listen((event) {
      onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CLOSED);
      _close();
    });
  }
  Future<void> initialize({bool incoming = false}) async {
    _peerConnection = await _createPeerConnection();
    if (incoming) _startAnswerTimer();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);
    _localMediaStream = await getUserMedia();
    // _localStreamController.sink.add(_localMediaStream);
    pc.addStream(_localMediaStream);
    pc.onIceCandidate = (cand) async {
      if (cand != null) {
        Map<String, dynamic> currCandidate = {
          'candidate': cand.candidate.toString(),
          'sdpMlineIndex': cand.sdpMlineIndex,
          'sdpMid': cand.sdpMid.toString(),
        };
        if (!_queuedLocalCandidates.contains(currCandidate))
          _queuedLocalCandidates.add(currCandidate);
      }
      if (_canSendCandidates && _localCandidateSendTries == 0) {
        _sendICECandidates();
        _canSendCandidates = false;
        _candidateTimer = Timer(Duration(milliseconds: 500), () {
          _canSendCandidates = true;
        });
      }
    };
    pc.onIceConnectionState = (state) {
      print("$state onIceConnectionState.");
      if (RTCIceConnectionState.RTCIceConnectionStateChecking == state) {
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CHECKING);

        _cancelTimers();
      }
      if (RTCIceConnectionState.RTCIceConnectionStateConnected == state ||
          RTCIceConnectionState.RTCIceConnectionStateCompleted == state) {
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CONNECTED);
      }
      if (RTCIceConnectionState.RTCIceConnectionStateDisconnected == state) {
        onConnectionStateChanged(
            PeerConnectionState.RTC_CONNECTION_DISCONNECTED);
      }
      if (RTCIceConnectionState.RTCIceConnectionStateFailed == state) {
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_FAILED);
      }
      if (RTCIceConnectionState.RTCIceConnectionStateClosed == state) {
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CLOSED);
      }
    };
    pc.onAddStream = (stream) {
      _remoteMediaStream = stream;
      _remoteStreamController.sink.add(stream);
    };
    pc.onRemoveStream = (stream) {
      _remoteMediaStream = null;
      _remoteStreamController.sink.add(null);
      //_localStreamController.sink.add(null);
    };
    pc.onSignalingState = (state) {
      print(state);
    };
    pc.onIceGatheringState = (state) {
      print(state);
    };
    // pc.onIceConnectionState = (state) {
    //   print(state);
    // };
    return pc;
  }

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:turn.connectycube.com'},
      {
        'url': 'turn:turn.connectycube.com:5349?transport=udp',
        'username': 'connectycube',
        'credential': '4c29501ca9207b7fb9c4b4b6b04faeb1'
      },
      {
        'url': 'turn:turn.connectycube.com:5349?transport=tcp',
        'username': 'connectycube',
        'credential': '4c29501ca9207b7fb9c4b4b6b04faeb1'
      },
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Map<String, dynamic> get _constraints => {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': _isVideoCall(),
        },
        'optional': [],
      };
  void startCall() {
    _createOffer(_peerConnection);
  }

  answerCall() async {
    // if (PeerConnectionState.RTC_CONNECTION_PENDING != _signalingState &&
    //     PeerConnectionState.RTC_CONNECTION_NEW != _signalingState) return;

    print('startAnswer');

    onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_CONNECTING);

    if (_remoteSdp == null) return;

    _setRemoteDescription();

    await _createAnswer();

    if (this._remoteCandidates.length > 0) {
      _remoteCandidates.forEach((candidate) async {
        if (candidate != null) await _peerConnection?.addCandidate(candidate);
      });
      _remoteCandidates.clear();
    }
  }

  _createOffer(RTCPeerConnection peerConnection) async {
    print('_createOffer called.');

    onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_PENDING);

    try {
      RTCSessionDescription sessionDescription =
          await peerConnection.createOffer(_constraints);
      peerConnection.setLocalDescription(sessionDescription);
      _sendOffer(sessionDescription);
      if (useCallingTimer) _startCallingTimer(sessionDescription);
    } catch (e) {
      print('_createOffer error!!!');
    }
  }

  _setRemoteDescription() async {
    if (_remoteSdp.sdp != null &&
        _signalingState != PeerConnectionState.RTC_CONNECTION_CONNECTED) {
      await _peerConnection.setRemoteDescription(_remoteSdp);
      if (!remoteDescriptionSet) remoteDescriptionSet = true;
    }
  }

  _createAnswer() async {
    try {
      RTCSessionDescription description =
          await _peerConnection.createAnswer(_constraints);
      _peerConnection.setLocalDescription(description);
      print("sendanswer called!!!!!");
      _sendAnswer(description);
    } catch (e) {
      print('_createAnswer error!!!');
    }
  }

  _sendOffer(RTCSessionDescription description) async {
    await room.inviteToCall(
      callId.toString(),
      RTCConfig.defaultNoAnswerTimeout,
      description.sdp.toString(),
    );
  }

  _sendAnswer(RTCSessionDescription description) async {
    await room
        .answerCall(
          callId.toString(),
          description.sdp,
        )
        .then((value) => print("answer sent!!!!!!!!!!!"));
  }

  _sendICECandidates() async {
    try {
      if (_queuedLocalCandidates.isNotEmpty) {
        await room.sendCallCandidates(callId, _queuedLocalCandidates);
        _queuedLocalCandidates.clear();
      }
    } catch (e) {
      print(e);
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
        _sendICECandidates();
      });
    }
  }

  Future<void> _addCandidate() async {
    try {
      _remoteCandidates.forEach((session) {
        print('candidates are adding    ' +
            '${session.candidate}   ${session.sdpMid}    ${session.sdpMlineIndex}');
        if (session != null) _addCandidateFromList(session);
      });
      _remoteCandidates.clear();
    } catch (e) {
      print('Exception in adding the candidates');
    }
  }

  Future<void> _addCandidateFromList(RTCIceCandidate candidate) async {
    await _peerConnection
        ?.addCandidate(candidate)
        ?.then((value) => print('successfully added'));
  }

  void switchCamera() {
    if (_localMediaStream != null) {
      _localMediaStream.getVideoTracks()[0].switchCamera();
    }
  }

  void muteMic() {
    if (_localMediaStream != null) {
      bool enabled = _localMediaStream.getAudioTracks()[0].enabled;
      _localMediaStream.getAudioTracks()[0].enabled = !enabled;
    }
  }

  void muteVideo() {
    if (_localMediaStream != null) {
      bool enabled = _localMediaStream.getVideoTracks()[0].enabled;
      _localMediaStream.getVideoTracks()[0].enabled = !enabled;
    }
  }

  void _close() {
    _cancelTimers();
    _candidateTimer?.cancel();
    _stateController.close();
    _remoteStreamController.close();
    //_localStreamController.close();
    if (_localMediaStream != null) _localMediaStream.dispose();
    if (_remoteMediaStream != null) _remoteMediaStream.dispose();
    if (_peerConnection == null) return;
    _peerConnection.close();
    _peerConnection = null;
  }

  void hangUp() {
    room.hangupCall(callId);
    _close();
  }

  bool _isVideoCall() {
    return CallType.VIDEO_CALL == 1; //_peerConnectionStateCallback?.callType;
  }

  void _startCallingTimer(RTCSessionDescription sessionDescription) {
    _startConnectionTime = DateTime.now().millisecondsSinceEpoch;
    _diallingTimer = Timer.periodic(
        Duration(seconds: RTCConfig.defaultDillingTimeInterval), (timer) {
      if (_isConnectionExpired()) {
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_TIMEOUT);
        timer?.cancel();
      } else {
        if (PeerConnectionState.RTC_CONNECTION_CONNECTING == _signalingState ||
            PeerConnectionState.RTC_CONNECTION_PENDING == _signalingState) {
           _sendOffer(sessionDescription);
        } else {
          timer?.cancel();
        }
      }
    });
  }

  void _startAnswerTimer() {
    _startConnectionTime = DateTime.now().millisecondsSinceEpoch;
    _diallingTimer = Timer.periodic(
        Duration(seconds: RTCConfig.defaultDillingTimeInterval), (timer) {
      if (_isConnectionExpired()) {
        onConnectionStateChanged(PeerConnectionState.RTC_CONNECTION_TIMEOUT);
        timer.cancel();
      }
    });
  }

  void _cancelTimers() {
    if (_diallingTimer != null) _diallingTimer?.cancel();
  }

  bool _isConnectionExpired() {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int diff = currentTime - _startConnectionTime;
    bool isCallExpired = (diff / 1000) >= RTCConfig.defaultNoAnswerTimeout;

    return isCallExpired;
  }

  void onConnectionStateChanged(PeerConnectionState state) {
    _signalingState = state;
    try {
      _stateController.sink.add(state);
      print("$state changed");
    } catch (e) {
      print(e);
    }
    // _peerConnectionStateCallback.onPeerConnectionStateChanged(_userId, state);
  }

  bool hasRemoteSdp() {
    return _remoteSdp != null;
  }
}

enum PeerConnectionState {
  RTC_CONNECTION_NEW,
  RTC_CONNECTION_PENDING,
  RTC_CONNECTION_CONNECTING,
  RTC_CONNECTION_CHECKING,
  RTC_CONNECTION_CONNECTED,
  RTC_CONNECTION_DISCONNECTED,
  RTC_CONNECTION_TIMEOUT,
  RTC_CONNECTION_CLOSED,
  RTC_CONNECTION_FAILED
}
