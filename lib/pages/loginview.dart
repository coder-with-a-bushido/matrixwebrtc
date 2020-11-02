import 'package:flutter/material.dart';

import '../main.dart';
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
        MaterialPageRoute(builder: (_) => ChatListView()),
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
                  child: Text('Karthi'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _homeserverController.text =
                              'https://talk-dev.vyah.com';
                          _usernameController.text = 'kartik';
                          _passwordController.text = 'kartik123';
                          _loginAction();
                        }),
              RaisedButton(
                  child: Text('Anurag'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _homeserverController.text =
                              'https://talk-dev.vyah.com';
                          _usernameController.text = 'anurag';
                          _passwordController.text = 'anurag123';
                          _loginAction();
                        })
            ],
          )
        ],
      ),
    );
  }
}
