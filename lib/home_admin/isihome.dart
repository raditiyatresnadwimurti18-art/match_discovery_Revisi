import 'package:flutter/material.dart';

import 'package:match_discovery/home_admin/widget_home/widget2.dart';

class IsiHome extends StatefulWidget {
  const IsiHome({super.key});

  @override
  State<IsiHome> createState() => _IsiHomeState();
}

class _IsiHomeState extends State<IsiHome> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),

      child: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.start, // Pastikan mulai dari atas
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Widget2()],
          ),
        ),
      ),
    );
  }
}
