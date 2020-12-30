import 'package:flutter/material.dart';

class CallStatusProvider extends ChangeNotifier {
  Status _status = Status.None;
  Status get currentCallStatus => _status;
  setOutgoingCall() {
    _status = Status.Outgoing;
    notifyListeners();
  }

  setIncomingCall() {
    _status = Status.Incoming;
    notifyListeners();
  }

  setCallNONE() {
    _status = Status.None;
    notifyListeners();
  }
}

enum Status { None, Outgoing, Incoming }
