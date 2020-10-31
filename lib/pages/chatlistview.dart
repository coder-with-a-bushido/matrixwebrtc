import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.add),
      //   onPressed: () {
      //     TalkDevTestApp.client.createRoom(
      //         name: 'newroom',
      //         isDirect: true,
      //         preset: CreateRoomPreset.private_chat,
      //         topic: 'A private chat for webrtc test.',
      //         invite: ['@anurag:talk-dev.vyah.com']);
      //     // TalkDevTestApp.client.inviteToRoom(roomId, '');
      //     TalkDevTestApp.client.rooms.forEach((element) {
      //       print(element.name);
      //     });
      //   },
      // ),
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
                itemBuilder: (BuildContext context, int i) {
                  final room = TalkDevTestApp.client.rooms[i];
                  if (room.membership == Membership.invite ||
                      room.membership == Membership.join) {
                    TalkDevTestApp.client.joinRoom(room.id);
                  }
                  return ListTile(
                    title:
                        Text(room.displayname + ' (${room.notificationCount})'),
                    subtitle: Text(room.lastMessage ?? '', maxLines: 1),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatView(room: room),
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
