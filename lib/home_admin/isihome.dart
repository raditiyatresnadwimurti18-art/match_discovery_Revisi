import 'package:flutter/material.dart';
import 'package:match_discovery/home_admin/widget_home/widget2.dart';
import 'package:match_discovery/util/app_theme.dart';

class IsiHome extends StatefulWidget {
  const IsiHome({super.key});

  @override
  State<IsiHome> createState() => _IsiHomeState();
}

class _IsiHomeState extends State<IsiHome> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [Widget2()],
        ),
      ),
    );
  }
}