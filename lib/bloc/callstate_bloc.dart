import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meta/meta.dart';

part 'callstate_event.dart';
part 'callstate_state.dart';

class CallstateBloc extends Bloc<CallstateEvent, CallstateState> {
  CallstateBloc() : super(CallstateNone());

  @override
  Stream<CallstateState> mapEventToState(
    CallstateEvent event,
  ) async* {
    if (event is OutgoingCall)
      yield CallstateOutgoing(room: event.room);
    else if (event is IncomingCall)
      yield CallstateIncoming(remoteSDP: event.remoteSDP, room: event.room);
    else
      yield CallstateNone();
  }
}
