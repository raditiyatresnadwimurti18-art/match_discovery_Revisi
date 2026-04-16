import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/controllers/admin.dart';
import 'package:match_discovery/database/controllers/user.dart';
import 'package:match_discovery/models/admin_model.dart';
import 'package:match_discovery/models/login_model.dart';
import 'package:match_discovery/util/app_theme.dart';

class DaftarAdminPage extends StatefulWidget {
  const DaftarAdminPage({super.key});

  @override
  State<DaftarAdminPage> createState() => _DaftarAdminPageState();
}

class _DaftarAdminPageState extends State<DaftarAdminPage> {
  int _selectedIndex = 0;

  // Fungsi untuk memuat ulang daftar admin
  Future<List<AdminModel>> _loadAdmin() async {
    return await AdminController.getSemuaAdmin();
  }

  // Fungsi untuk memuat ulang daftar user
  Future<List<LoginModel>> _loadUser() async {
    return await UserController.getAllUser();
  }

  void _confirmDeleteAdmin(AdminModel admin) {
    if (admin.role == 'super') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Super Admin tidak dapat dihapus melalui menu ini."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus Admin"),
        content: Text("Apakah Anda yakin ingin menghapus admin ${admin.nama}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminController.deleteAdmin(admin.id!);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Admin berhasil dihapus")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminList() {
    return FutureBuilder<List<AdminModel>>(
      future: _loadAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data admin."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final admin = snapshot.data![index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  backgroundImage: admin.profilePath != null && admin.profilePath!.isNotEmpty
                      ? (admin.profilePath!.startsWith('data:image')
                          ? MemoryImage(base64Decode(admin.profilePath!.split(',').last)) as ImageProvider
                          : (admin.profilePath!.startsWith('http')
                              ? NetworkImage(admin.profilePath!) as ImageProvider
                              : FileImage(File(admin.profilePath!))))
                      : null,
                  child: admin.profilePath == null || admin.profilePath!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),

                title: Text(
                  admin.nama ?? "Tanpa Nama",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("@${admin.username} • Role: ${admin.role}"),
                trailing: admin.role == 'super'
                    ? const Icon(Icons.stars, color: Colors.amber)
                    : IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: () => _confirmDeleteAdmin(admin),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(LoginModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus User"),
        content: Text("Apakah Anda yakin ingin menghapus user ${user.nama}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await UserController.deleteUser(user.id!);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User berhasil dihapus")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<LoginModel>>(
      future: _loadUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data user terdaftar."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  backgroundImage: user.profilePath != null && user.profilePath!.isNotEmpty
                      ? (user.profilePath!.startsWith('data:image')
                          ? MemoryImage(base64Decode(user.profilePath!.split(',').last)) as ImageProvider
                          : (user.profilePath!.startsWith('http')
                              ? NetworkImage(user.profilePath!) as ImageProvider
                              : FileImage(File(user.profilePath!))))
                      : null,
                  child: user.profilePath == null || user.profilePath!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  user.nama ?? "User Baru",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email ?? "Tidak ada email"),
                    if (user.tlpon != null) Text(user.tlpon!),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.red),
                  onPressed: () => _confirmDeleteUser(user),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "Kelola Admin Staff" : "Daftar User Terdaftar",
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: _selectedIndex == 0 ? _buildAdminList() : _buildUserList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: kPrimaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'User'),
        ],
      ),
    );
  }
}
