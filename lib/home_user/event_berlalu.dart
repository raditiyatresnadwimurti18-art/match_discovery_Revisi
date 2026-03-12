import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/sql_lite.dart';

class EventBerlalu extends StatefulWidget {
  const EventBerlalu({super.key});

  @override
  State<EventBerlalu> createState() => _EventBerlaluState();
}

class _EventBerlaluState extends State<EventBerlalu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Event Telah Berakhir"),
        centerTitle: true,
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Kita perlu buat fungsi getRiwayatEvent di DBHelper
        future: DBHelper.getRiwayatEvent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text(
                    "Belum ada event yang berakhir",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final listEvent = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listEvent.length,
            itemBuilder: (context, index) {
              final event = listEvent[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Opacity(
                  opacity:
                      0.7, // Memberikan efek "grayscale/redup" karena sudah lewat
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: event['gambarPath'] != null
                            ? Image.file(
                                File(event['gambarPath']),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(height: 150, color: Colors.grey[300]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  event['judul'] ?? "",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "SELESAI",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Lokasi: ${event['lokasi']}"),
                            Text("Tanggal: ${event['tanggal']}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
