part of 'callstate_bloc.dart';

@immutable
abstract class CallstateState {}

class CallstateNone extends CallstateState {}

class CallstateIncoming extends CallstateState {
  CallstateIncoming({this.remoteSDP});
  final RTCSessionDescription remoteSDP;
}

class CallstateOutgoing extends CallstateState {
  CallstateOutgoing({this.room});
  final Room room;
}
