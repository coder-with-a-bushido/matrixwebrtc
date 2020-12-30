part of 'callstate_bloc.dart';

@immutable
abstract class CallstateEvent {}

class IncomingCall extends CallstateEvent {
  IncomingCall({this.remoteSDP});
  final RTCSessionDescription remoteSDP;
}

class OutgoingCall extends CallstateEvent {
  OutgoingCall({this.room});
  final Room room;
}

class NoCall extends CallstateEvent {}
