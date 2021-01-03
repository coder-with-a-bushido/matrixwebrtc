part of 'callstate_bloc.dart';

@immutable
abstract class CallstateState {}

class CallstateNone extends CallstateState {}

class CallstateIncoming extends CallstateState {
  CallstateIncoming({this.remoteSDP, this.room});
  final RTCSessionDescription remoteSDP;
  final Room room;
}

class CallstateOutgoing extends CallstateState {
  CallstateOutgoing({this.room});
  final Room room;
}
