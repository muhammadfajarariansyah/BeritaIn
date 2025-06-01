import 'dart:convert';

import 'package:BeritaIn/screens/full_image_screen.dart';
import 'package:BeritaIn/screens/comment_screen.dart';
import 'package:BeritaIn/favoriteservice.dart';
import 'package:BeritaIn/commentservice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.imageBase64,
    this.title,
    required this.description,
    required this.createdAt,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.heroTag,
    this.reportId,
  });

  final String imageBase64;
  final String? title;
  final String description;
  final DateTime createdAt;
  final String fullName;
  final double latitude;
  final double longitude;
  final String category;
  final String heroTag;
  final String? reportId; // ID untuk identifikasi laporan

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  final FavoriteService _favoriteService = FavoriteService();
  final CommentService _commentService = CommentService();
  late String _reportId;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    // Generate reportId jika tidak ada
    _reportId = widget.reportId ?? 
        '${widget.createdAt.millisecondsSinceEpoch}_${widget.category}_${widget.description.hashCode}';
    _checkFavoriteStatus();
    _loadCommentCount();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _favoriteService.isFavorite(_reportId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _loadCommentCount() async {
    try {
      final count = await _commentService.getCommentCount(_reportId);
      if (mounted) {
        setState(() {
          _commentCount = count;
        });
      }
    } catch (e) {
      print('Error loading comment count: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(_reportId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dihapus dari favorit'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final reportData = {
          'imageBase64': widget.imageBase64,
          'title': widget.title,
          'description': widget.description,
          'createdAt': widget.createdAt.millisecondsSinceEpoch,
          'fullName': widget.fullName,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'category': widget.category,
          'heroTag': widget.heroTag,
        };
        await _favoriteService.addFavorite(_reportId, reportData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ditambahkan ke favorit'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // Update status favorite
      await _checkFavoriteStatus();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status favorit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
      );
    }
  }

  void _openCommentScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          reportId: _reportId,
          reportTitle: widget.title ?? 'Detail Berita',
        ),
      ),
    );
    
    // Refresh comment count setelah kembali dari comment screen
    if (result == true) {
      _loadCommentCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAtFormatted = DateFormat(
      'dd MMMM yyyy, HH:mm',
    ).format(widget.createdAt);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title != null && widget.title!.isNotEmpty 
              ? widget.title! 
              : 'Detail Berita',
          overflow: TextOverflow.ellipsis, // Untuk menangani judul yang panjang
        ),
        backgroundColor: const Color(0xFF2E5266),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: widget.heroTag,
                  child: Image.memory(
                    base64Decode(widget.imageBase64),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullscreenImageScreen(
                            imageBase64: widget.imageBase64,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Lihat gambar penuh',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kiri: Kategori & Waktu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.category,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  createdAtFormatted,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Kanan: Icon favorit dan map
                      Row(
                        children: [
                          IconButton(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 32,
                              color: _isFavorite ? Colors.red : Colors.grey,
                            ),
                            tooltip: _isFavorite ? "Hapus dari favorit" : "Tambah ke favorit",
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: openMap,
                            icon: const Icon(
                              Icons.map,
                              size: 32,
                              color: Colors.lightGreen,
                            ),
                            tooltip: "Buka di Google Maps",
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  // Section komentar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: InkWell(
                      onTap: _openCommentScreen,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.comment,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Komentar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    _commentCount > 0 
                                        ? '$_commentCount komentar'
                                        : 'Belum ada komentar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}