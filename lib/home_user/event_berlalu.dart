import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/util/app_theme.dart';

class EventBerlalu extends StatefulWidget {
  const EventBerlalu({super.key});

  @override
  State<EventBerlalu> createState() => _EventBerlaluState();
}

class _EventBerlaluState extends State<EventBerlalu> {
  late Future<List<Map<String, dynamic>>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = RiwayatController.getRiwayatEvent();
  }

  void _refreshData() =>
      setState(() => _eventFuture = RiwayatController.getRiwayatEvent());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: kPrimaryAppBar(
        title: 'Event Telah Berakhir',
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: Colors.grey.withOpacity(0.1), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.event_busy_outlined,
                        size: 56, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada event yang berakhir',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) =>
                  _buildCard(snapshot.data![index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: kCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Opacity(
          opacity: 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar + Badge
              Stack(
                children: [
                  event['gambarPath'] != null
                      ? (event['gambarPath']!.toString().startsWith('data:image')
                          ? Image.memory(
                              base64Decode(event['gambarPath']!.toString().split(',').last),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(event['gambarPath']),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ))
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 48, color: Colors.grey)),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('SELESAI',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['judul'] ?? '-', style: kTitleStyle),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined, event['lokasi']),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_outlined, event['tanggal']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String? value) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(value ?? '-', style: kSubtitleStyle)),
        ],
      );
}