import 'dart:convert';
import 'package:beritain/screens/detail_screen.dart';
import 'package:beritain/favoriteservice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _favoriteService.getFavorites();
      print('Loaded ${favorites.length} favorites');
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat favorit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFavorite(String reportId, int index) async {
    try {
      await _favoriteService.removeFavorite(reportId);
      setState(() {
        _favorites.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari favorit'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus favorit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(String reportId, int index, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Favorit'),
          content: Text('Apakah Anda yakin ingin menghapus "$category" dari favorit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFavorite(reportId, index);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetail(Map<String, dynamic> favorite) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          imageBase64: favorite['imageBase64'],
          title: favorite['title'],
          description: favorite['description'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(favorite['createdAt']),
          fullName: favorite['fullName'],
          latitude: favorite['latitude'],
          longitude: favorite['longitude'],
          category: favorite['category'],
          heroTag: 'favorite_${favorite['id']}',
          reportId: favorite['id'],
        ),
      ),
    ).then((_) {
      // Refresh favorit setelah kembali dari detail
      _loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        backgroundColor: const Color(0xFF2E5266),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Hapus Semua Favorit'),
                      content: const Text('Apakah Anda yakin ingin menghapus semua favorit?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              await _favoriteService.clearAllFavorites();
                              await _loadFavorites(); // Refresh list
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Semua favorit telah dihapus'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menghapus semua favorit: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Hapus semua favorit',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada laporan favorit',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tambahkan laporan ke favorit untuk melihatnya di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = _favorites[index];
                      final createdAt = DateTime.fromMillisecondsSinceEpoch(favorite['createdAt']);
                      final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(createdAt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _navigateToDetail(favorite),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gambar thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(favorite['imageBase64']),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Konten
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Kategori
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          favorite['category'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Deskripsi
                                      Text(
                                        favorite['description'],
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Tanggal
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Tombol hapus
                                IconButton(
                                  onPressed: () => _showDeleteDialog(
                                    favorite['id'],
                                    index,
                                    favorite['category'],
                                  ),
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Hapus dari favorit',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}