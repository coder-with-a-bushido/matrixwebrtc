import 'package:example/bloc/callstate_bloc.dart';
import 'package:example/src/callstatusprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'callpages/incomingcall.dart';
import 'callpages/outgoingcall.dart';
import 'chatlistview.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _homeserverController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _error;

  void _loginAction() async {
    setState(() => _isLoading = true);
    setState(() => _error = null);
    try {
      await TalkDevTestApp.client.checkHomeserver(_homeserverController.text);
      // ignore: unrelated_type_equality_checks
      if (await TalkDevTestApp.client.login(
            user: _usernameController.text,
            password: _passwordController.text,
          ) ==
          false) {
        throw (Exception('Username or password incorrect'));
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => BlocBuilder<CallstateBloc, CallstateState>(
                    builder: (context, state) {
                  return Navigator(
                    pages: [
                      MaterialPage(child: ChatListView()),
                      if (state is CallstateOutgoing)
                        MaterialPage(
                            child: OutgoingScreen(
                          room: state.room,
                        )),
                      if (state is CallstateIncoming)
                        MaterialPage(
                            child: IncomingScreen(
                          remoteSDP: state.remoteSDP,
                        ))
                    ],
                    onPopPage: (route, result) {
                      if (!route.didPop(result)) return false;
                      return true;
                    },
                  );
                })),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _homeserverController,
            readOnly: _isLoading,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Homeserver',
              hintText: 'https://matrix.org',
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            readOnly: _isLoading,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: '@username:domain',
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            readOnly: _isLoading,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '****',
              errorText: _error,
            ),
          ),
          SizedBox(height: 8),
          RaisedButton(
            child: _isLoading ? LinearProgressIndicator() : Text('Login'),
            onPressed: _isLoading ? null : _loginAction,
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RaisedButton(
                  child: Text('charlie'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _homeserverController.text =
                              'https://matrixdev.vyah.com:8443';
                          _usernameController.text = 'charlie';
                          _passwordController.text = 'charlie123';
                          _loginAction();
                        }),
              RaisedButton(
                  child: Text('delta'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _homeserverController.text =
                              'https://matrixdev.vyah.com:8443';
                          _usernameController.text = 'delta';
                          _passwordController.text = 'delta123';
                          _loginAction();
                        })
            ],
          )
        ],
      ),
    );
  }
}
