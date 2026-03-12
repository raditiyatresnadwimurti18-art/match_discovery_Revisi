import 'dart:io';

import 'package:flutter/material.dart';
import 'package:match_discovery/database/preferences.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/extension/navigator.dart';
import 'package:match_discovery/home_user/profil.dart';
import 'package:match_discovery/home_user/event_berlalu.dart';
import 'package:match_discovery/home_user/history_user.dart';
import 'package:match_discovery/home_user/isi_home_user.dart';
import 'package:match_discovery/models/login_model.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  static const List<Widget> _widgetOption = <Widget>[
    IsiHomeUser(),
    HistoryUser(),
    EventBerlalu(),
  ];
  int _selectIndex = 0;
  void _ketikaDitekan(int index2) {
    _selectIndex = index2;
    setState(() {});
  }

  int? _userId;
  LoginModel? _user;
  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    int? id = await PreferenceHandler.getId();
    setState(() {
      _userId = id;
    });
  }

  Future<void> _fetchUserData() async {
    if (_userId != null) {
      var data = await DBHelper.getUserById(_userId!);
      setState(() {
        _user = data; // Pastikan data ini berisi profilePath terbaru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/images/logof1.png'),
        title: Text('Discovery', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              context.push(ProfilUser()).then((_) {
                _fetchUserData();
              });
            },
            icon: ClipOval(
              child:
                  _user?.profilePath != null && _user!.profilePath!.isNotEmpty
                  ? Image.file(
                      File(_user!.profilePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 80),
                    )
                  : const Icon(Icons.person, size: 80),
            ),
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 114, 234, 255),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(
            color: const Color.fromARGB(255, 105, 105, 105),
            height: 1,
          ),
        ),
      ),

      body: _widgetOption.elementAt(_selectIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Event Terlewat',
          ),
        ],
        currentIndex: _selectIndex,
        onTap: _ketikaDitekan,

        // selectedItemColor: Colors.blueAccent,
      ),
    );
  }
}
