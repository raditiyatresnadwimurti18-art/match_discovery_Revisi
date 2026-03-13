import 'dart:io';

import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/user.dart';
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
  LoginModel? _user;

  void _ketikaDitekan(int index) {
    setState(() => _selectIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    int? id = await PreferenceHandler.getId();
    if (id != null) {
      LoginModel? data = await UserController.getUserById(id);
      setState(() => _user = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ),
        title: const Text(
          'Discovery',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff0f2a55),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                context.push(ProfilUser()).then((_) => _fetchUserData());
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child:
                      _user?.profilePath != null &&
                          _user!.profilePath!.isNotEmpty
                      ? Image.file(
                          File(_user!.profilePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white24, height: 1),
        ),
      ),

      body: _widgetOption.elementAt(_selectIndex),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff0f2a55),
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_rounded),
            label: 'Event Terlewat',
          ),
        ],
        currentIndex: _selectIndex,
        onTap: _ketikaDitekan,
      ),
    );
  }
}
