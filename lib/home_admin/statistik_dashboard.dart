import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/controllers/lomba.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await UserController.getAllUser();
      final admins = await AdminController.getSemuaAdmin();
      final lomba = await LombaController.getAllLomba();

      // 1. Statistik Dasar
      _totalUsers = users.length;
      _totalAdmins = admins.length + 1; // +1 super admin
      _totalLomba = lomba.length;

      // 2. Filter Lomba
      DateTime now = DateTime.now();
      _ongoingLomba = 0;
      _finishedLomba = 0;
      for (var l in lomba) {
        try {
          DateTime tgl = DateTime.parse(l.tanggal);
          if (tgl.isAfter(now) ||
              (tgl.day == now.day &&
                  tgl.month == now.month &&
                  tgl.year == now.year)) {
            _ongoingLomba++;
          } else {
            _finishedLomba++;
          }
        } catch (_) {
          _ongoingLomba++;
        }
      }

      // 3. Logika "Pandas" di Dart (Grouping Data)
      _chartData = {};
      for (var u in users) {
        String key = "";
        try {
          DateTime tgl = u.tanggal_daftar != null
              ? DateTime.parse(u.tanggal_daftar!)
              : now;

          if (_selectedPeriod == "Hari") {
            key = DateFormat('dd/MM').format(tgl);
          } else if (_selectedPeriod == "Bulan") {
            key = DateFormat('MMM').format(tgl);
          } else {
            key = tgl.year.toString();
          }
          _chartData[key] = (_chartData[key] ?? 0) + 1;
        } catch (_) {}
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error loading statistik: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Statistik Sistem",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Data analitik real-time",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            items: _periods
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPeriod = val);
                _loadData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statBox("User", _totalUsers.toString(), Icons.people, Colors.blue),
        const SizedBox(width: 12),
        _statBox(
          "Admin",
          _totalAdmins.toString(),
          Icons.admin_panel_settings,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _statBox(
          "Lomba",
          _totalLomba.toString(),
          Icons.emoji_events,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statBox(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: col, size: 24),
            const SizedBox(height: 8),
            Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pertumbuhan Pengguna ($_selectedPeriod)",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_chartData.values.isEmpty
                    ? 10
                    : _chartData.values.reduce((a, b) => a > b ? a : b) + 2),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueAccent,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rod.toY.round()} User",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= _chartData.keys.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _chartData.keys.elementAt(index),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _chartData.entries.toList().asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: Colors.blue,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
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
    return Row(
      children: [
        _lombaCard("Lomba Berlangsung", _ongoingLomba.toString(), Colors.teal),
        const SizedBox(width: 12),
        _lombaCard(
          "Lomba Selesai",
          _finishedLomba.toString(),
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _lombaCard(String title, String val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: col.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: col.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: col,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: col,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
