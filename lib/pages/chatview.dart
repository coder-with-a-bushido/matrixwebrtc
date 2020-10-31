import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class ChatView extends StatefulWidget {
  final Room room;

  const ChatView({Key key, @required this.room}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();

  void _sendAction() {
    print('Send Text');
    widget.room.sendTextEvent(_controller.text);
    _controller.clear();
  }

  Timeline timeline;

  Future<bool> getTimeline() async {
    timeline ??=
        await widget.room.getTimeline(onUpdate: () => setState(() => null));
    return true;
  }

  @override
  void dispose() {
    timeline?.cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TalkDevTestApp.client.onCallInvite.stream.listen((event) {
      if (event.senderId != TalkDevTestApp.client.userID) {
        print('${event.content['offer']}same id');
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<Object>(
            stream: widget.room.onUpdate.stream,
            builder: (context, snapshot) {
              return Text(widget.room.displayname);
            }),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call),
            onPressed: () {
              widget.room
                  .inviteToCall('${widget.room.name}call', 30000, "TestSdp");
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: getTimeline(),
              builder: (context, snapshot) => !snapshot.hasData
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: timeline.events.length,
                      itemBuilder: (BuildContext context, int i) => Opacity(
                        opacity: timeline.events[i].status != 2 ? 0.5 : 1,
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  timeline.events[i].sender.calcDisplayname(),
                                ),
                              ),
                              Text(
                                timeline.events[i].originServerTs
                                    .toIso8601String(),
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          subtitle: Text(timeline.events[i].body),
                          leading: CircleAvatar(
                            child: timeline.events[i].sender?.avatarUrl == null
                                ? Icon(Icons.person)
                                : null,
                            backgroundImage:
                                timeline.events[i].sender?.avatarUrl != null
                                    ? NetworkImage(
                                        timeline.events[i].sender?.avatarUrl
                                            ?.getThumbnail(
                                          TalkDevTestApp.client,
                                          width: 64,
                                          height: 64,
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Container(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      labelText: 'Send a message ...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendAction,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
