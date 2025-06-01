import 'dart:convert';
import 'dart:io';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGenerating = false;

  List<String> categories = [
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

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _aiCategory = category;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        await _generateDescriptionWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );

      if (compressedImage == null) return;

      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengkompres gambar: $e')));
      }
    }
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;
    setState(() => _isGenerating = true);
    try {
      final imageBytes = await _image!.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      const apiKey = 'AIzaSyBXJle5sTy6MZE8mxtg5Vh8cl163xA7dHk';
      final url =
          'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey';
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
              {
                "text":
                    "Berdasarkan foto ini, identifikasi kategori berita yang paling sesuai "
                    "dari daftar berikut: Berita Utama, Politik, Ekonomi, Teknologi, Olahraga, "
                    "Hiburan, Kesehatan, Pendidikan, Lingkungan, Sosial, Budaya, Internasional, "
                    "Daerah, Kriminal, Bisnis, Lifestyle, dan Lainnya. "
                    "Buatlah judul berita yang menarik dan deskripsi singkat untuk artikel berita ini. "
                    "Fokus pada aspek yang terlihat dalam gambar dan hindari spekulasi.\n\n"
                    "Format output yang diinginkan:\n"
                    "Kategori: [satu kategori yang dipilih]\n"
                    "Judul: [judul berita yang menarik]\n"
                    "Deskripsi: [deskripsi singkat artikel berita]",
              },
            ],
          },
        ],
      });
      final headers = {'Content-Type': 'application/json'};
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        print("AI TEXT: $text");

        if (text != null && text.isNotEmpty) {
          final lines = text.trim().split('\n');
          String? category;
          String? title;
          String? description;

          for (var line in lines) {
            final lower = line.toLowerCase();
            if (lower.startsWith('kategori:')) {
              category = line.substring(9).trim();
            } else if (lower.startsWith('judul:')) {
              title = line.substring(6).trim();
            } else if (lower.startsWith('deskripsi:')) {
              description = line.substring(10).trim();
            }
          }

          setState(() {
            _aiCategory = category ?? 'Berita Utama';
            if (title != null && title.isNotEmpty) {
              _titleController.text = title;
            }
            if (description != null && description.isNotEmpty) {
              _aiDescription = description;
              _descriptionController.text = description;
            }
          });
        }
      } else {
        debugPrint('Request failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to generate AI description: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Layanan lokasi tidak aktif.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Izin lokasi ditolak.')));
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> sendNotificationToTopic(String body, String senderName) async {
    final url = Uri.parse('https://https://fasum-clode.vercel.app/send-to-topic');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "topic": "berita-terbaru",
        "title": "📰 Berita Baru",
        "body": body,
        "senderName": senderName,
        "senderPhotoUrl":
            "https://static.vecteezy.com/system/resources/thumbnails/041/642/167/small_2x/ai-generated-portrait-of-handsome-smiling-young-man-with-folded-arms-isolated-free-png.png",
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Notifikasi berhasil dikirim')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal kirim notifikasi: ${response.body}')),
        );
      }
    }
  }

Future<void> _submitPost() async {
  if (_base64Image == null ||
      _titleController.text.isEmpty ||
      _descriptionController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mohon lengkapi judul, foto, dan deskripsi berita.'),
      ),
    );
    return;
  }

  setState(() => _isUploading = true);

  final now = Timestamp.now(); // Lebih baik menggunakan Timestamp
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengguna tidak ditemukan. Silakan masuk kembali.'),
      ),
    );
    return;
  }

  try {
    await _getLocation();

    // Ambil data user
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
        
    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    final fullName = userDoc.data()?['fullName'] ?? 'Anonim';
    print('User fullName: $fullName');

    // Simpan berita
    final docRef = await FirebaseFirestore.instance.collection('news').add({
      'image': _base64Image,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _aiCategory ?? 'Berita Utama',
      'createdAt': now, // Gunakan Timestamp
      'latitude': _latitude,
      'longitude': _longitude,
      'fullName': fullName, // Field yang konsisten
      'userId': uid,
      'status': 'published',
    });

    print('Berita berhasil disimpan dengan ID: ${docRef.id}');

    if (!mounted) return;

    sendNotificationToTopic(_titleController.text, fullName);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Berita berhasil dipublikasikan!')),
    );
  } catch (e) {
    debugPrint('Upload failed: $e');
    if (!mounted) return;
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mempublikasikan berita: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _isUploading = false);
    }
  }
}

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text('Kamera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Galeri'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFF87CEEB),
      appBar: AppBar(
        title: const Text(
          'Tambah Berita',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E5266),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Foto
            const Text(
              'Upload Foto Berita',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E5266),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _image == null
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 50,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ketuk untuk upload foto',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Judul Berita
            const Text(
              'Judul Berita',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF2E5266),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Masukkan judul berita...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Kategori
            const Text(
              'Kategori',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF2E5266),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showCategorySelection,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _aiCategory ?? 'Pilih kategori',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2E5266),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Deskripsi Berita
            const Text(
              'Deskripsi Berita',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF2E5266),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Masukkan deskripsi berita...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5266),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text(
                      'Posting Berita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
