import 'package:flutter/material.dart';

class Widget1 extends StatelessWidget {
  const Widget1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hallo, Peserta!\u{1F44B}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text('Temukan kompetisi terbaik untuk karirmu.'),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            labelText: 'Cari kompetisi impianmu',
            icon: Icon(Icons.search),
            suffixIcon: Icon(Icons.filter_list),
          ),
        ),

        SizedBox(height: 20),
      ],
    );
  }
}
