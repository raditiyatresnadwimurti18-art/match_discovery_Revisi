import 'dart:io';
import 'package:flutter/material.dart';
import 'package:match_discovery/database/sql_lite.dart';
import 'package:match_discovery/models/admin_model.dart';

class DaftarAdminPage extends StatefulWidget {
  const DaftarAdminPage({super.key});

  @override
  State<DaftarAdminPage> createState() => _DaftarAdminPageState();
}

class _DaftarAdminPageState extends State<DaftarAdminPage> {
  // Fungsi untuk memuat ulang daftar admin
  Future<List<AdminModel>> _loadAdmin() async {
    return await DBHelper.getSemuaAdmin();
  }

  void _confirmDelete(AdminModel admin) {
    // Jangan biarkan Super Admin menghapus dirinya sendiri secara tidak sengaja
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
        title: const Text("Konfirmasi Hapus"),
        content: Text("Apakah Anda yakin ingin menghapus admin ${admin.nama}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper.deleteAdmin(admin.id!);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {}); // Refresh UI setelah hapus
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Admin Staff"),
        backgroundColor: const Color(0xff0f2a55),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AdminModel>>(
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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xff0f2a55),
                    backgroundImage:
                        admin.profilePath != null &&
                            admin.profilePath!.isNotEmpty
                        ? FileImage(File(admin.profilePath!))
                        : null,
                    child:
                        admin.profilePath == null || admin.profilePath!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    admin.nama ?? "Tanpa Nama",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("@${admin.username} • Role: ${admin.role}"),
                  trailing: admin.role == 'super'
                      ? const Icon(
                          Icons.stars,
                          color: Colors.amber,
                        ) // Tanda bintang untuk Super Admin
                      : IconButton(
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmDelete(admin),
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
