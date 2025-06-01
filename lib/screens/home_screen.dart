import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:intl/intl.dart';
import 'package:BeritaIn/screens/add_post_screen.dart';
import 'package:BeritaIn/screens/detail_screen.dart';
import 'package:BeritaIn/screens/sign_in_screen.dart';
import 'package:BeritaIn/screens/profile_screen.dart';
import 'package:BeritaIn/screens/favorite_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    'Berita Utama',
    'Politik',
    'Ekonomi',
    'Teknologi',
    'Olahraga',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Lingkungan',
    'Sosial',
    'Budaya',
    'Internasional',
    'Daerah',
    'Kriminal',
    'Bisnis',
    'Lifestyle',
    'Lainnya',
  ];

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik lalu';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  List<QueryDocumentSnapshot> _getRandomNews(List<QueryDocumentSnapshot> allNews) {
    if (allNews.length <= 3) return allNews;
    
    final random = Random();
    final shuffled = List<QueryDocumentSnapshot>.from(allNews)..shuffle(random);
    return shuffled.take(3).toList();
  }

  void _showCategoryFilter() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Kategori',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.clear_all),
                        title: const Text('Semua Kategori'),
                        onTap: () => Navigator.pop(context, null),
                      ),
                      const Divider(),
                      ...categories.map(
                        (category) => ListTile(
                          title: Text(category),
                          trailing: selectedCategory == category
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedCategory = result;
      });
    } else {
      setState(() {
        selectedCategory = null;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan search bar dan toggle dark mode (tetap fixed)
            _buildHeader(context),
            
            // Scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: CustomScrollView(
                  slivers: [
                    // Spacing after header
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    
                    // Section Random News (Horizontal)
                    SliverToBoxAdapter(
                      child: _buildRandomNewsSection(),
                    ),
                    
                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    
                    // Section Kategori
                    SliverToBoxAdapter(
                      child: _buildCategorySection(),
                    ),
                    
                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    
                    // Section Hot News Header
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'BERITA TERKINI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                    
                    // List Berita (as SliverList)
                    _buildSliverNewsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRandomNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Berita Pilihan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('news')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error memuat berita',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada berita tersedia',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              final validPosts = snapshot.data!.docs.where((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['createdAt'] != null;
                } catch (e) {
                  return false;
                }
              }).toList();

              if (validPosts.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada berita tersedia',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              final randomNews = _getRandomNews(validPosts);

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: randomNews.length,
                itemBuilder: (context, index) {
                  try {
                    final doc = randomNews[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Ekstrak data dengan default values
                    final imageBase64 = data['image'] as String?;
                    final description = data['description'] as String? ?? 'Tidak ada deskripsi';
                    final title = data['title'] as String? ?? 'Tidak ada judul';
                    final fullName = data['fullName'] as String? ?? 'Anonim';
                    final category = data['category'] as String? ?? 'Lainnya';
                    
                    // Parse tanggal
                    DateTime createdAt;
                    final createdAtStr = data['createdAt'];
                    if (createdAtStr is Timestamp) {
                      createdAt = createdAtStr.toDate();
                    } else if (createdAtStr is String) {
                      createdAt = DateTime.parse(createdAtStr);
                    } else {
                      createdAt = DateTime.now();
                    }

                    return _buildRandomNewsItem(
                      imageBase64: imageBase64,
                      title: title,
                      description: description,
                      createdAt: createdAt,
                      fullName: fullName,
                      category: category,
                      heroTag: 'random-news-${doc.id}',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              imageBase64: data['image'],
                              description: description,
                              createdAt: createdAt,
                              fullName: fullName,
                              latitude: data['latitude'],
                              longitude: data['longitude'],
                              category: category,
                              heroTag: 'random-news-${doc.id}',
                            ),
                          ),
                        );
                      },
                    );
                  } catch (e) {
                    debugPrint('Error building random news item $index: $e');
                    return _buildRandomNewsErrorItem();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRandomNewsItem({
    required String? imageBase64,
    required String title,
    required String description,
    required DateTime createdAt,
    required String fullName,
    required String category,
    required String heroTag,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              if (imageBase64 != null && imageBase64.isNotEmpty)
                Hero(
                  tag: heroTag,
                  child: Image.memory(
                    base64Decode(imageBase64),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Meta info
                      Text(
                        '${formatTime(createdAt)} • $fullName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRandomNewsErrorItem() {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: const Center(
        child: Text(
          'Gagal memuat berita',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2E5266),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari berita...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16,vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.dark_mode, color: Colors.white),
              onPressed: () {
                AdaptiveTheme.of(context).toggleThemeMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Kategori',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = isSelected ? null : category;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF2E5266),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliverNewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('news')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading posts: ${snapshot.error}');
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Text(
                  'Error memuat berita: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: Text(
                  'Belum ada berita tersedia',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs.where((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            
            // Validasi data
            if (data['createdAt'] == null) {
              debugPrint('Post tanpa createdAt: ${doc.id}');
              return false;
            }
            
            // Ambil data untuk filter
            final category = (data['category'] ?? 'Lainnya').toString().trim();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description =
                (data['description'] ?? '').toString().toLowerCase();
            
            // Filter kategori
            final categoryMatch = selectedCategory == null ||
                category.toLowerCase() == selectedCategory!.toLowerCase();
            
            // Filter pencarian
            final searchMatch = searchQuery.isEmpty ||
                title.contains(searchQuery) ||
                description.contains(searchQuery) ||
                category.toLowerCase().contains(searchQuery);
            
            return categoryMatch && searchMatch;
          } catch (e) {
            debugPrint('Error processing post ${doc.id}: $e');
            return false;
          }
        }).toList();

        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      selectedCategory == null && searchQuery.isEmpty
                          ? "Belum ada berita tersedia"
                          : searchQuery.isNotEmpty
                              ? "Tidak ditemukan hasil untuk '$searchQuery'"
                              : "Tidak ada berita untuk kategori '$selectedCategory'",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              try {
                final doc = posts[index];
                final data = doc.data() as Map<String, dynamic>;
                
                // Ekstrak data dengan default values
                final imageBase64 = data['image'] as String?;
                final description = data['description'] as String? ?? 'Tidak ada deskripsi';
                final title = data['title'] as String? ?? 'Tidak ada judul';
                final fullName = data['fullName'] as String? ?? 'Anonim';
                final category = data['category'] as String? ?? 'Lainnya';
                
                // Parse tanggal
                DateTime createdAt;
                final createdAtStr = data['createdAt'];
                if (createdAtStr is Timestamp) {
                  createdAt = createdAtStr.toDate();
                } else if (createdAtStr is String) {
                  createdAt = DateTime.parse(createdAtStr);
                } else {
                  createdAt = DateTime.now();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildNewsItem(
                    imageBase64: imageBase64,
                    title: title,
                    description: description,
                    createdAt: createdAt,
                    fullName: fullName,
                    category: category,
                    heroTag: 'news-image-${doc.id}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            imageBase64: data['image'],
                            description: description,
                            createdAt: createdAt,
                            fullName: fullName,
                            latitude: data['latitude'],
                            longitude: data['longitude'],
                            category: category,
                            heroTag: 'news-image-${doc.id}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                debugPrint('Error building item $index: $e');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildErrorItem(),
                );
              }
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }

  Widget _buildNewsItem({
    required String? imageBase64,
    required String title,
    required String description,
    required DateTime createdAt,
    required String fullName,
    required String category,
    required String heroTag,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 120,
          child: Stack(
            children: [
              // Gambar berita
              if (imageBase64 != null && imageBase64.isNotEmpty)
                Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(imageBase64),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Konten teks
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatTime(createdAt)} • $fullName • $category',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorItem() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Text(
            'Gagal memuat berita',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF2E5266),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.home, size: 28, color: Colors.white),
            )
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.favorite, size: 28, color: Colors.white),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2E5266),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPostScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 28, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }
}