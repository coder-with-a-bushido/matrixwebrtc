import 'package:example/bloc/callstate_bloc.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../main.dart';
import 'chatview.dart';

class ChatListView extends StatefulWidget {
  @override
  _ChatListViewState createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  _ChatListViewState();

  TextEditingController userName = TextEditingController();

  @override
  Widget build(BuildContext buildContext) {
    TalkDevTestApp.client.onCallInvite.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID) {
        RTCSessionDescription remotedescription = new RTCSessionDescription(
            event.content['offer']['sdp'].toString(),
            event.content['offer']['type'].toString());
        buildContext
            .read<CallstateBloc>()
            .add(IncomingCall(remoteSDP: remotedescription, room: event.room));
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) => VideoCallPage(
        //               room: event.room,
        //               type: 'CallAnswer',
        //               session: event.content['offer'],
        //             )));
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: Column(
        children: [
          TextField(
            controller: userName,
            onEditingComplete: () async {
              var userlist =
                  await TalkDevTestApp.client.searchUser(userName.text);
              print(userlist.results.first.displayname);
            },
          ),
          Flexible(
            child: StreamBuilder(
              stream: TalkDevTestApp.client.onSync.stream,
              builder: (c, s) => ListView.builder(
                itemCount: TalkDevTestApp.client.rooms.length,
                itemBuilder: (BuildContext cntxt, int i) {
                  final room = TalkDevTestApp.client.rooms[i];
                  if (room.membership == Membership.invite ||
                      room.membership == Membership.join) {
                    TalkDevTestApp.client.joinRoom(room.id);
                  }
                  return ListTile(
                    title:
                        Text(room.displayname + ' (${room.notificationCount})'),
                    subtitle: Text(room.lastMessage ?? '', maxLines: 1),
                    onTap: () => Navigator.of(buildContext).push(
                      MaterialPageRoute(
                        builder: (context) => ChatView(room: room),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
