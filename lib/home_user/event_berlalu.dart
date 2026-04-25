import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:match_discovery/util/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class EventBerlalu extends StatefulWidget {
  const EventBerlalu({super.key});

  @override
  State<EventBerlalu> createState() => _EventBerlaluState();
}

class _EventBerlaluState extends State<EventBerlalu> {
  late Future<List<Map<String, dynamic>>> _eventFuture;

  String _formatTanggal(String tanggal) {
    try {
      DateTime dateTime = DateTime.parse(tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return tanggal;
    }
  }

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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat event selesai',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              physics: const BouncingScrollPhysics(),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: event['gambarPath'] != null
                    ? (event['gambarPath']!.toString().startsWith('data:image')
                        ? Image.memory(
                            base64Decode(event['gambarPath']!.toString().split(',').last),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(event['gambarPath']),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ))
                    : Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey.shade50,
                        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade300)),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text('SELESAI', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.green.shade800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['judul'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: kPrimaryColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(event['lokasi'] ?? '-', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_formatTanggal(event['tanggal'] ?? ''), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
