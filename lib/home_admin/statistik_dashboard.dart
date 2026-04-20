import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/database/controllers/riwayat.dart';
import 'package:intl/intl.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/models/lomba_model.dart';
import 'package:match_discovery/models/riwayat_selesai_user.dart';

class StatistikDashboard extends StatefulWidget {
  const StatistikDashboard({super.key});

  @override
  State<StatistikDashboard> createState() => _StatistikDashboardState();
}

class _StatistikDashboardState extends State<StatistikDashboard> {
  bool _isLoading = true;
  String _selectedPeriod = "Bulan";
  final List<String> _periods = ["Hari", "Bulan", "Tahun"];

  int _totalUsers = 0;
  int _totalAdmins = 0;
  int _totalLomba = 0;
  int _ongoingLomba = 0;
  int _finishedLomba = 0;

  Map<String, double> _chartData = {};

  List<LoginModel> _users = [];
  List<AdminModel> _admins = [];
  List<LombaModel> _lomba = [];
  List<RiwayatSelesaiModel> _riwayatSelesai = [];
  List<Map<String, dynamic>> _riwayatRegistrasi = [];

  StreamSubscription? _userSub;
  StreamSubscription? _adminSub;
  StreamSubscription? _lombaSub;
  StreamSubscription? _riwayatSelesaiSub;
  StreamSubscription? _riwayatRegistrasiSub;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _adminSub?.cancel();
    _lombaSub?.cancel();
    _riwayatSelesaiSub?.cancel();
    _riwayatRegistrasiSub?.cancel();
    super.dispose();
  }

  void _initStreams() {
    _userSub = UserController.getUsersStream().listen((data) {
      _users = data;
      _processData();
    });

    _adminSub = AdminController.getAdminsStream().listen((data) {
      _admins = data;
      _processData();
    });

    _lombaSub = LombaController.getLombaStream().listen((data) {
      _lomba = data;
      _processData();
    });

    _riwayatSelesaiSub = RiwayatController.getRiwayatSelesaiStream().listen((data) {
      _riwayatSelesai = data;
      _processData();
    });

    _riwayatRegistrasiSub = RiwayatController.getRiwayatStream().listen((data) {
      _riwayatRegistrasi = data;
      _processData();
    });
  }

  void _processData() {
    if (!mounted) return;

    setState(() {
      // 1. Statistik Dasar
      _totalUsers = _users.length;
      _totalAdmins = _admins.length;
      _totalLomba = _lomba.length;

      // 2. Filter Lomba
      DateTime now = DateTime.now();
      _ongoingLomba = _lomba.length; // Lomba yang ada di koleksi 'lomba' adalah yang aktif
      _finishedLomba = _riwayatSelesai.length; // Berdasarkan konfirmasi selesai peserta

      // 3. Logika Grouping Data untuk Chart (Trend Pendaftaran)
      _chartData = {};
      
      if (_selectedPeriod == "Hari") {
        // Tampilkan 7 hari terakhir
        for (int i = 6; i >= 0; i--) {
          DateTime d = now.subtract(Duration(days: i));
          String key = DateFormat('dd/MM').format(d);
          _chartData[key] = 0;
        }
      } else if (_selectedPeriod == "Bulan") {
        // Tampilkan 6 bulan terakhir
        for (int i = 5; i >= 0; i--) {
          DateTime d = DateTime(now.year, now.month - i, 1);
          String key = DateFormat('MMM').format(d);
          _chartData[key] = 0;
        }
      } else {
        // Tampilkan 3 tahun terakhir
        for (int i = 2; i >= 0; i--) {
          String key = (now.year - i).toString();
          _chartData[key] = 0;
        }
      }

      for (var r in _riwayatRegistrasi) {
        try {
          String? tglStr = r['tanggalDaftar'];
          if (tglStr == null) continue;

          DateTime tgl = DateTime.parse(tglStr);

          String key = "";
          if (_selectedPeriod == "Hari") {
            key = DateFormat('dd/MM').format(tgl);
          } else if (_selectedPeriod == "Bulan") {
            key = DateFormat('MMM').format(tgl);
          } else {
            key = tgl.year.toString();
          }

          if (_chartData.containsKey(key)) {
            _chartData[key] = (_chartData[key] ?? 0) + 1;
          }
        } catch (_) {}
      }

      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                    const SizedBox(height: 24),
                    _buildLombaSection(),
                    const SizedBox(height: 100), // Extra space at bottom
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Statistik Dashboard",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            Text(
              "Update otomatis: ${DateFormat('HH:mm').format(DateTime.now())}",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
              items: _periods
                  .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontWeight: FontWeight.w600))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPeriod = val);
                  _processData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statBox("Total User", _totalUsers.toString(), Icons.people_alt_rounded, Colors.blue),
        const SizedBox(width: 12),
        _statBox(
          "Admin",
          _totalAdmins.toString(),
          Icons.shield_rounded,
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _statBox(
          "Lomba Aktif",
          _totalLomba.toString(),
          Icons.emoji_events_rounded,
          Colors.green,
        ),
      ],
    );
  }

  Widget _statBox(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: col.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: col, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    double maxData = _chartData.values.isEmpty ? 10 : _chartData.values.reduce((a, b) => a > b ? a : b);
    if (maxData < 5) maxData = 5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tren Pertumbuhan User",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey[900]),
              ),
              Icon(Icons.trending_up, color: Colors.green[400]),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Data pendaftaran berdasarkan periode $_selectedPeriod",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxData * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A237E),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rod.toY.round()}\n",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        children: [
                          const TextSpan(
                            text: 'Pendaftar Baru',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= _chartData.keys.length) {
                          return const SizedBox();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 10,
                          child: Text(
                            _chartData.keys.elementAt(index),
                            style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100],
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _chartData.entries.toList().asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF448AFF), Color(0xFF2979FF)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxData * 1.2,
                          color: Colors.grey[50],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLombaSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Status Aktivitas Lomba",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Jika lebar layar sangat sempit (misal < 300px), susun vertikal
              bool isNarrow = constraints.maxWidth < 280;
              
              return isNarrow 
                ? Column(
                    children: [
                      _lombaStatusItem("Sedang Berlangsung", _ongoingLomba.toString(), Icons.play_circle_fill, Colors.blue[300]!, isExpanded: false),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      _lombaStatusItem("Konfirmasi Selesai", _finishedLomba.toString(), Icons.check_circle, Colors.green[400]!, isExpanded: false),
                    ],
                  )
                : Row(
                    children: [
                      _lombaStatusItem("Sedang Berlangsung", _ongoingLomba.toString(), Icons.play_circle_fill, Colors.blue[300]!),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: Colors.white24,
                      ),
                      _lombaStatusItem("Konfirmasi Selesai", _finishedLomba.toString(), Icons.check_circle, Colors.green[400]!),
                    ],
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _lombaStatusItem(String title, String val, IconData icon, Color col, {bool isExpanded = true}) {
    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: col, size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    return isExpanded ? Expanded(child: content) : content;
  }
}
